---
name: viv-merge-conflicts
description: >-
  Resolves git merge, rebase, cherry-pick, revert, and stash-pop conflicts
  using only the plain git CLI. Use this whenever the user encounters CONFLICT
  (content), CONFLICT (rename/modify), CONFLICT (modify/delete), CONFLICT
  (submodule), "Automatic merge failed", "unmerged paths", "you need to resolve
  your current index first", or sees <<<<<<< / ======= / >>>>>>> / |||||||
  markers in files. Also use for lockfile conflicts (package-lock.json,
  yarn.lock, pnpm-lock.yaml, Cargo.lock, Gemfile.lock, poetry.lock, uv.lock,
  go.sum, composer.lock, Pipfile.lock), submodule conflicts, binary file
  conflicts, evil merges, semantic conflicts, and questions about
  merge.conflictStyle, rerere, MERGE_HEAD, REBASE_HEAD, or CHERRY_PICK_HEAD.
  Use this skill even when the user does not explicitly say "conflict" but is
  mid-merge or mid-rebase. Do NOT use for non-Git VCS, routine pulls that
  succeeded cleanly, or general code review unrelated to merging.
---

# Resolving Git merge conflicts

## Orient first

Run these before touching any file:

```
git status                              # identify: merge / rebase / cherry-pick / revert / am
git merge-base HEAD MERGE_HEAD          # (merge only) find the common ancestor
git ls-files -u                         # list every unmerged path with stage numbers
```

Read the `git status` header carefully:
- "You have unmerged paths" → merge in progress. `MERGE_HEAD` exists. Ours = HEAD, theirs = MERGE_HEAD.
- "interactive rebase in progress" / "rebase in progress" → `REBASE_HEAD` exists. **Ours and theirs are SWAPPED**: ours = upstream, theirs = your commit that git replays.
- "cherry-pick in progress" → `CHERRY_PICK_HEAD`. Same swap as rebase.
- "revert in progress" → `REVERT_HEAD`. Ours = HEAD, theirs = the inverted commit.

**Why the swap matters:** `git checkout --ours` during rebase keeps the upstream version, not yours. Always make sure of the orientation from `git status` before you use `--ours`/`--theirs`.

If `merge.conflictStyle` is not `zdiff3` or `diff3`, set it now. It adds the merge-base content between `|||||||` and `=======`, which is essential to understand what each side changed:

```
git config merge.conflictStyle zdiff3        # Git 2.35+; fall back to diff3 on older
```

To re-render markers on already-conflicted files: `git checkout --conflict=zdiff3 -- <path>`.

## Decision tree by conflict type

Read the two-letter status code from `git status -s`:

| Code | Meaning | Default action |
|------|---------|---------------|
| `UU` | Both modified | Read context, resolve text, `git add` |
| `AA` | Both added (new file, same path) | Merge content or pick one, `git add` |
| `AU` | Added by us only | Usually keep, `git add` |
| `UA` | Added by them only | Usually keep, `git add` |
| `DU` | Deleted by us, modified by them | **Escalate** — ask the user |
| `UD` | Modified by us, deleted by them | **Escalate** — ask the user |
| `DD` | Both deleted | Usually `git rm` |

Modify/delete (`DU`/`UD`) almost always requires human judgment: one side decided to remove something the other side is actively changing. When forced to pick without guidance, prefer `git add` (preserves data) over `git rm`.

## Per-conflict workflow

For **every** unmerged path, work through these steps in order:

### 1. Categorize the file

- **Binary** (images, compiled artifacts, sqlite, and so on) → go to Special Cases.
- **Lockfile** (`package-lock.json`, `yarn.lock`, `Cargo.lock`, and so on) → go to Special Cases.
- **Generated file** (header says `// Code generated`, `// @generated`, or lives in `generated/`, `dist/`, `__generated__/`) → go to Special Cases.
- **Submodule** (mode `160000`) → go to Special Cases.
- **Normal text** → continue below.

### 2. Extract the three versions

```
git show :1:<path>          # base (common ancestor)
git show :2:<path>          # ours
git show :3:<path>          # theirs
```

Stage 1 is absent for add/add (`AA`) conflicts — use `git diff :2:<path> :3:<path>` to compare the two versions directly.

### 3. Read intent from each side

```
BASE=$(git merge-base HEAD MERGE_HEAD)          # merge; for rebase use REBASE_HEAD~
git log -p $BASE..HEAD       -- <path>          # commits on our side
git log -p $BASE..MERGE_HEAD -- <path>          # commits on their side
git log --merge -p -- <path>                    # shorthand: only commits touching conflicted paths
```

Read full commit messages (bodies + footers like `Fixes #123`, `BREAKING CHANGE:`). The subject tells you *what*. The body tells you *why*.

### 4. Classify resolution difficulty

