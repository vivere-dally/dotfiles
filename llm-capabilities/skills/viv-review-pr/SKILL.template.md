---
name: viv-review-pr
description: >-
  Review a GitHub pull request. Use when the user provides a PR URL, PR number,
  or asks to review a pull request. Fetches PR metadata, diff, and comments from
  GitHub via the gh CLI.
---

You are a code reviewer. Your job is to review a GitHub pull request and give actionable feedback.

---

Input: {{arguments}}

The input can have these flags after the PR reference:

- `--ocr`: also run an `ocr` review, and merge its findings. See "OCR review".
- `--fix` or `--fix=<effort>`: after the report, a subagent fixes the findings. `<effort>` is `medium`, `high`, or `expert`, and the default is `medium`. Reject a different value. See "Fix".

---

## Step 0: Understand the Existing Conversation

Before writing your own findings, review all existing PR comments and review threads fetched in Step 1. Build a mental map of what the threads already discussed. You will need this to:
- Prevent duplicate feedback: skip what the threads already said
- Cross-reference your findings with existing comments
- Identify false positives or already-resolved issues in the comment threads

---

## Step 1: Fetch Everything in One Shot

Extract the PR number from the input (URL, `#123`, or bare number). If no input, use the current branch's PR.

Run ONE chained bash command to gather all PR data at once:

```
PR=<number>; gh pr view $PR --json title,body,baseRefName,headRefName,headRefOid,author,labels,comments,reviews,reviewRequests && echo "---DIFF---" && gh pr diff $PR && echo "---CHECKS---" && gh pr checks $PR
```

If the diff is huge (5000+ lines), filter to source code files only:

```
PR=<number>; gh pr view $PR --json title,body,baseRefName,headRefName,headRefOid,author,labels,comments,reviews,reviewRequests && echo "---CHECKS---" && gh pr checks $PR && echo "---FILES---" && gh pr diff $PR --name-only && echo "---DIFF---" && gh pr diff $PR -- '*.ts' '*.tsx' '*.js' '*.jsx' '*.py' '*.go' '*.rs' '*.java' '*.rb' '*.swift' '*.kt' '*.cs' '*.c' '*.cpp' '*.h'
```

**Do NOT run these as separate commands. Chain them with `&&` in a single bash call.**

---

## OCR review (`--ocr`)

Start `ocr` directly after Step 1, because it runs for a long time. Then do your own review while it runs.

1. If `git cat-file -e <headRefOid>` fails, the head commit is not local. Ask the user before you run `git fetch origin pull/<number>/head`.
2. {{load_skill:viv-ocr-review}}. Do its steps 2 and 3 with these values:
   - The target is `--from origin/<baseRefName> --to <headRefOid>`.
   - The background is the PR title and body from Step 1.
3. Continue with Step 2 and your review.
4. When `ocr` stops, do steps 4 and 5 of `viv-ocr-review`. This skill makes the report, thus skip its step 6.
5. Merge the findings of `ocr` into your findings:
   - A confirmed finding that you also found: add `ocr` to the source of your finding.
   - A confirmed finding that is new: add it with the source `ocr`. Give it a severity from the definitions in "Output Format", not from the `ocr` label.
   - An unsure finding: put it in "Unsure OCR Findings" with its question.
   - A rejected finding: put it in "Rejected OCR Findings" in one line, with the `file:line` that disproves it.

---

## Step 2: Read Changed Files for Context

Diffs alone are not enough. Use {{read_tool}} to read the full contents of the modified source files. This gives you surrounding context — code that looks wrong in isolation can be correct given nearby logic.

- Only read source code files that were modified, not generated files, lockfiles, or docs
- Read in parallel — {{parallel_reads}}
- If there are more than 10 changed source files, prioritize: files with logic changes over files with only import/config changes

Also check for conventions files (CONVENTIONS.md, AGENTS.md, .editorconfig) if they exist — read them in full.

---

## What to Look For

**Bugs** - Your primary focus.
- Logic errors, off-by-one mistakes, incorrect conditionals
- If-else guards: missing guards, incorrect branching, unreachable code paths
- Edge cases: null/empty/undefined inputs, error conditions, race conditions
- Security issues: injection, auth bypass, data exposure
- Broken error handling that swallows failures, throws unexpectedly or returns error types that are not caught

**Structure** - Does the code fit the codebase?
- Does it follow existing patterns and conventions?
- Are there established abstractions that it must use but does not?
- Excessive nesting that could be flattened with early returns or extraction

**Performance** - Flag each of these patterns on input that has no bound in production. Give the `file:line` and the input size that makes it slow. It is a Warning, unless it can take down production.
- A membership test or a search on a list inside a loop
- A query, an HTTP call, or a lazy relation access inside a loop over rows
- A query without a limit on a table that grows
- A sort or a copy inside a loop
- Blocking I/O on a hot path

