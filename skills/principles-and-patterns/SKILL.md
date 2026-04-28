---
name: principles-and-patterns
description: Use when reviewing cross-cutting design principles: SOLID, separation of concerns, dependency inversion, composition over inheritance, loose coupling and high cohesion
---

# Principles and Patterns Leverage Point

## When to Use

- A planning agent reviews a plan that introduces or alters core abstractions
- A PR-review agent encounters changes to base classes, interfaces, or cross-module contracts
- The orchestrator (`software-leverage-review`) fans out a subagent for principle-level analysis
- Design discussions where principle-level violations (god classes, inheritance abuse, leaky abstractions) are likely

## When NOT to Use

- For module-boundary specifics, layering, ADRs (use `architecture`)
- For code-level repetition (use `dry`)
- For complexity metrics and cognitive load (use `software-complexity`)

This skill enforces the *principles behind patterns*, not specific patterns. Domain-specific pattern recommendations belong to the relevant leverage-point skill. The lens reference at `../software-leverage-review/references/principles-and-patterns.md` remains authoritative for the orchestrator's synthesis pass.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect principle-relevant artifacts: class hierarchies, interface declarations, dependency wiring, cross-module imports, public APIs of newly introduced abstractions.
3. Apply checks (mirroring `references/principles-and-patterns.md`):
   - **Single Responsibility:** does any module/file/class touch more than one axis of change?
   - **Separation of Concerns:** is business logic mixed with transport, persistence, or presentation?
   - **Dependency Inversion:** do high-level modules depend on low-level concrete types instead of abstractions they own?
   - **Composition over Inheritance:** is a deep inheritance tree being used where a composition graph would be clearer?
   - **Loose coupling, high cohesion:** is related code spread across modules, or unrelated code crammed into one?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"principles-and-patterns"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"principles-and-patterns"`.

## Red Flags (anti-patterns to surface as findings)

- **A class or module with multiple axes of change.**
  - What to flag: a single class that handles HTTP parsing, business rules, and persistence; a module that changes for any of three unrelated reasons.
  - Why it matters: each axis of change is a reason to redeploy and retest. Bundling them means every reason ripples through every consumer. SRP separates the reasons so each can move independently.
  - Cite: Robert C. Martin, *Clean Architecture* (2017), the Single Responsibility Principle; David Parnas (1972), modules should hide a single design decision.

- **Business logic embedded in transport, persistence, or presentation.**
  - What to flag: pricing rules in an HTTP handler; authorization in an ORM model; workflow logic in a view template.
  - Why it matters: the rule cannot be reused, cannot be tested in isolation, and gets duplicated when the same rule is needed elsewhere. Separation of concerns exists so each layer changes for its own reasons.
  - Cite: Edsger Dijkstra (1974), "On the Role of Scientific Thought," the original separation-of-concerns essay; Eric Evans, *Domain-Driven Design* (2003), domain logic belongs in the domain layer.

- **High-level modules depending on concrete low-level types.**
  - What to flag: a use-case module importing a concrete database client, HTTP library, or filesystem helper instead of an abstraction it owns.
  - Why it matters: the dependency arrow points the wrong way; every change in a volatile detail ripples upward into stable business code. DI inverts it so details depend on the core, not vice versa.
  - Cite: Robert C. Martin, *Clean Architecture* (2017), the Dependency Inversion Principle; Alistair Cockburn, "Hexagonal Architecture" (2005), ports and adapters.

- **Deep inheritance tree where composition would do.**
  - What to flag: a 4+ level inheritance chain to add behavior; abstract base classes whose only consumer is one concrete subclass; "is-a" relationships used for code reuse rather than substitutability.
  - Why it matters: inheritance couples subclass to superclass implementation, not just interface; refactors at the top break everything below. Composition makes the relationship explicit and replaceable.
  - Cite: Gang of Four, *Design Patterns* (1994), "favor object composition over class inheritance"; Alberto Brandolini's modeling guidance on inheritance abuse in domain code.

- **Loose cohesion or tight coupling at module boundaries.**
  - What to flag: a `utils/` module mixing date parsing, cryptography, and string formatting (low cohesion); two modules that import each other's internals (high coupling).
  - Why it matters: cohesion measures whether a module has one job; coupling measures how much knowledge of one module another requires. Both axes determine how independently the system's parts can evolve.
  - Cite: Larry Constantine and Edward Yourdon, *Structured Design* (1979), the original coupling-and-cohesion vocabulary; Parnas (1972) on information hiding.

- **Cross-context coupling at the strategic level.**
  - What to flag: two bounded contexts sharing entity types, mutating each other's state, or reaching into internal models without an explicit context map.
  - Why it matters: bounded contexts exist so each can model the world on its own clock. Strategic coupling collapses two contexts into one with two names, and autonomy is lost long before the architecture diagram catches up.
  - Cite: Eric Evans, *Domain-Driven Design* (2003), strategic patterns and context maps.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Robert C. Martin, *Clean Architecture* (2017).** SOLID principles (SRP, OCP, LSP, ISP, DIP) and the Dependency Rule. Use this when justifying single-responsibility and dependency-direction findings.
- **David Parnas, "On the Criteria to Be Used in Decomposing Systems into Modules" (CACM, 1972).** Information hiding as the basis of decomposition; the original module-boundary argument. Use this when justifying cohesion and SRP at the module level.
- **Edsger Dijkstra, "On the Role of Scientific Thought" (1974).** The canonical separation-of-concerns framing. Use this when arguing that a layer should change for one reason.
- **Gang of Four (Gamma, Helm, Johnson, Vlissides), *Design Patterns* (1994).** Pattern catalog and the "favor composition over inheritance" maxim. Use this when flagging inheritance abuse.
- **Larry Constantine and Edward Yourdon, *Structured Design* (1979).** The original coupling-and-cohesion vocabulary; the seven coupling levels and the cohesion taxonomy. Use this when classifying module-boundary findings.
- **Alistair Cockburn, "Hexagonal Architecture" (2005).** Ports and adapters; the application core ignorant of its drivers. Use this paired with DIP to argue for inverted dependencies.
- **Eric Evans, *Domain-Driven Design* (2003).** Strategic patterns (bounded contexts, context maps) and tactical patterns (entities, value objects, aggregates). Use this when flagging context-level coupling and tactical patterns misapplied.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the responsibility to split out, the interface to introduce, the composition refactor, or the context boundary to honor.
