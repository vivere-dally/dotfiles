# Code comments

## Default

- Keep routine code commentless. Use names, types, structure, and tests for facts that code can express.
- Match the comment style of adjacent code.
- Keep a new union member, enum case, field, or branch uncommented when equivalent neighbors have no comments.
- Do not add a comment only because a line changed.

## Admission test

Add or update a comment only when each condition is true:

- The fact is not visible from the code.
- The fact remains useful without the current task, diff, or session.
- Without the fact, a future reader can misunderstand the code or make a harmful edit.
- A name, type, test, assertion, or clearer structure cannot carry the fact better.

Eligible facts include an external constraint, correctness argument, load-bearing invariant, unusual constant, deliberate omission, or accepted trade-off.

## Content and placement

- State the hidden constraint and its consequence.
- Keep the work log, task narrative, and routine rejected alternatives outside source files.
- Put a broad design decision in an architecture record. Put a change explanation in the commit or pull request.
- State the local fact before a stable external link. A TODO can link to its issue.
- For an escape hatch, state the invariant that makes it safe and necessary.
- Flag unhandled behavior with an explicit error, panic, or TODO. Never return a fake value from a stub.

## Examples

A routine type member has no comment because its peers and fields explain it:

```ts
type Event =
  | { kind: "opened"; path: string }
  | { kind: "saved"; path: string }
  | { kind: "closed"; path: string };
```

A hidden aggregation rule earns a comment because the expression does not show it:

```ts
// Match only parent prefixes; child records already contribute to the parent total.
const projectPrefix = /^projects\/[a-z0-9-]+\/$/;
```

An escape hatch states the invariant that makes it safe:

```ts
// The schema validates each field before this boundary, so the cast cannot admit unchecked input.
const record = value as StoredRecord;
```

`Cast to StoredRecord` fails the admission test because it restates the code.

## Final comment review

Inspect only comments that the patch added or changed. Remove each comment that fails the admission test or duplicates adjacent code.

## Escape hatches per language

Each of these must carry a comment that gives the reason. The types give the "what". The comment states the invariant that makes the unsafe thing sound.

- **TypeScript / JS:** `as X`, `as unknown as X`, non-null `!`, `any`, `@ts-expect-error`, `@ts-ignore`, `@ts-nocheck`, `eslint-disable*`, type predicates (`x is T`), and each unchecked cast of external data (JSON, API responses, `process.env`).
- **Rust:** `unsafe { }`, `unwrap()` / `expect()` / `unreachable!()` (say why it cannot fail or panic), `#[allow(...)]`, `mem::transmute`, raw pointers, lossy `as` numeric casts (truncation or sign), and a dropped `#[must_use]` value.
- **Go:** `interface{}` or `any` with a type assertion `x.(T)` (say why the form without comma-ok is safe), `unsafe.Pointer`, and an ignored error (`_ = f()`).
- **Go, continued:** `//nolint` directives, `//go:` pragmas (`linkname`, `noescape`), and `panic` or `recover` as control flow.
- **C#:** null-forgiving `!`, `#nullable disable`, `dynamic`, explicit `(T)` downcasts, `unsafe`/`fixed`/pointers, `#pragma warning disable`, `[SuppressMessage]`, and reflection that gets past access checks.
- **Java:** `@SuppressWarnings(...)`, unchecked or raw-type casts `(T)`, `setAccessible(true)` and other reflection, `sun.misc.Unsafe`, empty `catch` blocks, and `assert` as control flow.

## Exhaustiveness per language

Make "each case is handled" a compile-time guarantee, not a comment:

- **TS:** a `never`-typed default branch (`const _exhaustive: never = x`).
- **Rust:** no catch-all `_ =>` arm on a closed enum. List each variant, so that a new variant breaks the build.
- **C#:** a switch expression whose discard `_ =>` arm throws, or the exhaustiveness analyzer.
- **Java:** sealed types and a `switch` that the compiler controls. Otherwise, `default: throw new IllegalStateException(...)`.
- **Go:** the compiler gives no enum exhaustiveness. Use a `default:` that panics on the impossible case, and consider an `exhaustive` linter.
