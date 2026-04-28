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

## References & rationales

The "why" behind the checks above:

- **README explains purpose, install, usage:** the README is the project's entry point. Without these three, a new contributor or autonomous agent has to reverse-engineer intent. Cite: Daniele Procida's "Diátaxis" framework (tutorials/how-to/reference/explanation as four documentation modes); your README is "explanation".
- **Public APIs documented:** the API surface IS the contract. Undocumented APIs become tribal knowledge. Cite: Steve Yegge's "platforms over products" memo (an undocumented API is not a platform).
- **ADRs for non-obvious decisions:** decisions made informally evaporate. The next person (or agent) sees only the result and can't tell what was deliberate vs accidental. Cite: Michael Nygard, *Documenting Architecture Decisions* (2011); ADR templates from `joelparkerhenderson/architecture-decision-record`.
- **TBD or placeholder text in shipped docs:** TBD is a debt marker that ages poorly. Either resolve or remove. Cite: code-as-documentation discipline (Ousterhout, *A Philosophy of Software Design*, chapter 12).

Each red flag is a finding with concrete remediation: name the section to add, point at an ADR template, link the convention.
