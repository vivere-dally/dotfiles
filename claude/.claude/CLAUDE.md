# Code comments

## Comment the why, not the what

- Do NOT write comments that restate what the code already says. If a comment paraphrases the line below it, delete it. Types and good names already document the "what"; lean on them.
- DO write comments that capture intent and reasoning: why the code works this way, what problem it solves, and what would otherwise be non-obvious to a future reader.
- Prefer making the "what" self-evident through the type system (descriptive types, unions, branded types, `readonly`, exhaustive `switch`) so prose doesn't have to carry it.

## Document the decisions you made

- Record which alternative approaches were considered and discarded, and why.
- Record which downsides or trade-offs were explicitly accepted, and why (e.g. why you reached for an escape hatch, why you disabled a lint rule, why you chose a library).
- Every escape hatch (see per-language list below) should carry a comment explaining why it is safe and necessary — these must never be silent.

## Document what is NOT there

- Flag shortcuts and unhandled cases explicitly rather than leaving them silent. Use an explicit error/panic (`throw new Error("not implemented")`, `todo!()`, `panic("unimplemented")`) or a `// TODO:` with an issue link instead of a stub that returns a fake value.
- In exhaustive `switch`/match handling, make the compiler flag any case you forgot (see per-language exhaustiveness below) — this documents "everything is handled" and breaks the build when it stops being true.
- Note deliberate absences: why a method is intentionally not provided, why a guard is omitted, a future optimization opportunity.

## Treat comments as first-class, write them early

- Comments are among the most important code you write; treat them with the same care as the logic.
- Consider writing the comment/contract before the implementation — sketch intended behavior, inputs, and invariants in prose (or a doc comment) first, then fill in the code beneath it.

## Comment the surprising, the unsafe, and the load-bearing

- Clearly comment anything a reader would find unexpected: reliance on external/global state, mutation of shared objects, ordering or timing requirements (async sequencing, microtask vs macrotask, lock ordering), subtle invariants, or a non-obvious algorithm choice.
- Anywhere you defeat the type checker or borrow checker or a lint, state exactly which invariant the surrounding code upholds to make it sound (e.g. "validated by the zod schema above", "guaranteed non-null because we just `.set()` it", "indices are in-bounds because `len` was checked above").

## Comments are NOT changelogs

Never write change-history phrasing: "Bumped from X to Y", "Refactored to W", "Now does Z", "Renamed from V", "Extracted from U", "Previously did A". Git tracks history; comments describe the static rationale a fresh reader meets tomorrow. If a value is unusual, justify the value — not the diff.

## Escape hatches per language — each REQUIRES a justifying comment

The "what" is documented by types; the comment must state the invariant that makes the unsafe thing sound.

- **TypeScript / JS:** `as X`, `as unknown as X`, non-null `!`, `any`, `@ts-expect-error`, `@ts-ignore`, `@ts-nocheck`, `eslint-disable*`, type predicates (`x is T`), and any unchecked cast of external data (JSON, API responses, `process.env`).
- **Rust:** `unsafe { }`, `unwrap()` / `expect()` / `unreachable!()` (justify why it cannot fail/panic), `#[allow(...)]`, `mem::transmute`, raw pointers, lossy `as` numeric casts (truncation/sign), and ignoring a `#[must_use]`.
- **Go:** `interface{}`/`any` with a type assertion `x.(T)` (say why the non-comma-ok form is safe), `unsafe.Pointer`, a deliberately ignored error (`_ = f()`), `//nolint` directives, `//go:` pragmas (`linkname`, `noescape`), and `panic`/`recover` used for control flow.
- **C#:** null-forgiving `!`, `#nullable disable`, `dynamic`, explicit `(T)` downcasts, `unsafe`/`fixed`/pointers, `#pragma warning disable`, `[SuppressMessage]`, and reflection that bypasses access checks.
- **Java:** `@SuppressWarnings(...)`, unchecked/raw-type casts `(T)`, `setAccessible(true)` and other reflection, `sun.misc.Unsafe`, empty `catch` blocks, and `assert` used for control flow.

## Exhaustiveness per language

Make "everything is handled" a compile-time guarantee, not a comment:

- **TS:** a `never`-typed default branch (`const _exhaustive: never = x`).
- **Rust:** no catch-all `_ =>` arm on a closed enum — list every variant so adding one breaks the build.
- **C#:** switch expression whose discard `_ =>` arm `throw`s, or rely on the exhaustiveness analyzer.
- **Java:** sealed types + a `switch` the compiler checks; otherwise `default: throw new IllegalStateException(...)`.
- **Go:** no enum exhaustiveness from the compiler — use a `default:` that panics on the impossible case, and consider an `exhaustive` linter.
