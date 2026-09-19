---
name: viv-opsx-artifact-check
description: Audit OPSX artifacts (proposal, design, specs, tasks) against the conversation that produced them. Use after /opsx:ff or /opsx:continue to surface big decisions the agent made without user consultation, ambiguous wording that leaves room for poor implementation, scope drift, cross-artifact inconsistencies, and deferred placeholders — before /opsx:apply runs.
---

# OPSX Artifact Check

A post-creation audit for OPSX change artifacts. Compares what the agent **wrote** against what the user **said in conversation**, and flags issues that would cause poor implementation downstream.

This is distinct from `/opsx:verify` — that compares artifacts to code after implementation. This compares artifacts to **user intent** before implementation.

## When to use

- Immediately after `/opsx:ff` (most common case)
- After `/opsx:continue` if the user wants to sanity-check a single artifact
- When the user asks to "check", "review", "audit" OPSX artifacts, or says things like `did I miss anything?` / `is this clear enough to implement?`

Do NOT use:
- During or after `/opsx:apply` — use `/opsx:verify` instead
- If no artifacts exist for the change yet

## Workflow

### 1. Identify the change

If the user named one, use it. Otherwise infer from conversation context. If still ambiguous, run `openspec list --json` and ask the user with {{ask_user}}.

Announce: `Auditing change: <name>`.

### 2. Load both sides of the audit

In parallel:
- Read **every** artifact file in `openspec/changes/<name>/` (proposal.md, design.md, specs/**/*.md, tasks.md, anything else present)
- Re-scan the **prior conversation** in this session: what the user explicitly said, what they confirmed, what questions they did not answer, what the agent inferred or chose unilaterally

The conversation is the source of truth for **what the user wanted**. The artifacts are the source of truth for **what the agent wrote**. The gap between them is the audit surface.

### 3. Run the checks

For each category, scan and produce findings. Be conservative — false positives erode trust.

**A. Unconsulted or under-consulted decisions** (CRITICAL)
Decisions in the artifacts that the user never weighed in on. This includes a brief answer that the agent then extrapolated far beyond:
- Technology / library / pattern choices ("use Redis", "JWT in cookies", "Postgres JSONB")
- Architectural shape (sync vs async, monolith vs split, push vs pull, in-process vs queue)
- Scope boundaries (in/out-of-scope lists, features cut without discussion)
- Data model shape (field names, types, relations, constraints, indices)
- API surface (endpoint names, verbs, payload shapes, status codes)
- Failure / error semantics (retry, fallback, partial-success behavior)
- Performance / scale targets stated as facts ("must handle 10k rps")

**Under-consulted** means the user answered narrowly ("yes, async is fine") and the agent then committed to many downstream choices (queue tech, retry policy, dead-letter handling, observability hooks) as if all of them were sanctioned. Flag these as a single finding: "user agreed to X, agent committed to X + A + B + C — confirm A, B, C separately."

Cite the artifact location AND the conversation gap. Examples:
> `design.md:42` — chose Redis for rate limiting. User said "rate limit this endpoint" but did not specify a store. Confirm: Redis vs in-process vs Postgres?
> `design.md:88-120` — user said "make it async". Agent then chose SQS + 3-retry exponential backoff + DLQ + CloudWatch alarms. Confirm each of these independently.

**B. Ambiguity / interpretation risk** (CRITICAL)
Wording a downstream implementer could read multiple ways:
- Vague qualifiers: "fast", "robust", "scalable", "user-friendly", "appropriate", "reasonable"
- Quantifier-less statements: "users can have many tags" (bounded? unbounded? typical N?)
- Tasks without verifiable acceptance criteria ("polish the UI")
- Conditional logic stated incompletely ("if X, do Y" — what about !X?)
- Schemas described in prose instead of typed definitions
- Pronouns / "it" / "this" with unclear referents

For each finding, quote the phrase, name the alternative interpretations, and suggest a tightening.

**C. Scope drift** (WARNING)
Content not requested or that exceeds the request:
- Bonus features the user did not ask for
- Generalizations beyond the stated use case (`while we're at it…`)
- Premature extensibility / abstraction layers
- Tests, docs, migrations, telemetry the user did not scope

**D. Cross-artifact inconsistency** (WARNING)
- Proposal claims X, design specifies Y, tasks contain neither
- Spec scenarios not reflected anywhere in tasks
- Tasks reference concepts not defined in design or specs
- Counts mismatch (proposal lists 3 capabilities, `specs/` has 4)
- Capability names diverge across files

**E. Deferred / placeholder content** (WARNING)
- "TBD", "TODO", "FIXME", "to be decided"
- `We'll figure this out later` phrasing
- Empty sections or one-line placeholders that must have substance
- Unfilled template fragments

**F. Missing edge cases** (WARNING)
Flag when contextually relevant — missing edge cases is a frequent root cause of poor implementation, so promote freely:
- Empty / zero / null inputs
- Error and failure paths
- Concurrent / racing requests
- Auth / permission boundaries
- Migration / backwards compatibility
- Idempotency for retry-prone operations

### 4. Produce the report

