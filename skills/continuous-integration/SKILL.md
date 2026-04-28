---
name: continuous-integration
description: "Use when reviewing CI concerns: pre-merge gating, branch protection enforcement, fast feedback loops, full-suite vs subset gating, flaky-test discipline, workflow review hygiene, supply-chain attestation, mainline-always-green invariant"
---

# Continuous Integration

## Overview

Continuous integration is the practice that keeps the mainline always-green by integrating changes in small batches, building and testing each one before merge, and treating the gate as inviolable. The leverage point lives in the gate: when the gate is fast, full, and enforced, small commits are cheap and trunk stays releasable. When the gate is slow, partial, or bypassable, branches grow long, batches grow risky, and the trust that anchors the rest of the delivery system erodes.

**Core principle:** The mainline is always-green against the full suite, gated by automated checks that are enforced at the branch-protection layer, with a feedback loop fast enough to support small frequent integrations.

## Core Principles

### 1. Pre-merge gating, enforced at branch protection (scope: PR-based workflows)

This principle scopes to repositories with PR-based or merge-request workflows. When the scope applies: required status checks are configured at the branch-protection layer of the forge, not as advisory hints. The gate is policy: red cannot merge, admin bypass is not routine, and the configuration is itself reviewed.

For repositories without PR-based workflows (single-developer prototypes, paired-trunk-only setups), the gate degrades to a pre-push or local-hook discipline; the principle is "the gate exists and is honored," not "branch protection specifically."

### 2. CI runs on every change, before integration

CI triggers on the change being proposed (pull request / merge request), not only on `main` after the fact. Post-merge CI inverts the gating model: failures are discovered after integration, mainline becomes routinely red, and rollback substitutes for prevention. The fix is to run the workflow on the change, before merge.

### 3. The gate runs the full suite (or has a measured compensating gate)

The PR workflow runs the full test suite, lint, type-check, and security checks. A subset for speed is acceptable only if a compensating gate (nightly full run, pre-merge full run, or similar) catches what the subset skipped, and the gap between subset signal and full signal is measured. Without compensation, subsetting silently invalidates the always-green invariant.

### 4. Feedback is fast (scope: commit-gating CI)

This principle scopes to commit-gating CI (the path that gates a PR or merge). When the scope applies: target sub-10-minute median duration; over 20 minutes is a smell and erodes the practice CI exists to support. Use parallelization, sharding, dependency caching, and incremental builds to hold the line.

Long-batch jobs (nightly, full-matrix, performance regressions) inherit a different speed budget: their job is depth, not gating speed.

### 5. Flaky tests are quarantined or fixed, not retried into green

A flaky test is either a bug in the test, a bug in the system, or a real race. Retries answer none of those questions and erode trust in the suite (developers stop reading failures, then stop running it locally). The discipline: detect flakes, quarantine them out of the gate so they cannot block work, and fix them on a tracked cadence. Cross-reference the `testing` lens for the test-quality side of the same discipline.

### 6. CI configuration is reviewed code

Workflow files run arbitrary steps with access to secrets and the right to publish releases. Edits to workflow files go through the same PR review as code, runner images are pinned, action references are pinned to immutable SHAs (not floating tags), and secrets are scoped least-privilege. Unreviewed CI surface is the supply-chain hole.

### 7. Build artifacts carry provenance (scope: high-stakes pipelines)

This principle scopes to pipelines that produce externally distributed binaries, container images, or anything that runs with privilege. When the scope applies: emit provenance attestation, sign artifacts, and produce an SBOM. The chain from commit to artifact must be answerable downstream. For internal-only tooling at low stakes, the principle is "be aware the trust assumption exists"; for high-stakes pipelines, provenance is required. Cross-reference: the `continuous-deployment` lens carries the build-once-promote-everywhere stance that consumes the artifact CI emits here.

### 8. Workflow tool choice is consistent within a project

**Multiple valid workflow tools exist:** GitHub Actions, GitLab CI, CircleCI, Buildkite, Jenkins, Drone, Tekton, and others. The principle is within-project consistency: a project picks one, applies the same conventions across repos, and centralizes shared steps as reusable workflows or actions. The red flag is "no stated convention," not "did not pick tool X."

## Red Flags - STOP

- Branch protection allows merging with red or missing CI; required checks are advisory, or admin bypass is routine
- CI runs only on the main branch (post-merge), not on pull requests
- PR workflow runs a subset of tests "for speed" with no compensating full-suite gate elsewhere
- Median CI duration on the gating path exceeds 20 minutes with no parallelization, caching, or measured trend
- Flaky tests retried until green via opaque rerun mechanisms; no flake tracking or quarantine policy
- Workflow file edits land without PR review; runner images or action references are unpinned (floating tags)
- High-stakes pipelines emit binaries or images with no provenance attestation, no signing, no SBOM
- No stated convention for workflow tooling or for shared-step reuse; every repo invents its CI fresh

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "We'll fix the red on main next sprint" | Red on main accumulates; the gate is decoration once it is bypassable |
| "Subset tests catch most issues" | Most is not all; the class of bugs you skipped is the class that ships |
| "The CI is slow because the suite is comprehensive" | Slow CI batches changes; batches concentrate risk; speed is a precondition |
| "Just rerun it, it passed last time" | Flakes are signal; retrying hides the signal |
| "It's just a workflow file change" | Workflow files run with secrets and publish rights; review them like code |
| "Provenance is for paranoid teams" | The next supply-chain incident asks "where did this artifact come from"; provenance is the answer |
| "Each repo picks its own CI tool" | Convention is leverage; reinvented CI per repo multiplies the maintenance bill |

