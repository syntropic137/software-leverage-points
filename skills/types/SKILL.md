---
name: types
description: "Use when reviewing type-system concerns: type-coverage in public APIs, primitive obsession vs refinement, runtime validation at trust boundaries, soundness gaps and escape hatches, narrow vs wide types, strict-mode discipline"
---

# Types

## Overview

Types are the cheapest specification a codebase carries. Done well, the type system documents the public surface, makes illegal states unrepresentable, refines untrusted input at the boundary exactly once, and the strictness setting is uniform across the project. Done poorly, escape hatches scatter across exported signatures, primitive parameters hide which value means what, and the boundary between trusted and untrusted data is invisible.

**Core principle:** Types document intent and constrain illegal states. Validate untrusted data at the boundary, refine it into typed shapes, and let downstream code assume the invariants hold.

## Core Principles

### 1. Strict mode is uniform across the project (scope: typed-language projects)

This principle scopes to projects in typed languages (TypeScript, Python with a type checker, Sorbet-on-Ruby, Kotlin, Rust, Go, etc.). When the scope applies: a single declared strictness level applies project-wide, enforced in CI, with named and dated exceptions when relaxed for a single file.

**Multiple valid strictness ladders exist:** off, soft (warn but do not block), strict (block on errors), pedantic (every optional check on). The principle is: state the level, apply it uniformly, document any per-file relaxation with a migration plan. The red flag is "strictness varies file-to-file with no plan," not "did not pick the strictest setting."

### 2. Public APIs are typed precisely; no escape hatches at the seam

Exported function signatures, class methods, and public type aliases must not include `any`, `Object`, untyped `dict`, `dynamic`, or unconstrained generics. An escape hatch on a public boundary defeats the type system for every caller transitively. Hide escape hatches behind a refined private function and expose only the typed shape.

This principle also covers narrow-vs-wide: a public type should describe what the implementation actually returns, not a wider superset that forces every caller to handle cases the implementation never produces.

### 3. Refine domain primitives instead of accepting raw strings and numbers

Signatures like `transfer(from: string, to: string, amount: number)` cannot prevent argument-swapping at the type level. Wrap domain primitives in refined types: `UserId` not `string`, `Email` not `string`, `Money` not `number`. The type system then documents intent and the compiler catches misuse.

**Multiple valid refinement styles exist:** newtype/branded type (zero-cost compile-time tag), nominal class (runtime construction with validation), opaque type alias (language-specific). The principle is: pick a style and apply it consistently to domain primitives. The red flag is "domain primitives passed raw," not "did not use newtype specifically."

### 4. Make illegal states unrepresentable with sum types

Boolean flags and sentinel values that mutually exclude each other (`isLoading + data + error` triplet, where only one is meaningful at a time) are a category error: the type permits states the domain forbids. Sum types (discriminated unions, sealed traits, enums-with-data) replace the impossible-but-typeable with the typeable-only-when-valid.

### 5. Runtime validation at trust boundaries (scope: any system crossing trust boundaries)

This principle scopes to any system that ingests data from outside its own trust boundary: HTTP requests, file I/O, message queues, database reads of untrusted shape, foreign-function-interface calls. When the scope applies: untrusted data is parsed and validated exactly once at the boundary, refined into a typed shape, and downstream code assumes the invariants hold.

`JSON.parse(body)` flowing into domain code without a runtime validator is a soundness lie: the compiler trusts the unsound `any` it received. Parse, don't validate-on-every-use.

Cross-reference: the `security` lens covers input validation as an attack-surface concern; this lens covers the same boundary as a soundness concern. Both checks apply at the same seam.

### 6. Type assertions require a runtime check

`value as User`, `cast(User, payload)`, `# type: ignore`, or `@ts-expect-error` used to silence a type error rather than refine the value is a lie to the compiler that becomes a runtime crash on the first counterexample. If a refinement is genuinely needed, pair the assertion with a runtime check that justifies it.

### 7. Per-file strictness relaxations carry a migration plan

`// @ts-nocheck`, per-file `mypy: ignore`, or `tsconfig` overrides that disable strictness for one path must include a comment naming the migration plan and a target date. A per-file relaxation without a plan is a debt marker that compounds silently and licenses the next file to do the same.

## Red Flags - STOP

- Strictness setting varies file-to-file or directory-to-directory with no stated migration plan
- `any`, `Object`, `dynamic`, untyped `dict`, or unconstrained generics in exported signatures
- Public type wider than what the implementation returns (e.g., `Result | null` when the body always returns `Result`)
- Domain primitives passed as raw strings or numbers in signatures where mistakes would be silent (user IDs, currency, email addresses)
- Boolean flag triplets or sentinel values where a sum type would make the illegal combinations unrepresentable
- Untyped JSON, request bodies, or queue messages flowing into domain code without a runtime validator
- Type assertions or `# type: ignore` used to silence the compiler with no paired runtime check or migration comment
- Optional-chaining cascades (`user?.profile?.email?.toLowerCase()`) where one boundary refinement would lift the invariant once
- Type-checker not enforced in CI; type errors are an editor convenience only

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "We can fix the `any` later" | Each `any` on a public seam infects every caller; the cleanup grows faster than the codebase |
| "We trust this JSON, it comes from our own service" | Until the schema drifts on one side and the type system silently corroborates the lie |
| "The cast is fine, I checked the value upstream" | The cast outlives the upstream check; pair them or refine instead |
| "Strict mode has too many false positives" | Tune the rules or scope the relaxation; uniform strictness is the only stable equilibrium |
| "Refinement types are over-engineering" | Until the third bug from a swapped string argument that a `UserId` newtype would have caught |
| "0.x means we can change types freely" | Callers pinned on the contract still break; the cost just hides behind the version |
| "Per-file `@ts-nocheck` is temporary" | Without a date and an owner, "temporary" means forever |

