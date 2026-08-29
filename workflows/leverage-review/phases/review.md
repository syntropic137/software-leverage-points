---
description: "Fan out the 17 software leverage point lenses across the repository and emit the merged review"
argument-hint: "[path-within-repo, or '.' for the whole repo]"
---

Run a full software leverage review of the checked-out repository.

## Target

The review target is this path, relative to the repository root:

$ARGUMENTS

If that is `.` or empty, review the whole repository. Resolve it against the
single directory under `/workspace/repos/` (or, if several repos were cloned,
against each of them in turn and say in the report which one each finding
belongs to).

Maturity hint supplied by the operator (may be empty): `{{maturity_hint}}`

## What to run

You have the `software-leverage-review` skill and all 17 leverage point skills
it fans out over. Invoke `software-leverage-review` and follow its workflow
exactly. Do not improvise a review of your own: the value of this phase is the
parallel fan-out plus the deterministic verification and routing steps, not a
single agent's opinion.

The parts that are easy to skip and must not be:

- Read `slp-manifest.yaml` for the canonical lens list. Do not enumerate
  filesystem siblings; other skills are installed in the same scope and are not
  leverage points.
- Dispatch one subagent per lens, in parallel, using the orchestrator's
  subagent prompt. Pass the maturity stage to every subagent.
- If `{{maturity_hint}}` is non-empty, use it as `maturity_hint` and let it
  override the stage you would otherwise infer.
- Run `verify-stage1.py` after the fan-out. If it reports invalid or missing
  lenses, re-dispatch exactly those once, then re-verify. Partial coverage
  reported as a complete review is the failure mode this gate exists for.
- Run the dedup pass, then `dedup-verify.py`.
- Apply the action matrix in a script, not by asking a model. Any finding with
  `effort: large` gets `action: promote`, whatever its severity.
- Run the synthesis pass over the `references/` docs.
- Render the markdown with `render-review.py`.

You are the top-level session for this phase, so the orchestrator's own
dispatch budget is available to it. Use `/workspace/artifacts/output` as
`OUTPUT_DIR` so the intermediate files are collected along with the report.

## Deliverables

Write all of these to `/workspace/artifacts/output/`:

- `deliverable.md` — the rendered human-readable review: the Headline
  (auto-fix), Promoted for human review, and Low-priority / info-only sections,
  in that order. Open it with the maturity stage you used and whether it was
  inferred or supplied, the target path, and the lens count that passed the
  stage 1 gate.
- `leverage-review.yaml` — the merged machine-readable findings conforming to
  the orchestrator's output schema, every finding carrying its `action` and
  `software_leverage_point`.
- `raw-findings.yaml` and `raw-findings/` — the per-lens output, kept so the
  triage phase and a human can trace any merged finding back to the lens that
  raised it.

## Honesty rules

- A lens that failed twice is reported as failed, by name, in `deliverable.md`.
  Never quietly drop it and present the remaining lenses as the full review.
- Every finding cites a real file path and, where it applies, a line range.
  A finding you cannot anchor in the repository does not go in the report.
- If the target path does not exist in the repository, stop and say so rather
  than reviewing something adjacent.
