---
name: boundary-hardening
description: "Use when reviewing boundary-hardening concerns: whether load-bearing seams are explicit, dependency-inverted, and pinned by evidence strong enough that the implementation behind them is swappable and regenerable; the quality of the contract itself (error taxonomy, idempotency, cancellation, consumer-level abstraction, leaked vendor types); code that should be a boundary and is not; harden-vs-split diagnosis by cohesion; safe migration of a live seam; whether a landed extraction is ratcheted by a gate or test so it cannot silently re-couple. Do NOT use for reviewing the structure that already exists (that is architecture: dependency direction, layering, cycles, ADR coverage), for test-suite quality in general (that is testing), or for the external plug-point surface (that is extensibility); this skill is specifically the active discipline of extracting and pinning new seams."
---

# Boundary Hardening

## Overview

This skill reviews whether the **load-bearing seams** of a system have been found, designed as contracts, extracted safely, and pinned by evidence strong enough that the code behind them can be replaced. It is the active discipline: not "is the existing structure sound" but "what in this code *should* be a boundary and is not yet, and what would it take to make it one without breaking the system on the way."

The premise is a shift in what the durable software artifact is. When implementations are increasingly generated, and regenerated, by AI, the implementation is the cheap and replaceable part. What persists is the **contract between modules** and the **evidence suite that pins it**. That pair is what a replacement has to satisfy, so it is the thing worth investing in.

**Core principle:** Treat the contract and its pinning evidence as the artifact you are actually building, and the implementation behind it as replaceable. Find the seam that carries load, design the contract deliberately, invert the dependency across it, pin every characteristic the system actually depends on, migrate to it without a flag day, and ratchet it so it cannot re-couple.

Cross-reference: the [`architecture`](../architecture/SKILL.md) skill reviews the structure that exists (dependency direction, layering, cycles, bounded contexts, fitness functions) and supplies the diagnostic vocabulary this skill uses; do not re-derive it here. This skill covers the act of creating, proving, and enforcing a seam that does not exist yet.

## Core Principles

### 1. The boundary is the durable artifact, to the extent the contract is complete

An implementation is a current answer. A contract is a commitment about what any answer must satisfy. As generation costs fall, the asymmetry widens: rewriting the code behind a well-specified port is cheap and getting cheaper, while discovering the right seam, agreeing on its contract, and proving the system still works across it remains expensive design work.

The review question follows: for each load-bearing seam, is it **explicit** (a named contract, not an import-graph accident), **dependency-inverted** where that relationship applies (see principle 9), and **pinned by evidence** that a replacement must satisfy?

**Scope the regenerability claim honestly.** A behavioral test suite pins sampled observable behavior. On its own it does not pin performance and resource bounds, concurrency and ordering guarantees, transactional atomicity, idempotency under retry, cancellation and timeout behavior, authorization properties, data ownership and retention, or failure-recovery semantics. An implementation is safely replaceable only to the extent that the characteristics the system actually depends on are part of the contract and are backed by evidence appropriate to each: tests for functional behavior, benchmarks and budgets for performance, property or concurrency tests for ordering, fault injection for recovery, and explicit documented guarantees where no automated check is practical.

The failure this scoping prevents is the most expensive one this skill can cause: declaring a module replaceable because its happy-path API behavior is green, then discovering after the swap that a caller depended on an ordering guarantee nobody wrote down. **Unwritten guarantees are the real coupling**, and a seam is only as hard as the characteristics it names.

This principle scopes to seams that carry load: those crossed by many changes, or crossing a volatility difference (stable policy on one side, churning detail on the other). Not every function call is a boundary, and treating them all as one is its own pathology (see principle 8).

### 2. The contract is designed, not merely declared

Extracting an interface is not the same as designing one. A contract can be explicit, inverted, and tested, and still make replacement prohibitively expensive, because the shape of the contract is itself a decision with consequences.

What a review looks at once a port exists:

