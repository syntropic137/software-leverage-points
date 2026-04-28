---
name: documentation
description: Use when reviewing documentation concerns: README presence and quality, public API documentation, ADR coverage for non-obvious decisions, inline rationale comments, TBD/placeholder hygiene in shipped docs
---

# Documentation

## Overview

Documentation is the artifact that lets new contributors (human or agent) join a codebase without reverse-engineering intent. It is also the only place architectural decisions survive once their authors leave. Without it, every onboarding becomes archaeology and every non-obvious choice gets relitigated.

**Core principle:** Documentation is a contract surface. The README, the public-API docs, and the ADRs together encode "what this is supposed to do and why we chose it this way."

## Core Principles

### 1. README explains purpose, install, usage

The README is the project's entry point. It must answer three questions in order: what is this, how do I install it, how do I use it. Without these three, a new contributor (or autonomous agent) has to reverse-engineer intent from code and tests.

The Diataxis framing names four documentation modes: tutorials, how-to, reference, explanation. The README is "explanation" plus a tutorial seed.

### 2. Public APIs are the contract; document them (scope: contract surfaces only)

The public API surface IS the contract. Undocumented APIs become tribal knowledge. This principle applies to the contract surface only: private internals do not require external docs, though they may benefit from inline rationale comments.

A library, service, or module without documented entry points is not a platform; it is a private artifact someone published by accident.

### 3. ADRs capture non-obvious decisions

Decisions made informally evaporate. The next person sees only the result and cannot tell deliberate from accidental. Architecture Decision Records capture context, decision, and consequences at the moment of choice.

**Multiple valid layouts exist:** `docs/adr/`, `docs/architecture/decisions/`, `docs/decisions/`. Multiple valid templates exist: Nygard, MADR, custom. The principle is: pick one location and one template and stay consistent within the project. The red flag is "no stated convention," not "did not pick MADR."

### 4. No TBD or placeholder text in shipped docs

TBD is a debt marker that ages poorly. Placeholder text in shipped docs signals either incomplete thought or abandoned intent. Either resolve the placeholder or remove the section.

## Red Flags - STOP

- README missing one of: purpose, install instructions, usage example
- Public API surface with no doc strings, no examples, or no reference page
- Architectural decision made (database swap, framework change, new service boundary) with no ADR and no rationale comment in the diff
- TBD, TODO, XXX, or placeholder text in shipped documentation
- ADRs scattered across multiple locations with no stated convention
- Doc strings that restate the function name instead of explaining intent or contract
- Inline comments that describe what the code does (the code already says that) rather than why it does it

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The code is self-documenting" | Code documents the what, not the why; rationale only lives in prose |
| "We'll write the README later" | Later doesn't come; the next contributor pays the cost first |
| "ADRs are bureaucracy" | ADRs are receipts for decisions; without them, the same decision gets relitigated |
| "TBD is fine, we'll fix it before release" | TBD ships; release pressure ensures it |
| "Internal APIs don't need docs" | They do once a second consumer appears, which is always sooner than expected |
| "The wiki has it" | Wikis decay faster than READMEs; co-locate with the code |

## Key Patterns

```
✅ README: # Project / What it is / Install / Usage / Link to docs/
❌ README: # Project / (one paragraph from the original PR description, two years stale)
```

```
✅ Public function has docstring: contract, parameters, return, raises, example
❌ Public function has docstring: "Does the thing." (restates the name)
```

```
✅ Database swap → new ADR docs/adr/0042-postgres-to-cockroach.md (context, decision, consequences)
❌ Database swap → diff only; rationale lives in a Slack thread that will expire
```

```
✅ // Why: vendor API rate-limits at 10rps; batch to stay under
❌ // Iterate over items and call the API for each
```

```
✅ Single ADR convention: docs/adr/NNNN-kebab-case.md, Nygard template
❌ Half the ADRs in docs/adr/, half in docs/decisions/, half in Confluence
```

## Why This Matters

Documentation is the artifact that survives turnover. Every other artifact (code, tests, infrastructure) describes the current state; documentation describes the intent. When the team changes, the intent is the part that walks out the door first unless it was written down.

Without real documentation:

- Onboarding stalls; new contributors reverse-engineer intent from code.
- Decisions get relitigated because no one remembers why they were made.
- Public APIs become guess-and-check, which leaks abstractions and breaks consumers.
- Placeholder text accumulates; trust in the docs erodes; people stop reading them.

With real documentation:

- New contributors are productive in days, not months.
- Decisions stay decided; ADRs are the receipts.
- The contract surface is legible; consumers integrate without source diving.
- Docs are trusted because they are kept current.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** a one-paragraph README stating purpose and how to run it. No ADRs yet; decisions are still fluid. Public API docs are not yet relevant because there are no external consumers.
- **Growing internal tool:** README expands to purpose, install, usage, and a "how it works" sketch. First ADRs appear for the choices that already feel load-bearing (storage, framework, deployment target). Public functions used by another module gain docstrings.
- **Shared library:** full reference documentation generated from source; usage examples live alongside the reference. ADR directory is established with a stated convention. Every public function has a docstring stating contract, parameters, and example. README links to a "decisions" index.
- **Production service:** runbook lives next to the code. ADRs cover every load-bearing decision. Onboarding doc walks a new engineer from clone to first PR. Documentation is reviewed in PRs, not as a separate task. Stale docs are flagged as findings.
- **Safety-critical:** documentation is part of the release artifact and is reviewed by a second pair of eyes. Every change to a documented contract requires a doc-and-ADR update in the same PR. Regulatory documentation (audit trails, change logs) is generated from the same source of truth.

## References & rationales

- **Daniele Procida, Diataxis framework.** Backs principle 1 (README as explanation) and the broader four-mode taxonomy of tutorials, how-to, reference, explanation.
- **Steve Yegge, "platforms over products" memo (2011).** Backs principle 2 (public APIs are the contract). Argues that an undocumented API is not a platform; it is a private artifact.
- **Michael Nygard, "Documenting Architecture Decisions" (2011).** Backs principle 3 (ADRs for non-obvious decisions). The canonical ADR template (context / decision / consequences) and the case for capturing rationale at the moment of choice.
- **John Ousterhout, *A Philosophy of Software Design* (2018), chapter 12.** Backs principle 4 (no TBD in shipped docs) and the inline-comment-as-rationale discipline. Comments should explain what the code cannot say for itself, namely the why.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **Static site generators for docs:** MkDocs (with Material theme), Sphinx, Docusaurus, Astro Starlight, mdBook.
- **API reference generation:** Sphinx autodoc (Python), TypeDoc (TS), rustdoc (Rust), godoc (Go), JSDoc (JS).
- **ADR tooling:** `adr-tools` (Nygard's CLI), `log4brains`, MADR template, plain markdown in `docs/adr/`.
- **Internal developer portals:** Backstage TechDocs for organizations with many services; overkill for single repos.
- **Doc linting:** Vale for prose style; markdownlint for structure; broken-link checkers (`lychee`, `markdown-link-check`).
- **Diagrams as code:** Mermaid (rendered by GitHub natively), PlantUML, D2, Excalidraw with embed.
