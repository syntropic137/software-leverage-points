---
name: extensibility
description: "Use when reviewing extensibility concerns: whether a seam should be exposed to people who are not its authors at all, stable plug points and ports, event/hook contracts treated as public APIs, compatibility and deprecation policy across host releases, trust tiers and isolation of extension code (in-process, sandboxed, out-of-process, remote), failure containment when an extension crashes or hangs, the extension author's experience (manifest, SDK, reference implementation, conformance suite, distribution and signing), and third-party/plugin/marketplace surface. Do NOT use for internal module boundaries or dependency direction (that is architecture), for the act of extracting and pinning a seam in the first place (that is boundary-hardening), or for code-level SOLID/DI mechanics in general (that is principles-and-patterns); this skill starts at the decision to make a seam public."
---

# Extensibility

## Overview

This skill reviews the surface a system offers to people who are not its authors: whether that surface should exist, what it promises, how it evolves, what happens when the code behind it misbehaves, and whether an outsider can actually build against it. It is the skill that asks *"is this a platform, and does it meet a platform's obligations?"*

**Core principle:** a hardened seam creates the **option** to be extended; exercising that option is a separate decision with its own obligations. Publishing a plug point commits you to a compatibility policy, a trust model, a failure-containment story, and an author experience, for as long as anyone depends on it. Design the surface deliberately and meet those obligations, or leave the seam internal.

Cross-reference: the [`boundary-hardening`](../boundary-hardening/SKILL.md) skill carries the act of finding, designing, extracting, and pinning the seam in the first place, and the [`architecture`](../architecture/SKILL.md) skill carries the structural rules the seam sits inside. This skill starts where they end: at the decision to make the seam public.

## Core Principles

### 1. Exposure is a decision with its own evidence, not a byproduct of having a seam

A clean internal boundary and a public extension point look alike in the code and differ completely in what they cost. Publishing freezes the internals behind the contract against change, enlarges the surface to include code you did not write, and creates compatibility obligations that outlast the team's interest in them.

So the review question is not "is there a seam here" but "**should this one be public, and is there evidence for it**": a named class of extension author, at least one concrete extension somebody wants that the current surface cannot express, and a team willing to own the compatibility and support obligations that follow.

The corollary is that the internal and external payoffs of a boundary are priced **independently**. Many excellent internal boundaries should never be exposed. Option value is real and routinely under-counted, which is why a marginal internal case can still be worth funding when exposure is genuinely planned, but the option is not itself a payoff, and a contract maintained for an exposure that never comes is a cost with no return. The [`boundary-hardening`](../boundary-hardening/SKILL.md) skill carries the internal side of that pricing.

### 2. Extension is proven by authoring independence

A plug point is an explicit contract: named, documented, versioned. Whether it actually works is proven by evidence, and the evidence forms a ladder, each rung proving strictly more than the one below:

1. **A fake or test double** proves the wiring is injectable. It proves nothing about extensibility, because the author of the contract shaped it and it reproduces the contract's own blind spots.
2. **A second in-house implementation** proves substitutability: the abstraction is not welded to the first implementation.
3. **A clean-room extension**, built only from published artifacts by someone without access to the internals, proves the contract is *usable by an outsider*. This is the first rung that proves extensibility as such.
4. **A deployed third-party extension in real use** proves the surface is operationally viable, including its versioning, distribution, and support paths.

Claiming a surface is extensible on the strength of rung 1 or 2 is the most common error in this area, because those rungs are cheap and feel like proof. A private-knowledge dependency (an undocumented initialization order, an internal type that happens to be importable) is invisible from inside and fatal from outside. Principle 7 covers what a host must supply to make rung 3 reachable; this principle is the claim about what counts as proof.

Cross-reference: the [`principles-and-patterns`](../principles-and-patterns/SKILL.md) skill carries the dependency-inversion and injection mechanics that make an implementation substitutable at all; those mechanics are necessary and nowhere near sufficient, because substitutability by the author is a lower rung than usability by a stranger.

### 3. The extension mechanism is chosen per surface, and stated