- **Whose level of abstraction is it at?** A port shaped by the consumer's needs is replaceable. A port that mirrors one provider's SDK method-for-method has embedded that provider in the contract, so the second implementation contorts itself and the seam buys nothing.
- **Do provider types leak through it?** Vendor exceptions, ORM entities, framework request objects, or persistence-shaped structs crossing the boundary re-couple it regardless of the interface in front.
- **Is the error taxonomy part of the contract?** Callers branch on failures. If which errors can occur and what they mean is not specified, every implementation invents its own and the callers couple to whichever one shipped first.
- **Are the operational semantics stated?** Idempotency under retry, timeout and cancellation behavior, ordering, and transactional scope are contract members whenever a caller depends on them. Cross-reference: the [`error-handling`](../error-handling/SKILL.md) skill carries retry, backoff, and idempotency discipline in depth; this principle is the narrower claim that those semantics belong in the boundary's contract rather than in each implementation's habits.
- **Is it chatty or temporally coupled?** A contract requiring a fixed call sequence, or many round trips to do one thing, constrains every future implementation to the current one's internal structure.
- **Is it minimal?** Every operation on a port is a promise each implementation must keep. Surface added speculatively is surface that must be reimplemented forever.

Hyrum's Law is the reason this matters more than it looks: with enough consumers, every observable behavior of an implementation becomes something someone depends on, whether or not it was promised. Contract design is the act of deciding, deliberately, which behaviors are promises.

### 3. A boundary is pinned by behavior, not implementation

A test suite that reaches through the port and asserts on internals re-couples the boundary it was meant to protect. Such a suite fails when a correct reimplementation lands, which is precisely the event it should have survived, so it converts the implementation back into the artifact.

The pinning suite is the operational definition of the contract: it should pass against any correct implementation and fail on any behavior the contract promised and the implementation broke. Where multiple implementations exist, the strongest form is a shared contract test suite the port owns and every implementation runs, including the fakes used in other modules' tests, since a fake that drifts from the real behavior silently invalidates every test that depends on it.

Cross-reference: the [`testing`](../testing/SKILL.md) skill carries the general discipline of test quality, coverage, and speed; this principle is the narrow claim that a boundary is only as hard as the evidence pinning it, and principle 1 is the claim that behavioral tests are only part of that evidence.

### 4. Active extraction: name what should be a boundary and is not

The finding this skill uniquely produces is about absent structure. Signals that a seam is load-bearing but unextracted:

- A concrete detail (a driver, a vendor SDK, a model provider, a file format) is referenced directly from many call sites across layers.
- Two responsibilities with different rates of change live in one module, so the stable one is redeployed and retested every time the volatile one moves.
- **Change coupling:** a set of files that repeatedly change together while sharing no module. Tornhill's core observation is that version-control history reveals coupling the static structure hides, and a recurring co-change cluster is the shape of a module that exists conceptually but not structurally.
- A module cannot be tested without standing up something it should not know about.

Each is a candidate cut. Reporting "this is fine, it compiles" against these signals is the failure mode this skill exists to prevent.

### 5. Harden or split: diagnose cohesion before you cut

Coupling is the symptom; cohesion informs the treatment, and the two treatments are opposites.

- High coupling **plus high cohesion**: the module is one real thing that too many callers reach into. **Harden.** Design a contract, invert the dependency, pin it.
- High coupling **plus low cohesion**: the module is a grab-bag that accumulated by proximity. **Split.** Decompose by responsibility first, because there is no single contract to write.

Applying the wrong treatment makes things worse. Splitting a cohesive kernel produces chatty cross-module traffic worse than the in-module coupling it replaced; hardening a grab-bag wraps mud in an interface and calls it a port.

**This is a heuristic that starts the diagnosis, not a decision rule that ends it.** Cohesion has kinds, and Constantine and Yourdon's ranking is the reason: a module cohesive only because its parts run at the same time (temporal cohesion) is not the same as one cohesive around a single function, and the first often still wants splitting. Coupling likewise has direction and kind, and the cost of a dependency on a stable abstraction is not the cost of a dependency on a volatile concrete type. Two cases the two-cell rule gets wrong on its own: a cohesive module whose responsibilities belong to different owners or different rates of change may still need splitting, and a deliberately low-cohesion compatibility facade may be correct to leave intact because its whole job is to be the one place the mess is contained.

