#!/usr/bin/env python3
"""Deterministic pre-pass for the viv-opsx-compact skill.

Counting, similarity scoring, and drift detection are reproducible operations,
so they run here instead of inside an agent. The fan-out agents then spend
their whole context on judgment -- is this overlap real, is this merge safe --
rather than re-deriving arithmetic that would drift between runs and make two
monthly reports incomparable.

Emits JSON on stdout (or --out) plus a human summary on stderr.

Usage:
    python3 scan.py [REPO_ROOT] [--out signals.json]
                    [--min-req-sim 0.40] [--min-cap-sim 0.25] [--agents 8]
"""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

# Structural markers fixed by the OpenSpec spec format.
RE_REQUIREMENT = re.compile(r"^### Requirement:\s*(.*)$", re.M)
RE_SCENARIO = re.compile(r"^#### Scenario:\s*(.*)$", re.M)
# A delta header inside a *live* spec means an archive/sync left change syntax
# behind; the parser treats it as a section, so the requirements under it are
# silently outside the main `## Requirements` block.
RE_DELTA_HEADER = re.compile(r"^##\s+(ADDED|MODIFIED|REMOVED|RENAMED)\s+Requirements\s*$", re.M)
RE_CODE_REF = re.compile(r"`((?:src|tests?|lib|app|packages)/[A-Za-z0-9_./-]+\.[A-Za-z0-9]{1,4})`")

# Scenario titles asserting only that something is wired up. These describe the
# spec's own registration rather than product behavior, and are the usual
# residue when a command spec and a behavior spec both grew around one feature.
RE_WIRING = re.compile(
    r"\b(is |are )?(registered|listed|wired|exported|exposed|present|available|defined|installed)\b"
    r"|\bhelp\b|\bexists\b|\bshows up\b|\bappears in\b",
    re.I,
)

STOPWORDS = set(
    """the a an of to and or is are be been being shall must not that this it its with for on in as by
    from at when then given if any all each system user when- and- then- also should may can will
    requirement scenario purpose spec specification section""".split()
)


def tokens(text: str) -> set[str]:
    """Content tokens for similarity. Short and stop words carry no signal and
    inflate Jaccard denominators unevenly across specs of different verbosity."""
    return {w for w in re.findall(r"[a-z0-9]+", text.lower()) if len(w) > 3 and w not in STOPWORDS}


def jaccard(a: set[str], b: set[str]) -> float:
    if not a or not b:
        return 0.0
    return len(a & b) / len(a | b)


# Fixture and scratch trees contain throwaway `openspec/` instances that would
# otherwise be scanned as real corpora and pollute every count in the report.
SKIP_DIRS = {
    "node_modules", ".git", "dist", "build", ".next", "archive", "coverage",
    "fixtures", "__fixtures__", "__snapshots__", "tmp", ".tmp", "vendor", ".venv",
}


def discover_roots(repo: str, extra_skip: set[str]) -> list[dict]:
    """Find every `openspec/specs` directory, so a monorepo with per-module
    OpenSpec instances is handled identically to a single-root project."""
    roots = []
    skip = SKIP_DIRS | extra_skip
    for dirpath, dirnames, _ in os.walk(repo):
        dirnames[:] = [d for d in dirnames if d not in skip]
        if os.path.basename(dirpath) == "specs" and os.path.basename(os.path.dirname(dirpath)) == "openspec":
            openspec_dir = os.path.dirname(dirpath)
            module = os.path.relpath(os.path.dirname(openspec_dir), repo)
            roots.append(
                {
                    "module": "." if module == "." else module,
                    "specs_dir": os.path.relpath(dirpath, repo),
                    "openspec_dir": os.path.relpath(openspec_dir, repo),
                    "code_root": os.path.relpath(os.path.dirname(openspec_dir), repo),
                }
            )
    return sorted(roots, key=lambda r: r["module"])