Several mechanisms exist, and they are genuinely different in kind rather than points on one scale: configuration, declarative manifests, webhooks and remote integrations, event or hook SDKs, and sandboxed code execution (the bar at which users build things the authors never imagined). They vary along separate axes, including expressiveness, where the code runs, who is trusted, and how it is distributed, so comparing them as "more" or "less" extensible produces false choices.

The rule is that **each surface has a deliberate, stated mechanism** suited to its audience and risk, not that the product picks one. A single product may legitimately expose configuration for presentation, webhooks for integrations, and sandboxed code for computation. What is defective is an unstated choice, an incoherent mix *within* one surface, or a mechanism arrived at by accident because a hook happened to be convenient. A common form of the accidental case is configuration sprawl: a hundred flags accumulate because behaviors that should have been contributed were shipped instead, which is the signature of a surface whose mechanism was never chosen.

### 4. A published contract is a commitment, and compatibility is the central obligation

A contract a third party consumes is a public interface: stable shape, documented payload, defined error semantics, and a stated policy for change. An undocumented, unversioned event stream is not an extension surface; it is a leak someone will couple to.

The obligations attach whether or not they were intended. With enough consumers, every observable property becomes something someone depends on, including ones never promised: field ordering, timing, incidental fields, error text. Publishing means deciding **which properties are promises**, because the ones you do not decide will be decided for you by whoever ships first.

The hard part is not shipping v1; it is shipping v7 while v1 extensions still run. A mature surface has answers to:

- **What the version boundary is:** which host versions an extension declares support for, and which extension API versions a host accepts.
- **How change is classified:** which changes are additive and safe and which are breaking, and where that line sits for each artifact (adding an optional field, adding an enum value, tightening validation, changing an error type).
- **How unknown data is handled:** whether an extension must tolerate unknown fields and events, which is what makes additive evolution possible at all.
- **How capability differences are negotiated,** so an extension can detect what a given host supports rather than assuming.
- **What the deprecation path is:** an announced window, a migration path, and usage telemetry, because a deprecation with no usage data is a guess about who you are about to break.
- **How compatibility is verified:** a conformance suite run across supported host versions rather than a promise in a release note.
- **What happens to extension-owned state** across upgrades and rollbacks. Data written by a v1 extension outlives the code that wrote it, so the surface needs backward compatibility for reading old data and forward compatibility for data written by a newer peer during a staged rollout.

A surface that treats "we use semantic versioning" as the whole answer has stated an intention, not a policy.

Cross-reference: the [`boundary-hardening`](../boundary-hardening/SKILL.md) skill carries contract design in general (error taxonomy, operational semantics, consumer-level abstraction); this principle is the narrower claim that publishing converts those design choices into commitments you cannot unilaterally revise.

### 5. Isolation is chosen by trust tier and execution model

Extension code is code you did not write, so the surface is a trust boundary. But "sandbox it" is not a universal rule, and applying it as one produces false findings: a first-party in-process module, a signed partner plugin, an untrusted marketplace upload, and a remote webhook integration are different problems.

The review requires a **stated trust tier per surface, with controls that match it**:

- **In-process, first-party or trusted:** ordinary native in-process loading gives the extension the host's ambient authority, so the effective controls are review, provenance, and blast-radius limits rather than isolation.
- **In-process, untrusted:** requires a real isolation mechanism, meaning a runtime that actually confines the code (a managed sandbox or interpreter with no ambient host access). A capability-scoped host interface is necessary but not sufficient on its own: it narrows what a *cooperative* extension can reach through the API, while arbitrary native code in the same process can bypass the API entirely.
- **Out-of-process, local:** isolation comes from the process boundary; the controls are the interface surface, resource limits, and what the host hands across.
- **Remote (webhooks, API integrations):** the threats are authentication, replay, delivery semantics, quotas, and tenant isolation, and a local code sandbox is irrelevant.

The invariant across tiers is **least privilege**: authority is granted explicitly and narrowly rather than held ambiently. The defect is a surface whose trust tier is unstated, or whose controls do not match the tier it claims.