Rank candidates by instability combined with fan-in rather than fan-in alone. A module everything depends on is *healthy* when it is stable (low churn, high abstraction, few outward dependencies); the mud forms when a heavily depended-on module is also volatile. Martin's distance from the main sequence expresses that combination, and the [`architecture`](../architecture/SKILL.md) skill carries the metric vocabulary.

### 6. Extraction is a migration, not an edit

Writing the interface is the easy half. For any seam with live callers and live data, the risk is concentrated in the transition, and a skill that stops at "extract the port" has stopped before the dangerous part.

What a review expects of a non-trivial extraction:

- **Characterization tests first.** Before changing code whose behavior is not fully understood, pin what it currently does, including behavior nobody intended. Extracting a seam under a suite written after the fact only proves the new code matches the new assumptions.
- **Incremental, not flag-day.** Branch by abstraction or an equivalent: introduce the contract, route callers through it one at a time while both paths work, and keep the system releasable throughout. A long-lived extraction branch is the failure mode this avoids.
- **Comparison where correctness is uncertain.** For high-stakes seams, run the new implementation alongside the old and compare results before cutting over. The distinction that makes this safe rather than reckless: the shadow path is **read-only or otherwise side-effect-free**, with the old path remaining the only one that writes, sends, or charges. Running two side-effecting implementations in parallel does not verify a migration; it doubles the side effects.
- **A named cutover and rollback condition.** "We will switch when X and revert if Y," decided before the switch rather than during the incident.
- **The old path is deleted.** An extraction that leaves the direct access route in place has added a contract without removing the coupling, so both exist and the new one is optional.

Splitting data ownership deserves particular care: code can be routed through a new contract in an afternoon, while the data behind it may need dual writes, a backfill, and a reconciliation check. That temporary dual-write phase is legitimate and is not the same thing as the failure it resembles. A controlled dual write has **one authority of record**, a reconciliation check that detects divergence, and a stated exit condition that ends it. What is fatal is the permanent version: two independently writable paths to the same state, neither authoritative, with nothing detecting when they disagree. That corrupts data rather than merely disappointing the architect, and it is the worst outcome the entire exercise can produce.

### 7. The ratchet is the hardening

Extraction without enforcement is temporary. The next change that finds the boundary inconvenient reaches across it, nothing objects, and the seam is gone while the interface file remains as evidence of good intentions.

A boundary is hardened only when a mechanical check rejects its regression: an import-direction or module-graph rule that fails the build on a back-edge, a contract test that fails when the port's behavior drifts, a coupling or complexity metric floored at its post-extraction value. Detect, design, extract, migrate, **enforce**. The last step is not polish; it is the step that makes the earlier ones durable.

This is the fitness-function pattern the [`architecture`](../architecture/SKILL.md) skill carries, applied to a specific seam at the one moment when the correct floor is known and the cost of setting it is lowest: the change that creates it.

### 8. Every cut buys something concrete, and the second payoff is an option, not a guarantee

Extraction costs indirection, a migration, and a contract someone must maintain. It is not free and it is not automatically good, so a proposed boundary names its payoff or it does not land. Valid payoffs: a module that can be worked on in isolation (by a separate person or agent) without serializing on shared state, a unit that can be tested without standing up its neighbors, a concrete swap that is actually coming, or an enforced rule that is currently violated.

A hardened boundary also creates an **option**: the same clean seam can later become the surface an outside author extends. Baldwin and Clark's argument is that modularity's value is largely option value, which is real and routinely under-counted, but an option is not a payoff until it is exercised. Two errors follow from confusing them:

- Counting the external payoff for a seam that will never be exposed. Many excellent internal boundaries should never be public: exposure freezes the internals against change, enlarges the security surface, and creates compatibility obligations that outlast the team's interest in them.
- Refusing a seam that is only barely justified internally when exposure is genuinely planned, since the option has value that the internal case alone does not capture.

