---
name: types
description: "Use when reviewing type-system concerns: type coverage, type-as-documentation, refinement vs primitive obsession, narrow vs wide types, runtime validation at boundaries, soundness gaps"
---

# Types Leverage Point

## When to Use

- A planning agent is reviewing a plan that introduces or alters type definitions, type configuration (`tsconfig`, `mypy`, `sorbet`), or boundary-validation logic
- A PR-review agent encounters changes to public-API signatures, domain models, or parse/validate seams
- The orchestrator (`software-leverage-review`) fans out a subagent for types

## When NOT to Use

- For language or type-system selection at the project level: that is the `architecture` LP
- For runtime input validation as a security concern (injection, authz, input fuzzing): that is the `security` LP. This LP cares about types as a soundness and documentation surface; the two LPs cross-reference at the validation boundary.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect type-system artifacts: `tsconfig.json`, `mypy.ini` / `pyproject.toml` `[tool.mypy]`, `sorbet`, type-only modules, parse/validate libraries (`zod`, `pydantic`, `io-ts`, `attrs`/`cattrs`), public-API signatures.
3. Apply checks:
   - Is type-checking enforced in CI, not just an editor convenience?
   - Are public APIs typed precisely, with no `any`, `Object`, or implicit `unknown` left in signatures?
   - Are domain primitives wrapped in types that encode invariants (`UserId` not `string`, `Email` not `string`)?
   - Are sum or union types used to make illegal states unrepresentable?
   - Is runtime data validated at the boundary (HTTP, file I/O, queue) and refined into typed shapes before crossing into domain code?
   - Is the type system used as documentation, so types replace some doc-strings?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"types"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"types"`.

## Red Flags (anti-patterns to surface as findings)

- **`any`, `Object`, or `dynamic` escape hatches in public APIs.**
  - What to flag: an exported function or method whose parameters or return type include `any`, `Object`, untyped `dict`, or an unconstrained generic.
  - Why it matters: an escape hatch on a public boundary defeats the type system for every caller transitively. The whole point of types as a tooling layer is lost the moment a public seam returns `any`. Hide escape hatches behind a refined private function and expose only the typed shape.
  - Cite: Dan Vanderkam, *Effective TypeScript* (2024), Items on `any`-avoidance and the "narrow your types" stance. Cite also: Anders Hejlsberg on the TypeScript design goal of types as a tooling and documentation layer.

- **Domain primitives passed as raw strings or numbers (primitive obsession).**
  - What to flag: signatures like `function transfer(from: string, to: string, amount: number)` where `from` and `to` are user IDs and `amount` is currency.
  - Why it matters: the compiler cannot stop the caller from swapping arguments, and the type system fails to document what each value means. Wrapping them in `UserId`, `Money`, `Email` makes illegal calls fail at the type level and turns the signature into self-documenting design.
  - Cite: Scott Wlaschin, *Domain Modeling Made Functional* (2018), on primitive obsession and refining primitives into domain types. Cite also: Yaron Minsky's "make illegal states unrepresentable" framing.

- **Optional chains where a refinement type would prevent the optional.**
  - What to flag: `user?.profile?.email?.toLowerCase()` chains, or repeated null-checks on the same field, where the type could be narrowed to `User & { profile: Profile & { email: Email } }` after an early validation.
  - Why it matters: optional-chasing pushes invariant checks into every caller instead of holding them at one boundary. A refinement type lifts the check once and lets every downstream caller assume the invariant holds.
  - Cite: Hillel Wayne and the formal-methods crowd on refinement types and the spectrum from types to specs.

- **Untyped JSON crossing boundaries without parse/validate.**
  - What to flag: `JSON.parse(body)` or `request.json()` whose result flows into domain code without a `zod.parse`, `pydantic.parse_obj`, or equivalent validator.
  - Why it matters: untyped JSON at a boundary is a category error that masquerades as type-correct because the compiler trusts the unsound `any` it received. The boundary is where parse-then-trust replaces validate-on-every-use.
  - Cite: Alexis King, "Parse, don't validate" (2019), on refining unstructured input into a typed shape exactly once at the boundary.

- **Type assertions (`as Foo`, `cast(Foo, x)`) without a runtime check.**
  - What to flag: `value as User`, `cast(User, payload)`, `# type: ignore`, or `@ts-expect-error` used to silence a type error rather than refine the value.
  - Why it matters: an unchecked assertion is a lie to the compiler that becomes a runtime crash on the first counterexample, and the lie is invisible at the call site. If a refinement is genuinely needed, pair the assertion with a runtime check that justifies it.
  - Cite: Boris Cherny, *Programming TypeScript* (2019), on the cost of type assertions and the type-narrowing patterns that replace them.

- **Type-checker config relaxed for one file at a time without justification.**
  - What to flag: `// @ts-nocheck`, per-file `mypy: ignore`, or `tsconfig` overrides that disable strictness for one path with no comment naming the migration plan.
  - Why it matters: a per-file relaxation is a debt marker that compounds silently; without a deadline or migration plan it stays forever and licenses the next file to do the same. Strict-by-default with named exceptions is the only stable equilibrium.
  - Cite: Phil Wadler on type theory and parametricity, framing why uniform strictness is what makes types reasoning tools rather than annotations.

- **Public API typed less precisely than its implementation.**
  - What to flag: an exported function returning `Result | null` while the body always returns a `Result`, or accepting `string` while the body only handles two literal values.
  - Why it matters: imprecise public types invite imprecise callers and force every caller to handle cases the implementation never produces. John Ousterhout's "deep modules" and "code as documentation" argue the interface should narrow toward the truth, not widen toward laziness.
  - Cite: John Ousterhout, *A Philosophy of Software Design* (chapter 12), on code as documentation and the cost of imprecise interfaces.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Anders Hejlsberg on TypeScript design.** Types as a tooling-and-documentation layer, not just type safety. Use this when justifying why public-API precision pays off in editor tooling and reading speed.
- **Scott Wlaschin, *Domain Modeling Made Functional* (2018).** Sum types and refinement to make illegal states unrepresentable. Use this when justifying domain primitives and union-typed states.
- **Yaron Minsky, "make illegal states unrepresentable" (Jane Street).** The OCaml-flavored framing of the same principle. Use this when arguing for sum types over boolean flags.
- **John Ousterhout, *A Philosophy of Software Design* (chapter 12).** Code as documentation and the cost of imprecise interfaces. Use this when justifying narrow types over wide ones.
- **Dan Vanderkam, *Effective TypeScript* (2024) and Boris Cherny, *Programming TypeScript* (2019).** Working-language-level guidance on `any`-avoidance, narrow types, and assertion costs.
- **Phil Wadler on type theory and parametricity.** Why uniform strictness makes types into reasoning tools. Use this when justifying strict-by-default config.
- **Hillel Wayne and the formal-methods crowd on refinement types.** The spectrum from types to specs. Use this when justifying boundary-validation that refines untyped data into typed shapes.
- **Alexis King, "Parse, don't validate" (2019).** Refine unstructured input into a typed shape exactly once. Use this when flagging untyped JSON crossing a boundary.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the typed wrapper to introduce, the boundary parser to add, the assertion to replace with a refinement, or the strict-mode flag to flip.
