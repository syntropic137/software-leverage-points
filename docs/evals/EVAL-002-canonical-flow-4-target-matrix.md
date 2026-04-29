# EVAL-002: Canonical-flow 4-target matrix

**Date:** 2026-04-29
**Scope:** end-to-end validation of the canonical Phase A+B orchestrator (per ADR-0001 Performance Architecture) against four real targets: two plans + two full codebases. First run with the new policy, schemas, manifest, scripts, and ADR all in their committed canonical state.

**What was held constant:**

- Stage 1: 17 SLP reviewers (Opus 4.7), parallel dispatch, per-SLP file writes
- Bash concat of per-SLP files into raw-findings.yaml
- Single Opus dedup pass
- Deterministic Python action routing (severity + effort -> action)
- Deterministic Python presentation (`render-review.py`)
- Deterministic Python plan-v2 generation (`build-plan-v2.py`) where target is a plan
- Manifest-driven SLP membership (no filesystem listing)
- Per-SLP L2 calibration

**What varied:** target type and target repo.

## Scorecard

| Run | Target | Wall | Cost | Raw | Deduped | Compression | Headline / Promoted / Bulk |
|---|---|---:|---:|---:|---:|---:|---:|
| 1 | openclaw-hermes plan (second-brain RAG) | 12m 26s | $11.92 | 137 | 97 | 1.41x | 59 / 0 / 38 |
| 2 | openclaw-hermes codebase | 12m 41s | $14.49 | 124 | 74 | 1.68x | 39 / 1 / 34 |
| 3 | syntropic137 codebase | 14m 47s | $16.49 | 152 | 55 | 2.76x | 35 / 6 / 14 |
| 4 | syntropic137 plan (cost-budget feature) | 21m 51s | $11.19 | 99 | 60 | 1.65x | 35 / 0 / 25 |

Total spend (matrix + plan-author for run 4): ~$56.

## Quality observations (after spot-checking ~30 headline items across the four runs)

**Findings are senior-engineer caliber.** Concrete examples:

- openclaw plan run: 9-lens convergence on the `compose.yaml` literal default `:-750` for `SECOND_BRAIN_RETRIEVAL_TIMEOUT_MS`; cites ADR-002 registry-wins and CLAUDE.md NO-magic-numbers; suggested fix names the exact replacement (drop the literal, let resolve-env materialize from registry).
- openclaw codebase run: catches a v0.4.0 release commit on main with no matching git tag (tag history stops at v0.3.0); verifiable in seconds; suggested fix includes the corrective git command.
- syntropic codebase run: catches type-laundering where Pydantic models declared on FastAPI routes call services that return `dict[str, Any]`; cites three pairs of file:line locations; suggests returning Pydantic models from services to make the contract one source of truth.
- syntropic codebase run: enumerates 8+ Dockerfile paths still pinned to mutable tags, including the spicy `envoyproxy/envoy:v1.31-latest`; calls out the inconsistency that GitHub Actions are uniformly SHA-pinned but Docker base images are not.
- syntropic codebase run: catches duplicate ADR numbers (027, 035, 060, 062) AND a broken back-reference where AGENTS.md cites ADR-020 / ADR-025 that do not exist locally (they live in a vendored submodule).
- syntropic plan run: catches a primitive-obsession issue where `ExecutionPausedEvent.reason` is a free-form string carrying structured budget-breach data parsed by string-prefix match in the CLI; suggests a typed discriminator with a Pydantic submodel.

The cross-cutting convergence story holds: items where 4-9 lenses agree are the strongest signals. A maintainer reading the headline gets a prioritized list of issues that would otherwise require multiple specialist reviewers.

## Reliability gaps observed

### Dedup variance is real

Compression ratios across the four runs ranged from **1.41x to 2.76x** for similar inputs. Single-shot Opus dedup is non-deterministic enough that the headline count varies meaningfully run-to-run. When dedup is weak, near-duplicate clusters survive and inflate the headline; when dedup is strong, the headline is clean.

### Plan reviews under-flag promoted items

Both plan reviews returned **0 promoted findings**. Both codebase reviews returned 1 and 6 respectively. The pattern is consistent with earlier eval evidence: when the dedup pass canonicalizes a cluster's effort, it tends to pick the lowest-effort member's value, which keeps the action-matrix-routed result on the auto-fix track even when the cluster contains a large-effort observation.

This is the second time this failure mode has surfaced in our evals. It is now a documented production-readiness gap. A two-pass dedup verifier (a second LLM call that re-reads the deduped output and flags clusters needing effort upgrades) would address it.

### Wall-time inflation under multi-session API pressure

Run 4 (syntropic plan) wall: 21m 51s. This is double the average for the other three runs and was launched concurrently with three other `claude -p` sessions. Token cost was actually the lowest of the four ($11.19); the wall inflation is consistent with Anthropic-side concurrency throttling under load.

For production use as a workflow phase, this means: per-target wall is bounded but not by a deterministic budget when multiple workflows run in parallel. A workflow scheduler that paces orchestrator dispatches should account for this.

### Schema compliance: still imperfect

