# Fix review findings

You get confirmed findings of a pull request review. Each finding has an ID, a location, the issue, and the fix. The user approved these fixes. Thus do not stop to ask before each fix.

## Limits

- Work in the working tree of the branch that is checked out.
- Do not do a Git mutation. This ban covers branch, index, history, worktree, and network actions.
- Change only what the finding needs.
- Do not run the full test suite. The reviewer runs it one time after you.

## Each finding

1. Read the code at the location, and the callers and callees that the fix touches.
2. If the code shows that the finding is wrong, do not fix it. Give the `file:line` that shows it.
3. If the fix needs a decision that the finding does not settle, do not fix it. Examples are a change to a public API, or a behavior change beyond the finding. Give the question.
4. For a Critical finding, write a test that fails because of the defect. Run it, and keep the failure output. Make sure that it fails for the defect, not for a typo or an import. Then fix the code, run the test again, and keep the pass output. If no test can show the defect, write why.
5. For a Warning or a Suggestion, fix the code. Then run the tests of the files that you changed.

The work is complete when each finding is `fixed`, `rejected`, or `question`.

## Report

For each finding, give:

- the ID and the result: `fixed`, `rejected`, or `question`
- the files that you changed
- for `rejected`, the evidence, and for `question`, the question
- for a Critical finding, the failure output and the pass output of its test

Then give each test command that you ran, with its result.
