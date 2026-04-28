---
name: authoring-software-leverage-points
description: Use when authoring or refining any skill in the software-leverage-points plugin (the 18 SLPs, the 3 operator skills, lens references, or L2 templates). Captures the architectural model, the section shape per skill type, and the house rules so authoring stays consistent.
---

# Authoring Software Leverage Points

## Overview

This skill is the canonical authoring contract for this repo. Read it before adding or refining any skill. It encodes:

- The three-layer model (L1 plugin generic, L2 repo-specific, L3 active reviews) the plugin rests on.
- The structural difference between **principle skills** (the 18 SLPs and 3 lens references) and **procedural skills** (the 3 operator skills: `software-leverage-review`, `skill-builder`, `skill-auditor`).
- The L2 skill template `skill-builder` emits, including `## Maturity Assessment` and `## Growth Direction`.
- The house rules: em-dash hygiene, citation discipline, audit-script gates, dated technology recommendations.

**Core principle:** Each kind of skill in this plugin has a defined shape. Don't mix shapes; don't drift them; consult this skill before authoring.

## When to Use

- Authoring a new software leverage point (e.g., adding a 19th).
- Refining an existing SLP based on user feedback or evals.
- Authoring or refining one of the 3 operator skills.
- Authoring or refining a lens reference doc.
- Updating the L2 template that `skill-builder` emits.
- Reviewing an agent-authored skill to check it conforms.

## The Three-Layer Model

| Layer | What lives here | Examples |
|---|---|---|
| **L1: Plugin generic skills** | Principle docs (the 18 SLPs + 3 lens refs) and procedural docs (the 3 operator skills). Repo-agnostic. | `skills/testing/SKILL.md`, `skills/software-leverage-review/SKILL.md` |
| **L2: Repo-specific skills** | Bootstrapped per target repo by `skill-builder`. Includes Maturity Assessment + Growth Direction. | `<target-repo>/.claude/skills/testing/SKILL.md` |
| **L3: Active reviews** | Runtime invocations: `software-leverage-review` fans out subagents per LP; each consults its L2 skill, which backlinks to L1 principles. | (no files; runtime only) |

The principle/procedural split tracks Layer 1's two skill types. SLP and lens skills are principle docs. Operator skills are procedural. Each has a different section shape.

## SLP Skill Structure (principle-doc shape)

For each of the 18 software leverage points and the 3 lens references, the SKILL.md is a **principle doc**: a body of named principles, anti-patterns, and growth examples that an operator skill consults during a review. It is **not** invoked as a function and does not have a workflow of its own.

```
---
name: <lp-name>
description: Use when reviewing <lp-name> concerns: <short list of axes>
---

# <Title>

## Overview                 (intent + Core principle one-liner)
## Core Principles          (the durable patterns this lens enforces)
## Red Flags - STOP         (concrete anti-patterns the lens surfaces)
## Rationalization Prevention   (table: Excuse / Reality)
## Key Patterns             (side-by-side good/bad scenarios)
## Why This Matters         (the consequence of ignoring the lens)
## Growth examples          (POC, growing, production, safety-critical)
## References & rationales  (named sources, paired with the principle each backs)
## Suggested technologies (as of YYYY-MM-DD)   (dated, illustrative, not prescriptive)
```

**Notably absent:** Input, Workflow, Output, schema reference. SLPs do not have "workflows" because they are not invoked as procedures. The operator skills carry the procedure; SLPs carry the content the procedure consults.

## L2 Skill Structure (`skill-builder` output)

When `skill-builder` instantiates an SLP into a target repo, the L2 SKILL.md adds two sections that capture *where this repo is* and *where its next maturity step would lead*:

```
---
name: <lp-name>
description: Use when reviewing <lp-name> concerns in <repo-name>
---

> **Generic principles:** see L1 meta-skill at <plugin>/skills/<lp>/SKILL.md

## Repo Context             (language, framework, layout, observed facts)
## Maturity Assessment      (Current level + Signals + Last reviewed)
## Growth Direction         (Natural next step + Trigger + Don't bother yet)
## Repo-Specific Checks     (calibrated to current maturity)
## Workflow                 (apply repo-specific checks; defer to L1; emit findings per output schema)
```

L2 skills are **journey artifacts**: they describe the repo's current stage and document the path forward. `skill-auditor` watches them for drift.

