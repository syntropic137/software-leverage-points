---
name: continuous-deployment
description: "Use when reviewing deployment concerns: rollback safety, health-gated deploys, deploy/release decoupling via feature flags, single-artifact promotion, deploy frequency and lead time, runbook freshness, deploy-credential scoping"
---

# Continuous Deployment

## Overview

Continuous deployment is the practice of moving the artifact CI emits into production safely, frequently, and reversibly. The leverage point lives in the safety properties of the deploy itself: rollback automation, health-gating, decoupling deploy from release, and single-artifact promotion. When these are in place, deploys are routine low-stakes events and recovery is mechanical. When they are missing, deploys concentrate risk into rare big-bang releases and recovery becomes ad hoc archaeology under pressure.

**Core principle:** Deploys are reversible, observable, and decoupled from release. The artifact that shipped to production is the artifact CI tested, the deploy is gated by health signals, and the rollback path is automated and exercised.

## Core Principles

### 1. Rollback is automated (scope: systems with reversible deploys)

This principle scopes to systems where rollback is technically possible: the previous artifact is still available, no irreversible data migration has occurred, no external integration has been notified of a one-way change. When the scope applies: the rollback path is scripted, one-step, and exercised.

For deploys that are intrinsically irreversible (forward-only schema migrations, one-way external calls), the discipline shifts to forward-fix rollouts plus stronger pre-deploy gating; the rollback principle does not apply, but the absence of rollback must be acknowledged in the runbook.

### 2. Deploys are gated by health signals

A deploy step completes on "health endpoint returns OK and key SLOs are within bounds for N minutes," not on "process started." Process-start gating misses config errors, dependency unreachability, and latency regressions; health-gated deploys catch the regression at the deploy boundary, where automated rollback is still cheap. Cross-reference: the `logging` and observability discipline determines what signals are available to gate on.

### 3. Deploy and release are decoupled (scope: systems with feature-flag infrastructure)

This principle scopes to systems where feature-flag infrastructure exists or is feasible. When the scope applies: risky changes ship dark behind a flag, then are gradually enabled for 1%, 10%, 100% of users (or per-tenant) with the abort path being a flag flip rather than a redeploy.

For systems without flag infrastructure (small POCs, libraries with no per-user surface), the decoupling principle inherits a weaker form: stage risky changes in a deploy stream that can be reverted independently, and acknowledge in the plan that any rollout is a deploy rollout.

### 4. Single artifact promoted, not rebuilt per environment

The artifact CI emitted on the integration commit is the artifact that staging tested and the artifact that ships to production. Per-environment rebuilds resolve dependencies fresh and produce binaries that are not bit-identical, so what was tested is not what was shipped. Build once; promote the artifact through environments. Cross-reference: the `environments` lens owns the parity side of this discipline.

### 5. Rollback runbook is exercised on a calendar (scope: production systems)

This principle scopes to production systems where rollback is the intended recovery primitive. When the scope applies: the rollback procedure is run in a game day, staging drill, or recent real incident on a known cadence. Tooling changes, secrets rotate, the previous artifact gets garbage-collected, and runbooks rot silently. Verify recovery on a calendar, not on a pager.

### 6. Deploy frequency tracks commit frequency

A team committing daily but releasing weekly or monthly is batching risk. Large infrequent releases concentrate variables (more changes per deploy means more candidates when something breaks); small frequent releases distribute risk and keep recovery cheap. The empirical case from DORA is unambiguous: elite performers deploy on demand, recover faster, and have lower change-failure rates because each deploy carries less.

This principle scopes to systems where small frequent deploys are operationally feasible. Embedded firmware updates, regulated releases, or systems with mandatory change windows inherit a different cadence; the principle is "deploy frequency matches what the rest of the system can sustain," not "deploy daily regardless."

### 7. Deploy credentials are scoped, audited, and rotatable

The deploy step runs with privileges over production. Credentials live in a scoped CI-side secret store, are rotated on a known cadence, and have the least privilege the deploy actually needs. Implicit credentials (developer laptop tokens, plaintext files in the repo, shared service accounts) cannot be rotated, audited, or revoked cleanly; a stolen laptop becomes a production breach. Cross-reference: the `security` lens for the secret-handling stance and the `continuous-integration` lens for the CI-side scoping.