Earlier evals saw 1-4 SLPs per run emit YAML wrapped in markdown fences. The orchestrator silently tolerates this (the YAML inside the fence is still valid). Production-readiness wants a per-SLP retry-on-drift pass: validate `raw-findings/<slp>.yaml`, re-dispatch if invalid, with a count cap.

## Performance economics

| Stage | Per-run cost | Per-run wall (typical) |
|---|---:|---:|
| Stage 1 (17 Opus SLPs in parallel) | $11-15 | 3-5 min |
| Stage 2 dedup (single Opus call) | $1-2 | 5-8 min |
| Routing + presentation + plan-v2 (Python) | $0 | <30s |
| **Total per plan review** | **~$12** | **~12 min** |
| **Total per codebase sweep** | **~$15** | **~13 min** |

For a single high-stakes repo, ~$12-15 per review at weekly cadence is ~$700-800/year. Across a 50-repo fleet, $35-40K/year. The math holds against headcount. At higher cadence (per-PR), cost scales accordingly.

## Decision impact

These four runs validate the production-readiness claims in ADR-0001's Performance Architecture subsection. Specifically:

1. **Stage 1 fan-out is parallel and bounded by the slowest SLP.** Confirmed across all four runs (median Stage 1 wall ~3-4 minutes).
2. **Stage 1 outputs to per-SLP scratch files.** Confirmed: 17 raw-findings files per run, no parent re-ingest overhead.
3. **Single-shot Opus dedup is the floor for cluster-integrity.** Confirmed (and qualified): variance is real, but no other strategy from the C-matrix in EVAL-001 holds quality at lower cost.
4. **Routing, presentation, plan-v2 are deterministic Python.** Confirmed: no LLM calls at these stages; outputs are mechanically reproducible.

These four rules now have evidence from two eval cycles (EVAL-001 + EVAL-002). They are load-bearing on future architectural choices.

## Production-readiness assessment

**The system produces useful, actionable, senior-engineer-caliber findings.** It is conditionally production-worthy for plan reviews and PR reviews where the findings flow into a downstream revision phase. It is not yet production-worthy for unattended codebase audits where the operator never reads the output, because of the three reliability gaps named above.

The recommended path to unattended-production:

1. **Add a two-pass dedup verifier.** ~$0.30/run, ~30 sec wall. Re-reads deduped output, flags clusters needing effort or severity upgrades. Addresses the "0 promoted" plan-review failure mode.
2. **Add per-SLP retry-on-drift.** Validates each `raw-findings/<slp>.yaml` against the Stage 1 schema; re-dispatches the SLP once with a tightened prompt if invalid. Bounded by retry cap (probably 1).
3. **Add Stage 1 health gate.** If fewer than the manifest-listed N SLPs return successfully, surface a loud failure rather than proceed with partial coverage. Hard fail vs soft fail per workflow policy.

These three patches together cost roughly +$0.50 per run and add roughly 1-2 min wall in worst case. They turn occasional subtle quality regressions into loud, recoverable signals.

## Syntropic integration path

The natural fit is as a workflow phase. Concretely:

```
syntropic137 workflow
  Phase 1: plan generation (existing)
  Phase 2: plan review                <- invokes software-leverage-review via claude -p
  Phase 3: plan revision              <- consumes findings.yaml; addresses auto-fix items
  Phase 4: implementation
  Phase 5: PR review                  <- invokes software-leverage-review with target=diff
  Phase 6: PR revision
```

Mechanism:

- A Syntropic workflow plugin wraps the `claude -p` invocation with the canonical orchestrator prompt template.
- Output is `findings.yaml` (Stage 2 schema, already designed for machine consumption) plus `review.md` + `plan-v2.md` for human review.
- The action field gates downstream phase behavior: `auto-fix` -> phase addresses automatically; `promote` -> workflow pause; `bulk` -> appendix only.
- Cost-budget integration (the very feature in run 4's plan target) gives the workflow a safe envelope: per-phase budget caps, hard-fail on breach, operator escalation.

The eat-your-own-dog-food path: ship the cost-budget feature in syntropic137, then wire software-leverage-review as a workflow phase guarded by a cost budget. Run 4's plan becomes the first end-to-end demo: a real plan with real review findings, processed through the very feature it requested.

## Open follow-ups

1. **Land the three production-readiness gaps** as a single commit (two-pass dedup verifier, retry-on-drift, Stage 1 health gate). Estimated ~150 lines of Python + small SKILL.md updates.
2. **Build a Syntropic workflow plugin** that wraps `claude -p` with the canonical orchestrator. Phase plugin spec + prompt template + output parser. Estimated 100-200 lines of plumbing.
3. **First end-to-end Syntropic run.** Pipe a real Syntropic plan through Phase 1 (plan) -> Phase 2 (plan review via this plugin) -> Phase 3 (plan revision). Validate the action-matrix routing in production.

## Artifacts

Raw run artifacts (run.jsonl, raw-findings/*, deduped.yaml, findings.yaml, review.md, plan-v2.md, metrics.json) are under `_archive/eval-final-2026-04-29/<run-name>/`. Reproduction requires the canonical orchestrator prompt template plus per-target inputs; both are captured in the run artifacts.
