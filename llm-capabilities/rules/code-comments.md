# Code comments

## Comment the why, not the what

- Do not write a comment that restates the code. If a comment paraphrases the line below it, delete the comment.
- Types and good names already give the "what". Use them.
- Write the intent and the reason: why the code works this way, which problem it solves, and what a future reader cannot see in the code.
- Let the type system carry the "what" (descriptive types, unions, branded types, `readonly`, an exhaustive `switch`), so that the prose does not carry it.

## Record the decisions

- Record the alternatives that you considered and rejected, and why.
- Record the downsides and trade-offs that you accepted, and why. For example: why you used an escape hatch, why you disabled a lint rule, why you selected a library.
- Each escape hatch in the lists below must carry a comment that tells why it is safe and necessary. An escape hatch is never silent.

## Record what is not there

- Flag a shortcut or an unhandled case explicitly. Use an explicit error or panic (`throw new Error("not implemented")`, `todo!()`, `panic("unimplemented")`), or a `// TODO:` with an issue link.
- Never write a stub that returns a fake value.
- In an exhaustive `switch` or match, make the compiler find each case that you forgot (see the exhaustiveness list below). Then the build fails when a case is missing.
- Note a deliberate absence: why a method is not there, why a guard is omitted, or an optimization for later.

## Comments are first-class code

- Comments are among the most important code that you write. Give them the same care as the logic.
- Write the comment or the contract before the code. Give the intended behavior, the inputs, and the invariants in prose, then write the code below it.

## Comment the surprising, the unsafe, and the load-bearing

- Comment each thing that a reader does not expect:
  - a dependency on external or global state
  - a change to a shared object
  - a constraint on order or timing (async order, microtask against macrotask, lock order)
  - a subtle invariant
  - an algorithm choice that is not obvious
- Where you defeat the type checker, the borrow checker, or a lint, state the invariant that makes the code sound. For example: `the zod schema above validates it`, `not null because the line above sets it`, `in bounds because the code compared it to len above`.

## Comments are not changelogs

Never write the history of a change: `Bumped from X to Y`, `Refactored to W`, `Now does Z`, `Renamed from V`, `Extracted from U`, `Previously did A`. Git keeps the history. A comment gives the static reason that a fresh reader meets tomorrow. If a value is unusual, give the reason for the value, not for the diff.

## Comments point at code, never at documents

A person reads a comment with the code in front of them, not the plan. State the rule, the invariant, or the trade-off itself. Never cite the place where it lives. Thus a comment carries no pointer into a document:

- a design-decision id (`design D4`)
- a task, group, or section number
- a change name or a spec name
- a PR or issue reference (`PR #72`)
- a component that does not exist yet

Each of these pointers goes stale when the document moves. A pointer to living code (a function, a type, `file.ts:42`) or to an external standard is permitted.

## Counts belong to their owner

Never restate a count that a list, a constant, or a file owns. This rule applies to a comment, a docstring, a config header, and a test name. Write `the patterns in PATTERN_NAMES`, not `the eighteen patterns`. Otherwise each change to the list must find each copy, and a missed copy is wrong in silence.

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
