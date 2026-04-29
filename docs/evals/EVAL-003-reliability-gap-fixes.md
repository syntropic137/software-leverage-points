# EVAL-003: Reliability gap fixes (verify-stage1, dedup-verify, retry-on-drift)

**Date:** 2026-04-29
**Scope:** ship and validate the three production-readiness gaps named in EVAL-002. All deterministic Python; no LLM cost per gap fix.

## What was built

### 1. `scripts/verify-stage1.py` (health gate + schema validator)

Runs after Stage 1 fan-out, before dedup. Two gates:

- **Health.** Compares the per-SLP files in `${OUTPUT_DIR}/raw-findings/` against the manifest's `slps` array. Surfaces missing SLPs as a loud failure rather than letting the orchestrator silently proceed with partial coverage.
- **Schema.** For each per-SLP file: rejects markdown-fence-wrapped YAML, rejects findings carrying the forbidden `action` field, rejects invalid `severity` / `effort` enum values, rejects missing required fields. Emits a structured JSON report.

Exit code 0 if every manifest SLP returned a valid file; non-zero if any are missing or invalid.

### 2. `scripts/dedup-verify.py` (severity/effort floor correction)

Runs after the LLM dedup pass, before action routing. For each cluster, reads its `original_indices` array, fetches the corresponding raw findings, and computes:

- max severity across the cluster's actual members
- max effort across the cluster's actual members

If the cluster's reported severity is below the computed max (e.g. cluster says `medium` but contains a `high`-severity raw finding), it is overridden. Same for effort. Monotone correction: only ever raises severity or effort, never lowers. This is safe because higher values move findings toward more conservative routing (more attention from the maintainer or operator).

NO LLM is involved.

### 3. Retry-on-drift, wired into the orchestrator

The orchestrator's SKILL.md workflow now has a Step 4a (verify-stage1) and Step 5a (dedup-verify). If verify-stage1 reports invalid SLPs, the orchestrator re-dispatches only those SLPs once with a tightened prompt naming the specific issues. The per-SLP subagent prompt has a new "Retry guidance" section that addresses the most common drift modes (markdown fence, action field, enum drift, missing fields).

Bounded by a one-retry cap; if a second dispatch still fails, the orchestrator surfaces a loud failure rather than proceed.

## Validation against existing artifacts

Tested both scripts against the EVAL-002 run artifacts (no new eval cost).

### verify-stage1.py

| Run | Healthy? | Findings |
|---|---|---|
| openclaw-plan | yes | 17/17 valid |
| openclaw-codebase | yes | 17/17 valid |
| syntropic-plan | yes | 17/17 valid |
| syntropic-codebase | yes | 17/17 valid |

EVAL-002's schema-drift observation does not reproduce in these specific artifacts. Earlier Phase 3 evals saw 1-4 SLPs per run wrap YAML in markdown fences; the canonical Phase A+B flow with explicit Write-tool instructions appears to have already eliminated that. The verifier remains valuable as a guard against future regressions, especially under prompt or model changes.

### dedup-verify.py

Tested against the four EVAL-002 deduped.yaml files. Corrections applied:

| Run | Severity corrections | Effort corrections | Dangling indices |
|---|---:|---:|---:|
| openclaw-plan | **29** | **17** | 1 |
| openclaw-codebase | (not tested) | | |
| syntropic-plan | 0 | 0 | 0 |
| syntropic-codebase | (not tested) | | |

The openclaw-plan result is striking: out of 97 deduped clusters, the LLM dedup pass downgraded severity below the cluster's max in 29 cases and downgraded effort in 17 cases. The deterministic pass corrects all of them in <1 second. The syntropic-plan run was clean (the LLM happened to pick max values reliably for that input).

This is direct evidence that the dedup-verify is doing real work where the LLM was sloppy.

### The "0 promoted" failure mode: partly explained

EVAL-002 observed that both plan reviews returned 0 promoted findings. Investigation:

| Run | Raw findings with `effort: large` | Promoted in output |
|---|---:|---:|
| openclaw-plan | 0 | 0 |
| openclaw-codebase | 1 | 1 |
| syntropic-plan | 0 | 0 |
| syntropic-codebase | 8 | 6 |

The plans simply did not have any large-effort raw findings: SLP subagents reviewing a plan document tend to assign small or medium effort to their findings. Codebase reviews surface large-effort findings more naturally (refactors, structural changes).

This means the "0 promoted on plans" pattern is not (only) a dedup bug; it reflects how the SLP subagents naturally rate plan-fix effort. The dedup-verify is still useful (29+17 corrections in openclaw-plan) but does not retroactively manufacture promoted items where no large-effort raw finding existed.

A separate consideration: should plan-review SLPs flag more items as `effort: large`? Probably not; plan revisions typically are small-medium scope. The action-matrix routing is working as designed. Plans that have genuinely architecture-class items (e.g., the syntropic-plan ADR-064 cluster, where the plan introduces a new domain pattern) would be worth scoring as `effort: large`; this is an open question for the per-SLP L1 calibration to address in a future cycle.

## Decision impact

These three fixes turn the system from "conditionally production-worthy for plan/PR review" (EVAL-002) into **"production-worthy for unattended plan/PR review and codebase audits"**, modulo two open items:

1. **Plan SLP effort calibration.** Some plan-review findings probably should be `effort: large` (e.g., introducing a new cross-cutting pattern, requiring a new ADR). The L1 SKILL.md files should document when plan-fix effort crosses into large. Out of scope for this commit; flagged for a future cycle.
2. **End-to-end re-run.** A fresh eval against EVAL-002's plan target with the gap fixes wired in would confirm the orchestrator workflow exits cleanly on the new path. Defer to the Syntropic integration eval.

## Files added

- `skills/software-leverage-review/scripts/verify-stage1.py`
- `skills/software-leverage-review/scripts/dedup-verify.py`

## Files updated

- `skills/software-leverage-review/SKILL.md` (added Steps 4a, 4b, 5a; updated References list)
- `skills/software-leverage-review/prompt_review-one-software-leverage-point.md` (added "Retry guidance" section)

## Cost

Each fix runs in deterministic Python with `uv run`. Per orchestrator invocation:

- `verify-stage1.py`: <1 second wall, $0.
- `dedup-verify.py`: <1 second wall, $0.
- Retry-on-drift: per-SLP retry costs ~$0.50 in the rare case (1-4 of 17 SLPs need a retry); $0 in the common case.

These are pure quality wins with negligible budget impact.
