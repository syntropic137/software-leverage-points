---
name: skill-builder
description: Use when bootstrapping leverage-point skills in a target repo, or when the user asks to "create skills" or "set up leverage skills" in a project
---

# Skill Builder (templated mode, POC)

## When to Use

- The user wants to bootstrap repo-specific (L2) leverage-point skills in a target repo
- An automation step needs to instantiate L1 meta-skills as L2 repo skills

## When NOT to Use

- For greenfield (one-off) skill creation (deferred to post-POC)
- For drift detection on an existing L2 skill (use `skill-auditor`)

## Input

- `target_repo`: absolute path to the repo to install L2 skills into
- `software_leverage_point_subset` (optional): list of software leverage point names. Default: all sibling skills that are leverage points (exclude `software-leverage-review`, `skill-builder`, `skill-auditor`).

## Workflow

1. Resolve `software_leverage_point_subset` by listing sibling skill directories under `../` and filtering out operator skills.
2. For each software leverage point, compute:
   - `L1_SKILL_PATH` = `<this skill's parent>/<software-leverage-point>/SKILL.md`
   - `OUTPUT_PATH` = `<target_repo>/.claude/skills/<software-leverage-point>/SKILL.md`
3. For each software leverage point, dispatch a subagent using `prompt_template-one-skill.md`. Run dispatches in parallel.
4. Collect confirmation messages.

## L2 SKILL.md shape

Each generated L2 SKILL.md MUST include, in order:

1. Frontmatter and the L1 backlink line.
2. `## Repo Context`: facts inspected from the target.
3. `## Maturity Assessment`: current level (POC, growing, stable, legacy, safety-critical), the signals the assessment is based on, and the date last reviewed.
4. `## Growth Direction`: the natural next step for this lens, the trigger that would force the step, and what is premature at this maturity.
5. `## Repo-Specific Checks`: tailored to the stack, **calibrated to the maturity assessment** (next-step checks emit as `info`, current-level hygiene as `warn`, current-level production blockers as `error`).
6. `## Workflow`: defers to L1 for principles, emits findings per L1's output schema.

Maturity Assessment + Growth Direction are what `skill-auditor` later inspects for drift, so the bullets must be concrete.

## Output

```
{
  "target_repo": "<path>",
  "skills_created": ["testing", "documentation"],
  "outputs": ["<path>/.claude/skills/testing/SKILL.md", ...]
}
```

## References

- `prompt_template-one-skill.md` (subagent prompt)
