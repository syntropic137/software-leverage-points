---
name: software-leverage-review
description: Use when reviewing a plan document, PR diff, or codebase against multiple software leverage points in parallel; before implementation; during code review
---

# Software Leverage Review (Orchestrator)

## When to Use

- A plan document is drafted and needs review before implementation
- A PR diff needs cross-cutting review through every leverage-point lens
- A codebase audit is requested
- An autonomous agent has reached a "plan complete, ready to review" gate

## When NOT to Use

- Reviewing a single concern (invoke the software leverage point skill directly)
- Skill drift detection (use `skill-auditor` instead)

## Input

`target`: file path, directory, plan document, or git diff.
`software_leverage_point_subset` (optional): list of software leverage point names to fan out across. Default: all installed software leverage point skills (siblings of this skill that are NOT `skill-builder`, `skill-auditor`, or `software-leverage-review`).

## Workflow

1. Resolve `software_leverage_point_subset`. List sibling skill directories under `../`. Filter to leverage points (exclude operator skills: `skill-builder`, `skill-auditor`, and this orchestrator). Note: `dry`, `principles-and-patterns`, and `software-complexity` are now valid LPs in the default fan-out (each has its own `SKILL.md`); the matching docs under `references/` are still consulted in step 4 as a separate synthesis pass, not skipped.
2. For each software leverage point in `software_leverage_point_subset`, dispatch a subagent using the prompt in `prompt_review-one-software-leverage-point.md`. Pass `SOFTWARE_LEVERAGE_POINT`, `TARGET_PATH`, and `OUTPUT_SCHEMA_PATH = output-schema.json` (the JSON Schema is the canonical contract; `output-schema.md` is the human-readable companion). Run dispatches in parallel.
3. Collect each subagent's JSON output.
4. Consult `references/dry.md`, `references/principles-and-patterns.md`, `references/software-complexity.md` (whichever are present in this skill's `references/` directory) and apply a synthesis pass: surface any cross-cutting findings the per software leverage point subagents missed.
5. Merge all findings into a single report.

## Output

```
{
  "target": "<TARGET_PATH>",
  "software_leverage_points_reviewed": ["testing", "documentation", ...],
  "findings": [<all findings, sorted by severity then file>],
  "lens_synthesis": [<cross-cutting findings>],
  "summary": "<top-level summary>"
}
```

## References

- `output-schema.json` (canonical contract; required reading for all subagents)
- `output-schema.md` (human-readable companion to the JSON schema)
- `references/dry.md` (lens, consulted in synthesis)
- `references/principles-and-patterns.md` (lens, consulted in synthesis)
- `references/software-complexity.md` (lens, consulted in synthesis)
- `prompt_review-one-software-leverage-point.md` (subagent prompt)
