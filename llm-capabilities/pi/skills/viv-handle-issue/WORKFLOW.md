# Issue Coordinator Workflow

## Authority

The skill invocation authorizes this workflow for the supplied issue. It authorizes one new branch when the current branch does not start with `feat/` or `bugfix/`.

Do not stage, commit, push, merge, rebase, tag, stash, reset, restore, or close the issue. Do not use a worktree. Preserve all user changes.

Only the implementor edits product code and tests. The coordinator edits OpenSpec artifacts and controls the workflow. Reviewers do not edit files.

## OpenSpec instructions

For each OpenSpec phase, read its instruction file in full. Use the first file that exists in this search order:

1. `.pi/skills/<skill>/SKILL.md`
2. `.pi/prompts/opsx-<command>.md`
3. `.claude/skills/<skill>/SKILL.md`
4. `.claude/commands/opsx/<command>.md`

Use these skill and command names:

| Phase | Skill | Command |
| --- | --- | --- |
| Explore | `openspec-explore` | `explore` |
| Fast-forward | `openspec-ff-change` | `ff` |
| Apply | `openspec-apply-change` | `apply` |
| Implementation review | `openspec-verify-change` | `verify` |
| Sync | `openspec-sync-specs` | `sync` |
| Archive | `openspec-archive-change` | `archive` |

Treat the issue or change name as the input to the instruction file. Stop with a setup blocker when no instruction file exists for a necessary phase.

## Start

1. Parse the issue reference, effort, flavor, and skill directory.
2. Read `flavors.json` from the skill directory.
3. Use `gh issue view` to read the title, body, labels, comments, state, and repository.
4. Stop if the current repository is not the issue repository.
5. Read each applicable instruction file in full.
6. Read the related code, tests, configuration, and OpenSpec files.
7. Do the relevant baseline tests before an implementation change.

Run `git branch --show-current`. If the branch has no permitted prefix, make a branch from the current `HEAD`:

- Use `bugfix/<issue>-<slug>` for a defect.
- Use `feat/<issue>-<slug>` for new behavior.
- Ask the user when the issue facts do not show the correct type.

This branch action spends the authorization. Do not do a different Git mutation.

## Clarity gate

Apply this gate during the Explore and Fast-forward phases.

Stop the phase when one of these conditions is true:

- The objective or an acceptance condition does not make sense.
- The next decision has no clear answer from the issue, the user, or the repository.
- The proposed solution uses technology or architecture with no close local pattern.
- Plausible solutions cause materially different behavior or costs.

First, inspect the repository for facts that can answer the question. If the question remains, return one focused question to the parent. State the conflict and give a recommendation with its reason.

Do not select an unfamiliar design through inference. Do not write more artifacts until the user answers. Resume after the parent supplies the answer.

## Explore and specify

1. Obey the Explore instructions for the issue.
2. Apply the clarity gate throughout the exploration.
3. Obey the Fast-forward instructions for the same change.
4. Apply the clarity gate while the artifacts take shape.
5. Write the issue facts, user answers, acceptance conditions, change name, and artifact paths to a temporary review packet.

The skill invocation authorizes the OpenSpec artifacts for this issue. Ask again only when a phase expands the issue scope.

## Audit the artifacts

Do the coordinator audit with `viv-opsx-artifact-check`. Then start two `viv-issue-reviewer` subagents in parallel with fresh context. Use the `reviewer` and `secondReviewer` model settings for the selected flavor and effort.

Give each reviewer the same review packet. Tell each reviewer to do an artifact audit and to return findings without file edits.

Merge equivalent findings by location and concern. Investigate conflicting findings against the repository and issue. Keep only findings that the evidence supports.

Warnings and suggestions do not block the Apply phase. Record them in the review packet for the implementor and implementation reviewers.

Correct the supported critical findings in one correction pass. Ask the user when a correction contains a product or architecture decision that the evidence does not settle.

After the correction pass, do a targeted closure review. Inspect each supported critical finding and the artifact text changed for it. Do not run the full audits again. Do not inspect unchanged artifact text for new findings.

A new finding blocks progress only when the correction directly caused it and it is critical. Correct only that finding and do its targeted closure review again. Continue when no supported critical finding remains.

## Apply and verify

Start `viv-issue-implementor` with fresh context. Use the `implementor` model settings for the selected flavor and effort. Give it the review packet, change name, artifact paths, baseline result, and resolved audit findings. Keep its run identifier.

The implementor obeys the Apply instructions, completes the tasks, and does the applicable tests.

After the implementor returns, start two `viv-issue-reviewer` subagents in parallel from the same repository state. Use the `reviewer` and `secondReviewer` model settings again. Tell both reviewers to obey the instruction file for `verify`.

Merge equivalent findings. Send each supported correctness or acceptance finding to the same implementor run. Also send each failure in the required test suite. Resume that run to make corrections and do the affected tests.

Run the independent reviews again after a correction. Continue until no blocking finding remains and the required test results are successful. Ask the user if repository evidence cannot resolve a reviewer conflict.

## Sync and archive

Obey the Sync instructions after the review passes. Then obey the Archive instructions.

Do not archive incomplete artifacts or tasks. Do not skip a necessary specification sync. If the Archive phase finds a conflict, resolve it or ask one focused question.

Make sure that the archive exists and the active change no longer exists. Remove the temporary review packet.

Report the issue, branch, change name, results of tests, review result, and archive path. Stop. Leave all other Git work and GitHub state to the user.