**Mechanical — resolve directly:**
- Import/include lists: union them, sort per project convention.
- Both sides added non-overlapping code in the same region: stitch together.
- Identical changes on both sides (cherry-pick/backport): take either.
- Pure whitespace/formatting: re-run the project formatter.
- Comment-only changes that do not affect code logic.

**Tractable — resolve, then make sure of the result carefully:**
- Both sides modified different parts of the same function: combine, but check for cross-references to variables one side added or removed.
- Both sides added entries to the same list/array/enum/dict: union, but watch for order-sensitive structures (middleware chains, protobuf field numbers — number collisions are fatal, escalate).
- Rename on one side + edit on the other: apply the edit to the renamed path.
- Both sides extended a data structure with new fields: union, check for name collisions.

**Requires human judgment — escalate:**
- Both sides replaced the same logic with different intent.
- One side removes a feature, the other extends it.
- API/signature changes with ripple effects through the codebase.
- Conflicting refactors (same module reorganized differently on each side).
- Conflicting business logic (validation rules, pricing, permissions).
- Commit messages reveal contradictory goals (for example, "tighten rate limits" against "relax rate limits for X tier").

### 5. Resolve

Edit the file to produce the correct merged content. Remove all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`, `|||||||`).

### 6. Verify the resolution

```
git diff --check                        # catches leftover markers and whitespace errors
```

Then scan changed files for stray markers that `git diff --check` might miss:

```
grep -rnE '^(<{7}|={7}|>{7}|\|{7})( |$)' <resolved-paths>
```

Run the type checker, linter, and tests that the project instruction file names.

### 7. Stage

```
git add <path>              # for resolved content
git rm <path>               # only for confirmed deletions
```

`git add` collapses index stages 1/2/3 into stage 0. Do not run `git add` until verification passes.

### 8. Repeat for all unmerged paths, then finalize

```
git ls-files --unmerged                 # must be empty
git merge --continue                    # or: git rebase --continue / git cherry-pick --continue
```

## When to STOP and ask the user

Escalate whenever:
- The conflict is a **modify/delete** (`DU`/`UD`) — one side removed what the other changed.
- The conflict involves a **binary file** — you cannot inspect pixels, DOCX semantics, or compiled artifacts.
- The conflict is in a **submodule** — picking the right gitlink SHA requires understanding downstream changes.
- Both sides made **rename/rename** changes (same file renamed to different targets, or different files renamed to the same target).
- Commit messages reveal **contradictory goals**.
- The resolution would be an **evil merge** — introducing content not present in either parent — and you are not confident it is correct.
- You are **below ~70% confidence** that the resolution preserves both sides' intent.
- A **test fails** after resolution and you cannot determine whether the failure is merge-induced or pre-existing.

### Escalation format

Present this information, in order:

1. **Each side's intent** in plain English, derived from commit messages and PR descriptions.
2. **The base version** of the conflicting region (the `|||||||` section in zdiff3, or `git show :1:<path>`).
3. **Options you see** — at minimum: take ours, take theirs, union, a specific composition — with code snippets for each.
4. **Your recommendation and confidence** — for example, "Leans toward union (70%) because both additions are independent, but lower confidence because A's commit message mentions deprecating the path B extends."
5. **Downstream implications** — affected call sites, tests, configs.

Ask **one focused question at a time** with two or three concrete labeled options. Do not dump walls of text.

## Special cases

### Lockfiles

Textual merge of lockfiles produces invalid files — integrity hashes, dependency graphs, and content-hashes will be wrong. **Never hand-edit a lockfile to remove markers.**

Workflow: resolve the manifest first, then regenerate:

| Ecosystem | Lockfile | Regenerate |
|-----------|----------|-----------|
| npm | `package-lock.json` | `git checkout --theirs package-lock.json && npm install` |
| yarn | `yarn.lock` | `git checkout --theirs yarn.lock && yarn install` |
| pnpm | `pnpm-lock.yaml` | `git checkout --theirs pnpm-lock.yaml && pnpm install` |
| Cargo | `Cargo.lock` | `git checkout --theirs Cargo.lock && cargo generate-lockfile` |
| Bundler | `Gemfile.lock` | `git checkout --theirs Gemfile.lock && bundle install` |
| Poetry | `poetry.lock` | `git checkout --theirs poetry.lock && poetry lock --no-update` |
| uv | `uv.lock` | `git checkout --theirs uv.lock && uv lock` |
| Go | `go.sum` | Resolve `go.mod` (often union of `require`); `go mod tidy` |
| Pipenv | `Pipfile.lock` | `git checkout --theirs Pipfile.lock && pipenv lock` |
| Composer | `composer.lock` | `git checkout --theirs composer.lock && composer update --lock` |

Always: resolve manifest → take one whole side of lockfile → regenerate → `git add`.

### Generated files

Files with `// Code generated`, `// @generated`, `linguist-generated=true` in `.gitattributes`, or in conventional dirs (`generated/`, `dist/`, `__generated__/`).