def parse_spec(path: str) -> dict:
    text = open(path, encoding="utf-8", errors="replace").read()
    # Split on the requirement marker so each chunk carries its own scenarios,
    # which is what makes per-requirement similarity meaningful.
    chunks = re.split(r"^### Requirement:", text, flags=re.M)[1:]
    requirements = []
    line_of = {}
    for m in RE_REQUIREMENT.finditer(text):
        line_of.setdefault(m.group(1).strip(), text[: m.start()].count("\n") + 1)
    for chunk in chunks:
        title = chunk.split("\n", 1)[0].strip()
        requirements.append(
            {
                "title": title,
                "line": line_of.get(title, 0),
                "body": chunk,
                "scenarios": [s.strip() for s in RE_SCENARIO.findall(chunk)],
                "code_refs": sorted(set(RE_CODE_REF.findall(chunk))),
                "tokens": tokens(chunk),
            }
        )
    return {
        "text": text,
        "lines": text.count("\n") + 1,
        "chars": len(text),
        "requirements": requirements,
        "delta_headers": [m.group(1) for m in RE_DELTA_HEADER.finditer(text)],
        "tokens": tokens(text),
    }


def resolve_ref(repo: str, code_root: str, ref: str, index: dict[str, list[str]]) -> tuple[str, str | None]:
    """Classify a spec's code reference as live, moved, or dead.

    Specs cite paths inconsistently -- some relative to the module root, some
    already relative to `src/` -- so a single-base check reports live files as
    dead. Only after every plausible base fails does a basename lookup decide
    between "the file moved" (repair the path) and "the file is gone" (the
    requirement may describe deleted behavior). Those two need different fixes,
    so collapsing them into one "stale" bucket would make the report unusable.
    """
    for base in (code_root, os.path.join(code_root, "src"), ".", "src"):
        if os.path.exists(os.path.join(repo, base, ref)):
            return "live", os.path.normpath(os.path.join(base, ref))
    matches = index.get(os.path.basename(ref), [])
    if matches:
        return "moved", matches[0]
    return "dead", None


def build_basename_index(repo: str) -> dict[str, list[str]]:
    index: dict[str, list[str]] = defaultdict(list)
    for dirpath, dirnames, filenames in os.walk(repo):
        dirnames[:] = [
            d for d in dirnames if d not in {"node_modules", ".git", "dist", "build", ".next", "coverage", "openspec"}
        ]
        for fn in filenames:
            index[fn].append(os.path.relpath(os.path.join(dirpath, fn), repo))
    return index


def git_last_touched(repo: str, relpath: str) -> str | None:
    try:
        out = subprocess.run(
            ["git", "-C", repo, "log", "-1", "--format=%ad", "--date=short", "--", relpath],
            capture_output=True,
            text=True,
            timeout=15,
        )
        return out.stdout.strip() or None
    except Exception:
        # Staleness is a nice-to-have signal; a non-git checkout must still scan.
        return None


