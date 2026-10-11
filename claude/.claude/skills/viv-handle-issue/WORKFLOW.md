# Issue Coordinator Workflow

## Authority

The skill invocation authorizes this workflow for the supplied issue. It authorizes one new branch when the current branch does not start with `feat/` or `bugfix/`.

Do not stage, commit, push, merge, rebase, tag, stash, reset, restore, or close the issue. Do not use a worktree. Preserve all user changes.

Only the implementor edits product code and tests. The coordinator edits OpenSpec artifacts and controls the workflow. Reviewers never edit files.

## Fast mode

The `--fast` flag selects a shorter workflow for a small issue. The agent that runs the skill does the work itself, thus no coordinator or implementor agent starts. That agent edits the OpenSpec artifacts, the product code, and the tests. Only the verification stays independent.

Do these steps in order:

1. Do the "Start" section.
2. Do the "Explore and specify" section with the clarity gate. Ask the user with `AskUserQuestion`.
3. Load `viv-opsx-artifact-check` and audit the artifacts. Correct the supported critical findings in one pass.
4. Invoke `/opsx:apply`, complete the tasks, and run the applicable tests.
5. Start the reviewer agent for the selected effort, and wait for it. Ask it to invoke `/opsx:verify` for the change. Give it the review packet, the change name, the artifact paths, and the baseline result. Keep its agent ID.
6. Investigate each finding against the repository. Fix each supported correctness or acceptance finding, and run the affected tests.
7. If step 6 changed the code, start `viv-issue-rechecker` as the "Recheck" section tells.
8. If a supported critical finding remains after that check, stop and ask the user. Do not start a third review.
9. Do the "Sync and archive" section.

Do not do the `Size the issue`, `Audit the artifacts`, or `Apply and verify` section. Do not run the external reviews.

## Start

1. Parse the issue reference and effort.
2. Use `gh issue view` to read the title, body, labels, comments, state, and repository.
3. Stop if the current repository is not the issue repository.
4. Read each applicable instruction file in full.
5. Start `viv-issue-scout` with the issue facts. It returns a map of the related code, tests, configuration, and OpenSpec files, and a size recommendation.
6. Read in full the files that the map marks as central. Read the other files only when a decision needs them.
7. Run the relevant baseline tests before an implementation change.

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

## Size the issue

After the Explore phase, select the size of the issue. Use the scout recommendation and the exploration facts. The size controls the number of reviews and correction rounds. The effort controls the strength of each agent. The two are independent.

| Size | Use when | Artifact audit | Implementation reviews | Correction rounds |
| --- | --- | --- | --- | --- |
| Small | The change stays in one module, the clarity gate did not stop, and the change adds no design or public interface. | Coordinator audit | Reviewer agent and Codex | 1 |
| Mechanical | The issue asks for one transformation repeated across many sites, and the artifacts carry no design decision. Examples: clone or dedup sweeps, mechanical renames, dependency or API migrations, deprecation cleanups. | Coordinator audit | All | 2 |
| Standard | All other issues. | All | All | 2 |

`--mechanical` selects the mechanical size. Without it, select the size yourself. If the size is not clear, select the larger size. Record the size in the review packet.

If the evidence shows a design decision or a larger scope at a later step, change to the standard size. Do the omitted reviews of the current phase. Record the change and its reason for the final report.

On the mechanical size, do the Apply phase as scripted batch passes. The implementor writes one repeatable edit script or batch plan for each cluster of sites, and runs it across the cluster in one pass. It runs the repository tests after each cluster. Use a small number of large passes: each pass loads the full context again, so small slices multiply the cost.

## Explore and specify

1. Invoke `/opsx:explore` for the issue with the `Skill` tool.
2. Apply the clarity gate throughout the exploration.
3. Invoke `/opsx:ff` for the same change with the `Skill` tool.
4. Apply the clarity gate while the artifacts take shape.
5. Record the issue facts, user answers, acceptance conditions, change name, and artifact paths in a temporary review packet.

The skill invocation authorizes the OpenSpec artifacts for this issue. Ask again only when a phase expands the issue scope.

## Audit the artifacts

Load `viv-opsx-artifact-check` and do the coordinator audit. For the standard size, run these external audits against the same review packet, in parallel with the coordinator audit:

- `"$HOME/.claude/skills/viv-handle-issue/scripts/codex-review.sh" artifacts <effort> <packet>`
- `"$HOME/.claude/skills/viv-handle-issue/scripts/pi-review.sh" artifacts <effort> <packet>`

If an external reviewer is unavailable, continue with the other reviews and record that fact. Do not substitute a different model.

Merge equivalent findings by location and concern. Investigate conflicting findings against the repository and issue. Keep only findings that the evidence supports. Record in the review packet which reviewer raised each finding, and whether the evidence supported it.

Warnings and suggestions do not block `/opsx:apply`. Record them in the review packet so the implementor and implementation reviewers can use them.

Correct the supported critical findings in one correction pass. Ask the user when a correction contains a product or architecture decision that the evidence does not settle.

After the correction pass, the coordinator does a targeted closure review. Inspect each supported critical finding and the artifact text changed for it. Do not run the full audits again. Do not inspect unchanged artifact text for new findings.

A new finding blocks progress only when the correction directly caused it and it is critical. If a supported critical finding remains, correct only that finding and do its targeted closure review again. Continue to `/opsx:apply` when no supported critical finding remains.

## Apply and verify

Start the implementor agent for the selected effort. Give it the issue packet, change name, artifact paths, baseline result, and resolved audit findings. Keep its agent ID.

The implementor invokes `/opsx:apply`, completes the tasks, and runs the applicable tests.

After the implementor returns, start these reviews in parallel from the same repository state:

1. Ask the reviewer agent to invoke `/opsx:verify` for the change.
2. Run `"$HOME/.claude/skills/viv-handle-issue/scripts/codex-review.sh" implementation <effort> <packet>`.
3. Except for the small size, run `"$HOME/.claude/skills/viv-handle-issue/scripts/pi-review.sh" implementation <effort> <packet>`.

Merge equivalent findings. Record in the review packet which reviewer raised each finding, and whether the evidence supported it. Send each supported correctness or acceptance finding to the same implementor agent. Also send each failure in the suite. Resume that agent to make the corrections and run the affected tests.

After a correction, do a targeted re-review as the "Recheck" section tells. Do not run the full reviews again. A new finding blocks progress only when the correction directly caused it.

The size sets the maximum number of correction rounds. If a blocking finding remains after the last round, stop and ask the user. Ask the user also if reviewers conflict and repository evidence cannot resolve the conflict.

## Recheck

Recheck only the supported blocking findings that a correction addressed. Add the corrected findings and the changed files to the review packet first.

- For a finding from a reviewer agent, start `viv-issue-rechecker`. Give it the review packet, the corrected findings, and the changed files.
- For a finding from an external reviewer, run its script again with the `recheck` phase.

Each recheck examines only its corrected findings and the code changed for them.

## Sync and archive

The coordinator invokes `/opsx:sync` after verification passes. Then the coordinator invokes `/opsx:archive`.

Do not archive incomplete artifacts or tasks. Do not skip a necessary spec sync. If the archive phase finds a conflict, resolve it or ask one focused question.

Make sure that the archive exists and the active change no longer exists. Collect the reviewer record from the review packet. Then remove the temporary review packet.

Report the issue, branch, size, change name, result of the tests, review result, and archive path. Report the number of correction rounds in the Apply phase. For each reviewer, report its model and, for each phase, the number of supported and unsupported findings that it raised. Report an unavailable reviewer as unavailable. Stop. Leave all Git work and GitHub state to the user.
