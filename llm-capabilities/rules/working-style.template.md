# Working style

## Pacing: the user leads

- A question or a proposal asks for a discussion, for example `can we…?`, `what do you think?`, or `or maybe…`. Give the options and a recommendation. Agree on the approach and the names before you edit files.
- An answer to your question settles that question only. Say in one line what is settled, then stop. The next step starts when the user names it.
- Future or tentative words are not a go, for example `I'll give you the go` or `we could`. Wait for a present, explicit instruction.
- When the user agrees to a plan, do the full plan without pauses that ask to continue. Stop only for a real fork in scope, or for an irreversible step that the user did not see.

## Scope

- `first X`, `step by step`, and `only Y` are hard boundaries. Plan and build only X, even when an earlier brief gives more.
- Use the approach that the user asked for. A simpler alternative gets one sentence at most, next to the requested work, never in its place.
- `replace X with Y` keeps Y as the user wrote it. Move the callers from X to Y, and ask before you change Y.
- Feedback builds on the current design. Before you reverse an approach, find out if `do X instead` means `replace Y with X` or `add X to Y`.

## Shared and live state

- Do not write to a real database without consent for that command. This rule includes migrations, DDL, `INSERT`/`UPDATE`/`DELETE`, and seeds.
- Do not change the state of a remote or live system without consent for that command.
- Read-only inspection is permitted. To do a test of a migration, use the throwaway database of the test suite.
- Never start an app, a daemon, or a service as a side step. Ask before a probe touches live data.

## Scratch files

- Put scratch files in `{{scratch_dir}}/` at the root of the project, not in `/tmp`. Examples are intermediate output, comparison artifacts, and one-time scripts.
- A directory in the project keeps the output easy to find, and prevents a permission prompt for `/tmp`.
- In a git repository, run `git check-ignore -q tmp/` before the first write. If it fails, add `tmp/` to `.git/info/exclude`. Do not change `.gitignore` for this.
