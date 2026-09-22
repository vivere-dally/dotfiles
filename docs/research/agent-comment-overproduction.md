# Agent comment overproduction

- Research date: 2026-09-22.
- Scope: source comments that agents add near new or changed code.
- Sources: local capability rules, official vendor documentation, first-party writing, and original research.

## Conclusion

The current rule is the strongest local cause. It bans weak comments but gives stronger, broader instructions to write comments.

This conclusion comes from instruction and output alignment. The evaluation below can measure the causal effect.

The strongest cause is `write the comment or the contract before the code` (`llm-capabilities/rules/code-comments.md:23-26`). This instruction turns a source comment into a reasoning surface.

The rule also tells agents to record considered alternatives and deliberate absences (`llm-capabilities/rules/code-comments.md:10-21`). These directions apply without an admission test.

The fix is a short positive rule with a strict admission test. It must also tell new type members to match adjacent style.

Do not start with a hard comment gate. First, compare the new rule with the current rule on representative edit tasks.

## What the current system does

The renderer copies the comment rule to each harness. It also joins all rule files into one instruction file for some harnesses (`llm-capabilities/render.ts:157-170`).

The comment rule contains useful limits:

- Code comments must not restate code (`llm-capabilities/rules/code-comments.md:3-8`).
- Code comments must not record change history (`llm-capabilities/rules/code-comments.md:38-40`).
- Types must carry exhaustiveness facts (`llm-capabilities/rules/code-comments.md:65-73`).

Other directions put pressure in the opposite direction:

- Agents must record each considered alternative (`llm-capabilities/rules/code-comments.md:10-14`).
- Agents must note each deliberate absence (`llm-capabilities/rules/code-comments.md:16-21`).
- Comments receive the same rank as the most important code (`llm-capabilities/rules/code-comments.md:23-25`).
- Agents must write a comment or contract before code (`llm-capabilities/rules/code-comments.md:25-26`).
- Agents must comment each fact that a reader does not expect (`llm-capabilities/rules/code-comments.md:28-36`).

The TODO rule asks for an issue link (`llm-capabilities/rules/code-comments.md:18`). The document-pointer rule forbids issue references (`llm-capabilities/rules/code-comments.md:42-52`). Thus one case has conflicting instructions.

The current automated gate does not apply the comment rule. It loads only `ste.md` (`llm-capabilities/ste/core.ts:551-558`).

The write event contains file paths only (`llm-capabilities/ste/core.ts:565-569`). It reviews Markdown prose, not source comments (`llm-capabilities/ste/core.ts:611-623`).

The Pi adapter sends a file path after an edit (`llm-capabilities/adapters/pi/ste-gate.ts:66-83`). The Codex hook also runs only the STE command (`llm-capabilities/adapters/codex/hooks.json:16-28`).

Thus the comment policy is prompt context. No tool can tell an agent that a new comment violates it.

## Why agents comment the changed part

The active task makes the new behavior highly visible. The unchanged neighboring code has no comparable task rationale.

This explanation is an inference from the prompt and the output pattern. The sources do not prove a unique internal cause.

The current rule then converts that visible rationale into source prose. The before-code direction makes this conversion explicit.

This effect explains the new type-arm pattern. The new arm gets an explanation because the task mentions it, while equivalent arms remain commentless.

The changelog ban does not prevent this pattern. An agent can rewrite task history as a present-tense reason and obey the literal ban.

The local writing skill also warns that prohibitions activate the unwanted concept. It recommends a positive target beside each necessary ban (`llm-capabilities/skills/viv-writing-for-agents/SKILL.md:74`).