The review rule is therefore to price the payoffs **independently** and count both only where the evidence supports both. Where the option is real, it can raise the priority of a seam that already has an internal payoff, and it can tip a marginal one when a specific exposure is planned and someone is accountable for it. What it cannot do is supply the justification by itself: that is the line between counting an option and building on speculation, and it is the same line the rule of three draws. Cross-reference: the [`extensibility`](../extensibility/SKILL.md) skill carries the decision to exercise that option and everything it obligates (compatibility, trust tiers, lifecycle, author experience); this skill carries the internal payoff and the act of cutting the seam.

The inverse guard applies with equal force: a port introduced for one implementation with no second one plausible is premature abstraction wearing a boundary's clothes. This threshold (a plausible second implementation) is deliberately lower than the rule of three: the rule of three governs extracting a shared abstraction from duplicated code, while a seam pays off through swappability and evidence pinning, which one real second implementation (a contract-tested fake counts) already delivers. Cross-reference: the [`software-complexity`](../software-complexity/SKILL.md) skill carries the cost side of speculative indirection, and the [`architecture`](../architecture/SKILL.md) skill carries the rule of three for extraction.

### 9. Name the seam's form, and check the mechanism fits it

"Extract a port and invert the dependency" is the mechanism for one family of seams: in-process module boundaries where a consumer can own the abstraction its provider implements. Other durable seams exist and take different mechanisms:

- **Process and deployment boundaries**, where the contract is a network API and the enforcement is versioning plus compatibility testing, not an import rule.
- **Message, event, and file-format schemas**, where the contract is the schema, the consumers may be unknown, and evolution rules (additive change, unknown-field handling) replace dependency inversion entirely.
- **Data-ownership boundaries**, where the rule is that one module writes a given table and others read through an interface it publishes.
- **Peer contracts** between components neither of which owns the other, where "the consumer owns the abstraction" simply does not apply and the contract is negotiated or standardized instead.

A review names which kind of seam it is proposing before prescribing a mechanism, because prescribing dependency inversion for a published data contract is a category error.

Within in-process seams, the cut is either **horizontal** (separating policy from mechanism: a port with adapters behind it, which is what makes an implementation swappable) or **vertical** (separating one capability from another end to end, so a slice changes without touching its neighbors, which is what lets two workers proceed without meeting). Most systems need both, and the review requirement is a **stated, consistently applied convention** for how they compose, not a particular school. The [`architecture`](../architecture/SKILL.md) skill carries the layering schools and the vertical-slice and hexagonal patterns in depth, including the rule that mixing schools without a stated convention is the actual red flag.

### 10. Boundaries encode the system's mental model

The boundary structure is where the team's theory of the problem is written down. Module names, contract shapes, and what each side is allowed to know constitute the shared understanding of what this system is; the code inside is one expression of it.

Naur's argument is that the program text is secondary to the theory its builders hold, and that a program whose theory has been lost cannot be modified sensibly even when the source is fully available. The inference this skill draws, and it is an inference rather than Naur's own claim, is that **boundaries are the most durable written trace of that theory**, which is why they survive rewrites of the code behind them and why losing them is more expensive than losing an implementation.

The corollary is the definition of the big ball of mud: not ugly code, but the state where no boundary encodes the model, so the only representation of the system's theory is the entire codebase and the only people who hold it are those who have read all of it. Hardening is how a growing codebase keeps writing that theory down.

## Red Flags - STOP

