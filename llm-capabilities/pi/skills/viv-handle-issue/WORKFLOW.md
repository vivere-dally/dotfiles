# Issue Coordinator Workflow

## Authority

The skill invocation authorizes this workflow for the supplied issue. It authorizes one new branch when the current branch does not start with `feat/` or `bugfix/`.

Do not stage, commit, push, merge, rebase, tag, stash, reset, restore, or close the issue. Do not use a worktree. Preserve all user changes.

Only the implementor edits product code and tests. The coordinator edits OpenSpec artifacts and controls the workflow. Reviewers do not edit files.

## Fast mode

The `--fast` flag selects a shorter workflow for a small issue. The session that runs the skill does the work itself, thus no coordinator or implementor subagent starts. That session edits the OpenSpec artifacts, the product code, and the tests. Only the verification stays independent.

Do these steps in order:

1. Do the "Start" section.
2. Do the "Explore and specify" section with the clarity gate. Ask the user with the `ask_user` tool.
3. Load `viv-opsx-artifact-check` and audit the artifacts. Correct the supported critical findings in one pass.
4. Obey the Apply instructions, complete the tasks, and do the applicable tests.
5. Start `viv-issue-reviewer` as the "Child runs" section tells, with the `reviewer` model settings for the selected flavor and effort. Tell it to obey the instruction file for `verify`. Give it the review packet, the change name, the artifact paths, and the baseline result. Keep its run identifier.
6. Investigate each finding against the repository. Fix each supported correctness or acceptance finding, and do the affected tests.
7. If step 6 changed the code, recheck the fixed findings as the "Recheck" section tells.
8. If a supported critical finding remains after that check, stop and ask the user. Do not start a third review.
9. Do the "Sync and archive" section.

Do not do the `Size the issue`, `Audit the artifacts`, or `Apply and verify` section. Do not run the second reviewer or the external reviews.

## Child runs

Start each child agent with the `subagent` tool as one single-agent run: `action: "run"`, `context: "fresh"`, `async: true`, and the model settings from `flavors.json` as `<model>:<thinking>`. Do not put more than one agent in one run. A single-agent background run is the only kind of run that gets the checkpoint steer before its deadline.

Give each run a `timeoutMs` that covers its phase with a margin. State that budget in the task text.

After you start the runs of a phase, wait with `bg_wait` and `stopOnAttention: false` until each run of the phase has finished. If `bg_wait` returns before then, answer a supervisor question if there is one, and then call `bg_wait` again. Do not end your turn while a child run is active, because the end of your turn ends your own run.

A child that stops after the checkpoint steer returns a handoff. Treat the handoff as the normal end of the phase for that child: read the state that it reports, and resume the same run when work remains.

## External reviews

The external reviews give second opinions from different vendors. Run each with the `bash` tool and a timeout of at least 60 minutes:

```bash
"$HOME/.claude/skills/viv-handle-issue/scripts/codex-review.sh" <artifacts|implementation|recheck> <effort> <packet>
"$HOME/.pi/agent/skills/viv-handle-issue/scripts/claude-review.sh" <artifacts|implementation|recheck> <effort> <packet>
```

Start them in parallel with the `viv-issue-reviewer` subagents of the same phase. If an external reviewer is unavailable, continue with the other reviews and record that fact. Do not substitute a different model.

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
6. Start `viv-issue-scout` with the `scout` model settings and the issue facts. It returns a map of the related code, tests, configuration, and OpenSpec files, and a size recommendation.
7. Read in full the files that the map marks as central. Read the other files only when a decision needs them.
8. Do the relevant baseline tests before an implementation change.

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

## Size the issue

After the Explore phase, select the size of the issue. Use the scout recommendation and the exploration facts. The size controls the number of reviews and correction rounds. The effort and the flavor control the model of each agent. The two are independent.

| Size | Use when | Artifact audit | Implementation reviews | Correction rounds |
| --- | --- | --- | --- | --- |
| Small | The change stays in one module, the clarity gate did not stop, and the change adds no design or public interface. | Coordinator audit | `reviewer` and Codex | 1 |
| Mechanical | The issue asks for one transformation repeated across many sites, and the artifacts carry no design decision. Examples: clone or dedup sweeps, mechanical renames, dependency or API migrations, deprecation cleanups. | Coordinator audit | All | 2 |
| Standard | All other issues. | All | All | 2 |

`--mechanical` selects the mechanical size. Without it, select the size yourself. If the size is not clear, select the larger size. Record the size in the review packet.

