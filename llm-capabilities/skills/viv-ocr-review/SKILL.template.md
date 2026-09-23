---
name: viv-ocr-review
description: Runs an Open Code Review (`ocr`) review of a branch range, a commit, or the working tree, then does a check of each finding against the code. Use when the user mentions ocr or Open Code Review, or asks for an ocr review.
---

# Open Code Review

`ocr` sends a git diff to the LLM of its own configuration, and writes findings for each line. A finding is a claim by a different model. Each finding gets a check against the code before it goes to the user.

Input: {{arguments}}

## 1. Select the target

Get the target from the input:

- A range: `--from <base> --to <head>`, for example `--from origin/main --to origin/feat/173-zip-archive-job`. `ocr` reviews the diff from the merge base.
- A commit: `--commit <sha>`. `ocr` reviews the commit against its parent.
- The working tree: no target flag. `ocr` reviews the staged, unstaged, and untracked changes.

If the input gives no target, use the working tree.

A ref such as `origin/main` is only as new as the last fetch. `git fetch` changes the repository, thus ask before you run it.

## 2. Write the background

The findings are better when `ocr` knows the intent of the change. Write the intent to `{{scratch_dir}}/ocr/background.md` with the file tool, not with the shell. Then a quote or a `$(...)` in a pull request body cannot run.

Get the intent from these sources, in this order:

- the request of the user
- the pull request of the head branch: `gh pr view <head> --json title,body`
- the issue that the pull request or the branch name refers to

If the change reads a database or loops over input that grows, add a request to the background. Ask for a check of lookups in loops, queries in loops, and queries without a limit.

`ocr` rejects a background file above 1 MiB, or above 8000 characters after it removes the markup. Write a summary that fits, and keep each requirement and each acceptance criterion.

## 3. Run the review

```bash
ocr review --audience agent --format json \
  --background-file {{scratch_dir}}/ocr/background.md \
  --output {{scratch_dir}}/ocr/<name>.json \
  <target flags>
```

`<name>` identifies the target, for example the head branch with each `/` replaced by `-`.

A review can take more than 30 minutes, because each review round of a file group has a `--timeout` of 15 minutes. Run the command with {{long_command}}.

If the command fails:

- `command not found`: ask the user for consent, then run `brew install open-code-review`.
- An LLM error: the provider has no configuration, or it does not answer. Ask the user to run `ocr config provider` and then `ocr llm test`. Do not ask for an API key in the chat.
- An interrupted range or commit review prints `retry with: --resume <id>`. Run the same command again with `--resume <id>`. A working-tree review cannot continue.

## 4. Read the result

Read the status first, then the findings. The `jq` fields below keep the `thinking` text of each finding out of the context:

```bash
jq '{status, message, summary, warnings, failed: .manifest.coverage.failed}' <file>
jq '.comments[] | {path, start_line, end_line, severity, category, content, suggestion_code}' <file>
```

- `complete` or `success`: each selected file got a review.
- `partial`, `failed`, or `completed_with_errors`: some files got no review. Give the path and the reason of each from `failed`.
- `summary.budget_exceeded` is true when the token budget stopped the review.

If `start_line` and `end_line` are both 0, `ocr` did not find the position. Find the code that the `content` describes.

## 5. Check each finding

Do a check of each `critical`, `high`, and `medium` finding. Read `low` findings only when the user asks for them.

1. Read the code at the `path` and the lines. When the claim depends on a caller or a callee, read it too.
2. Give a verdict:
   - `confirmed`: the code shows the failure. Write the input or the state that causes it.
   - `rejected`: the code prevents the failure. Write the `file:line` that prevents it.
   - `unsure`: the code does not decide it. Write the question that decides it.

The step is complete when each `critical`, `high`, and `medium` finding has a verdict.

## 6. Report

- Group the confirmed findings by severity. Give the `path:line`, the category, the failure, and the fix of each.
- Give each unsure finding with its question.
- Give each rejected finding in one line, with its reason.
- Give the path of the JSON file, and each file that got no review.

Change code only when the user asks for fixes. Then fix only the confirmed findings.

## Delegation mode

In delegation mode, `ocr` selects the files and the rules, and you do the review. Use it when the user asks for it, or when `ocr` has no LLM and the user agrees. Then read [DELEGATE.md](DELEGATE.md).