## Key Patterns

```
✅ PR workflow blocks merge on test/lint/type-check/security; branch protection enforces required checks
❌ CI is "informational"; admin bypass is routine; red can merge
```

```
✅ on: pull_request triggers full pre-merge run
❌ on: push to main only; failures discovered after integration
```

```
✅ Median PR CI under 10 minutes via test sharding + dependency cache + incremental build
❌ 30-minute uncached CI; developers batch changes to amortize the wait
```

```
✅ Flaky test detected → quarantined out of the gate → tracked → fixed on cadence
❌ retries: 3 buried in workflow config; no dashboard; "just rerun"
```

```
✅ Workflow file edits go through PR review; uses: actions/checkout@<sha>
❌ uses: actions/checkout@v4 (floating tag); workflow edits self-merged
```

```
✅ Release pipeline emits SLSA provenance, signed image, and SBOM
❌ Release pipeline produces a tarball; no signature, no SBOM, no chain to source
```

## Why This Matters

CI is the empirical gate that distinguishes "we believe this works" from "we have evidence this works." When the gate is reliable, every other delivery practice rides on it: trunk-based development, small frequent commits, low-risk deploys, fast rollback. When the gate is unreliable, those practices invert: branches grow long to amortize CI cost, batches grow risky, deploys become events rather than routine, and the team's trust in any green signal degrades.

Without disciplined CI:

- Mainline drifts red; the always-green invariant collapses.
- Flaky tests train the team to ignore failures; real failures hide among noise.
- Slow CI forces batching; batched changes concentrate risk and merge conflicts compound.
- Workflow files become the soft underbelly of the supply chain.
- The team cannot answer "did this change pass the gate" without manually inspecting runs.

With disciplined CI:

- Trunk stays releasable; the deploy decision is "when," not "is it safe."
- Small frequent commits are cheap; integration risk stays bounded.
- Failures surface fast and cleanly; flake noise is quarantined and tracked.
- The build platform itself is reviewed code with attested artifacts.
- DORA's four metrics (lead time, deploy frequency, change failure rate, mean time to restore) move in the right direction together.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** local pre-push hook runs the test suite. No PR workflow yet; awareness that one becomes necessary the moment a second contributor lands.
- **Growing internal tool:** PR workflow runs tests, lint, type-check; branch protection enforces required checks; mainline-green invariant established. Workflow file edits go through review.
- **Shared library:** matrix runs across supported runtime versions and platforms; cache and shard to keep PR runs fast; flaky-test policy stated; first dependency-audit step added (cross-reference the `dependencies` lens).
- **Production service:** sub-10-minute gating path; full-suite compensating gate scheduled; flake quarantine and tracking dashboard; pinned runner images and pinned action references; release pipeline emits provenance and signs artifacts; SBOM published.
- **Safety-critical:** mutation testing and fuzz testing in the gate or as a compensating run; reproducible builds verified across runners; multi-party review for workflow file changes; supply-chain attestation at the highest level the platform supports.

## References & rationales

- ***Continuous Integration* (Paul Duvall, Steve Matyas, Andrew Glover, 2007).** Backs principles 2 (run on every change before integration) and 3 (full-suite gate). The foundational text on integrate-early and mainline-always-green.
- **Martin Fowler's CI bliki article.** Backs principle 3 (full-suite gate) as the canonical short-form definition: the mainline-always-green invariant against the full suite.
- ***Continuous Delivery* (Jez Humble and David Farley, 2010).** Backs principle 7 (build artifacts carry provenance) and underwrites the CI-to-CD handoff. The deployment pipeline begins with the build that CI emits.
- **DORA's *State of DevOps* reports and *Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim, 2018).** Back principle 1 (pre-merge gating enforced) and principle 4 (fast feedback). Empirical link between CI discipline and delivery performance.
- **Trunk-based development (Paul Hammant).** Backs principle 4 (sub-10-minute gating). Short-lived branches require fast CI; the speed budget is derived from the practice it must support.
- **Google Engineering Practices, Testing on the Toilet on flaky tests.** Backs principle 5 (quarantine or fix, not retry). The empirical case for flake discipline.
- **SLSA framework (slsa.dev).** Backs principle 6 (CI configuration is reviewed code) and principle 7 (build artifacts carry provenance). Build-platform integrity at L2 and above; the build process must be reviewed and isolated.
- **Recent supply-chain incidents (codecov 2021, GitHub Actions tag-mutation 2024-2025).** Back principle 6 (workflow review and pinned references). Concrete demonstrations of the unreviewed-CI-surface attack class.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **Workflow platforms:** GitHub Actions, GitLab CI, CircleCI, Buildkite, Jenkins, Drone, Tekton, Argo Workflows.
- **Caching and acceleration:** native cache primitives per platform; remote build caches (Bazel, Turborepo, Nx, Gradle Build Cache); test sharding via runners' matrix features; incremental compilation in language toolchains.
- **Flake tracking:** Buildkite Test Analytics, Datadog CI Visibility, Trunk.io flaky-test detection, GitHub Actions test reporters.
- **Provenance and signing:** SLSA provenance generators, sigstore / cosign for artifact signing, in-toto attestations, syft / trivy / grype for SBOM generation, GitHub Actions artifact attestations.
- **Workflow hardening:** pin actions to commit SHAs (Dependabot can rewrite tags to SHAs), use OIDC federation instead of long-lived secrets where the platform supports it, audit-log analyzers for workflow events.
- **Cross-cutting:** reusable workflows / shared pipeline templates per organization to keep convention consistent across repos.
