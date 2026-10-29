---
name: viv-handle-issue
description: Resolve a ready GitHub issue through OpenSpec with an issue coordinator and independent reviews.
---

# Handle a GitHub Issue

Pi appends the invocation arguments to this skill in a `User:` message.

Use this form:

```text
<issue> [--fast] [--mechanical] [medium|high|expert] [flavor]
```

Use `--fast` or `--mechanical`, never both. Without a flag, the coordinator selects the size of the issue itself.

The issue is a GitHub URL, `owner/repo#number`, or an issue number for the current repository. Use `medium` when the effort is absent. Read `flavors.json` and use its `defaultFlavor` when the flavor is absent. Reject an effort or flavor that the files do not define.

With `--fast`, do not start a coordinator. Read `WORKFLOW.md` from this skill directory in full, and obey its "Fast mode" section in this session. The flavor and effort select the model of the reviewer. This explicit skill invocation authorizes the branch action in `WORKFLOW.md`.

With `--mechanical`, start the coordinator as usual. State in the task that the invocation selects the mechanical size. This explicit skill invocation authorizes the branch action in `WORKFLOW.md`.

Without `--fast`, read the coordinator model and thinking level from the selected flavor and effort. Join them as `<model>:<thinking>`.

Call the `subagent` tool with `action: "run"`, `agent: "viv-issue-coordinator"`, `context: "fresh"`, and `async: true`. Do not start the coordinator with `bash`, `pi`, `pi -p`, or another shell command. Give the coordinator the complete issue input, effort, flavor, and this skill directory. State that this explicit skill invocation authorizes the branch action in `WORKFLOW.md`. Do not give it a model for its nested agents. The flavor sets them.

Use one coordinator for one OpenSpec change. For more work after the archive, start a new coordinator, or use `--fast` for a small change. Do not give new work to a finished coordinator.

The coordinator runs in the background, and its completion notice wakes this session. Do not do its work in this session. If it returns a user question, ask that question and resume the same coordinator with the answer. Continue until the coordinator reports a successful OpenSpec archive or a blocker that repository evidence cannot resolve.

The workflow stops after the successful archive. Do not stage, commit, push, merge, or close the GitHub issue.
