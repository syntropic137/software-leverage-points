---
name: documentation
description: Use when reviewing documentation concerns (README presence, API docs, inline comments rationale, ADRs) in a codebase, plan, or PR diff
---

# Documentation Leverage Point

## When to Use

- A planning or PR-review agent is checking documentation concerns
- The orchestrator fans out a subagent for documentation
- A user explicitly asks for a docs-focused review

## Input

`target`: a file path, directory, plan document, or git diff.

## Workflow

1. Read the `target`.
2. Apply checks:
   - Does a top-level README exist and explain purpose, install, usage?
   - Are public APIs documented?
   - Do non-obvious decisions have ADRs or rationale comments?
   - Are TODO/TBD markers present in shipped docs?
3. Emit findings using the schema at `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"documentation"`.

## Red Flags

- TBD or placeholder text in shipped docs
- README missing install instructions
- Public API surface with no doc strings or examples
