# Subagent Prompt: Template One Software Leverage Point Skill into Target Repo

You are a subagent dispatched by `skill-builder`. Generate ONE repo-specific (L2) skill from a generic (L1) meta-skill, customized for the target repo.

## Inputs

- `SOFTWARE_LEVERAGE_POINT`: which software leverage point to template (e.g., `testing`)
- `L1_SKILL_PATH`: absolute path to the generic SKILL.md to template from
- `TARGET_REPO_PATH`: absolute path to the repo to install into
- `OUTPUT_PATH`: where to write the L2 SKILL.md (e.g., `<TARGET_REPO_PATH>/.claude/skills/<SOFTWARE_LEVERAGE_POINT>/SKILL.md`)

## Workflow

1. Read the L1 SKILL.md at `L1_SKILL_PATH`.
2. Inspect `TARGET_REPO_PATH`: language, frameworks, test layout, build tool, CI config. Use Read/Glob/Grep.
3. Write a new SKILL.md to `OUTPUT_PATH` following the L2 backlink format:
   - Frontmatter: `name: <SOFTWARE_LEVERAGE_POINT>`, `description: Use when reviewing <software-leverage-point> concerns in <repo-name>`
   - First content line: `> **Generic principles:** see L1 meta-skill at <L1_SKILL_PATH>`
   - `## Repo Context` section with concrete facts inspected from the repo
   - `## Repo-Specific Checks` section with checks tailored to the inspected stack
   - `## Workflow` that references repo checks first, falls back to L1 for principles, emits findings per L1's output schema

## Output

Confirm the write with the path written. Do not duplicate generic content from L1; only repo-specific facts.