Distribution is part of the same trust story once extensions are shipped by others: packaging with a verifiable identity, signing and provenance so a host can tell what it is loading and who produced it, an admission decision before code reaches a trusted surface, and a revocation path for when a published extension turns out to be malicious or broken.

Cross-reference: the [`security`](../security/SKILL.md) skill carries threat modeling, authorization boundaries, and the agentic tool-call attack surface in depth; this principle is the narrower claim that publishing an extension point creates a new trust boundary whose tier must be stated and whose controls must match it.

### 6. Extensions are a failure domain, and the host owns containment

Once someone else's code runs in a request path, the host's availability is partly controlled by code its authors have never seen. A surface that specifies only the payload shape has published an API and left its own reliability undefined.

What the contract must answer: whether a hook runs synchronously or asynchronously, and whether ordering among registered extensions is defined or arbitrary; what timeout applies and whether cancellation is honored; whether delivery is at-least-once, and therefore whether handlers must be idempotent; what happens when one extension of many fails, and whether the host continues, retries, or aborts; when a misbehaving extension is quarantined or circuit-broken; how back-pressure is applied when extensions cannot keep up; and how an operator disables an extension at runtime, without shipping a release, when it starts causing damage.

Per-extension observability is what makes this operable: without attribution, an extension-caused latency regression looks like a host defect, and the platform team debugs its own code for a week.

### 7. The author's experience is the surface

An extension point that is technically correct and practically unusable produces no extensions. From the author's side the surface includes discovery and registration, an identity and manifest, generated types or an SDK, a reference implementation to copy, a way to run and debug against a host locally, a conformance suite that tells them whether they got it right before shipping, and error diagnostics that name the actual problem.

Principle 2 sets the standard of proof; this principle is about what the host must supply for anyone to meet it. The concrete review question: **could a competent outsider build a working extension using only the published artifacts?** If the answer depends on reading the host's source or asking the team, the surface is not published yet, whatever the interface files say.

## Red Flags - STOP