- A concrete detail (database driver, vendor SDK, model provider, file format, queue client) referenced directly from call sites across multiple layers, with no contract anywhere
- A seam named as a boundary in docs, ADRs, or diagrams, but with no contract, no inversion, and no check that would fail if it were violated
- A module declared replaceable on the strength of behavioral tests alone, while callers depend on ordering, latency, atomicity, or idempotency that the contract never states
- A port whose operations mirror one vendor's SDK method-for-method, so the abstraction is the provider's rather than the consumer's
- Provider types crossing the boundary: vendor exceptions, ORM entities, framework request objects, or persistence-shaped structs in the contract's signatures
- A contract with no stated error taxonomy, so each implementation invents its own failures and callers couple to whichever shipped first
- A contract that requires a fixed call sequence or many round trips to accomplish one thing, freezing every future implementation to the current one's internal structure
- A port and its tests assert on implementation internals, so a correct reimplementation fails them
- Fakes used by other modules' tests that do not run the port's own contract suite, so they drift from real behavior and silently invalidate their dependents
- An extraction performed without characterization tests over behavior nobody fully understood
- A big-bang extraction on a long-lived branch, with no incremental path and no releasable intermediate state
- An extraction that leaves the old direct-access path in place, so the contract is optional
- Two writable paths to the same state with no authority of record, no reconciliation check, and no exit condition; a dual-write phase that has become permanent
- A parallel-run comparison in which both implementations produce side effects, so the verification step doubles the writes it was meant to check
- Data ownership split in code while the underlying store is still shared and writable from both sides, with no migration, backfill, or reconciliation plan
- An extraction landed with no mechanical enforcement: no import-direction rule, no contract test, no floored metric, so the next reach-across is silent
- A module with high fan-in and high volatility that no one has diagnosed as harden or split
- A grab-bag module wrapped in an interface and reported as hardened, with the low cohesion untouched behind it
- Cohesive kernel split into chatty fragments that now round-trip across a boundary for what used to be a local call
- A boundary proposed with no named payoff: no isolation win, no plausible second implementation, no violated rule it fixes
- A port introduced for exactly one implementation with no second one plausible, justified as future flexibility
- External extensibility counted as a payoff for a seam nobody intends to expose, or an exposure commitment made incidentally because a seam happened to exist
- Dependency inversion prescribed for a seam where it does not apply, such as a published schema or a peer contract with no owning consumer
- The same category of change repeatedly touches the same scattered file set, and no one has proposed the module that shape implies
- A unit cannot be tested without standing up a dependency it should not know about, and this is treated as a testing problem rather than a boundary problem
- Horizontal and vertical cuts mixed across the codebase with no stated convention for how they compose

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The implementation is the real work; the interface is ceremony" | The implementation is the part that gets regenerated. The contract and its pinning evidence are what survive that event. |
| "The behavior tests pass, so it's swappable" | Behavioral tests sample observable behavior. If callers depend on ordering, latency, atomicity, or idempotency that nothing states, the swap breaks them and the suite stays green. |
| "The guarantee is obvious from the implementation" | A guarantee readable only from the implementation is a property of that implementation, not of the contract. The replacement will not have it. |
| "We can extract the boundary later when we need it" | Later means extracting it from code that has grown assumptions across the seam, and doing it under time pressure rather than deliberately. |
| "It's already modular, the files are separate" | Separate files with direct concrete imports across them are one module with a directory structure. |
| "We have an interface, so it's a boundary" | An interface with one implementation, no inversion, and no pinning evidence is indirection. The boundary is the contract plus the enforcement, not the keyword. |
| "Just wrap the SDK; that's the port" | A port shaped like one provider has embedded that provider in the contract. The second implementation contorts to fit and the seam buys nothing. |
| "We'll rewrite the callers in one pass, it's cleaner" | A flag-day extraction is unreviewable and unrevertable. Route callers incrementally with both paths working. |
| "Leave the old path for now, nobody uses it" | Then the contract is optional. If both paths can write, the outcome is corrupted data, not just an untidy design. |
| "We extracted it, we can add the gate later" | The floor is cheapest and most accurate the day the extraction lands. Later, the metric has drifted and nobody knows the correct value. |
| "This module is coupled to everything, let's break it up" | If it is cohesive, splitting it makes it worse. Diagnose cohesion first, and check which kind of cohesion it is. |
| "Extracting this makes the design cleaner" | Cleanliness is not a payoff. Name the isolation, the swap, or the rule it fixes, or do not cut. |
| "We might want a plugin system someday, so let's add ports now" | A port with no plausible second implementation is premature abstraction. An option has value; a speculative contract you must maintain forever is a cost. |
| "The seam exists, so we may as well make it public" | Exposure is a separate commitment: it freezes internals, enlarges the attack surface, and creates compatibility obligations. Price it on its own evidence. |
| "Boundaries slow us down" | Un-partitioned work serializes its workers. The boundary is what lets two people, or two agents, proceed without meeting. |
| "AI can just refactor it later" | Regeneration works against a specified contract and fails without one. Without stated characteristics and evidence there is nothing to regenerate against. |

