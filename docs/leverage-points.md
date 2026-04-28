# Leverage Points Catalog

The complete list of skills shipped by this plugin. For the mental model and rationale, see `../README.md`.

## Operator skills

| Skill | Status | Purpose |
|---|---|---|
| `software-leverage-review` | shipped (v0.1) | Orchestrator: fans out subagents per leverage point, synthesizes findings using lens references |
| `skill-builder` | shipped (v0.1) | Bootstrap repo-specific (L2) skills from generic (L1) meta-skills, customized per repo's stack |
| `skill-auditor` | shipped (v0.1) | Detect drift between L2 skills and current code/docs; flag the kind of cross-doc inconsistency the evals keep finding |

## Leverage-point skills (18)

| LP | Status | LP | Status |
|---|---|---|---|
| testing | shipped (v0.1) | continuous-deployment | shipped (v0.1) |
| documentation | shipped (v0.1) | types | shipped (v0.1) |
| logging | shipped (v0.1) | developer-experience | shipped (v0.1) |
| architecture | shipped (v0.1) | versioning | shipped (v0.1) |
| configuration | shipped (v0.1) | purpose-and-scope | shipped (v0.1) |
| dependencies | shipped (v0.1) | dry | shipped (v0.1) |
| security | shipped (v0.1) | principles-and-patterns | shipped (v0.1) |
| environments | shipped (v0.1) | software-complexity | shipped (v0.1) |
| continuous-integration | shipped (v0.1) | error-handling | shipped (v0.1) |

## Lens reference docs

| Lens | File |
|---|---|
| DRY | `skills/software-leverage-review/references/dry.md` |
| Principles and patterns | `skills/software-leverage-review/references/principles-and-patterns.md` |
| Software complexity | `skills/software-leverage-review/references/software-complexity.md` |

Note: the 3 lenses are also shipped as full skills with the same names under `skills/`.