Output the report and **nothing else** in this turn. No preamble ("Here are the findings..."), no trailer ("Let me know..."), no emojis, no decorative separators, no horizontal rules, no bold prose paragraphs between findings. The report is the entire response.

**Strict format — follow exactly.** Use this template verbatim, including section headers and the `(none)` placeholder when a section is empty. IDs are stable within a single report: `C1, C2, ...` numbered in the order findings appear under CRITICAL. The same applies to `W#` under WARNING and `S#` under SUGGESTION. Numbering restarts per severity. Do not skip numbers.

````
Change: <change-name>
Artifacts audited: <count> files

## CRITICAL
[C1] <category> | <path/to/artifact:line>
Found: "<exact quote or ≤15-word paraphrase>"
Concern: <one sentence, ≤25 words>
Suggest: <one concrete question OR one precise edit, ≤25 words>

[C2] <category> | <path/to/artifact:line>
Found: "..."
Concern: ...
Suggest: ...

## WARNING
[W1] <category> | <path/to/artifact:line>
Found: "..."
Concern: ...
Suggest: ...

## SUGGESTION
[S1] <category> | <path/to/artifact:line>
Found: "..."
Concern: ...
Suggest: ...

## Summary
CRITICAL: N | WARNING: M | SUGGESTION: K
Verdict: <one of the three verdicts below>
````

**Field rules:**
- `<category>` is one of: `unconsulted`, `ambiguity`, `scope-drift`, `inconsistency`, `deferred`, `edge-case` — exactly these tokens, lowercase, no synonyms.
- `<path/to/artifact:line>` must be a real path with a line number or a `§<section-heading>` reference. Never "see design.md" without a locator.
- `Found:` must be a quoted string (use `"..."`) or a paraphrase tagged with `(paraphrase)`. No mixed prose.
- `Concern:` and `Suggest:` are each a single sentence. Hard cap 25 words. No semicolons used as sentence joiners.
- Each finding is exactly the four lines shown — header line, `Found:`, `Concern:`, `Suggest:`. Separate findings with one blank line. No extra commentary between findings.
- If a severity bucket is empty, write the section header followed by `(none)` on the next line. Do not omit the section.

**Verdict (pick exactly one, verbatim):**
- `BLOCK — resolve CRITICAL before /opsx:apply`
- `PROCEED-WITH-CAUTION — no CRITICAL; review WARNINGs before /opsx:apply`
- `CLEAR — proceed to /opsx:apply`

Pick `BLOCK` iff `CRITICAL > 0`. Pick `CLEAR` iff `CRITICAL = 0` and `WARNING = 0`. Otherwise `PROCEED-WITH-CAUTION`.

### 5. Offer to resolve

After the report, in a **separate** message, ask which findings to resolve. Reference findings by ID only — for example "Resolve C1, C3, W2?". Do not restate the finding text. For each chosen ID, ask the user for the clarification with {{ask_user}}, then edit the relevant artifact directly. Do not auto-edit without confirmation.

## Heuristics

- **Read the conversation, not just the artifacts.** This is what makes the skill different from `/opsx:verify`.
- **Quote, do not paraphrase.** Findings must cite exact wording so the user can judge severity. If you must paraphrase (artifact text too long), tag it `(paraphrase)`.
- **Conservative bias.** CRITICAL means "implementation will be wrong". SUGGESTION means "nice to tighten". When unsure, downgrade.
- **Do not flag confirmed decisions again.** If the conversation shows the user agreed — even briefly — it is not unconsulted.
- **Aggregate.** If five tasks share the same ambiguity, file one finding and list all five locations on the header line separated by `;`. Do not file five near-duplicate findings.

## Output discipline

The report's value depends on being machine-greppable and stable across runs. Treat the format in step 4 as a contract, not a suggestion.

- **No emojis. Anywhere.** Not in headers, not in findings, not in the summary.
- **No bullets, no markdown bold, no horizontal rules** inside findings. The four-line per-finding shape is the only structure.
- **No prose around the report.** No "I found the following...", no "Hope this helps", no closing remarks. The report starts at `Change:` and ends at the verdict line.
- **Stable IDs.** Number findings in the order they appear under each severity, starting at 1. Never skip numbers, never reuse numbers, never use sub-IDs like `C1a`.
- **Deterministic ordering.** Within each severity, order findings by `(artifact-path ASCII order, then line number ascending)`. Same inputs must produce the same IDs.
- **Empty sections shown explicitly.** Always print all three severity headers. Use `(none)` when empty. This keeps IDs unambiguous when sections grow between runs.
- **Word caps are hard caps.** If a `Concern:` or `Suggest:` exceeds 25 words, rewrite — do not let it bleed onto a second line.

## Guardrails

- Read every artifact in the change folder, not just the latest one created
- Do not edit artifacts during the audit phase — produce the report first, then ask
- Do not invent decisions the agent did not actually make
- If the conversation history is unavailable or too short to compare against, say so explicitly and audit only intra-artifact issues (categories D, E, F still work)
- If the change has no artifacts yet, stop and tell the user to run `/opsx:new` or `/opsx:ff` first