## Key Patterns

```
✅ Domain owns a Store contract expressed in domain terms; the Postgres adapter implements it; a shared contract suite runs against the adapter and the in-memory fake
❌ Domain calls the Postgres client directly from twelve call sites; "we could swap it if we had to"
```

```
✅ Port defined by what the consumer needs: save(order) / find(id); vendor errors translated at the adapter
❌ Port mirrors the vendor SDK: connect(), begin(), execCommand(), fetchRows(); vendor exceptions thrown through the interface
```

```
✅ Contract states its error taxonomy, idempotency under retry, and timeout behavior; the suite exercises each
❌ Contract states method signatures only; each implementation invents its own failure modes and callers couple to the first one
```

```
✅ Port's suite asserts observable behavior through the interface and passes against a second, independently-shaped implementation
❌ Port's tests reach past the interface to assert on internal call order; a correct rewrite turns the suite red
```

```
✅ Characterization tests pin current behavior first, then callers move through the new contract one at a time, system releasable throughout
❌ Six-week extraction branch, all callers rewritten at once, correctness argued from reading the diff
```

```
✅ Cutover criteria stated in advance; old path deleted once the last caller moves
❌ New contract added, old direct-access path left in place "for now"; both can write and neither is authoritative
```

```
✅ Extraction lands with an import-direction rule in CI that fails the build on a back-edge across the new seam
❌ Extraction lands with a code-review agreement not to reach across it
```

```
✅ High-coupling, high-cohesion module: contract designed, dependency inverted, module left whole behind it
❌ High-coupling, high-cohesion module: split into four fragments that now round-trip through each other
```

```
✅ High-coupling, low-cohesion grab-bag: decomposed by responsibility first, contracts introduced afterward where they earn it
❌ High-coupling, low-cohesion grab-bag: single interface added in front of it, reported as hardened
```

```
✅ Published event schema treated as a seam with additive-evolution and unknown-field rules
❌ Published event schema treated as a seam by adding a consumer-owned interface; the mechanism does not fit the boundary
```

```
✅ Proposal names its payoff: "isolates the ingest path so it can be built and tested without the query side"
❌ Proposal names no payoff: "improves modularity"
```

## Why This Matters

The cost of producing an implementation is falling faster than the cost of understanding a system. That changes what is worth investing in. A codebase where the load-bearing seams are explicit, deliberately shaped, and pinned by evidence is one where a given implementation can be replaced, by a person or by a model, without a whole-system investigation first. A codebase where they are implicit is one where every implementation is load-bearing, so nothing can be regenerated and the only path to change is reading everything.

The second consequence is throughput. Work that shares mutable state serializes its workers: two people, or two agents, cannot proceed without meeting, so adding capacity adds coordination instead of speed. Boundaries are one of the mechanisms that convert extra hands into parallel progress, alongside clear ownership and independent deployability, and their value rises with the number of concurrent workers.

The third is optionality. A hardened seam is also the surface an outside author could later extend, which is a real option even when it is never exercised, and one that is systematically under-counted because it does not show up in the current sprint.

Without this discipline, the codebase converges on mud: no boundary encodes the model, every change is global, no implementation can be swapped, and the system's theory exists only in the heads of the people who have read all of it. With it, the durable artifact accumulates while implementations churn underneath.

## Growth examples

Soft sketch, not a checklist; the right stage is shaped by the target's maturity.

