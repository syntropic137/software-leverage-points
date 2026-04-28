---
name: architecture
description: Use when reviewing architectural concerns: module boundaries, dependency direction, layer discipline, bounded-context isolation, ADR coverage, premature abstraction, and structural fitness for change
---

# Architecture

## Overview

Architecture is the set of structural decisions that shape what a system can become. It is the part hardest to change after the fact, so the part most worth getting right deliberately. Architecture is not "the diagram"; it is the constraint regime that determines whether the next change is local or global.

**Core principle:** Dependencies point toward stability; modules hide secrets; decisions leave receipts. Each named principle below is a way of preserving the option to change.

## Core Principles

### 1. Information hiding (modules hide a secret)

A module is a unit of decomposition organized around something it hides from its callers: a data structure, an algorithm choice, a third-party API. The interface is the contract; the secret is whatever can change behind it without breaking callers.

A module that hides nothing (a "junk drawer" `utils/`, `common/`, `core/`) is not a module; it is a coupling point.

### 2. Dependency direction (point toward stability)

Dependencies point from volatile details toward stable abstractions. High-level modules (use cases, domain logic) do not import low-level concrete types (database drivers, HTTP clients, filesystem helpers); they depend on abstractions they own.

When the arrow points the other way, every detail change ripples upward through the stable core.

### 3. Layer discipline (one axis of change per layer)

Validation, pricing, authorization, and workflow rules are domain concerns; they do not live in HTTP handlers, ORM models, or view templates. Layering exists so each module changes for one reason. When business logic lives in the transport layer, it cannot be reused, tested without spinning the layer up, or moved without rewriting it.

**Multiple valid layering schools exist:** clean architecture, hexagonal (ports and adapters), onion, vertical-slice. The principle is: pick one and apply it consistently. The red flag is mixing schools without a stated rule, not "did not pick hexagonal."

### 4. No cycles in the module graph

Module `A` imports `B` and `B` imports `A` (directly or transitively) means `A` and `B` are one module pretending to be two. Neither can be reasoned about, tested, or replaced in isolation, and the build graph stops being a graph.

The Acyclic Dependencies Principle is non-negotiable in any layering scheme.

### 5. Rule of three for abstraction extraction

The cheapest abstraction is the one extracted from three concrete cases. Speculative abstractions ("for future flexibility") locked in from one or two cases lock in the wrong shape; future changes route around the abstraction rather than through it, accumulating accidental complexity.

This principle scopes to abstraction extraction, not to constants or configuration. A constant defined once is fine; an interface defined for one caller is not.

### 6. Bounded-context isolation (scope: systems with multiple contexts)

This principle scopes to systems large enough to have multiple bounded contexts. A single-context POC inherits a weaker form: keep the option to split later by not coupling internal models to transport.

