#!/usr/bin/env bash
# Compares the generation speed of the GLM models that the Pi viv-handle-issue
# flavors use. The serving speed of a model changes with the provider load, so
# run this again before you move a role in flavors.json from one model to another.
# Each call is short (thinking low), and the order alternates on each trial so
# that a change in load affects each model equally.
set -euo pipefail

usage() {
    echo "usage: glm-speed.sh [trials] [model...]" >&2
    echo "default: 3 trials of zai/glm-5.3-flash and zai/glm-5.3" >&2
    exit 2
}

trials=${1:-3}
[[ $trials =~ ^[1-9][0-9]*$ ]] || usage
shift || true
models=("$@")
[[ ${#models[@]} -gt 0 ]] || models=(zai/glm-5.3-flash zai/glm-5.3)

command -v pi >/dev/null || {
    echo "glm-speed: pi is not available" >&2
    exit 10
}

python3 -I - "$trials" "${models[@]}" <<'PY'
import json
import statistics
import subprocess
import sys
import time

trials = int(sys.argv[1])
models = sys.argv[2:]
prompt = (
    "Write a Python function that parses an ISO 8601 duration such as P3DT4H5M "
    "into seconds. Give the function and three test cases, with no other text."
)


def run(model):
    command = [
        "pi", "-p", "--mode", "json", "--no-session", "--no-tools", "--no-extensions",
        "--no-skills", "--no-context-files", "--no-prompt-templates",
        "--model", f"{model}:low", prompt,
    ]
    start = time.monotonic()
    first = None
    usage = {}
    process = subprocess.Popen(command, stdout=subprocess.PIPE, text=True)
    for line in process.stdout:
        now = time.monotonic()
        try:
            event = json.loads(line)
        except json.JSONDecodeError:
            continue
        if first is None and event.get("type") == "message_update":
            first = now
        if event.get("type") == "turn_end":
            usage = event.get("message", {}).get("usage") or {}
    process.wait()
    end = time.monotonic()
    output = usage.get("output", 0)
    return {
        "model": model,
        "ok": process.returncode == 0 and first is not None and output > 0,
        "first_s": (first - start) if first else None,
        "total_s": end - start,
        "output": output,
        "tok_s": output / (end - first) if first and end > first else None,
    }


rows = []
for trial in range(trials):
    order = models if trial % 2 == 0 else models[::-1]
    for model in order:
        row = run(model)
        rows.append(row)
        if row["ok"]:
            print(
                f"{model:24} first output {row['first_s']:5.1f} s  "
                f"total {row['total_s']:6.1f} s  {row['output']:6} tokens  "
                f"{row['tok_s']:6.1f} tok/s",
                flush=True,
            )
        else:
            print(f"{model:24} failed", flush=True)

print()
for model in models:
    ok = [row for row in rows if row["model"] == model and row["ok"]]
    if not ok:
        print(f"{model:24} no successful call")
        continue
    print(
        f"{model:24} median: first output {statistics.median(r['first_s'] for r in ok):.1f} s, "
        f"{statistics.median(r['tok_s'] for r in ok):.1f} tok/s ({len(ok)} calls)"
    )
PY
