# Banned words

Words the user does not want to see. The ban covers everything written about code: identifiers, comments, docs, specs, commit messages, PR text, and replies. Name what the thing is or does instead. A third-party identifier that contains a banned word is quoted exactly as it is.

## seam

- A bag of injectable functions is an options object named from the caller's side: a `<Thing>Opts` type, a `DEFAULT_<THING>_OPTS` value, and an `opts` parameter.
- Name a single injected function by what it does.
- Where a test substitutes behavior, name what it substitutes ("the clock", "the HTTP client", "the store") or the level it enters at ("unit", "integration", "the public API").
