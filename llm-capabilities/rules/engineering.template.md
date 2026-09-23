# Engineering

## Change only what the task asks for

- Do not add backward compatibility, a migration, a fallback, or a deprecation path, unless the user asks for it in that message.
- Unmerged work, the current branch, and earlier decisions in the conversation constrain nothing. Before you keep an old shape, name who still depends on it and prove that they exist. If you cannot, delete the shape.
- A fix is the smallest diff that makes the thing true. Amend what exists. Never delete valid work to make it again.
- Ship one root-cause change with its tests. Never offer "hotfix now, real fix later".
- If you find a small, verified defect beside the task, fix it in the same change and tell why it goes beyond the request. Examples are a stale reference or a one-line lint error.
- A scope that the user narrowed wins over the rule above. Defer only large work. Ask before you change a repository policy, for example a new CI gate.

## Deferred findings

- When you find a bug, a missing feature, or an oddity that the task does not fix, add one entry to `{{scratch_dir}}/SESSION.md`. Give what is wrong, the `file:line`, and why it matters.
- Do not write what you did in `{{scratch_dir}}/SESSION.md`. The file holds only work that is still open.
- If you are a subagent, only add entries. The agent that talks to the user files the issues.
- When you report that the task is ready and `{{scratch_dir}}/SESSION.md` has entries, write one draft issue for each entry.
- Use the issue tracker that the project instruction file or `CONTRIBUTING.md` names. If none is named and the remote is on GitHub, use GitHub issues through `gh`. Otherwise, ask the user.
- Before you write a draft, search the tracker for a duplicate. If you find one, give its link instead of a draft.
- Show the drafts and ask for consent to open them. Open only the issues that the user approves.
- Then remove from `{{scratch_dir}}/SESSION.md` each entry that you filed, that has a duplicate, or that the user rejected. Give the URL of each new issue.

## Write code

- Bound each operation whose cost grows with an input that the code does not control (file size, tree size, row count). Stream, chunk, or page it.
- Keep the throughput when you add a bound. Use a queue of fixed width, not a sequential loop.
- If no bound is possible, tell the user in the same reply. A `TODO(perf)` is not a bound.
- Match the data structure to the access. If a loop looks up items by key or tests membership, build a set or a map one time before the loop.
- Keep queries and network calls out of loops over rows. Collect the keys first, and fetch the relation in one call (`select_related`, `includes`, `joinedload`, `selectinload`).
- When the project has a query-count test or an N+1 detector, add an assertion for each new code path that returns a list. If a project with an ORM has neither, propose one to the user, and add it only after the user agrees.
- Prove a claimed speedup with a measurement on an input large enough to show the complexity classes. Give the input sizes and the numbers.
- Before you write a common operation, search for an existing helper by its verb. Extend a near match where it lives. Never copy it.
- Normalize untrusted input one time, where it enters the system. Code past that boundary trusts it.
- If a lint rule flags a sanctioned idiom at many sites, change the lint config. Do not add a disable at each site, and do not rewrite the sites into a form that is not canonical.

## Tests

- For a bug fix, write the failing test first and let the user see it fail. Apply the fix after the user confirms.
- When a test fails before the fix, read the failure output. Make sure that it fails for the reason under test, not for a typo, an import, or a fixture.
- When a test expects an error, assert which error: the type, the code, or the message. A bare "it throws" or "the exit code is not 0" also passes for a different failure.
- Run the test files that you changed. Run the full suite one time, deliberately, at the end. Never run it again and again, at the same time as other runs, or in a subagent.
