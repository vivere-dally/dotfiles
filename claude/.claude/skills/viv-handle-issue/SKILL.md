---
name: viv-handle-issue
description: Resolve a ready GitHub issue through OpenSpec with separate coordinator, implementor, and reviewer agents. Use only when the user invokes this skill with an issue and an optional effort level.
argument-hint: "<issue> [--fast] [--mechanical] [medium|high|expert]"
disable-model-invocation: true
---

# Handle a GitHub Issue

Input: `$ARGUMENTS`

The issue can be a GitHub URL, `owner/repo#number`, or an issue number for the current repository.
The final argument can be `medium`, `high`, or `expert`. Use `medium` when the argument is absent. Reject a different effort value.
The input can contain `--fast` or `--mechanical` before the effort, never both. Without a flag, the coordinator selects the size of the issue itself.

## With `--fast`

Read `${CLAUDE_SKILL_DIR}/WORKFLOW.md` in full. Do its "Fast mode" section in this conversation. Start the reviewer as the "Agents" section of the workflow tells. This explicit invocation authorizes the branch action in the workflow.

## With `--mechanical`

Start the coordinator as in the next section. State in the task that the invocation selects the mechanical size.

## Without `--fast`

Start `viv-issue-coordinator` as one foreground agent with the `Agent` tool. Set its `model` and `effort` parameters from this table:

| Effort | `model` | `effort` |
| --- | --- | --- |
| `medium` | `opus` | `xhigh` |
| `high` | `fable` | `medium` |
| `expert` | `fable` | `xhigh` |

Give the agent the complete issue input and the selected effort. Tell the agent that this explicit invocation authorizes the branch action in its workflow.

Wait for the coordinator. Do not do its work in this conversation.

If the coordinator asks a question, show that one question to the user. Then resume the same coordinator with the answer. Continue until the coordinator reports a successful OpenSpec archive or a blocker that it cannot resolve.

The workflow ends after the successful archive. Do not stage, commit, push, merge, or close the GitHub issue.