## Key Patterns

```
✅ function transfer(from: UserId, to: UserId, amount: Money): TransferReceipt
❌ function transfer(from: string, to: string, amount: number): any
```

```
✅ const body = UserSchema.parse(await req.json())  (refined at boundary)
❌ const body = await req.json() as User             (lie to the compiler)
```

```
✅ type Request = { kind: "loading" } | { kind: "ok", data: T } | { kind: "error", error: E }
❌ type Request = { isLoading: boolean, data: T | null, error: E | null }
```

```
✅ Strict mode on, project-wide, enforced in CI; relaxations carry a migration comment
❌ Strict mode on for new code; old code untouched; no plan to converge
```

```
✅ Public type: function getUser(id: UserId): User
❌ Public type: function getUser(id: UserId): User | null  (when the body never returns null)
```

## Why This Matters

Types are the specification the compiler can check on every build. The cost of skipping them is paid in runtime crashes, primitive-confusion bugs, and the slow erosion of confidence that the type signatures describe the truth.

Without disciplined typing:

- Public APIs ship with `any` escape hatches that infect every caller.
- Primitive-obsession bugs swap user IDs, currencies, and emails silently.
- Untyped JSON crosses the boundary and pretends to be valid.
- Type assertions accumulate as runtime time bombs.
- Strict mode is on for new code and a no-go zone for old code.

With disciplined typing:

- Public APIs document intent and constrain misuse at compile time.
- Domain primitives carry their meaning in their type.
- The boundary between trusted and untrusted data is one explicit refinement.
- Sum types make illegal states unrepresentable.
- The strictness level is uniform; relaxations are dated and tracked.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** types are present where they cost nothing; obvious primitive obsession is avoided on the few public seams. Awareness that boundary validation will be needed when the system ingests untrusted data.
- **Growing internal tool:** type checker enforced in CI; public APIs typed precisely; domain primitives wrapped where the cost of confusion is real. First boundary validators appear at HTTP and queue ingress.
- **Shared library:** public surface fully typed; no `any` exported; sum types model the public protocol; per-file strictness relaxations carry migration plans. Library consumers can rely on the type signatures as documentation.
- **Production service:** strict mode uniform; boundary validators on every untrusted ingress; refined domain types throughout the model layer; sum types replace flag triplets in core domain logic; type errors block merge in CI.
- **Safety-critical:** refinement types or formal-verification adjacent typing for invariants that resist enumeration; type-level state machines for protocol correctness; soundness gaps documented and reviewed; type signatures are part of the release artifact.

## References & rationales

- **Anders Hejlsberg, on TypeScript design.** Backs principle 1 (strict mode uniform). Types as a tooling-and-documentation layer; uniform strictness is what makes them reasoning tools, not annotations.
- **Dan Vanderkam, *Effective TypeScript* (2024); Boris Cherny, *Programming TypeScript* (2019).** Back principle 2 (no escape hatches in public APIs) and principle 6 (assertions need runtime checks). Working-language-level guidance on `any`-avoidance and the cost of unchecked casts.
- **Scott Wlaschin, *Domain Modeling Made Functional* (2018).** Backs principle 3 (refine domain primitives) and principle 4 (sum types for illegal states). The canonical functional-programming framing of domain modeling through types.
- **Yaron Minsky, "Make Illegal States Unrepresentable" (Jane Street).** Backs principle 4. The OCaml-flavored framing of using sum types to forbid the impossible-but-typeable.
- **Alexis King, "Parse, Don't Validate" (2019).** Backs principle 5 (runtime validation at boundaries). Refine unstructured input into a typed shape exactly once at the boundary, then trust the type.
- **Hillel Wayne and the formal-methods community on refinement types.** Backs principle 5. The spectrum from types to specs; refinement types as the cheapest place on that spectrum.
- **John Ousterhout, *A Philosophy of Software Design* (chapter 12).** Backs principle 2 (narrow types over wide ones). Code as documentation; the interface should narrow toward the truth.
- **Phil Wadler on type theory and parametricity.** Backs principle 7 (uniform strictness with documented exceptions). Why uniform strictness makes types reasoning tools rather than decoration.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **TypeScript:** `strict: true` in `tsconfig`; `zod`, `valibot`, or `io-ts` for boundary parsing; branded-type pattern for refinement; `ts-pattern` for sum-type matching.
- **Python:** mypy or Pyright in strict mode; Pydantic v2 or attrs+cattrs for boundary parsing; `NewType` for refinement; `match` statements with sum types via `dataclass` plus `Literal` discriminators.
- **Ruby:** Sorbet for gradual typing; runtime checks at boundaries via `T.let`/`T.cast`; `T::Struct` for refined records.
- **Rust:** the standard library's newtype pattern; `serde` for boundary parsing; the type system covers most of the discipline natively.
- **Go:** named types over primitives for refinement; explicit unmarshaling at boundaries; struct-tag validation libraries (`go-playground/validator`).
- **Kotlin / Scala:** sealed classes / sealed interfaces for sum types; value classes for newtype; kotlinx.serialization or circe for boundary parsing.
- **Cross-language:** JSON Schema or OpenAPI as the source-of-truth for boundary contracts; codegen typed clients from the schema where the toolchain supports it.
