---
name: ci-optimization
description: "Use when diagnosing slow CI or excessive runner costs, optimizing validation pipelines, reviewing caching and sharding, or comparing hosted and self-hosted runners. Deployment and release policy belong to continuous-delivery."
---
# CI Optimization

## Overview

Preserve the evidence required to merge while reducing waiting and resource use.
Keep repo-specific timings and conventions in calibration documents.

## Outcomes we are looking for

- Shorter successful validation latency, measured on equivalent workloads.
- Lower runner consumption or billed cost, measured separately from elapsed time.
- Preserved coverage, isolation, cache freshness, and truthful merge gates.

## Measure the actual constraint

Distinguish commit-to-required-check completion, first actionable failure, queue
time, job execution, total runner-minutes, and billed cost. They are different
objectives. A faster failing run is not evidence of faster successful validation.
Separate successful, failed, cancelled, retried, and skipped runs; PR, main,
release, and scheduled events; cold and warm caches. State sample size and dates.

Use job/step timestamps and logs to reconstruct the dependency path that delays
merging. Workflow update time is only a screening proxy, not exact merge latency.
Include required checks in other workflows. Record runner OS, architecture,
toolchain, dependency pins, test count, and cache outcome before comparing runs.

## Optimization menu

The following lessons are distilled from [Mufeez Amjad's Linear case study](https://linear.app/now/ci-bottleneck-reworked)
(2026-09-21), not promised speedups:

- Evaluate faster runners and toolchains on the same workload.
- Remove unnecessary work from prerequisite jobs and minimize checkout scope.
- Move bookkeeping off the merge-critical path.
- Reduce repeated setup with suitable images and narrowly scoped installs.
- Measure cache transfer against rebuilding; a cache can cost more than it saves.
- Batch tiny checks when shared setup dominates.
- Avoid replaying unchanged initialization where equivalence is established.
- Balance shards by measured execution units; split oversized test files.
- Reduce setup before increasing shard count.
- Share test module state only through explicit eligibility and reliable cleanup;
  retain isolation for incompatible tests.

## Correctness constraints

A binary cache must identify source revision, compiler, target architecture,
build configuration, and relevant environment. A source change without a version
bump still invalidates it. Broad fallback keys are suitable for reusable build
inputs only when the build system revalidates them. A restored directory is not
proof that compilation was avoided. Inspect the subsequent build log.

Treat cached test results separately: reuse requires a complete input identity,
including dependencies, generated inputs, configuration, and external services.
Test both invalidation and reuse. Never accept file existence as proof of a
current tool or passing suite.

Before removing duplicate checks, map the remaining owner of every guarantee.
Exercise the final gate with a failed, cancelled, and unexpectedly skipped
required job. Expected conditional skips need explicit policy. A shorter run
that silently omits coverage is a regression.

Path filters must cover shared dependencies, tool/config changes, generated
inputs, and submodule pins. Unknown diffs must run validation. Keep one truthful
local entry point; splitting CI must not strand checks outside local QA.

## Runner decision

Confirm current pricing and repository visibility before claiming savings.
Compare end-to-end throughput under concurrent PRs, not one warm laptop run.
Include power, maintenance, queue contention, network, and cache lifecycle.

On a personal machine, distinguish an isolated disposable worker from access
to the developer's home, credentials, Docker socket, and LAN. Public PR code is
untrusted even without injected secrets. Native macOS is not a replacement for
Linux service-container jobs; verify platform and image architecture support.
Explore runners when requested; a performance review does not itself authorize
registering a persistent runner, purchasing compute, or changing repository trust.

## Red flags

- Claims of lower cost based only on wall time or runner-minutes.
- More shards without measuring replicated setup and available concurrency.
- Cache hits followed by full builds, or stale binaries accepted after pin changes.
- Required checks that pass when a prerequisite fails or is cancelled.
- Performance changes that weaken test isolation or remove gates without evidence.
- Hardware migration proposed before identifying where time is spent.

## Evidence to return

Provide the baseline and source run links; the bottleneck and its measured share;
ranked changes with expected latency, resource, and correctness effects; and
validation results. Label estimates and unmeasured outcomes. For a patch, test
the failure path and compare equivalent hosted runs after deployment before
claiming achieved speedups. Establish a project-specific budget and regression
trigger; do not turn one team's target into a universal threshold.

## References

- [CI bottleneck reworked: Linear case study](references/ci-bottleneck-reworked.md): read on demand for the optimization menu's context and the original article link.
- [GitHub Actions billing](https://docs.github.com/en/billing/concepts/product-billing/github-actions): verify current economics.
- [Self-hosted runner reference](https://docs.github.com/en/actions/reference/runners/self-hosted-runners): platform constraints.
- [Secure use reference](https://docs.github.com/en/actions/reference/security/secure-use): runner trust boundaries.

For deployment and release policy, see [continuous-delivery](../continuous-delivery/SKILL.md).

## Continual improvement

Propose evidence-backed improvements at
https://github.com/syntropic137/software-leverage-points/blob/main/skills/ci-optimization/SKILL.md.
Follow the repository's authoring-skills guidance when changing these principles.