When the scope applies: each context owns its data and its model; cross-context coupling (importing internal types, querying another context's tables, sharing mutable in-process objects) collapses two contexts into one with two names. Integration between contexts goes through explicit messaging or APIs.

### 7. ADR coverage for non-obvious decisions

Architectural decisions evaporate the moment they are made unless captured. ADRs record context, decision, and consequences at the moment of choice, so the next contributor (or agent) can tell deliberate from accidental.

ADR coverage is a precondition for the system to remain editable across team changes; without it, every load-bearing decision becomes a candidate for relitigation.

## Red Flags - STOP

- Architectural decision (database swap, new service boundary, framework replacement) shipped without an ADR or rationale comment in the diff
- Circular dependencies between modules (direct or transitive)
- High-level module importing concrete database driver, HTTP client, or filesystem helper directly (Dependency Inversion violation)
- Business logic (validation, pricing, authorization, workflow) inside HTTP handlers, ORM models, or view templates
- A `common/`, `utils/`, `core/` package imported almost everywhere and growing unboundedly (god module)
- New abstraction (base class, interface, generic helper) introduced to support one or two callers (rule of three violation)
- One bounded context importing another's internal types or querying its tables directly
- Layering style mixed across the codebase with no stated convention

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "We'll write the ADR later" | Later doesn't come; the rationale lives in a Slack thread that expires |
| "It's just a small cycle" | A cycle means the modules are one module; reasoning collapses regardless of size |
| "Importing the driver directly is simpler" | It is, until the driver changes and every use case has to change with it |
| "Business logic in the controller is fine for now" | Now becomes the next five years; the rule duplicates the next time it is needed |
| "We need this abstraction for future flexibility" | Future flexibility from one case is a guess; from three cases it is a pattern |
| "Bounded contexts are over-engineering" | They are, until two teams ship conflicting changes to the same model |
| "utils.py is just a place for shared helpers" | It is the de facto coupling point; every change to it is a change to everything |

## Key Patterns

```
✅ Use case imports a Repository interface it owns; adapter implements it
❌ Use case imports psycopg2.connect directly
```

```
✅ HTTP handler: parse request → call use case → format response
❌ HTTP handler: parse, validate business rules, query DB, compute price, format response
```

```
✅ docs/adr/0042-switch-to-cockroach.md (context, decision, consequences)
❌ Database swap shipped with diff only; rationale in a stale Slack thread
```

```
✅ Module graph: domain ← application ← interface; no back-edges
❌ domain imports application for a "shared helper"; cycle established
```

```
✅ Abstraction extracted from three concrete cases that already exist
❌ Abstraction introduced for "future flexibility" with one caller
```

```
✅ Context A talks to Context B via published API or message
❌ Context A queries Context B's tables directly
```

## Why This Matters

Architecture is the part of a system that resists change most. Get it wrong early and every subsequent change pays a tax; get it right and the system absorbs new requirements without rewrites. The principles above are not preferences; they are the constraints that keep change local.

Without architectural discipline:

- Every change becomes global; the team slows down as the codebase grows.
- Decisions get relitigated because no one remembers why they were made.
- Bounded contexts collapse into a single distributed monolith.
- Premature abstractions become permanent shapes the codebase routes around.

With architectural discipline:

- Changes stay local because modules hide secrets behind contracts.
- Decisions are receipts; the rationale survives team changes.
- Contexts evolve on their own clock without coupling to neighbors.
- Abstractions reflect three real cases, not one imagined future.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** one module, one process, one data store. No ADRs yet; decisions are still fluid. Awareness that the first cycle, the first god module, and the first leaked detail will lock shape if not noticed.
- **Growing internal tool:** explicit module boundaries appear; the first ADRs document the choices that already feel load-bearing. Layering convention is named (one of the schools). Public-vs-internal distinction enforced by language or convention.
- **Shared library:** dependency direction enforced; the library does not import application-level concerns. Public API is documented; internal modules hide their secrets. ADRs cover every load-bearing decision.
- **Production service:** layering enforced in review or by automated checks. Module graph is acyclic and validated. ADRs are part of the workflow; non-obvious changes ship with one. Bounded contexts (if multiple) are isolated and integrate via published contracts.
- **Safety-critical:** architectural decisions reviewed by a second pair of eyes; ADRs are part of the release artifact. Module boundaries enforced mechanically (architecture tests, dependency rules in CI). Cross-context integration uses explicit, versioned, monitored contracts. Premature abstraction caught in review before it lands.

## References & rationales

- **David Parnas, "On the Criteria to Be Used in Decomposing Systems into Modules" (CACM, 1972).** Backs principle 1 (information hiding). The foundational argument that interfaces are designed around what to hide.
- **Robert C. Martin, *Clean Architecture* (2017).** Backs principles 2 (Dependency Rule, dependencies point inward) and 4 (Acyclic Dependencies Principle).
- **Martin Fowler, *Patterns of Enterprise Application Architecture* (2002).** Backs principle 3 (layer discipline, presentation/domain/data separation).
- **Alistair Cockburn, "Hexagonal Architecture" (2005).** Backs principles 2 and 3 from the ports-and-adapters direction. Core is ignorant of drivers and driven side.
- **Frederick Brooks, *The Mythical Man-Month* (1975) and "No Silver Bullet" (1986).** Backs principle 5 (rule of three). Essential vs accidental complexity; speculative abstraction is accidental complexity by construction.
- **Eric Evans, *Domain-Driven Design* (2003).** Backs principle 6 (bounded contexts). Strategic-design vocabulary for context boundaries.
- **Sam Newman, *Building Microservices* (2nd ed., 2021).** Corroborates principle 6 at service granularity. Autonomy as a service-design constraint.
- **Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns* (2003).** Corroborates principle 6 from the integration direction. Messaging vocabulary for cross-context integration.
- **Michael Nygard, "Documenting Architecture Decisions" (2011).** Backs principle 7 (ADR coverage). The canonical ADR template and the rationale-capture practice.
- **John Ousterhout, *A Philosophy of Software Design* (2018).** Backs principle 1 from the depth direction. Deep modules over shallow ones; complexity as the dominant force; restraint on shallow utility packages.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **Architecture testing (mechanical enforcement):** ArchUnit (Java/Kotlin), `dependency-cruiser` (JS/TS), `import-linter` (Python), `archtest` (Go).
- **ADR tooling:** `adr-tools` CLI, `log4brains`, MADR template, plain markdown in `docs/adr/`.
- **Hexagonal / ports-and-adapters scaffolding:** language-native; rarely needs a framework. Spring (Java) and NestJS (TS) provide DI primitives that align well; Go and Rust prefer explicit constructor injection.
- **Module-graph visualization:** `dependency-cruiser --output-type dot`, `pydeps`, `cargo-modules`, `go-callvis`.
- **Bounded-context messaging:** Kafka, NATS, RabbitMQ, cloud-native (SQS/SNS, Pub/Sub, EventBridge); the choice is downstream of the integration pattern.
- **Diagrams as code:** Mermaid (rendered by GitHub natively), Structurizr (C4 model), PlantUML, D2.
