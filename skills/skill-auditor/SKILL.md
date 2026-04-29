---
name: skill-auditor
description: Use when reviewing whether a plugin's leverage-point skills still match the codebase or its own documentation; detect drift between SKILL.md claims and current state
---

# Skill Auditor (Operator Skill)

## When to Use

- A repo's bootstrapped (L2) leverage skills have not been refreshed since major changes to the codebase
- Cross-document drift is suspected within a leverage-points plugin (README vs catalog vs MIGRATION)
- A planning agent or reviewer needs to verify that an SKILL.md's claims still hold before relying on it

## When NOT to Use

- For a single-skill content review (just read the skill itself)
- For end-of-feature review through every leverage point (use `software-leverage-review`)
- For initial bootstrap of L2 skills (use `skill-builder`)

## Input

- `target_repo`: absolute path to a repo whose `.claude/skills/` we should audit (or this plugin's own repo)
- `mode` (optional): `repo-skills` (default) checks L2 skills against the target's actual code; `cross-doc` checks the plugin's own docs for internal consistency; `both` runs both passes

## Workflow

1. If `mode` includes `repo-skills`:
   - List all L2 SKILL.md files under `<target_repo>/.claude/skills/`.
   - For each skill, parse the `## Repo Context` section. Extract claimed facts (language, framework, tool versions, layout).
   - Verify each claim against the target repo's actual state (Read/Glob/Grep).
   - For each mismatch, emit a finding with `severity: warn` (drift), the claimed value, the actual value, and a suggested update.
   - Parse the `## Maturity Assessment` and `## Growth Direction` sections (added by `skill-builder`). Compare the claimed level against current signals (CI presence, contributor count, deploy cadence, public consumers, release tags). Apply maturity-drift checks:
     - `severity: medium`: the Maturity Assessment claims a level the target has outgrown (for example, "POC" with CI green for 90 days, multiple contributors, and external users).
     - `severity: info`: the Growth Direction's "natural next step" is now overdue (the documented trigger has fired without the step being addressed).
     - `severity: info`: `Last reviewed` is older than 6 months even when the assessment still appears accurate (stale review timestamp).

2. If `mode` includes `cross-doc`:
   - Read the plugin's load-bearing docs: `README.md`, `MIGRATION.md`, the design spec (if present), and `docs/leverage-points.md`.
   - Extract LP counts, version strings, install commands, skill names, status labels.
   - Cross-reference: do all sources agree? Surface contradictions as findings.
   - For findings that propagate (e.g., a single rename mentioned in README and not in MIGRATION), one finding per affected file.

3. Validate reference-link integrity (regardless of mode):
   - For every relative path mentioned in any SKILL.md, references doc, or prompt file in scope, verify the file exists.
   - Broken links emit `severity: high` findings.

4. Emit findings using the schema at `../software-leverage-review/slp-output-schema.yaml`. The `software_leverage_point` field MUST be `"skill-auditor"`. Note: the auditor is an operator skill, not a leverage point per se; the schema's `software_leverage_point` field is overloaded here for output-format consistency.

## Output

Conforms to `../software-leverage-review/slp-output-schema.yaml` per-LP shape.

## Red Flags (anti-patterns the auditor surfaces as findings)

- An L2 skill claims a framework version the target's manifest no longer pins
- An L2 skill's `Repo Context` lists tooling that no longer appears in the repo
- An L2 skill's `Maturity Assessment` says POC, but the target now ships to external users with CI gates and multiple contributors
- An L2 skill's `Growth Direction` documents a trigger that has fired (e.g., "first incident where log noise hides the cause") without the next step being addressed
- README and MIGRATION disagree on what is shipped
- An LP count appears differently in README vs spec vs MIGRATION
- A SKILL.md references a file that does not exist
- A SKILL.md cites the schema at an obsolete path

## References & rationales

The "why" behind a drift-detection skill at all:

- **Single source of truth.** When the same fact lives in multiple documents, it diverges. Cite: Ousterhout (*A Philosophy of Software Design*, ch. 12) on code-as-documentation; the same principle for prose. The fix is either deduplication or automated enforcement.
- **Doc drift as recurring failure mode.** Three consecutive evals (001, 002, 003) flagged cross-doc inconsistency in this plugin. The auditor is the structural fix. Cite: Bertrand Meyer's "Open/Closed" applied to documentation ecosystems: open for extension via the catalog, closed for modification of the source-of-truth.
- **L2 skills as artifacts that age.** A repo skill bootstrapped today may be stale tomorrow when the target ships a major refactor. Cite: Hunt and Thomas's "broken windows" principle (*The Pragmatic Programmer*); unmaintained docs accumulate decay.
- **Reference-link integrity as a symptom.** Broken links signal renames or moves that the rest of the docs missed. Cite: Nygard's ADR practice and the related "links should resolve" hygiene rule.

A future enhancement: this skill could ship a `scripts/audit.sh` that runs a subset of the cross-doc checks deterministically (count-the-LPs grep, link-check). For now, the SKILL.md is the contract; an autonomous agent applies it manually.

## Continual improvement

This skill is maintained at:
https://github.com/syntropic137/software-leverage-points/blob/main/skills/skill-auditor/SKILL.md

To improve it, edit the file directly and follow the chassis discipline in [`maintaining-software-leverage-points`](../../.claude/skills/maintaining-software-leverage-points/SKILL.md): regenerate catalogs, run `just qa`, then commit.