- **POC / prototype:** one module, direct calls, no contracts. Correct at this stage. The signal to notice is which detail is already referenced from many places, because that is the first seam, and noticing it costs nothing now and a migration later.
- **Growing internal tool:** the first one or two contracts appear at the seams that actually hurt, typically where a volatile detail meets stable policy. Dependency inverted there, tests written through the contract rather than around it. Extractions are small enough that migration risk is low. No general ports program, and that restraint is correct.
- **Shared library:** the public surface is an explicit contract with a stated error taxonomy; internal implementations sit behind it and are replaceable without a consumer noticing. A behavioral suite defines the contract, and at minimum a second implementation proves it can be satisfied. Import-direction rules keep consumers off internals.
- **Production service:** load-bearing seams are identified deliberately rather than discovered by accident. Contracts state the operational characteristics callers depend on, not just signatures. Non-trivial extractions run as migrations: characterization tests, incremental caller movement, a named cutover, the old path deleted. Each extraction lands with its ratchet in the same change. Harden-vs-split diagnosis and the seam's form are explicit in proposals.
- **Safety-critical / ecosystem:** the contract is a versioned release artifact with its own compatibility suite; every implementation behind it runs that suite as a release gate; the characteristics that matter (timing, ordering, recovery) carry evidence appropriate to each rather than functional tests alone. Seam regressions fail the build rather than the review. High-stakes extractions run old and new in parallel with reconciliation before cutover. Boundaries are treated as the specification of record.

## References & rationales

- **David Parnas, "On the Criteria to Be Used in Decomposing Systems into Modules" (CACM, 1972).** Backs principles 1 and 4. Decomposition follows what a module hides and what is likely to change, which is the original statement of "cut where the volatility differs," and the basis for the red flags on concrete details leaking across layers.
- **Larry Constantine and Edward Yourdon, *Structured Design* (1979).** Backs principle 5. The original coupling and cohesion taxonomies, including the ranking of cohesion kinds that makes the harden-versus-split rule a starting heuristic rather than a decision procedure, and the source for the qualification that temporal cohesion is not functional cohesion.
- **Adam Tornhill, *Software Design X-Rays* (2018) and *Your Code as a Crime Scene* (2015).** Backs the change-coupling signal in principle 4 and its red flag. Version-control history reveals logical coupling that static structure hides, which is what makes "files that always change together but share no module" a detectable missing-boundary signal rather than an intuition.
- **Michael Feathers, *Working Effectively with Legacy Code* (2004).** Backs principles 4 and 6. The vocabulary of seams as places where behavior can be changed without editing in place, and characterization tests as the precondition for changing code whose behavior is not fully understood. Source for the red flag on extraction without characterization.
- **Martin Fowler, "Branch By Abstraction," "Strangler Fig Application," and "Parallel Run."** Back principle 6. The incremental-migration patterns that keep the system releasable during an extraction, and the comparison technique for seams where correctness is uncertain. Source for the red flags on flag-day extractions and long-lived extraction branches.
- **Sam Newman, *Monolith to Microservices* (2019).** Corroborates principle 6 from the data direction. Extraction patterns for seams with live callers and shared state, including the dual-write, backfill, and reconciliation sequence that makes splitting data ownership different in kind from routing code through a new contract.
- **Joshua Bloch, "How to Design a Good API and Why It Matters" (2006).** Backs principle 2. Minimality, naming at the consumer's level, not letting implementation details leak into signatures, and designing the contract against real usage before implementing it. Source for the red flags on vendor-shaped ports and leaked provider types.
- **Hyrum Wright, "Hyrum's Law," and Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google* (2020).** Back principles 1 and 2. With enough consumers, every observable behavior becomes something someone depends on regardless of what was promised, which is why unstated guarantees are real coupling and why contract design is the act of deciding which behaviors are promises.
- **Robert C. Martin, *Clean Architecture* (2017) and the Stable Dependencies / Stable Abstractions Principles.** Back principles 1, 5, and 9. Dependency inversion as the mechanism that makes an in-process implementation replaceable, and instability combined with abstractness (distance from the main sequence) as the ranking signal that separates a healthy shared kernel from a forming mud-ball.
- **Alistair Cockburn, "Hexagonal Architecture" (2005).** Backs principle 9 on the horizontal cut. Ports owned by the core with adapters outside it is the concrete shape of a swappable in-process implementation, and its scope is exactly the family of seams where a consumer can own the abstraction.
- **Vladimir Khorikov, *Unit Testing Principles, Practices, and Patterns* (2020).** Backs principle 3. Observable behavior versus implementation details, and resistance to refactoring as the property a test must have to be worth keeping. Source for the red flag on suites that fail against a correct reimplementation.
- **Martin Fowler, consumer-driven contract testing (and the Pact body of practice).** Backs principle 3. Contract suites owned by the boundary and run against every implementation, including fakes, are the operational form of a pinned seam and the basis for the red flag on drifting test doubles.
- **Carliss Baldwin and Kim Clark, *Design Rules: The Power of Modularity* (2000).** Backs principle 8. Modularity's value is largely option value: a boundary creates the option to substitute, to parallelize, and to open a surface later, which is real, routinely under-counted, and still not a payoff until exercised. Source for pricing the two returns independently.
- **Brian Foote and Joseph Yoder, "Big Ball of Mud" (1997).** Backs principles 7 and 10. Structure erodes by default under change pressure unless something actively maintains it, which is the argument for the ratchet and for hardening as a continuing practice rather than a one-time design phase.
- **Neal Ford, Rebecca Parsons, Patrick Kua, and Pramod Sadalage, *Building Evolutionary Architectures* (2nd ed., 2023).** Backs principle 7. Fitness functions as automated checks that keep architectural claims true under change; the ratchet is that pattern applied to a single seam at the moment of extraction. Deep-dive in [fitness-functions/README.md](../architecture/fitness-functions/README.md).
- **Peter Naur, "Programming as Theory Building" (1985).** Backs principle 10. The program text is secondary to the theory its builders hold, and a program whose theory is lost cannot be modified sensibly even with full source access. The further claim that boundaries are the most durable written trace of that theory is this skill's inference from Naur, not Naur's own argument, and is labeled as such in the principle.
- **Frederick Brooks, *The Mythical Man-Month* (1975).** Backs principle 8's cost side and part of "Why This Matters." Speculative indirection is accidental complexity by construction, and adding people to work that is not partitioned adds communication rather than throughput. Brooks grounds the partitioning claim; the specific application to parallel agent workers is this skill's extension.
- **Melvin Conway, "How Do Committees Invent?" (1968), and Matthew Skelton and Manuel Pais, *Team Topologies* (2019).** Back principle 9 on the vertical cut. Seams and worker boundaries mirror each other, so the slice is chosen to match the units of work intended to proceed independently.

