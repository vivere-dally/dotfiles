# Issue Coordinator Workflow

## Authority

The skill invocation authorizes this workflow for the supplied issue. It authorizes one new branch when the current branch does not start with `feat/` or `bugfix/`.

Do not stage, commit, push, merge, rebase, tag, stash, reset, restore, or close the issue. Do not use a worktree. Preserve all user changes.

Only the implementor edits product code and tests. The coordinator edits OpenSpec artifacts and controls the workflow. Reviewers never edit files.

## Start

1. Parse the issue reference and effort.
2. Use `gh issue view` to read the title, body, labels, comments, state, and repository.
3. Stop if the current repository is not the issue repository.
4. Read each applicable instruction file in full.
5. Read the code, tests, configuration, and OpenSpec files that relate to the issue.
6. Run the relevant baseline tests before an implementation change.

Run `git branch --show-current`. If the branch has no permitted prefix, make a branch from the current `HEAD`:

- Use `bugfix/<issue>-<slug>` for a defect.
- Use `feat/<issue>-<slug>` for new behavior.
- Ask the user when the issue facts do not show the correct type.

This branch action spends the authorization. Do not do a different Git mutation.

## Clarity gate

Apply this gate during `/opsx:explore` and `/opsx:ff`.

Stop the phase when one of these conditions is true:

- The objective or an acceptance condition does not make sense.
- The next decision has no clear answer from the issue, the user, or the repository.
- The proposed solution uses technology or architecture with no close local pattern.
- Plausible solutions cause materially different behavior or costs.

First, inspect the repository for facts that can answer the question. If the question remains, ask the user one focused question. State the conflict and give a recommendation with its reason.

Do not select an unfamiliar design through inference. Do not write more artifacts until the user answers. Use `AskUserQuestion` when available. Otherwise, return the question to the parent for relay and resume this agent after the answer.

## Explore and specify

1. Invoke `/opsx:explore` for the issue with the `Skill` tool.
2. Apply the clarity gate throughout the exploration.
3. Invoke `/opsx:ff` for the same change with the `Skill` tool.
4. Apply the clarity gate while the artifacts take shape.
5. Record the issue facts, user answers, acceptance conditions, change name, and artifact paths in a temporary review packet.

The skill invocation authorizes the OpenSpec artifacts for this issue. Ask again only when a phase expands the issue scope.

## Audit the artifacts

Run independent audits against the same review packet:

1. Load `viv-opsx-artifact-check` and do the coordinator audit.
2. Start the reviewer agent for the selected effort. Ask it to do the artifact audit.
3. Run `"$HOME/.claude/skills/viv-handle-issue/scripts/codex-review.sh" artifacts <effort> <packet>`.

If Codex is absent, continue with the Claude audits and record that fact. Do not substitute a different model.

Merge equivalent findings by location and concern. Investigate conflicting findings against the repository and issue. Correct factual errors, ambiguity, drift, and artifact conflicts.

Ask the user when a correction contains a product or architecture decision that the evidence does not settle. Do the audits again after a correction. Continue when no critical finding remains and each warning has a clear resolution.

## Apply and verify

Start the implementor agent for the selected effort. Give it the issue packet, change name, artifact paths, baseline result, and resolved audit findings. Keep its agent ID.

The implementor invokes `/opsx:apply`, completes the tasks, and runs the applicable tests.

After the implementor returns, start these reviews from the same repository state:

1. Ask the reviewer agent to invoke `/opsx:verify` for the change.
2. Run `"$HOME/.claude/skills/viv-handle-issue/scripts/codex-review.sh" implementation <effort> <packet>`.

Merge equivalent findings. Send each supported correctness or acceptance finding to the same implementor agent. Also send each failure in the suite. Resume that agent to make the corrections and run the affected tests.

Do the independent reviews again after a correction. Continue until no blocking finding remains and the required tests pass. Ask the user if reviewers conflict and repository evidence cannot resolve the conflict.

## Sync and archive

The coordinator invokes `/opsx:sync` after verification passes. Then the coordinator invokes `/opsx:archive`.

Do not archive incomplete artifacts or tasks. Do not skip a necessary spec sync. If the archive phase finds a conflict, resolve it or ask one focused question.

Make sure that the archive exists and the active change no longer exists. Remove the temporary review packet.

Report the issue, branch, change name, result of the tests, review result, and archive path. Stop. Leave all Git work and GitHub state to the user.