### 8. Deploy strategy and rollback mechanism are stated and consistent

**Multiple valid deploy strategies exist:** blue/green, canary, rolling, recreate, feature-flag-gated rollout. The choice is shaped by traffic shape, statefulness, and rollback budget; the principle is "the chosen strategy is stated, applied uniformly across services in the project, and matched to the rollback mechanism." The red flag is "no stated strategy," not "did not pick canary."

**Multiple valid rollback mechanisms exist:** automated rollback to previous artifact, runbook-driven rollback, forward-fix-only with stronger pre-deploy gates, feature-flag flip. Pick one per service class and match it to the deploy strategy; mixing strategies without convention fragments the recovery path.

## Red Flags - STOP

- No automated rollback path; rollback under pressure is "log into the box and figure it out" or "redeploy the previous tag manually"
- Deploy step completes on process-start, not on health-endpoint plus SLO-within-bounds for a measured window
- High-stakes change shipped without a feature flag for kill-switch; rollback is the only abort path even where flags would have been feasible
- Different artifacts in staging and production (rebuilds rather than promotes); no audit linking the prod artifact to the staging artifact
- Deploy frequency much lower than commit frequency, with no measured rationale (releases batched into rare big-bang events)
- Rollback runbook documented but not exercised in any game day, drill, or recent incident; cadence for verification is undefined
- Deploy script reads credentials from a plaintext file in the repo, depends on a developer's local credentials, or uses a shared unrotatable token
- No stated deploy strategy or rollback mechanism; every service deploys differently with no convention

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "We can roll back manually if we need to" | Manual rollback under pressure is when ad hoc procedures fail; build it during the calm |
| "The process started, the deploy is fine" | Process-start says nothing about config, dependencies, or latency; gate on health |
| "A flag for that change is over-engineering" | The change was supposed to be safe; flags are how you find out cheaply when it is not |
| "We rebuild for staging to keep the pipeline simple" | Simple pipelines that hide drift cost more than the simplicity saves |
| "We deploy weekly because that's our rhythm" | Rhythm is downstream of capability; small frequent deploys reduce risk per deploy |
| "The runbook hasn't changed" | The system around it changed; the runbook went stale silently |
| "The deploy token has been working for years" | Long-lived high-privilege tokens are the unrotated key in the broken-window neighborhood |

## Key Patterns

```
✅ Deploy script: kubectl apply --record; rollback script: kubectl rollout undo (one command, exercised)
❌ "If something breaks, SSH into the box and figure it out"
```

```
✅ Deploy gate: health endpoint OK + p99 latency within 10% of baseline for 5 minutes
❌ Deploy gate: process exit code 0 from "service start"
```

```
✅ New payment path ships disabled; flag enables for 1% → 10% → 100%; abort is a flag flip
❌ New payment path wired into request path on deploy; abort is a full rollback
```

```
✅ artifact-sha-abc123 promoted from CI → staging → prod; same digest verifiable at each stage
❌ Each environment runs its own build; staging "passed" a different binary
```

```
✅ Quarterly game day exercises rollback; runbook updated when the system changes
❌ Runbook last touched 18 months ago; nobody has run it
```

```
✅ Deploy uses OIDC-federated short-lived credentials scoped to the target environment
❌ Deploy uses a long-lived AWS access key checked into the repo or a shared dev laptop
```

## Why This Matters

Continuous deployment is the discipline that turns deploys from events into routine. The cost of getting it wrong is paid at every release: in stress, in rollback ambiguity, in incidents that compound because recovery is uncertain, and in the slow erosion of confidence that pushes teams toward larger, less frequent releases (which makes everything worse).

Without disciplined deployment:

- Releases become rare, large, and stressful; rollback is "what do we revert?"
- Process-start gating misses regressions until customers report them.
- Risky changes ride deploys directly; the only kill-switch is rollback, and rollback is expensive.
- Runbooks rot quietly; the calm-day procedure does not survive the incident-day system.
- Deploy credentials accumulate privilege over years and cannot be rotated without coordination.

With disciplined deployment:

