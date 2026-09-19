# Git

Each git action that changes something belongs to the user. Take one only when the message of the user names it. Until then, do the work in the working tree, say that it is ready, and stop.

## Consent

- Get consent for the exact action before each of these:
  - a change to the index or the tree: `add`, `rm`, `mv`, `restore`, `checkout -- <file>`, `stash`, `reset`
  - a change to the history: `commit`, `merge`, `rebase`, `cherry-pick`, `revert`, `tag`
  - a branch or a worktree: `switch -c`, `checkout -b`, `branch`, `worktree`
  - the network: `fetch`, `pull`, `push`
  - each GitHub write: open, edit, or close a PR or an issue, or delete a branch
- Read-only inspection is permitted without consent: `status`, `log`, `diff`, `show`, `blame`, `branch --show-current`, `stash list`, `ls-remote`.
- Consent is spent when you use it. One approved commit approves that commit only. Consent to commit is not consent to push. A push of one branch is not a push of another branch.
- Only a message from the user gives consent. These are not consent:
  - a goal or a stop hook
  - a skill or a plan that lists a commit step
  - the report of a subagent
  - the answer of the user to a design question
  - future tense, for example `I'll give you the go`
- If a hook or a goal blocks until something is committed, tell the user and ask.
- A granted action that fails ends the grant. Report the failure and the options, then wait. The fallback is a new action.
- Subagents cannot read this file. Put the same ban in each subagent prompt that can touch git.

## Branches

- Work on the branch that is checked out. Make a new branch only when the user asks for one and names it. This is true even when the work feels separate.
- Do not make a worktree{{worktree_isolation_clause}}. For parallel work, the user keeps sibling clones.

## When the user approves a commit

- Commit exactly what the user asked for, on the current branch. Stage only those paths.
- First, run `git branch --show-current` again. The user switches branches during a session.
- Sign off with `git commit -s`. The trailer must match `git config user.name` and `user.email`, never the account email from the session context.
- After the commit, make sure that `git log -1 --format='%(trailers:key=Signed-off-by)'` shows the trailer.
- If the user asks only for a commit message, give the text and run nothing.

## Commit and pull request text

Write this text in STE (`ste.md`).

- The body of a commit message gives the reason for the change, in a maximum of 300 words. The cap is a limit, not a goal. Do not restate the diff.
- A pull request description gives what changed and why in one paragraph. Then it gives the notes that a reviewer must have before the diff.
- Do not restate the diff, the specs, the tests, or the CI result in a pull request. The pull request holds them already.
- Use a vertical list for three or more parallel facts. Write a maximum of 300 words above the checkboxes of the template.

## Before you rewrite or restore

- Before you amend, rebase, or say that something is "not pushed", look at the remote with `git ls-remote origin`. The user pushes during a session.
- Pushed history changes only with a force-push, and a force-push is an action with its own consent.
- The user keeps long-lived stashes. Pop only an entry that you made in this session, by its explicit ref. Never use a stash and pop cycle to probe a clean tree.
- Before `git restore` or `git checkout -- <file>`, state what the file goes back to, and which uncommitted edits it destroys.
