---
name: viv-handle-issue
description: Resolve a ready GitHub issue through OpenSpec with separate coordinator, implementor, and reviewer agents. Use only when the user invokes this skill with an issue and an optional effort level.
argument-hint: "<issue> [--fast] [medium|high|expert]"
disable-model-invocation: true
---

# Handle a GitHub Issue

Input: `$ARGUMENTS`

The issue can be a GitHub URL, `owner/repo#number`, or an issue number for the current repository.
The final argument can be `medium`, `high`, or `expert`. Use `medium` when the argument is absent. Reject a different effort value.
The input can contain `--fast` before the effort.

## With `--fast`

Read `${CLAUDE_SKILL_DIR}/WORKFLOW.md` in full. Do its "Fast mode" section in this conversation. The effort selects the reviewer agent: `viv-issue-reviewer-<effort>`. This explicit invocation authorizes the branch action in the workflow.

## Without `--fast`

Start one foreground agent with the `Agent` tool:

| Effort | Agent |
| --- | --- |
| `medium` | `viv-issue-coordinator-medium` |
| `high` | `viv-issue-coordinator-high` |
| `expert` | `viv-issue-coordinator-expert` |

Give the agent the complete issue input and the selected effort. Tell the agent that this explicit invocation authorizes the branch action in its workflow.

Wait for the coordinator. Do not do its work in this conversation.

If the coordinator asks a question, show that one question to the user. Then resume the same coordinator with the answer. Continue until the coordinator reports a successful OpenSpec archive or a blocker that it cannot resolve.

The workflow ends after the successful archive. Do not stage, commit, push, merge, or close the GitHub issue.