- Deploys are routine; small batches concentrate less risk.
- Health-gated rollouts catch regressions at the deploy boundary, when automated rollback is still cheap.
- Flags decouple risk from deploy; risky changes are validated under partial traffic with a flag-flip abort.
- The artifact tested in staging is the artifact in production; what was tested is what shipped.
- Rollback is exercised, scoped credentials are rotatable, and DORA metrics move together in the right direction.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** deploy is "push to a single host"; rollback is "redeploy the previous commit." No formal runbook yet; awareness that the next maturity step adds health-gating and an automated reverse path.
- **Growing internal tool:** scripted deploy; documented rollback procedure (manual but stepwise); health-check endpoint exists and the deploy step waits for it. Deploy credentials live in a scoped secret store, not on developer laptops.
- **Shared library:** library publishes artifacts on tagged releases; the analogue of "rollback" is "yank or supersede"; provenance is attested. The deploy lens here is light because there is no running service.
- **Production service:** automated rollback exercised quarterly; health-gated deploys with SLO bounds; risky changes flag-wrapped; build-once-promote pipeline; DORA metrics tracked; deploy credentials short-lived and scoped.
- **Safety-critical:** all of the above plus pre-deploy canary analysis on real traffic, automated abort on SLO breach, multi-region progressive rollout, blast-radius limits enforced by the deploy platform, and game days that exercise the worst-case recovery on a calendar.

## References & rationales

- ***Continuous Delivery* (Jez Humble and David Farley, 2010).** Backs principles 1 (automated rollback), 4 (single artifact promoted), and 7 (deploy credentials scoped). The foundational text on deployment pipelines and access control as a first-class concern.
- ***Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim, 2018) and DORA's *State of DevOps* reports.** Back principle 6 (deploy frequency tracks commit frequency). Empirical link between deploy frequency, lead time, change failure rate, mean time to restore, and organizational performance.
- ***Site Reliability Engineering* (Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy, eds., Google, 2016).** Backs principles 2 (health-gated deploys) and 3 (gradual rollouts via flags). Error budgets, gradual rollouts, and canary analysis as the operational stance behind safe deploys.
- **Charity Majors on observability-driven deploys.** Backs principle 2 (health gating). The framing that you cannot safely deploy what you cannot observe; deploy is a question, observability is the answer.
- **LaunchDarkly and feature-flag pattern docs.** Back principle 3 (decouple deploy from release). The flag-as-kill-switch primitive that makes deploy and release independent acts.
- **The Knight Capital incident (2012, $440M loss in 45 minutes).** Backs principle 1 (automated rollback) and principle 5 (exercised runbooks). The canonical bad-deploy parable: ambiguous rollback procedures plus a partial deploy plus a reused feature flag turned a routine release into a near-bankruptcy event.
- **Netflix Chaos Engineering (Casey Rosenthal et al.).** Backs principle 5 (rollback runbook exercised on a calendar). The "test the rollback" discipline: verify recovery on a cadence, not on a pager.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **Deploy platforms and GitOps:** ArgoCD, Flux, Spinnaker, Harness, AWS CodeDeploy, Kubernetes Deployments and Rollouts (Argo Rollouts for canary / blue-green primitives).
- **Release manifests:** Helm, Kustomize, Terraform / OpenTofu for infra, Pulumi, Crossplane.
- **Feature flags:** LaunchDarkly, Unleash, Flagsmith, Statsig, OpenFeature for the vendor-neutral SDK shape.
- **Health gating and SLO-aware deploys:** Argo Rollouts analysis templates, Spinnaker Kayenta canary analysis, Datadog deployment tracking, Honeycomb deploy markers, Prometheus + Alertmanager for SLO breach signals.
- **Credential scoping:** OIDC federation (GitHub Actions to AWS / GCP / Azure), HashiCorp Vault dynamic secrets, AWS IAM Roles Anywhere, short-lived workload identity bindings.
- **Game-day and chaos tooling:** Gremlin, Chaos Mesh, AWS Fault Injection Simulator, runbook-as-code platforms.
- **Observability of deploys (cross-reference `logging` lens):** deploy markers in metrics dashboards, deploy events in tracing systems, runbook links from alerts.
