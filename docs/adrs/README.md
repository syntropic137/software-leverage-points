# Architecture Decision Records

Decisions that shape this plugin's structure, conventions, and constraints. Each ADR captures the context behind a decision so future contributors can understand *why* something is the way it is, not just *what* it is.

## Format

We use a lightweight MADR-style template: Status, Context, Decision, Consequences. Each ADR is dated and numbered sequentially. Status values: `proposed`, `accepted`, `superseded by ADR-NNNN`, `deprecated`.

## Index

| Number | Title | Status | Date |
|---|---|---|---|
| [ADR-0001](ADR-0001-three-layer-skill-pattern.md) | Three-layer skill pattern: generic meta-skill, repo-specific skill, parallel-fan-out orchestrator | Accepted | 2026-04-28 |

## When to write a new ADR

Add an ADR when a decision:

1. Constrains future work (e.g. "L2 SKILL.md files do not emit severity").
2. Picks one of multiple reasonable options (e.g. "L1 backlink uses namespaced skill invocation, not absolute path or `${CLAUDE_PLUGIN_ROOT}`").
3. Has consequences that won't be obvious from the code alone.

Trivial decisions (file naming, formatting choice with no downstream impact) do not need ADRs.