- A seam exposed publicly with no named class of extension author and no concrete extension anyone wants; the surface exists because the boundary did
- The compatibility and support obligations of a public surface are unowned; nobody has agreed to keep it working for the extensions that exist
- Adding a behavior requires forking the project or editing core files, in a system whose stated purpose includes third-party extension
- A surface called extensible where the only implementations are in-house and written by the contract's author; no clean-room extension has been built from the published artifacts alone
- Building an extension requires reading host source, copying an undocumented initialization order, or importing an internal type
- No stated extension mechanism for a surface, or mechanisms mixed incoherently within one surface
- Configuration sprawl standing in for a chosen mechanism: a hundred flags where a plug point would do, because behaviors were shipped that should have been contributed
- Events fire with undocumented, unversioned payloads; consumers reverse-engineer the shape and break silently on upgrade
- No stated policy for which changes are breaking, so additive and breaking changes ship through the same process
- Extensions are not required to tolerate unknown fields or events, which makes every additive change a breaking change
- No host-version or API-version declaration, so incompatibility is discovered at runtime by failing
- Deprecation announced with no migration path, no support window, or no usage data showing who still depends on the old contract
- Compatibility verified against one host version only; no conformance suite run across supported releases
- Extension-owned state has no story for being read by a newer host or written by a newer peer during a staged rollout
- A surface with an unstated trust tier, or controls that do not match the tier it claims (untrusted in-process code with ambient host authority, or a remote integration whose review discusses sandboxing while ignoring authentication and replay)
- Extension code granted broad ambient authority rather than explicitly scoped capabilities and resource limits
- A capability-scoped API presented as isolation for arbitrary native in-process code that can bypass it
- Third-party extensions loaded with no verifiable identity, no signature or provenance, and no way to revoke one after publication
- Someone else's code in a request path with no timeout, no failure policy, and no circuit breaking, so one slow extension degrades the host
- Hook ordering and sync-versus-async execution undefined where multiple extensions can register
- At-least-once delivery with no idempotency requirement stated for handlers
- No per-extension observability, so an extension-caused regression is indistinguishable from a host defect
- No way to disable a misbehaving extension without shipping a release
- Ports and interfaces introduced for a single implementation with no plausible second one, justified as future extensibility

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The seam is already clean, publishing it is free." | Publishing freezes the internals, enlarges the trust surface, and creates support obligations that outlive the team's interest. It is a new commitment, not reuse of an old one. |
| "We'll add plugin support later." | Some of it retrofits incrementally; the compatibility policy, trust model, and author experience do not appear by themselves, and each extension shipped before them becomes a constraint. |
| "It's internal-only, extensibility doesn't matter." | Correct, and that is a reason to keep the seam internal, not a reason to skip the question. Price the internal payoff on its own. |
| "Config flags make it extensible." | Config selects among behaviors you already shipped; extensibility is behaviors you did not ship. A hundred flags is usually a mechanism nobody chose. |
| "We have interfaces everywhere, so it's extensible." | An interface with one caller and one implementation is indirection. Extensibility is proven by an outsider building against the published artifacts. |
| "Our test double proves the seam works." | A fake written by the contract's author reproduces the contract's blind spots. It proves injectability, not that a stranger can implement it. |
| "We use semantic versioning." | That is a numbering scheme. The policy is which changes are breaking, how unknown data is handled, what the support window is, and how compatibility is verified. |
| "Events are enough." | An undocumented, unversioned event stream is a leak, not an API. Consumers couple to its accidents and break on your next refactor. |
| "We'll deprecate it and give people six months." | Six months for whom? Without usage telemetry a deprecation window is a guess about who you are about to break. |
| "A plugin can just call whatever it needs." | Then the plug point grants ambient authority. Scope capabilities explicitly and match controls to the trust tier. |
| "We sandbox everything, so we're safe." | Sandboxing is the right control for untrusted in-process code and irrelevant for a webhook integration, which needs authentication, replay protection, and quotas. State the tier first. |
| "The capability API means extensions can only touch what we allow." | That holds for cooperative code calling the API. Arbitrary native code in your process can ignore the API entirely. |
| "If an extension breaks, that's the author's problem." | It is your availability. Someone else's code in a request path without timeouts, failure policy, and circuit breaking makes third parties co-owners of your uptime. |
| "The API docs are complete, the surface is done." | If building an extension still requires reading host source or asking the team, it is not published. Test that claim with a clean-room build. |

## Key Patterns

```
✅ Exposure justified by a named author class and a concrete extension the current surface cannot express; compatibility owner named
❌ Surface published because a clean internal boundary already existed
```

```
✅ A clean-room extension built from published artifacts alone proves the contract is usable by an outsider
❌ "It's extensible": two in-house implementations, both written by the contract's author
```

```
✅ Extension declares supported host API versions; host validates and refuses incompatible extensions with a diagnosable error
❌ Extension loads against any host version; incompatibility surfaces as a runtime crash in a customer's environment
```

```
✅ Additive change adds an optional field; extensions are required to ignore unknown fields; conformance suite runs across supported host versions
❌ Every added field is a breaking change because nothing specifies how unknown data is handled
```

```
✅ Deprecation ships with a migration guide, a stated window, and telemetry showing remaining usage
❌ Deprecation ships as a note in the changelog
```

```
✅ Trust tier stated per surface: partner plugins signed, provenance-checked, and revocable; marketplace code run in a confining runtime with scoped capabilities and resource limits
❌ One "extensions are sandboxed" claim covering in-process modules, marketplace uploads, and webhooks alike
```

```
✅ Hooks run with a timeout and a stated failure policy; a repeatedly failing extension is circuit-broken, attributed in telemetry, and disableable at runtime
❌ Hooks run inline, unbounded; one slow extension degrades every request and looks like a host defect
```

```
✅ Typed payload, reference implementation in the repo, local test host, conformance suite the author runs before publishing
❌ emit("thing", data) with untyped data, no docs, and authors reading host source to guess the shape
```

## Why This Matters

