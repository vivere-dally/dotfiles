---
name: viv-opsx-compact
description: Compact an OpenSpec corpus that has grown redundant — merge overlapping capabilities, fold hollow wiring requirements into the specs that own the real behavior, repair or drop stale code references, absorb one-requirement specs, and trim enumerated scenarios. Scans the whole repo, fans out bounded parallel agents over spec clusters, emits one ranked plan, then applies approved items as a normal OpenSpec change with REMOVED/RENAMED/MODIFIED deltas. Use monthly, or when the user says specs have "grown too much", asks to compact/consolidate/dedupe/prune specs, or mentions spec sprawl, spec drift, or stale specs.
---

# OPSX Spec Compaction

Specs accumulate. Every change adds requirements. Almost none remove them. After a few
months the corpus describes the product **plus** its own history: duplicate capabilities,
requirements pinned to files that moved, scenarios that enumerate variants of one behavior.

This skill finds that residue and removes it **without losing behavioral coverage**.

Distinct from the neighboring skills: `/opsx:verify` compares artifacts to code after
implementation. `viv-opsx-artifact-check` compares artifacts to user intent before it.
This one compares the **spec corpus to itself**.

## When to use

- Monthly maintenance pass, or whenever the corpus passes ~100 specs
- User says specs "grew too much", "are duplicated", "need cleaning/compacting/consolidating"
- After a large refactor or a monorepo restructure, when specs still describe the old layout

Do NOT use:
- Mid-change, with unarchived work in `openspec/changes/` touching the same capabilities —
  compaction would conflict with in-flight deltas. Archive or finish those first.
- On `openspec/changes/archive/**`. Archived changes are an immutable record.

## Workflow

### Phase 0 — Scan (deterministic, ~5s)

```bash
python3 "{{skill_dir}}/scripts/scan.py" <repo-root> --agents <N> --out <repo-root>/{{scratch_dir}}/opsx-signals.json
```

{{skill_dir_note}}

`--agents N` (default 8) sets how many clusters the corpus is packed into — one agent per
cluster in Phase 1. Raise it for a bigger corpus or a faster pass.

The script handles every countable signal: inventory, requirement- and capability-level
Jaccard overlap, broken code references classified `moved` vs `dead`, leaked delta headers,
tiny specs, enumeration-heavy specs, wiring-only scenarios. Read its stderr summary aloud
to the user before fanning out — it is the baseline the final report is measured against.

Then check the corpus parses cleanly, so compaction is not blamed for pre-existing breakage:

```bash
openspec validate --specs --strict --json
```

Record `git rev-parse HEAD` and confirm a clean working tree. Compaction must be revertible.

### Phase 1 — Fan out over clusters

Clusters are connected components of the capability-overlap graph, seeded by name prefixes.
Thus every spec that can merge with another lands in the context of the same agent. Splitting a
family across agents produces contradictory merge proposals.

For the clusters in `clusters[]`, {{start_subagents}}. Each agent receives its
cluster's `paths[]` and the signal rows scoped to its members, and returns findings only —
it must not edit anything. Give every agent `CANDIDATES.md` as its rubric.

Each finding must carry: operation, source location(s), the **surviving owner**, a
behavior-preservation note, and a confidence. Ask each agent for one fixed JSON
shape, so synthesis never has to parse prose.

### Phase 2 — Synthesize one ranked plan

Merge all cluster findings into a single list ranked by payoff, ignoring cluster
boundaries — the user asked for one plan, not eight. Rank by `(tokens removed) ×
confidence`, with drift repairs first since they are mechanical and risk-free.

Before reporting, run the **conservation check** in `CANDIDATES.md`. Any finding that fails
it is dropped, not downgraded.

Emit the report exactly as specified in `REPORT-FORMAT.md`. That format is a contract:
stable IDs and deterministic ordering are what let two monthly reports be diffed.

### Phase 3 — Apply approved items

Only on explicit approval, and only for the IDs the user named. See `APPLY.md`.

## Guardrails

- **Behavior coverage is conserved.** A requirement can be merged, reworded, or relocated.
  It can only be *deleted* when either an owning spec already states the same contract, or
  the user confirms the behavior no longer exists. Never delete to hit a reduction target.
- **Name the owner.** Every merge finding names the surviving spec and requirement. A merge
  without a named owner is not a finding.
- **`dead` refs are questions, not deletions.** A reference to a deleted file can mean the
  spec is stale *or* that the feature was dropped without its spec. Ask. Do not assume.
- **Never touch `openspec/changes/archive/**`.**
- **No silent caps.** If the fan-out truncates candidates, say so in the report footer.
- **Report first, always.** Phase 3 never runs in the same turn as Phase 2.

## Files

- `CANDIDATES.md` — what each operation looks like, and the conservation check (agent rubric)
- `REPORT-FORMAT.md` — the strict output contract
- `APPLY.md` — turning approved findings into an OpenSpec change
