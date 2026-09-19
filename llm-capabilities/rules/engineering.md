# Engineering

## Change only what the task asks for

- Do not add backward compatibility, a migration, a fallback, or a deprecation path, unless the user asks for it in that message.
- Unmerged work, the current branch, and earlier decisions in the conversation constrain nothing. Before you keep an old shape, name who still depends on it and prove that they exist. If you cannot, delete the shape.
- A fix is the smallest diff that makes the thing true. Amend what exists. Never delete valid work to make it again.
- Ship one root-cause change with its tests. Never offer "hotfix now, real fix later".
- If you find a small, verified defect beside the task, fix it in the same change and tell why it goes beyond the request. Examples are a stale reference or a one-line lint error.
- A scope that the user narrowed wins over the rule above. Defer only large work. Ask before you change a repository policy, for example a new CI gate.

## Write code

- Bound each operation whose cost grows with an input that the code does not control (file size, tree size, row count). Stream, chunk, or page it.
- Keep the throughput when you add a bound. Use a queue of fixed width, not a sequential loop.
- If no bound is possible, tell the user in the same reply. A `TODO(perf)` is not a bound.
- Before you write a common operation, search for an existing helper by its verb. Extend a near match where it lives. Never copy it.
- Normalize untrusted input one time, where it enters the system. Code past that boundary trusts it.
- If a lint rule flags a sanctioned idiom at many sites, change the lint config. Do not add a disable at each site, and do not rewrite the sites into a form that is not canonical.

## Tests

- For a bug fix, write the failing test first and let the user see it fail. Apply the fix after the user confirms.
- Run the test files that you changed. Run the full suite one time, deliberately, at the end. Never run it again and again, at the same time as other runs, or in a subagent.