## Suggested technologies (as of 2026-07-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools.

- **Seam detection:** module-graph and metric tools that expose instability, abstractness, and fan-in (`dependency-cruiser` for JS/TS, `import-linter` for Python, `cargo-modules` for Rust, `go-callvis` for Go); change-coupling analysis over version-control history (`code-maat` and successors) to surface files that change together without sharing a module.
- **Characterization and migration:** approval or snapshot testing libraries to pin existing behavior cheaply before an extraction; feature-flag infrastructure to route callers incrementally and to hold a cutover switch with a rollback path.
- **Enforcing the ratchet:** architecture tests (ArchUnit, `dependency-cruiser` rules, `import-linter` contracts, `archtest`) wired into CI at the moment an extraction lands; metric floors held in a checked-in baseline file so a regression fails the build rather than a review.
- **Pinning the contract:** language-native contract suites the port owns and every implementation runs, fakes included; consumer-driven contract tooling (Pact and equivalents) where the seam crosses a process boundary; property-based testing for ordering and idempotency claims; benchmark harnesses with committed budgets where performance is a contract member.
- **Dependency inversion:** language-native constructor injection and traits or interfaces are usually sufficient; reach for a reflective DI container only when wiring volume genuinely warrants it.
- **Schema seams:** schema registries with compatibility modes (backward, forward, full) for event and message contracts, since for those seams compatibility checking replaces the import rule as the enforcement mechanism.

## Continual improvement

This skill is maintained at:
https://github.com/syntropic137/software-leverage-points/blob/main/skills/boundary-hardening/SKILL.md

To improve it, edit the file directly and follow the chassis discipline in [`maintaining-software-leverage-points`](../../.claude/skills/maintaining-software-leverage-points/SKILL.md): regenerate catalogs, run `just qa`, then commit.