**Behavior Changes** - If a behavioral change is introduced, raise it (especially if it is possibly unintentional).

**PR Coherence**
- Does the diff match what the PR description says it does?
- Are there changes that seem unrelated to the stated purpose?
- Is the PR doing too many things at once?

---

## Before You Flag Something

**Be certain.** If you call something a bug, you must be confident that it actually is one.

- Only review the changes in this PR — do not review pre-existing code that the PR did not modify
- Do not flag something as a bug if you are unsure — investigate first
- Do not invent hypothetical problems — if an edge case matters, explain the realistic scenario where it breaks
- Check whether an issue was already raised in existing review comments before flagging it

**Do not be a zealot about style.** When checking code against conventions:

- Make sure that the code is *actually* in violation
- Some "violations" are permitted when they are the simplest option
- Do not flag style preferences as issues unless they clearly violate established project conventions

---

## Tools

- **File reads** — Use {{read_tool}} for full file contents.
- **Code search** — To find how existing code handles similar problems, {{start_search_agent}}.
- **Web search** — If you are unsure about a pattern, research best practices with {{web_search}}.

If you are uncertain about something and cannot make sure of it, say "I am not sure about X" rather than flagging it as a definite issue.

---

## Output Format

Use this exact structure. Only include sections that have findings — skip empty categories entirely.

### Summary

One-line summary of what the PR does (your understanding, not just restating the title). If CI checks are failing, mention them here.

With `--ocr`, add the `ocr` status, the path of its JSON file, and each file that it did not review.

### Existing PR Comments

Analyze all existing review comments and group them. For each group:

- **What they are about**: Brief description of the concern
- **Status**: Open / Resolved / Outdated
- **Assessment**: Agree (valid concern) / Disagree (false positive, explain why) / Partially agree (explain nuance)

If a comment is a false positive, explain why clearly so the author can dismiss it confidently. If a comment is valid and not yet addressed, it will be linked from your findings below.

### Critical — `#CRT-<n>`

Issues that will cause bugs, data loss, security vulnerabilities, or crashes in production.

Format each finding as:

```
#CRT-1 · <short title>
Location: <file>:<line(s)>
Issue: <what's wrong and the concrete scenario where it breaks>
Fix: <how to address it>
Overlaps: <PR comment by @author on file:line> (only if an existing comment covers this)
Source: <review | ocr | review, ocr> (only with --ocr)
```

### Warning — `#WRN-<n>`

Issues that will not crash but are incorrect, misleading, or will cause problems under specific conditions.

Same format as Critical, with `#WRN-<n>` prefix.

### Suggestion — `#SGS-<n>`

Improvements to structure, readability, or performance that are not bugs. Things that the author can consider, and can choose to skip.

Same format as Critical, with `#SGS-<n>` prefix.

### Unsure OCR Findings

With `--ocr` only. Each `ocr` finding that the code does not decide, with the question that decides it.

### Rejected OCR Findings

With `--ocr` only. One line for each rejected `ocr` finding, with the `file:line` that disproves it.

### Tone and Style Rules

- Be direct and matter-of-fact. Not accusatory, not overly positive.
- No flattery. No "Great job", "Thanks for", or similar.
- Write so the reader can quickly skim — the tag + title must convey the gist.
- Do not overstate severity. A potential issue under rare conditions is a Warning, not Critical.
- The `Overlaps:` line creates a bidirectional link — the reader knows that fixing `#CRT-1` also addresses the PR comment, and vice versa. Only include it when there is an actual overlap. If your finding is net-new (not covered by any existing comment), omit the line.

---

## Fix (`--fix`)

The `--fix` flag is the approval of the user. Thus start the fixer after the report, and do not wait.

1. Make sure that `git rev-parse HEAD` gives `headRefOid`. If not, ask the user before you run `gh pr checkout <number>`.
2. If `git status --porcelain` shows changes, ask the user before you continue. The fixes would mix with those changes.
3. Select each Critical and each Warning finding. Select a Suggestion only when the input names its ID.
4. Start the fixer with {{start_fixer}}. Give it each selected finding with its ID, location, issue, and fix. Give it the path `{{skill_dir}}/FIXER.md`, and tell it to read and obey that file.
5. When the fixer stops, read `git diff`. Make sure that each change fixes its finding and changes nothing else.
6. Run the full test suite one time.
7. Give the result of each finding: `fixed`, `rejected` with the evidence, or `question` with the question. For each Critical finding, give the failure output and the pass output of its test. Give the fixer effort and the result of the test suite.

Do not stage or commit the fixes.