An extension surface can change what a system becomes: the value created can exceed what its authors could build alone. Third-party extension is one route to that, not the only one, since platforms also create value through APIs, distribution, data, and multi-sided coordination without ever running someone else's code. What the surface reliably buys is that contributions you did not have to build become possible, which is why it is a strategic asset and not only a technical structure.

It is also a set of standing liabilities. A published contract constrains the internals behind it for as long as anyone depends on it; someone else's code in a request path makes strangers co-owners of your availability; and an extension surface with no trust model is a boundary you have declined to design. These costs land on a different team, in a later quarter, than the one that shipped the surface.

The failure modes are therefore symmetrical, and this skill guards both. Under-investing caps the ceiling: work that could have been contributed is work you must build, and the seam that would have supported an ecosystem stays private. Over-exposing freezes a young system's internals against the changes it still needs, and buys compatibility obligations with capacity that was meant for the product. The discipline is to expose deliberately, then meet the obligations that exposure creates.

## Growth examples

Soft sketch, not a checklist; the right stage is shaped by the target's maturity.

- **POC / prototype:** one implementation, no plug points, and that is correct. The signal worth noticing is that the first boundary hardened for internal reasons is a candidate surface later; recognizing it costs nothing and commits to nothing.
- **Growing internal tool:** ports exist where a second implementation is genuinely plausible. Still no public surface. If a second team starts consuming a hook, that is the moment the compatibility question becomes real, well before a marketplace exists.
- **Shared library:** the public surface is documented and versioned; what counts as a breaking change is stated; a second implementation exists; deprecation has a stated window and a migration path. Extension happens by contract rather than by patching.
- **Production platform:** a stated mechanism per surface with a stated trust tier and matching controls; a conformance suite the author can run; compatibility verified across supported host versions; timeouts, failure policy, runtime disablement, and per-extension observability for anything in a request path; at least one external extension in real use; deprecation backed by usage telemetry.
- **Safety-critical / ecosystem:** extensions are capability-scoped and resource-limited by default and cannot exceed their blast radius; the contract is a versioned release artifact with its own compatibility suite; third-party code is signed, provenance-checked, admitted by policy, and revocable; extension-owned state has forward and backward compatibility across staged rollouts; admission and revocation are operated, not just documented.

## References & rationales