Anthropic gives similar advice. It says to state the desired action and to use examples that match the desired output.
[Anthropic prompt guidance](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

Anthropic also says that instruction files are context, not enforced configuration. It recommends concise, specific, and consistent instructions.
[Claude Code memory](https://code.claude.com/docs/en/memory)

The generated instruction file contains all shared rules. A broad positive comment instruction can remain salient even when later text limits comment content.

## What the first-party sources support

The Helsing article does not support comments for each change. Its bright comment color exposes noise and makes weak comments easy to remove.

The article favors durable information: correctness arguments, hard-learned failures, unusual constants, load-bearing choices, and rejected tempting alternatives.
[On comments](https://blog.helsing.ai/posts/on-comments/)

The article also favors ticket links for TODOs and stable references for outside facts. A complete ban on such links forces more rationale into source files.

Jon Gjengset's current agent configuration asks for a top-down narrative only in complex or non-obvious code. It excludes simple utilities and direct code.
[Jon Gjengset's agent instructions](https://github.com/jonhoo/configs/blob/master/agentic/AGENTS.md)

That conditional boundary is important. The local rule turns the narrative technique into a general before-code instruction.

Recent research gives another useful clue. Models often emit comments and then use those comments as context for later code.

The study found no reliable relation between comment frequency and pass rate. Correct solution content helped, while wrong-topic comments harmed results.
[Talking to Itself While Coding](https://arxiv.org/abs/2609.09242)

This result supports a narrow conclusion. Some models use comments as temporary solution context, but more comments do not imply better code.

Another study varied configuration size, position, structure, and contradiction. Its tested file structures had no clear corrected effect on instruction adherence.
[Instruction Adherence in Coding Agent Configuration Files](https://arxiv.org/abs/2605.10039)

This study has a narrow task and model set. It suggests that file rearrangement alone will not solve the problem.

## Proposed replacement rule

Replace the general sections above the language lists with this text. Keep the escape-hatch and exhaustiveness lists after it.

```markdown
# Code comments

## Default

- Keep routine code commentless. Use names, types, structure, and tests to carry facts that code can express.
- Match the comment style of adjacent code.
- Keep a new union member, enum case, field, or branch uncommented when equivalent neighbors have no comments.
- A changed line does not need a comment because it changed.

## Admission test

Add or update a comment only when each condition is true:

- The fact is not visible from the code.
- The fact remains useful without the current task, diff, or session.
- Without the fact, a future reader can plausibly misunderstand the code or make a harmful edit.
- A name, type, test, assertion, or clearer structure cannot carry the fact better.

Eligible facts include an external constraint, correctness argument, load-bearing invariant, unusual constant, deliberate omission, or accepted tradeoff.

## Content and placement

- State the hidden constraint and its consequence.
- Keep the work log, task narrative, and routine rejected alternatives outside source files.
- Put a broad design decision in an architecture record. Put a change explanation in the commit or pull request.
- State the local fact before a stable external link. A TODO can link to its issue.
- For an escape hatch, state the invariant that makes it safe and necessary.

## Final comment review

Inspect only comments that the patch added or changed. Remove each comment that fails the admission test or duplicates adjacent code.
```

This version gives the agent a positive default. It also gives one exact rule for new union and type members.

The admission test separates durable facts from task salience. The final review places the rule next to the completion decision.

## Examples for the rule

Examples can steer output more reliably than another abstract ban. The rule needs examples from routine and load-bearing edits.

### Routine type member

```ts
type Event =
  | { kind: "opened"; path: string }
  | { kind: "saved"; path: string }
  | { kind: "closed"; path: string };
```

The new member has no comment because its peers and fields explain it.

### Hidden aggregation rule

```ts
// Match only parent prefixes; child records already contribute to the parent total.
const projectPrefix = /^projects\/[a-z0-9-]+\/$/;
```

The comment earns its place because the aggregation rule is not visible in the expression.

### Escape hatch

```ts
// The schema validates every field before this boundary, so this cast cannot admit unchecked input.
const record = value as StoredRecord;
```

The comment gives the invariant that makes the cast safe. A comment such as `Cast to StoredRecord` would fail the admission test.

## Evaluation plan

Build a held-out fixture set from real edit shapes. Keep the same task, repository context, model, effort, and harness for each comparison.

The fixture set must include these cases:

- Add a routine member among commentless union members. The expected patch has no new comment.
- Add a member among documented members. The expected patch matches the local style.
- Add a member with a unique outside constraint. The expected patch states that constraint.
- Fix a direct conditional bug. The expected patch has no task narrative.
- Add an unsafe cast. The expected patch states its safety invariant.
- Preserve a non-obvious order dependency. The expected patch states the order and consequence.
- Add an unusual constant from an outside protocol. The expected patch states the source constraint.

Score the patch on separate properties:

- Unwanted-comment rate counts added comments that fail the admission test.
- Required-comment recall counts hidden constraints that the patch preserves in prose.
- Adjacent-style conformance checks equivalent neighboring constructs.
- History leakage detects text that depends on the task, diff, or session.
- Functional correctness measures tests and behavior separately from comment quality.

Use repeated samples because model output varies. Compare the present rule, the replacement, and the replacement with examples.

Reviewers must not know which rule made each patch. The desired result lowers unwanted comments without lower correctness or required-comment recall.

Anthropic recommends task-specific tests, measurable success criteria, automation where possible, and clear grader rubrics.
[Anthropic evaluation guidance](https://platform.claude.com/docs/en/test-and-evaluate/develop-tests)

## Enforcement design

Start with a post-edit advisory. Trigger it only when the current tool call adds or changes a source comment.

The advisory can say:

> Review the comments from this edit. Keep only comments that pass the code-comment admission test and match adjacent style.

This message puts the admission test near the edit. It does not force a comment when an edit contains none.

Do not compute this advice from the repository-wide Git diff. That diff can contain user work from before the tool call.

Each adapter must capture the edit payload or a before-and-after snapshot. The common event must carry changed comment lines, not file paths alone.

Claude Code `PostToolUse` hooks can return feedback after a successful tool call. They cannot undo the completed edit.
[Claude Code hooks](https://code.claude.com/docs/en/hooks)

A `Stop` hook can request one cleanup pass when flagged comments remain. It needs a one-pass guard to prevent a review loop.

Use hard checks only for facts that tools can prove. Good candidates include a comment on one new union arm beside uncommented equivalent arms.

A syntax-tree check can identify that pattern with high precision. It stays language-specific and needs an exception for unique hidden constraints.

Word filters for `new`, `now`, or `changed` have low precision. These words can describe real time or state invariants.

A rule that rejects every new comment has high recall and poor precision. It would reject the exact comments that the policy values.

An LLM comment grader adds cost and can disagree with the coding model. Use it for evaluation before it becomes an interactive gate.

## Recommendation

Replace the broad positive directions with the proposed admission rule. Add the adjacent-style examples and do the held-out comparison.

If unwanted comments remain, add the diff-aware post-edit advisory. Add a hard structural check only after its false-positive rate is known.
