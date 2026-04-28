---
name: continuous-integration
description: "Use when reviewing CI concerns: build/test gating, fast feedback loops, branch protection, flaky-test discipline, supply-chain attestation in CI, CI as a single source of truth for green"
---

# Continuous Integration Leverage Point

## When to Use

- A planning agent is reviewing a plan that adds or alters CI workflows, build matrices, branch-protection rules, or test gating
- A PR-review agent encounters changes to `.github/workflows/`, `.gitlab-ci.yml`, CircleCI, Buildkite, or equivalent CI configuration
- The orchestrator (`software-leverage-review`) fans out a subagent for continuous-integration

## When NOT to Use

- For the test framework itself (coverage, layout, mocking discipline): use the `testing` LP. This LP cares about whether CI runs the tests and gates merges on them, not about what those tests look like.
- For deploy automation (rollback, canary, release strategy): use the `continuous-deployment` LP.
- For dependency CVE gating and lockfile health: use the `dependencies` LP.

## Input

`target`: a CI workflow file, a branch-protection configuration, a plan document, or a git diff to review.

## Workflow

1. Read the `target`.
2. Detect CI artifacts: workflow files, runner-image pins, secrets configuration, branch-protection rules, status-check requirements, caching configuration, attestation steps.
3. Apply checks:
   - Are PRs gated by passing CI before merge, with required status checks enforced at the branch-protection layer?
   - Does CI run the full test suite, lint, type-check, and security checks, or surface explicitly why something is skipped?
   - Is the CI feedback loop fast enough to support trunk-based development (target: under 10 minutes for the gating path)?
   - Are flaky tests quarantined or fixed, not retried into green via opaque rerun mechanisms?
   - Is the CI configuration itself reviewed (workflow file edits go through the same PR review as code, runner images are pinned, secrets have least-privilege scope)?
   - Are build artifacts attested (SLSA provenance, signed artifacts, SBOM emission) where supply-chain integrity matters?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"continuous-integration"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"continuous-integration"`.

## Red Flags (anti-patterns to surface as findings)

- **Branch protection allows merging with red or missing CI.**
  - What to flag: a default branch with no required status checks, or required checks that are advisory rather than blocking, or an admin-bypass that is routinely used.
  - Why it matters: if red can merge, CI is decoration. The empirical case from DORA is that elite performers gate on green and treat the gate as inviolable; everyone else accumulates a red-baseline that erodes trust until no one reads CI output. The fix is policy, not culture: enforce the status check.
  - Cite: DORA's *State of DevOps* reports (Forsgren, Humble, Kim) and *Accelerate* (2018) for the empirical link between CI discipline and delivery performance.

- **CI workflows run a subset of tests "for speed" without a full-suite gate elsewhere.**
  - What to flag: a PR workflow that skips integration tests, slow tests, or a test directory, with no matching nightly or pre-merge full run that would catch what was skipped.
  - Why it matters: subsetting without a compensating full run means a class of bugs is invisible until prod. Martin Fowler's CI definition is that the mainline is always known-green against the full suite; partial gating breaks that invariant silently.
  - Cite: Martin Fowler's CI bliki article (canonical short-form definition), the mainline-always-green invariant. Cite also: *Continuous Integration* (Paul Duvall, Steve Matyas, Andrew Glover, 2007), the foundational text.

- **Flaky tests retried until green; no flake tracking.**
  - What to flag: workflow steps configured with `retries: 3` or equivalent, or a culture of "just rerun it" with no dashboard tracking which tests flake and at what rate.
  - Why it matters: retries hide signal. A flaky test is either a bug in the test, a bug in the system under test, or a real race; retries answer none of those questions and they erode trust in the suite (developers stop reading failures). Google's empirical work on flaky tests is the canonical case for quarantine and fix, not retry.
  - Cite: Google Engineering Practices on flaky tests (Testing on the Toilet) for the quarantine-or-fix discipline.

- **Long CI cycle (over 20 minutes for the gating path) without parallelization or caching.**
  - What to flag: a workflow whose median duration on a typical PR exceeds 20 minutes, with no test sharding, no dependency cache, no incremental build, and no measured trend.
  - Why it matters: long CI breaks the trunk-based-development feedback loop. Developers batch changes to amortize the wait, batches make merge conflicts worse, and the conflict cost discourages small commits, which is the core practice CI was meant to support. Speed is a precondition, not a luxury.
  - Cite: Trunk-based development (Paul Hammant) on short-lived branches and the CI speed required to sustain them. Cite also: DORA on lead-time-for-change as a delivery-performance metric.

- **Workflow file edits land without review.**
  - What to flag: changes to `.github/workflows/*.yml` (or equivalent) that bypass the same PR review code receives, or that can be modified by any contributor without elevated review.
  - Why it matters: CI is privileged code. A workflow file can run arbitrary steps with access to secrets and the right to publish releases; an unreviewed change is the supply-chain hole. Recent attacks (codecov 2021, GitHub Actions tag-mutation in 2024-2025) all exploit unreviewed CI surface.
  - Cite: SLSA framework (slsa.dev) on build-platform integrity at L2 and above; the build process must be a reviewed, isolated artifact.

- **No artifact attestation for high-stakes pipelines.**
  - What to flag: a release pipeline that produces binaries or container images with no provenance attestation, no signing, no SBOM, and no chain from commit to artifact.
  - Why it matters: without attestation, downstream consumers (and the next incident response) cannot answer "did this artifact come from this source." SLSA defines the levels precisely so this question has an answer; for high-stakes pipelines (anything externally distributed or running with high privilege) the answer is required.
  - Cite: SLSA framework (slsa.dev) levels L1 through L4. Cross-reference: see the `dependencies` LP for the consumer side of the same supply chain.

- **CI runs only on the main branch, not on PRs.**
  - What to flag: a configuration where the workflow triggers on `push` to `main` but not on `pull_request`, so authors discover failures only after merge.
  - Why it matters: post-merge CI inverts the gating model. The gate should run before integration, not after; otherwise main-branch breakage becomes routine and rollback becomes the recovery mechanism instead of prevention.
  - Cite: *Continuous Integration* (Duvall, Matyas, Glover, 2007), the integrate-early principle that pre-merge CI implements.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- ***Continuous Integration* (Paul Duvall, Steve Matyas, Andrew Glover, 2007).** The foundational CI book; integrate-early, mainline-always-green, fast feedback. Use this when justifying the basic CI invariants.
- ***Continuous Delivery* (Jez Humble and David Farley, 2010).** CD pipeline as an extension of CI; the deployment pipeline begins with the build that CI emits. Use this when justifying the CI-to-CD handoff.
- **Martin Fowler's CI bliki article.** The canonical short-form definition of continuous integration; the mainline-always-green invariant. Use this when stating the standard against which a configuration is measured.
- **Google Engineering Practices, Testing on the Toilet on flaky tests.** The empirical case for quarantine and fix over retry. Use this when justifying flake discipline.
- **DORA's *State of DevOps* reports and *Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim, 2018).** The empirical link between CI discipline (lead time, deployment frequency, change failure rate, mean time to restore) and organizational performance. Use this when justifying speed and gating as outcomes-based, not stylistic.
- **Trunk-based development (Paul Hammant).** Short-lived branches and continuous merge; the CI speed required to sustain the practice. Use this when justifying sub-10-minute gating paths.
- **SLSA framework (slsa.dev).** Build-platform integrity and supply-chain attestation; the levels that classify provenance maturity. Use this when justifying attestation, signed artifacts, and SBOM emission for high-stakes pipelines.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the branch-protection rule to add, the test to un-skip, the cache key to introduce, the flake to quarantine, the workflow review policy to enforce, or the attestation step to add.
