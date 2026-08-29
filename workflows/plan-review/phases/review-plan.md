---
description: "Fan out the leverage point lenses against a plan document before implementation"
argument-hint: "[path/to/plan.md]"
---

Review an implementation plan before anyone writes code for it.

## Target

The plan document, relative to the repository root:

$ARGUMENTS

Resolve it under `/workspace/repos/`. If the path does not exist, stop and say
so - naming the paths you looked at - rather than reviewing a different
document.

Maturity hint supplied by the operator (may be empty): `{{maturity_hint}}`

## What to run

Invoke the `software-leverage-review` skill with the plan document as
`TARGET_PATH` and follow its workflow. This is a plan review, not a codebase
review, and the two differ in one way that matters: effort is rated against
what the revised plan would commit the team to, not against the size of the
textual edit. Adding one sentence that commits the team to a new cross-cutting
pattern is `large`, and `large` always promotes to the operator.

Do not skip the machinery:

- iterate over `slp-manifest.yaml`, not filesystem siblings
- dispatch the lenses in parallel, passing the maturity stage
- run `verify-stage1.py` and re-dispatch any lens that failed schema or did not
  return, once, then re-verify
- run the dedup pass and then `dedup-verify.py`
- apply the action matrix in a script

Use `/workspace/artifacts/output` as `OUTPUT_DIR`.

## What good plan findings look like

The lenses are most useful on a plan when they name what the plan has left
undecided rather than what it says badly. Prefer findings of the form "the plan
commits to X but does not say who owns Y" or "this step has no rollback and the
delivery lens requires one at this maturity" over prose criticism.

Read the plan against the repository it will land in. A plan that contradicts
an existing ADR, duplicates a module that already exists, or assumes a
dependency the repo does not carry is a finding, and it is only visible if you
look at both.

## Deliverables

Write to `/workspace/artifacts/output/`:

- `deliverable.md` — the rendered review, with the three standard sections and
  a header naming the plan path, the maturity stage, and whether the stage was
  inferred or supplied.
- `plan-review.yaml` — the merged findings, each with `action` and
  `software_leverage_point`.
- `raw-findings.yaml` and `raw-findings/` — per-lens detail for the next phase.

Report any lens that failed twice, by name. Never present a partial fan-out as
a complete review.
