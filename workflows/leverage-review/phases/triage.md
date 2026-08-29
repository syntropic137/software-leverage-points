---
description: "Turn the merged leverage review into a prioritized, issue-ready queue"
argument-hint: "[unused; the target comes from the review phase]"
---

Turn the review produced by the previous phase into work a maintainer can pick
up without re-reading the whole report.

## Inputs

Read everything in `/workspace/artifacts/input/` first:

- `leverage-review.yaml` — the merged findings. This is your source of truth;
  each finding already carries `severity`, `effort`, `action`, and
  `software_leverage_point`.
- `deliverable.md` — the rendered review, for the maturity stage and any
  reported lens failures.
- `raw-findings/` — per-lens detail, when a merged finding is too terse to act
  on.

If `leverage-review.yaml` is missing or contains no findings, say so plainly
and stop. Do not re-run the review and do not invent findings.

## What to produce

Write `/workspace/artifacts/output/deliverable.md` containing:

1. **Summary line** — counts by action (auto-fix / promote / bulk) and by
   severity, plus the maturity stage the review was calibrated to.

2. **Do now** — every `auto-fix` finding at `critical` or `high` severity, in
   descending severity then ascending effort. For each: a one-line title, the
   file paths, why it matters in this repo (not the generic principle), and the
   concrete fix. These are meant to be pasted into issues, so each entry must
   stand alone.

3. **Decide** — every `promote` finding. These are the scope decisions the
   review deliberately refused to make. For each, state the decision the
   maintainer actually has to take, and the options with their consequences.
   Do not pick one for them.

4. **Batch** — every `bulk` finding, as a numbered list of one-liners grouped
   by leverage point. No individual context; the point is the audit trail.

5. **Sequencing** — where a "Do now" item is blocked by, or duplicated within,
   another, say so. A dependency between findings is the single most useful
   thing this phase can add, and it is the thing the per-lens subagents could
   not see.

Verify each file path you cite exists in `/workspace/repos/` before you cite
it. A triage list that sends a maintainer to a path that does not exist is
worse than no triage list.
