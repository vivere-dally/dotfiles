# Candidate Rubric

Given to each Phase 1 agent. Judge only the specs in your cluster. Return findings. Edit nothing.

The scan already counted everything countable. Your job is the part arithmetic cannot do:
deciding whether an overlap is **redundancy** or **legitimate layering**. Most overlap is
legitimate. Two specs sharing a name or a vocabulary is not evidence — read both.

## The five operations

### FOLD — hollow wiring requirement into the spec that owns the behavior

The most common real win. One spec registers a feature. Another spec specifies it. The
registering spec accrues requirements whose scenarios assert only that wiring exists.

**Signal:** `wiring_scenarios` rows, and `duplicate_requirement_pairs` with `cross_capability: true`.

**Test:** strip the requirement. Is any *behavioral* contract lost — an error path, a state
transition, an output shape? If the only loss is "the subcommand appears in `--help`", fold it.

```
cli-commands:222  "`tool export` writes the report archive"
                  Scenarios: "Export subcommand is registered"
                             "the report is resolved, the archive is written, path printed"
report-export:6   "CLI export command"
                  Scenarios: missing report / unwritable path / existing file / empty report
```

`report-export` owns the contract. `cli-commands` restates its existence. FOLD into `report-export`.

**Counter-example — do not fold:** a command-surface spec that genuinely owns *registration
semantics* (lazy-import boundaries, channel gating, exit-code conventions) is a real
capability. Hollow means the scenarios assert nothing but presence.

### REPAIR — broken code reference

**Signal:** `broken_code_refs`, already classified.

- `status: moved` with a `likely_new_path` — mechanical. Make sure that the file really is the same
  subject, then update the path. High confidence, near-zero risk.
- `status: dead` — **a question, never an automatic deletion.** Either the spec is stale, or
  the feature was deleted and its spec outlived it. Those need opposite fixes. Grep for the
  described behavior before you propose anything. If it stays unresolved, report it as a question.

Separately, `path_pinned_requirements` counts requirements citing a source path at all. A
spec pinned to a filename re-breaks on every refactor. Where the path is incidental to the
contract, propose dropping the pin — the spec states *what*, the code decides *where*.

### MERGE — sibling capabilities

**Signal:** `capability_overlap_pairs`.

Highest file-count reduction, highest review cost, most likely to be wrong. Overlap scores
measure shared vocabulary, not shared responsibility. Specs in one subsystem legitimately
share nouns.

**Test — merge only when all three hold:**
1. The same *subject* is specified in both, not merely the same domain.
2. A reader would not know which spec to update for a given change.
3. The merged spec stays coherent under one purpose statement.

```
container-runner  "Image source is the config default, overridden per job"
image-catalog     "Image reference comes from config, overridden per job"
```
Same subject, ambiguous ownership → MERGE, naming one owner.

```
app/structured-logging  file rotation, retention, PII redaction at the logger root
lib/structured-logging  the injected Logger interface, namespace binding, error normalization
```
Same name, same vocabulary, **different subjects** — one is a sink, one is an injected interface. DO NOT
MERGE. Cross-module pairs are usually this: a producer and its consumer.

### ABSORB — one- or two-requirement spec into its parent

**Signal:** `tiny_specs`.

A spec carrying a single requirement usually documents a decision that belongs inside a
larger capability. Absorb it, preserving the requirement verbatim, and name the parent.

Keep it standalone when it is a deliberate boundary other specs reference by name, or when the
capability is genuinely small but real (a feature flag, a compatibility guarantee).

### TRIM — enumerated scenarios

**Signal:** `enumeration_heavy_specs` (scenario:requirement ratio ≥ `--ratio-outlier`,
default 4.5). Weigh it against the scan's `corpus_scenario_ratio`.

A high ratio is a hint, not a verdict. Some requirements legitimately need many scenarios —
a parser, a state machine, an auth matrix.

**Trim only scenarios that differ by a value rather than by behavior.** Rewrite them as one
scenario with a table or a parameter list, and never delete coverage:

```
"renders red"  "renders blue"  "renders green"   ->  one scenario over a themed-color set
```

Keep every scenario that exercises a distinct branch, failure mode, or boundary. If trimming
would remove the only test of an edge case, do not trim.

## Confidence

- `high` — mechanical, or the owner is unambiguous and coverage demonstrably survives
- `medium` — the judgment holds but a reviewer could disagree on the surviving owner
- `low` — plausible, needs the user's product knowledge

Report `low` findings as questions. Do not inflate confidence to make a plan look decisive.

## Conservation check

Run before any finding leaves your hands. A finding that fails is **dropped, not downgraded**.

1. **Coverage** — every behavioral assertion in the removed text still appears somewhere in
   the corpus after the operation. Name where.
2. **Owner** — the surviving spec is named, and it is the spec a reader would search first.
3. **No orphan references** — nothing else in the corpus refers to a capability you removed
   by name. Grep before proposing.
4. **Reversible** — the operation is expressible as OpenSpec deltas, so it can be reviewed
   as a change rather than an unexplained rewrite.

## Return shape

One entry per finding:

- `op` — `FOLD` | `REPAIR` | `MERGE` | `ABSORB` | `TRIM`
- `sources` — `path:line` for each location involved
- `owner` — surviving `spec` / `requirement`, or `null` for REPAIR
- `rationale` — one sentence, why this is redundancy and not layering
- `preserves` — where the removed coverage survives (the conservation answer)
- `tokens_saved` — rough integer
- `confidence` — `high` | `medium` | `low`
- `question` — set when the user must decide. The plan surfaces it instead of acting