- **Carliss Baldwin and Kim Clark, *Design Rules: The Power of Modularity* (2000).** Backs principle 1 and the strategic framing in "Why This Matters." Modularity creates option value, including the option to open a surface to outside contributors, and the analysis of why that option is valuable, under-counted, and separately costly to exercise is the basis for pricing exposure on its own evidence.
- **Joshua Bloch, "How to Design a Good API and Why It Matters" (2006).** Backs principles 2, 4, and 7. Public APIs are permanent commitments, should be designed against real usage before implementation, and are validated by having someone else write code against them. Source for the clean-room test and for the red flags on surfaces that cannot be built against without private knowledge.
- **Hyrum Wright, "Hyrum's Law," and Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google* (2020).** Back principle 4. With enough consumers every observable behavior becomes a dependency regardless of what was promised, and the deprecation chapters supply the obligations this skill requires: classified change types, migration paths, usage telemetry before removal, and testing across versions. Source for the red flags on unversioned payloads, unclassified changes, and evidence-free deprecation.
- **Martin Kleppmann, *Designing Data-Intensive Applications* (2017), chapter 4.** Backs the data-lifecycle half of principle 4. Backward and forward compatibility as distinct obligations, and tolerant readers that ignore unknown fields, which is exactly the situation of extension-owned state read by a newer host or written by a newer peer during a staged rollout. Source for the red flags on unknown-field handling and extension state across upgrades.
- **Martin Fowler, "Plugin" and "Inversion of Control / Dependency Injection" patterns, and consumer-driven contract testing (with the Pact body of practice).** Back principles 2 and 4. The plug-point mechanics that make an implementation substitutable, and contract suites as the mechanical check that a published payload has not drifted from what consumers rely on.
- **Robert C. Martin, Dependency Inversion Principle and Stable Abstractions Principle.** Back principle 4. An abstraction should be as stable as it is depended upon, which is precisely the obligation publishing creates and the reason a public plug point constrains the internals behind it.
- **Alan Kay, "Design Principles Behind Smalltalk" (BYTE, August 1981).** Backs principle 3. Late binding and extension by the user rather than the author, argued as a design goal with explicit costs, which grounds the claim that the extension mechanism is a deliberate design choice rather than a default, and that a surface which never chose one has chosen by accident.
- **Jerome Saltzer and Michael Schroeder, "The Protection of Information in Computer Systems" (1975), and Mark Miller, *Robust Composition* (2006).** Back principle 5. Least privilege as the invariant across trust tiers, and object-capability security as the model in which authority is granted explicitly rather than held ambiently. Miller's treatment of cooperative versus adversarial code is also the basis for the red flag distinguishing a capability-scoped API from actual isolation.
- **The SLSA supply-chain framework and the Sigstore project.** Back the distribution half of principle 5. Verifiable build provenance, artifact signing, and the identity and revocation machinery a host needs to decide what it is loading and from whom. Source for the red flag on unsigned, unattributable, unrevocable third-party extensions.
- **Michael Nygard, *Release It!* (2nd ed., 2018).** Backs principle 6. Timeouts, circuit breakers, bulkheads, and back-pressure as the containment patterns for integration points you do not control, which is exactly what a third-party extension is. Source for the red flags on unbounded hooks and missing failure policy.
- **Pete Hodgson, "Feature Toggles (aka Feature Flags)" (martinfowler.com, 2017).** Backs the runtime-disablement requirement in principle 6. The ops-toggle and kill-switch category exists precisely so that a component causing damage in production can be turned off on a timescale shorter than a release, which is the obligation a host takes on when it runs code it did not write.
- **Gregor Hohpe and Bobby Woolf, *Enterprise Integration Patterns* (2003).** Backs the delivery-semantics half of principle 6. Vocabulary for message ordering, resequencing, idempotent receivers, and guaranteed delivery, which is what makes hook ordering, sync-versus-async dispatch, and at-least-once handling contract members rather than implementation accidents.
- **Sam Newman, *Building Microservices* (2nd ed., 2021).** Corroborates principles 4 and 6 from the remote-integration direction. Schema evolution, tolerant readers, and delivery semantics for surfaces where the extension runs elsewhere and the local sandbox question does not arise.

## Suggested technologies (as of 2026-07-28)

Illustrative of the current landscape, not prescriptive; the principles above outlive any of these.

- **DI seams:** language-native ports (traits or interfaces plus constructor injection) are usually enough; reach for a reflective DI framework only when the wiring genuinely warrants it.
- **Untrusted in-process extension code:** WASM component sandboxes or embedded interpreters that confine the guest; capability-based host interfaces so a cooperative extension reaches only what it was handed; CPU, memory, and wall-clock limits as defaults rather than options.
- **In-process extension contracts:** typed event buses and hook registries; schema'd payloads (JSON Schema, Protobuf, Avro) so the contract is machine-checkable rather than documented in prose.
- **Compatibility discipline:** schema registries with enforced compatibility modes; contract tests that fail when a payload shape drifts; a conformance suite published for extension authors and run in the host's CI across supported versions.
- **Remote extension surfaces:** signed webhook delivery with replay protection, per-tenant quotas, and explicit retry and idempotency semantics.
- **Distribution and provenance:** artifact signing and provenance attestation (Sigstore and the SLSA levels) for published extensions, with a revocation path; admission review before an extension reaches a trusted surface.
- **Operability:** per-extension tracing and metrics attribution, and a runtime kill switch that does not require a host deploy.

## Continual improvement

This skill is maintained at:
https://github.com/syntropic137/software-leverage-points/blob/main/skills/extensibility/SKILL.md

To improve it, edit the file directly and follow the chassis discipline in [`maintaining-software-leverage-points`](../../.claude/skills/maintaining-software-leverage-points/SKILL.md): regenerate catalogs, run `just qa`, then commit.
