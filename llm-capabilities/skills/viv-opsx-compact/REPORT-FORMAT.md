# Report Format

Output the report and **nothing else** in that turn. No preamble, no trailer, no emojis, no
horizontal rules, no bold prose between findings. The report is the entire response.

Its value depends on being greppable and comparable month to month. Treat this as a
contract, not a suggestion.

## Template

Follow verbatim, including headers and the `(none)` placeholder for empty sections.

````
Repo: <path>
Specs: <N> (<module>: <n>, <module>: <n>)
Baseline: <R> reqs, <S> scenarios, ~<T>k tok, scenario ratio <X>
Clusters: <K> | Candidates examined: <C>

## PLAN
[P1] <OP> | <confidence> | ~<tokens>k | <source> -> <owner>
Found: "<exact quote or ≤15-word paraphrase>"
Why: <one sentence, ≤25 words, why this is redundancy not layering>
Preserves: <where the removed coverage survives, ≤20 words>
Ref: <fingerprint>

[P2] ...

## QUESTIONS
[Q1] <OP> | <source>
Found: "..."
Ask: <one question, ≤25 words>
Ref: <fingerprint>

## Summary
Operations: <N> (high <H> / medium <M> / low <L>)
Questions: <Q>
Projected: specs <before> -> <after> | reqs <before> -> <after> | tokens ~<before>k -> ~<after>k
Verdict: <one verdict line, verbatim from below>
````

## Field rules

- `<OP>` is exactly one of `FOLD`, `REPAIR`, `MERGE`, `ABSORB`, `TRIM`. No synonyms.
- `<confidence>` is exactly `high`, `medium`, or `low`.
- `<source>` and `<owner>` are real `module/capability:line` locators. Never a bare filename.
  Multiple sources are joined with `;` on the header line — never filed as separate findings.
- `Found:` is a quoted string, or a paraphrase tagged `(paraphrase)`. No mixed prose.
- `Why:` and `Preserves:` are one sentence each. The caps are hard, as shown. Rewrite rather than wrap.
- `Ref:` is the first 8 chars of a stable hash over `op + sorted(sources) + owner`. It lets
  the user diff this month's report against last month's — IDs renumber, `Ref` does not.
- Every finding is exactly the five lines shown, separated by one blank line.
- Empty section: print the header, then `(none)`. Never omit a section.

## Ordering and IDs

Deterministic — the same corpus must produce the same report:

1. `REPAIR` findings first (mechanical, risk-free, unblock the rest).
2. Then by descending payoff: `tokens_saved × {high: 1.0, medium: 0.6, low: 0.3}`.
3. Ties broken by source path ASCII, then line number ascending.

Number `P1..Pn` in final order, restarting at 1. Never skip, reuse, or sub-ID (`P1a`).
`Q1..Qn` numbered independently.

## Projected totals

`Projected` is the arithmetic sum of the plan's own `tokens_saved`, not an estimate of what
compaction "could" achieve. If the user applies a subset, the delta will be smaller — say
so only if asked. Never project a percentage the plan does not itself account for.

## Verdict

Pick exactly one, verbatim:

- `READY — <N> operations, no questions blocking`
- `NEEDS-INPUT — <Q> questions must be answered before applying`
- `CLEAN — corpus shows no compaction opportunities above threshold`

`CLEAN` iff PLAN is empty. `NEEDS-INPUT` iff any question is a `dead`-ref or a `low`
confidence removal. Otherwise `READY`.

## Footer

If anything was capped or skipped, append one line after the verdict:

```
Capped: <what was truncated and why>
```

Silent truncation reads as "the corpus was fully covered" when it was not. Never omit this.

## After the report

In a **separate** message, ask which IDs to apply. Reference by ID only — do not restate
finding text. `Apply P1, P3, P7?` is the whole message. Then follow `APPLY.md`.
