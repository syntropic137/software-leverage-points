---
description: "Apply the auto-fix findings to the plan and surface the promoted decisions"
argument-hint: "[unused; the plan path comes from the review phase]"
---

Produce a revised plan from the review the previous phase wrote.

## Inputs

Read `/workspace/artifacts/input/` first:

- `plan-review.yaml` — the merged findings, each carrying an `action`
- `deliverable.md` — the rendered review
- `raw-findings/` — per-lens detail where a merged finding is too terse

Also read the original plan document under `/workspace/repos/`; the review
header names its path.

If `plan-review.yaml` is missing or has no findings, say so and stop.

## What to do

1. **Apply every `auto-fix` finding to the plan.** Edit the plan's prose so the
   finding no longer applies. Keep the plan's existing structure, headings, and
   voice; you are revising a document someone else owns, not rewriting it.

2. **Do not apply `promote` findings.** Those are scope decisions the policy
   deliberately hands back to the operator. Instead, insert an
   `## Open decisions` section listing each one: the decision to be taken, the
   options, and what each option costs. Leave them unresolved.

3. **Leave `bulk` findings out of the plan body.** List them at the end under
   `## Noted, not actioned` so the audit trail survives.

## Deliverables

Write to `/workspace/artifacts/output/`:

- `plan-v2.md` — the complete revised plan. Complete, not a diff and not a
  patch: a reader must be able to use this file alone.
- `deliverable.md` — a change log: every auto-fix finding you applied and the
  edit that satisfied it, every promoted decision now waiting on the operator,
  and anything from the review you could not action, with the reason.

Two things make this phase worthless if you get them wrong, so check both
before finishing: `plan-v2.md` must contain no placeholder or elided text, and
every change you claim in the change log must actually be present in
`plan-v2.md`.
