# Delegation mode

In delegation mode, `ocr` calls no LLM. It selects the files to review and gives the review rules for each file. You do the review.

Use the target flags and the background file from steps 1 and 2 of `SKILL.md`.

1. Get the files:

   ```bash
   ocr delegate preview --format json --background-file <background> <target flags>
   ```

   The output gives the `mode`, the refs (`merge_base` for a range), the `reviewable_files`, and each excluded file with its reason.

2. Get the rules:

   ```bash
   ocr delegate rule --format json <path>...
   ```

   Files that have the same rule are in one group.

3. Get the diff of each file:
   - A range: `git diff <merge_base>..<to> -- <path>`
   - A commit: `git show <commit> -- <path>`
   - The working tree: `git diff HEAD -- <path>`. For an untracked file, read the full file.

4. Review each file against the rules of its group. Write findings on changed lines only. Read the code around the change for context. For a large change, review in batches of files that have the same rule.

5. Keep a list of each `(path, status)` pair from `reviewable_files`. In the working tree, one path can occur two times: a staged deletion, then an untracked file with the same path. Mark each pair `reviewed`, or `skipped` with a reason.

The review is complete when each pair is `reviewed` or `skipped` with a reason.

Then do steps 5 and 6 of `SKILL.md` on your findings. In the report, give each skipped file with its reason.
