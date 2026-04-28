---
name: software-leverage-review
description: Use when reviewing a plan document, PR diff, or codebase against multiple software leverage points in parallel; before implementation; during code review
---

# Software Leverage Review (Orchestrator)

## When to Use

- A plan document is drafted and needs review before implementation
- A PR diff needs cross-cutting review through every leverage-point skill
- A codebase audit is requested
- An autonomous agent has reached a "plan complete, ready to review" gate

## When NOT to Use

- Reviewing a single concern (invoke the software leverage point skill directly)
- Skill drift detection (use `skill-auditor` instead)

## Input

`target`: file path, directory, plan document, or git diff.
`software_leverage_point_subset` (optional): list of software leverage point names to fan out across. Default: all installed software leverage point skills (siblings of this skill that are NOT `skill-builder`, `skill-auditor`, or `software-leverage-review`).
`maturity_hint` (optional): one of `poc`, `prototype`, `growing`, `production`, `safety-critical`. When provided, overrides the maturity stage that would otherwise be inferred from the target's signals (see `## Calibrate severity to maturity` below). Use this when the caller knows the project's intent better than the visible signals reveal (for example, a prototype repo that is about to be promoted to production).

## Calibrate severity to maturity

Before applying any leverage point's red flags, sense the target's maturity stage from signals (size, age, deploy frequency, # contributors, public consumers, presence of CI, language toolchain, visible roadmap). Calibrate finding severity accordingly:

- **POC / prototype:** surface most findings as `info` ("plan to address as you scale"). Reserve `warn` and `error` for things that compound badly later (data shape lock-in, security holes that ship to users).
- **Growing internal tool:** `warn` for hygiene gaps, `error` for things that will hurt production migration.
- **Production service:** `warn` and `error` apply at the documented rigor.
- **Safety-critical:** every finding shifts up one severity from baseline.

The fan-out subagents inherit this calibration via the prompt; the synthesis pass re-applies it as a sanity check. If `maturity_hint` is supplied as input, it overrides the inferred stage.

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
- `references/dry.md` (consulted in synthesis)
- `references/principles-and-patterns.md` (consulted in synthesis)
- `references/software-complexity.md` (consulted in synthesis)
- `prompt_review-one-software-leverage-point.md` (subagent prompt)

## Continual improvement

This skill is maintained at:
https://github.com/syntropic137/software-leverage-points/blob/main/skills/software-leverage-review/SKILL.md

To improve it, edit the file directly and follow the chassis discipline in [`maintaining-software-leverage-points`](../../.claude/skills/maintaining-software-leverage-points/SKILL.md): regenerate catalogs, run `just qa`, then commit.
