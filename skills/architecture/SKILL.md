---
name: architecture
description: Use when reviewing architectural concerns: module boundaries, dependency direction, ADR coverage, layering violations, and structural fitness for change
---

# Architecture Leverage Point

## When to Use

- A planning agent is reviewing a plan that introduces or alters module structure
- A PR-review agent encounters changes that cross layer or bounded-context boundaries
- The orchestrator (`software-leverage-review`) fans out a subagent for architecture

## When NOT to Use

- For micro-level code style or naming (different concern; falls under principles-and-patterns lens or developer-experience LP)
- For runtime-performance review (different concern; would belong to a future `performance` LP)

For DRY violations and software-complexity surface area, see the lens reference docs in `../software-leverage-review/references/`.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect architectural artifacts: module/package layout, public-vs-internal boundaries, ADR directory (`docs/adr/`, `docs/architecture/decisions/`, etc.), dependency declarations.
3. Apply checks:
   - Are non-obvious decisions captured in ADRs? Is there an ADR template in use?
   - Do dependencies point inward (toward stable abstractions) or outward (toward concrete details)?
   - Are layer boundaries respected? Look for upward calls, circular dependencies, business logic in transport/persistence.
   - Is the bounded context clear? Are the modules' responsibilities one-axis-of-change each?
   - Does the plan/diff introduce churn that hints at premature abstraction or missing abstraction?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"architecture"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"architecture"`.

## Red Flags (anti-patterns to surface as findings)

- **Architectural decision changes without an ADR or rationale comment.**
  - What to flag: a PR that swaps a database, introduces a new service boundary, or replaces a framework, with no `docs/adr/NNNN-*.md` entry and no rationale comment in the diff.
  - Why it matters: undocumented decisions evaporate. The next contributor (or agent) sees the result and cannot tell deliberate from accidental, so the decision gets relitigated or quietly reversed.
  - Cite: Michael Nygard, "Documenting Architecture Decisions" (2011), the canonical ADR template and the case for capturing context-decision-consequences at the moment of choice.

- **Circular dependencies between modules.**
  - What to flag: module `A` imports `B` and `B` imports `A`, directly or transitively.
  - Why it matters: a cycle means the two modules are one module pretending to be two. You cannot reason about, test, or replace either in isolation, and the build graph stops being a graph.
  - Cite: David Parnas, "On the Criteria to Be Used in Decomposing Systems into Modules" (CACM, 1972), on information hiding as the basis of decomposition; a cycle is the failure mode where neither side hides anything from the other. Cite also: Robert C. Martin, *Clean Architecture* (2017), Acyclic Dependencies Principle.

- **High-level modules importing low-level concrete types directly (Dependency Inversion violation).**
  - What to flag: a use-case or domain module importing a concrete database driver, HTTP client, or filesystem helper instead of an abstraction it owns.
  - Why it matters: the dependency arrow now points from the stable, business-meaningful core toward a volatile detail, so every detail change ripples upward. The Dependency Rule says it should point the other way.
  - Cite: Robert C. Martin, *Clean Architecture* (2017), the Dependency Rule. Cite also: Alistair Cockburn, "Hexagonal Architecture" (2005), the application core should be ignorant of its drivers and driven side.

- **Business logic mixed into transport, persistence, or presentation layers.**
  - What to flag: validation, pricing, authorization, or workflow rules living inside an HTTP handler, an ORM model, or a view template.
  - Why it matters: the rule cannot be reused outside that layer, cannot be tested without spinning the layer up, and gets duplicated the next time the same rule is needed elsewhere. Layering exists to keep one axis of change per module.
  - Cite: Martin Fowler, *Patterns of Enterprise Application Architecture* (2002), separation of presentation, domain, and data source. Cite also: Alistair Cockburn, "Hexagonal Architecture" (2005), on driving the core through ports rather than embedding logic in adapters.

- **A "god module" that all other modules depend on.**
  - What to flag: a `common/`, `utils/`, `core/`, or similar package that is imported almost everywhere and keeps growing.
  - Why it matters: it becomes the de facto coupling point of the whole system; any change to it is a change to everything, and its interface stops being designed and starts being whatever accumulated. Deep, narrow modules are the goal; this is the opposite.
  - Cite: John Ousterhout, *A Philosophy of Software Design* (2018), deep modules over shallow ones, complexity as the dominant force. Cite also: Parnas (1972), modules should hide a secret, not expose a junk drawer.

- **New abstraction added without three concrete cases driving it (rule of three violation).**
  - What to flag: a base class, interface, or generic helper introduced to support one or two callers, often "for future flexibility."
  - Why it matters: premature abstraction locks in the wrong shape and adds accidental complexity that future changes have to route around. The cheapest abstraction is the one extracted from three real cases, not imagined from one.
  - Cite: Frederick Brooks, *The Mythical Man-Month* (1975) and "No Silver Bullet" (1986), on essential vs accidental complexity; speculative abstraction is accidental complexity by construction.

- **Cross-context coupling (one bounded context reaching into another's internals).**
  - What to flag: code in one bounded context importing internal types, querying another context's tables directly, or sharing a mutable in-process object across contexts.
  - Why it matters: bounded contexts exist precisely so each can evolve its model on its own clock. When one reaches across, both contexts become a single context with two names, and autonomy is lost.
  - Cite: Eric Evans, *Domain-Driven Design* (2003), bounded contexts and context maps. Cite also: Sam Newman, *Building Microservices* (2nd ed., 2021), autonomy as the service-design constraint and coupling as the architecture failure mode. Cite also: Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns* (2003), for the messaging patterns that replace direct coupling when contexts must integrate.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Frederick Brooks, *The Mythical Man-Month* (1975) and "No Silver Bullet" (1986).** Essential vs accidental complexity; the design-by-decomposition argument. Use this when justifying restraint on speculative abstraction.
- **David Parnas, "On the Criteria to Be Used in Decomposing Systems into Modules" (CACM, 1972).** Information hiding and modular decomposition; interfaces should be designed around what to hide. Use this when justifying module boundaries and arguing against god modules and cycles.
- **Eric Evans, *Domain-Driven Design* (2003).** Bounded contexts and the strategic-design vocabulary for context boundaries. Use this when justifying context isolation.
- **Robert C. Martin, *Clean Architecture* (2017).** SOLID and the Dependency Rule (dependencies point inward toward use cases and entities). Use this when justifying dependency direction and the Acyclic Dependencies Principle.
- **Martin Fowler, *Patterns of Enterprise Application Architecture* (2002).** Layering, hexagonal framing, presentation/domain/data separation. Use this when justifying layer discipline.
- **Alistair Cockburn, "Hexagonal Architecture" (2005).** Ports and adapters; the application core is ignorant of its drivers and driven side. Use this paired with Fowler when flagging logic in adapters.
- **Michael Nygard, "Documenting Architecture Decisions" (2011).** The ADR template and rationale-capture practice. Use this when justifying ADR coverage.
- **Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns* (2003).** The messaging vocabulary for cross-context integration where direct coupling is wrong.
- **Sam Newman, *Building Microservices* (2nd ed., 2021).** Autonomy as a service-design constraint; coupling as the architecture failure mode. Use this when justifying context autonomy at service granularity.
- **John Ousterhout, *A Philosophy of Software Design* (2018).** Deep modules over shallow ones; complexity as the dominant force. Use this when justifying restraint on shallow utility packages.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the ADR path, name the boundary to introduce, name the layer the logic should move into, or name the integration pattern that replaces direct coupling.