Resolve the **source** first, then regenerate the artifact. Do not merge generated output by hand.

### Binary files

Git writes no conflict markers for binaries — working tree keeps ours. Resolution: `git checkout --ours <path>` or `git checkout --theirs <path>`, then `git add`. **Always escalate** — ask the user which version to keep. If the binary is a compiled artifact that must not be in the repo, flag the `.gitignore` gap.

### Submodules

Manifestation: `CONFLICT (submodule)` with divergent gitlinks (mode `160000`). Inspect with:

```
git diff --submodule=log
cd <submodule> && git log <our-sha>..<their-sha>
```

Resolution: `cd <submodule> && git checkout <chosen-sha> && cd .. && git add <submodule>`. **Almost always escalate** — the user must decide which submodule state is correct.

### Rename conflicts

- **Rename/modify**: If `ort` detected the rename (similarity ≥ 50%), markers appear at the new path — resolve as normal text. If similarity was too low, it shows as modify/delete on the old path — apply the orphaned changes to the renamed file manually.
- **Rename/rename (1-to-2)**: Same source, different target names on each side. Escalate.
- **Rename/rename (2-to-1)**: Different sources renamed to same target. Escalate.

### `.gitattributes` merge drivers

Check `.gitattributes` for `merge=union`, `merge=binary`, or custom drivers. If Git still reports a conflict despite a custom driver, the driver failed — escalate. Note: custom drivers in `.git/config` are ignored by GitHub/GitLab web merges.

### `rerere` replays

If `rerere.enabled` is true, Git can auto-apply a previously recorded resolution. **Always make sure that a replayed resolution is correct** with `git diff` and tests before `git add`. If the surrounding code changed after the recording, the replay can be silently wrong. Use `git rerere diff` to inspect what was replayed.

## Anti-patterns — do NOT do these

1. **`git checkout --ours .` or `--theirs .` over the whole tree** — silently discards an entire side of every conflict. Especially dangerous in rebase where ours/theirs are swapped.
2. **`git add .` while unmerged paths exist** — stages files that can still contain markers or dropped changes.
3. **Picking the side with more lines** — line count is not a quality signal. A two-line bug fix can be more important than a fifty-line refactor.
4. **Treating clean `git status` as success** — textual resolution is necessary but not sufficient. Semantic conflicts pass `git status` but break the program.
5. **`git add` before you make sure of the result** — once staged, markers are gone and the merge can be committed with broken content.
6. **Hand-editing lockfiles** to remove markers — produces invalid integrity hashes. Regenerate instead.
7. **Deleting a submodule directory** to resolve a submodule conflict.
8. **`git push --force` to fix a botched public merge** — use `git revert -m 1 <sha>` instead.
9. **Auto-resolving when commit messages disagree** — if side A says "remove deprecated API" and side B says "add usage of API," a clean textual merge keeping both is almost certainly wrong.
10. **Trusting `rerere` replays blindly** — the surrounding code can change after the recording.
11. **Ignoring markers in config files** — `<<<<<<<` in YAML/JSON/TOML breaks parsers silently. Run the config's validator (`jq -e .`, `python -c "import yaml; yaml.safe_load(open(f))"`, `yq`).
12. **Squash-merging a conflict resolution** — destroys dual-parent history and makes forensic review with `git log --cc` impossible.

## Detecting semantic conflicts after a clean merge

A textually clean merge can still be broken. After resolution (or after a merge that had no textual conflicts), cross-check:

1. **Build and test.** Non-negotiable — the dominant safety net.
2. **Type-check / lint** (`tsc --noEmit`, `mypy`, `cargo check`, `go vet`). Catches signature mismatches and undefined references.
3. **Cross-reference diffs.** For each identifier added, removed, or renamed in one side's diff, search the other side's diff for references to it. A symbol removed by side A but newly referenced by side B is a semantic conflict.

## Recovery

```
git merge --abort                       # cancel merge, restore pre-merge state
git rebase --abort                      # cancel rebase, restore original branch
git cherry-pick --abort                 # cancel cherry-pick
git revert --abort                      # cancel revert
git reset --merge ORIG_HEAD             # undo a completed merge (before push)
git revert -m 1 <merge-sha>            # undo a public merge safely (no force-push)
git reflog                              # find any prior state to recover
```

`git merge --abort` does not always restore the working tree perfectly if there were uncommitted changes before the merge. If the tree has uncommitted changes, tell the user before a merge starts.

To re-merge a branch after reverting a merge: revert the revert first (`git revert <revert-sha>`), then merge again.