If the evidence shows a design decision or a larger scope at a later step, change to the standard size. Do the omitted reviews of the current phase. Record the change and its reason for the final report.

On the mechanical size, start the implementor with the `mechanicalImplementor` model settings. It does the Apply phase as scripted batch passes. It writes one repeatable edit script or batch plan for each cluster of sites, and runs it across the cluster in one pass. It runs the repository tests after each cluster. Use a small number of large passes: each pass loads the full context again, so small slices multiply the cost.

## Explore and specify

1. Obey the Explore instructions for the issue.
2. Apply the clarity gate throughout the exploration.
3. Obey the Fast-forward instructions for the same change.
4. Apply the clarity gate while the artifacts take shape.
5. Write the issue facts, user answers, acceptance conditions, change name, and artifact paths to a temporary review packet.

The skill invocation authorizes the OpenSpec artifacts for this issue. Ask again only when a phase expands the issue scope.

## Audit the artifacts

Do the coordinator audit with `viv-opsx-artifact-check`. For the standard size, also start two `viv-issue-reviewer` runs in parallel. Use the `reviewer` and `secondReviewer` model settings for the selected flavor and effort. Run the external reviews with the `artifacts` phase at the same time.

Give each reviewer the same review packet. Tell each reviewer to do an artifact audit and to return findings without file edits.

Merge equivalent findings by location and concern. Investigate conflicting findings against the repository and issue. Keep only findings that the evidence supports. Record in the review packet which reviewer raised each finding, and whether the evidence supported it.

Warnings and suggestions do not block the Apply phase. Record them in the review packet for the implementor and implementation reviewers.

Correct the supported critical findings in one correction pass. Ask the user when a correction contains a product or architecture decision that the evidence does not settle.

After the correction pass, do a targeted closure review. Inspect each supported critical finding and the artifact text changed for it. Do not run the full audits again. Do not inspect unchanged artifact text for new findings.

A new finding blocks progress only when the correction directly caused it and it is critical. Correct only that finding and do its targeted closure review again. Continue when no supported critical finding remains.

## Apply and verify

Start `viv-issue-implementor`. Use the `implementor` model settings, or the `mechanicalImplementor` settings for the mechanical size, for the selected flavor and effort. Give it the review packet, change name, artifact paths, baseline result, and resolved audit findings. Keep its run identifier.

The implementor obeys the Apply instructions, completes the tasks, and does the applicable tests.

After the implementor returns, start the implementation reviews in parallel from the same repository state:

- For the small size, start one `viv-issue-reviewer` run with the `reviewer` model settings, and run only `codex-review.sh` with the `implementation` phase.
- For the other sizes, start two `viv-issue-reviewer` runs with the `reviewer` and `secondReviewer` model settings, and run both external reviews with the `implementation` phase.

Tell each reviewer to obey the instruction file for `verify`. Keep the run identifier of each reviewer.

Merge equivalent findings. Record in the review packet which reviewer raised each finding, and whether the evidence supported it. Send each supported correctness or acceptance finding to the same implementor run. Also send each failure in the required test suite. Resume that run to make corrections and do the affected tests.

After a correction, do a targeted re-review as the "Recheck" section tells. Do not run the full reviews again. A new finding blocks progress only when the correction directly caused it.

The size sets the maximum number of correction rounds. If a blocking finding remains after the last round, stop and ask the user. Ask the user also if repository evidence cannot resolve a reviewer conflict.

## Recheck

Recheck only the supported blocking findings that a correction addressed. Add the corrected findings and the changed files to the review packet first.

- For a finding from a `viv-issue-reviewer` run, start a new `viv-issue-reviewer` run with the `rechecker` model settings. Give it the review packet, the corrected findings, and the changed files.
- For a finding from an external reviewer, run its script again with the `recheck` phase.

Each recheck examines only its corrected findings and the code changed for them. It reports each finding as closed or open, and a new finding only when the correction directly caused it.

## Sync and archive

Obey the Sync instructions after the review passes. Then obey the Archive instructions.

Do not archive incomplete artifacts or tasks. Do not skip a necessary specification sync. If the Archive phase finds a conflict, resolve it or ask one focused question.

Make sure that the archive exists and the active change no longer exists. Collect the reviewer record from the review packet. Then remove the temporary review packet.

Report the issue, branch, size, change name, results of tests, review result, and archive path. Report the number of correction rounds in the Apply phase. For each reviewer, report its model and, for each phase, the number of supported and unsupported findings that it raised. Report an unavailable reviewer as unavailable. Stop. Leave all other Git work and GitHub state to the user.