## Operator Skill Structure (procedural shape)

The 3 operator skills are procedural. They invoke things, dispatch subagents, emit structured output.

```
---
name: <operator-name>
description: Use when <triggers>
---

# <Title>

## When to Use
## When NOT to Use
## Input                (named parameters)
## Workflow             (numbered, executable steps)
## Output               (conforms to skills/software-leverage-review/output-schema.json)
## References           (relevant prompt files, schema docs, lens refs)
```

Operator skills MAY include `## Calibrate severity to maturity` (per Stream B) and similar procedural extensions, but they keep the Input/Workflow/Output spine.

## House Rules

1. **No em-dashes anywhere** in tracked content. The project rule (CLAUDE.md) and `scripts/audit.sh` both enforce this. Use a colon, comma, or restructure.
2. **`bash scripts/audit.sh` must pass** before every commit. The script verifies LP count consistency, version parity across vendor manifests, link integrity, and the em-dash rule.
3. **Citations paired with rationale.** Every red flag in an SLP must trace back to a named source in the `## References & rationales` section. Decorative citations are not allowed; each citation must do work.
4. **Suggested technologies are dated.** Format: `## Suggested technologies (as of YYYY-MM-DD)`. The line under the heading explicitly notes that these go stale and the date is the "as-of." The principles outlast the technologies.
5. **Never inline multi-line bash in markdown.** Procedure code lives in `scripts/`; SKILL.md cites by relative path.
6. **Conventional commits.** `feat(skills): ...`, `feat(operators): ...`, `fix(...): ...`, `docs(...): ...`, `eval(NNN): ...`. Match existing history.
7. **No marketplace-targeted polish in skill content.** The skills serve agents, not marketplace browsers. Marketing-toned descriptions live in `marketplace.json`, not in SKILL.md frontmatter.
8. **Maturity awareness, not maturity gates.** Findings calibrate severity to the target's stage. They do not block work for being at an earlier stage.

## Red Flags - STOP

Mistakes to catch in SLP authoring:

- An SLP has an `## Input` or `## Workflow` section. (It should not. Move the procedure to the operator skill.)
- A red flag in the SLP has no paired rationale citation in `## References & rationales`.
- A "Suggested technologies" section is undated.
- Citations are decorative, not load-bearing (citing a famous book whose ideas don't actually appear in the SLP's checks).
- Em-dashes or en-dashes anywhere (Unicode U+2014 or U+2013); use a colon, comma, or restructure.
- An L2 skill is missing `## Maturity Assessment` or `## Growth Direction`.
- An operator skill is consulting an SLP "as a function" rather than reading its principles.
- The SLP description is generic ("Use when reviewing testing concerns" with no axes named); auto-trigger has no signal to match.

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The SLP needs a workflow so the agent knows what to do" | The operator skill carries the workflow; the SLP carries the principles the workflow consults |
| "We can fix the em-dash later" | The audit script blocks the commit; fix it now |
| "These tools are obviously the right ones" | Frameworks shift; the date is the receipt |
| "Adding a citation makes it look rigorous" | A citation that doesn't shape a check is decorative; remove it |
| "L2 doesn't need Maturity Assessment for a small repo" | Small repos grow; the L2 captures the journey, not just the snapshot |
| "I'll skip audit.sh just this once" | The drift findings the eval suite catches are exactly the failures we are preventing |

## Why This Matters

Without this skill, every authoring session reinvents conventions. SLPs drift toward inconsistent shapes, citations become decorative, em-dashes leak in, and the principle/procedural split blurs. The plugin then loses the property that made the eval scores climb: each SLP is a coherent lens, distinct from its neighbors, calibrated to the target.

This skill is the single source of authoring truth. Read it. Apply it. Future maintainers (humans and agents) thank you.

## References

- `scripts/audit.sh` enforces the mechanical subset of these rules (em-dash hygiene, link integrity, count consistency across docs, manifest version parity).
- `skills/software-leverage-review/output-schema.json` is the structured-output contract that every finding conforms to (emitted by the operator skills, not the SLPs themselves).
- `skills/software-leverage-review/SKILL.md` shows the procedural-skill shape in practice.
- Any existing SLP under `skills/<lp>/SKILL.md` shows the principle-doc shape in practice (`testing`, `logging`, `architecture` are good starting points).