def similar_pairs(items: list[dict], key: str, threshold: float) -> list[dict]:
    """All pairs above `threshold` Jaccard.

    Prunes with the exact bound Jaccard(a,b) <= min(|a|,|b|)/max(|a|,|b|): when
    two token sets differ enough in size, no overlap can reach the threshold, so
    the pair is skipped without computing the intersection.
    """
    pairs = []
    ordered = sorted(items, key=lambda x: len(x[key]))
    for i, a in enumerate(ordered):
        na = len(a[key])
        if not na:
            continue
        for b in ordered[i + 1 :]:
            nb = len(b[key])
            if na / nb < threshold:
                # Sorted by size, so every later b is at least as large: no
                # remaining pair for this `a` can clear the bound either.
                break
            s = jaccard(a[key], b[key])
            if s >= threshold:
                pairs.append({"score": round(s, 3), "a": a, "b": b})
    return sorted(pairs, key=lambda p: -p["score"])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("repo", nargs="?", default=".")
    ap.add_argument("--out", default=None, help="write JSON here instead of stdout")
    ap.add_argument("--min-req-sim", type=float, default=0.40)
    ap.add_argument("--min-cap-sim", type=float, default=0.25)
    ap.add_argument("--ratio-outlier", type=float, default=4.5, help="scenario:requirement ratio flagged as enumeration-heavy")
    ap.add_argument("--tiny-spec", type=int, default=2, help="requirement count at or below which a spec is a fold candidate")
    ap.add_argument("--agents", type=int, default=8, help="target cluster count for the fan-out")
    ap.add_argument("--exclude", default="", help="comma-separated extra directory names to skip")
    args = ap.parse_args()

    repo = os.path.abspath(args.repo)
    extra_skip = {d.strip() for d in args.exclude.split(",") if d.strip()}
    roots = discover_roots(repo, extra_skip)
    if not roots:
        print(f"error: no openspec/specs directory found under {repo}", file=sys.stderr)
        return 2

    specs: list[dict] = []
    for root in roots:
        specs_dir = os.path.join(repo, root["specs_dir"])
        for cap in sorted(os.listdir(specs_dir)):
            spec_path = os.path.join(specs_dir, cap, "spec.md")
            if not os.path.isfile(spec_path):
                continue
            parsed = parse_spec(spec_path)
            rel = os.path.relpath(spec_path, repo)
            specs.append(
                {
                    "module": root["module"],
                    "capability": cap,
                    "path": rel,
                    "code_root": root["code_root"],
                    "id": f"{root['module']}/{cap}",
                    **parsed,
                }
            )

    # ---- inventory -------------------------------------------------------
    per_module: dict[str, dict] = defaultdict(lambda: {"specs": 0, "requirements": 0, "scenarios": 0, "lines": 0, "chars": 0})
    for s in specs:
        m = per_module[s["module"]]
        m["specs"] += 1
        m["requirements"] += len(s["requirements"])
        m["scenarios"] += sum(len(r["scenarios"]) for r in s["requirements"])
        m["lines"] += s["lines"]
        m["chars"] += s["chars"]
    for m in per_module.values():
        m["approx_tokens"] = m["chars"] // 4

    total = {
        "specs": len(specs),
        "requirements": sum(len(s["requirements"]) for s in specs),
        "scenarios": sum(len(r["scenarios"]) for s in specs for r in s["requirements"]),
        "lines": sum(s["lines"] for s in specs),
        "approx_tokens": sum(s["chars"] for s in specs) // 4,
    }

    # ---- signal: broken code references ----------------------------------
    basenames = build_basename_index(repo)
    broken_refs, ref_total = [], 0
    for s in specs:
        for r in s["requirements"]:
            for ref in r["code_refs"]:
                ref_total += 1
                status, resolved = resolve_ref(repo, s["code_root"], ref, basenames)
                if status != "live":
                    broken_refs.append(
                        {
                            "spec": s["id"],
                            "path": s["path"],
                            "line": r["line"],
                            "requirement": r["title"],
                            "ref": ref,
                            "status": status,
                            "likely_new_path": resolved,
                        }
                    )

    # ---- signal: path-pinned requirements --------------------------------
    path_pinned = [
        {"spec": s["id"], "path": s["path"], "line": r["line"], "requirement": r["title"], "refs": r["code_refs"]}
        for s in specs
        for r in s["requirements"]
        if r["code_refs"]
    ]

    # ---- signal: leaked delta headers ------------------------------------
    leaked = [
        {"spec": s["id"], "path": s["path"], "headers": s["delta_headers"]} for s in specs if s["delta_headers"]
    ]

    # ---- signal: tiny specs ----------------------------------------------
    tiny = sorted(
        (
            {"spec": s["id"], "path": s["path"], "requirements": len(s["requirements"]), "lines": s["lines"]}
            for s in specs
            if len(s["requirements"]) <= args.tiny_spec
        ),
        key=lambda x: x["requirements"],
    )

    # ---- signal: enumeration-heavy specs ---------------------------------
    ratio_outliers = []
    for s in specs:
        nreq = len(s["requirements"])
        nsc = sum(len(r["scenarios"]) for r in s["requirements"])
        if nreq and nsc / nreq >= args.ratio_outlier:
            ratio_outliers.append(
                {"spec": s["id"], "path": s["path"], "requirements": nreq, "scenarios": nsc, "ratio": round(nsc / nreq, 2)}
            )
    ratio_outliers.sort(key=lambda x: -x["ratio"])
    corpus_ratio = round(total["scenarios"] / total["requirements"], 2) if total["requirements"] else 0

    # ---- signal: wiring-only scenarios -----------------------------------
    wiring = [
        {"spec": s["id"], "path": s["path"], "line": r["line"], "requirement": r["title"], "scenario": sc}
        for s in specs
        for r in s["requirements"]
        for sc in r["scenarios"]
        if RE_WIRING.search(sc)
    ]

    # ---- signal: duplicate requirement pairs -----------------------------
    flat_reqs = [
        {"spec": s["id"], "path": s["path"], "line": r["line"], "title": r["title"], "tokens": r["tokens"]}
        for s in specs
        for r in s["requirements"]
    ]
    req_pairs = [
        {
            "score": p["score"],
            "a": {k: p["a"][k] for k in ("spec", "path", "line", "title")},
            "b": {k: p["b"][k] for k in ("spec", "path", "line", "title")},
            "cross_capability": p["a"]["spec"] != p["b"]["spec"],
        }
        for p in similar_pairs(flat_reqs, "tokens", args.min_req_sim)
    ]

    exact_titles = defaultdict(list)
    for fr in flat_reqs:
        exact_titles[fr["title"].strip().lower()].append(f"{fr['spec']}:{fr['line']}")
    exact_dupes = [{"title": t, "locations": v} for t, v in sorted(exact_titles.items()) if len(v) > 1]

    # ---- signal: capability overlap --------------------------------------
    cap_pairs = [
        {
            "score": p["score"],
            "a": p["a"]["id"],
            "b": p["b"]["id"],
            "a_path": p["a"]["path"],
            "b_path": p["b"]["path"],
            "cross_module": p["a"]["module"] != p["b"]["module"],
        }
        for p in similar_pairs(specs, "tokens", args.min_cap_sim)
    ]

    # ---- signal: staleness ------------------------------------------------
    stale = []
    for s in specs:
        d = git_last_touched(repo, s["path"])
        if d:
            stale.append({"spec": s["id"], "path": s["path"], "last_touched": d})
    stale.sort(key=lambda x: x["last_touched"])

    # ---- clusters: the fan-out work units ---------------------------------
    # Union-find over the overlap graph, seeded with name-prefix families. A
    # merge decision needs every related spec in one agent's context at once --
    # splitting a family across agents produces contradictory merge proposals.
    parent: dict[str, str] = {s["id"]: s["id"] for s in specs}

    def find(x: str) -> str:
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    def union(x: str, y: str) -> None:
        rx, ry = find(x), find(y)
        if rx != ry:
            parent[ry] = rx

    by_prefix: dict[tuple[str, str], list[str]] = defaultdict(list)
    for s in specs:
        by_prefix[(s["module"], s["capability"].split("-")[0])].append(s["id"])
    for members in by_prefix.values():
        for other in members[1:]:
            union(members[0], other)
    for cp in cap_pairs:
        union(cp["a"], cp["b"])

    groups: dict[str, list[str]] = defaultdict(list)
    for s in specs:
        groups[find(s["id"])].append(s["id"])

    spec_by_id = {s["id"]: s for s in specs}
    clusters = []
    for members in groups.values():
        members.sort()
        clusters.append(
            {
                "members": members,
                "paths": [spec_by_id[m]["path"] for m in members],
                "requirements": sum(len(spec_by_id[m]["requirements"]) for m in members),
                "approx_tokens": sum(spec_by_id[m]["chars"] for m in members) // 4,
            }
        )
    # Biggest first: the largest cluster dominates wall-clock, so it should
    # claim an agent slot before the singletons are packed.
    clusters.sort(key=lambda c: -c["approx_tokens"])

    # Real merge clusters get their own agent slot first, because a cross-spec
    # merge decision is the expensive judgment. Singletons carry only per-spec
    # hygiene, so they ride along in the lightest slots rather than each
    # consuming an agent.
    multi = [c for c in clusters if len(c["members"]) > 1]
    singles = [c for c in clusters if len(c["members"]) == 1]
    slots = max(1, args.agents)

    packed = [
        {**c, "members": list(c["members"]), "paths": list(c["paths"])}
        for c in multi[:slots]
    ]
    if not packed:
        packed = [{"members": [], "paths": [], "requirements": 0, "approx_tokens": 0}]

    # Least-loaded-first assignment keeps agent context roughly balanced, which
    # matters more than grouping neatness: one overloaded agent sets wall-clock.
    for c in multi[slots:] + singles:
        target = min(packed, key=lambda p: p["approx_tokens"])
        target["members"].extend(c["members"])
        target["paths"].extend(c["paths"])
        target["requirements"] += c["requirements"]
        target["approx_tokens"] += c["approx_tokens"]

    for i, c in enumerate(packed):
        c["cluster_id"] = f"K{i + 1}"

    payload = {
        "repo": repo,
        "roots": roots,
        "inventory": {"total": total, "per_module": dict(per_module), "corpus_scenario_ratio": corpus_ratio},
        "thresholds": {
            "min_req_sim": args.min_req_sim,
            "min_cap_sim": args.min_cap_sim,
            "ratio_outlier": args.ratio_outlier,
            "tiny_spec": args.tiny_spec,
        },
        "signals": {
            "broken_code_refs": broken_refs,
            "code_ref_total": ref_total,
            "path_pinned_requirements": path_pinned,
            "leaked_delta_headers": leaked,
            "tiny_specs": tiny,
            "enumeration_heavy_specs": ratio_outliers,
            "wiring_scenarios": wiring,
            "duplicate_requirement_pairs": req_pairs,
            "exact_duplicate_titles": exact_dupes,
            "capability_overlap_pairs": cap_pairs,
            "spec_last_touched": stale,
        },
        "clusters": packed,
    }

    out = json.dumps(payload, indent=2, default=str)
    if args.out:
        os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(out)
    else:
        print(out)

    w = sys.stderr.write
    w(f"scanned {total['specs']} specs across {len(roots)} openspec root(s)\n")
    for mod, m in sorted(per_module.items()):
        w(f"  {mod}: {m['specs']} specs, {m['requirements']} reqs, {m['scenarios']} scen, ~{m['approx_tokens'] // 1000}k tok\n")
    w(f"  TOTAL: {total['requirements']} reqs, {total['scenarios']} scen, ~{total['approx_tokens'] // 1000}k tok, ratio {corpus_ratio}\n")
    w("signals:\n")
    moved = sum(1 for r in broken_refs if r["status"] == "moved")
    w(f"  broken code refs ............ {len(broken_refs)} of {ref_total} ({moved} moved, {len(broken_refs) - moved} dead)\n")
    w(f"  path-pinned requirements .... {len(path_pinned)}\n")
    w(f"  leaked delta headers ........ {len(leaked)}\n")
    w(f"  tiny specs (<={args.tiny_spec} reqs) ....... {len(tiny)}\n")
    w(f"  enumeration-heavy specs ..... {len(ratio_outliers)}\n")
    w(f"  wiring-only scenarios ....... {len(wiring)}\n")
    w(f"  dup requirement pairs ....... {len(req_pairs)} (exact titles: {len(exact_dupes)})\n")
    w(f"  capability overlap pairs .... {len(cap_pairs)}\n")
    w(f"clusters for fan-out: {len(packed)}\n")
    for c in packed:
        w(f"  {c['cluster_id']}: {len(c['members'])} specs, {c['requirements']} reqs, ~{c['approx_tokens'] // 1000}k tok\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
