---
name: continuous-deployment
description: "Use when reviewing deployment concerns: release strategy, rollback safety, feature flags, blue/green or canary, monitoring during deploy, deployment frequency, lead time for change"
---

# Continuous Deployment Leverage Point

## When to Use

- A planning agent is reviewing a plan that alters deploy automation, release strategy, rollback mechanism, or post-deploy monitoring
- A PR-review agent encounters changes to deploy scripts, release manifests, feature-flag wiring, or health-check definitions
- The orchestrator (`software-leverage-review`) fans out a subagent for continuous-deployment

## When NOT to Use

- For the CI gate itself (build/test gating, branch protection): use the `continuous-integration` LP. This LP picks up where CI ends, with the artifact CI emitted.
- For environment parity (dev/staging/prod sameness, declarative environments): use the `environments` LP.

## Input

`target`: a deploy script, release manifest, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect deployment artifacts: deploy workflows, release manifests (Helm, Kustomize, Terraform), feature-flag service config, health-check endpoints, monitoring/alerting bindings, rollback scripts, runbooks.
3. Apply checks:
   - Is there an automated rollback path (one-click or script-driven), and has it been exercised recently?
   - Are deploys gated by health checks and observability signals (error rate, latency, saturation), with automated abort on regression?
   - Are risky changes wrapped in feature flags so deploy and release are decoupled (the binary ships dark; the behavior turns on separately)?
   - Is the deploy pipeline reproducible (the same artifact promoted through environments rather than rebuilt at each stage)?
   - Are deploy frequency and lead-time-for-change tracked as DORA metrics, with a target baseline?
   - Is the rollback runbook tested in a game day or staging exercise, not assumed to work?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"continuous-deployment"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"continuous-deployment"`.

## Red Flags (anti-patterns to surface as findings)

- **No automated rollback (manual SSH-into-server cleanup as the recovery plan).**
  - What to flag: a deploy mechanism with a forward path but no scripted reverse path, where rollback is "log into the box and figure it out" or "redeploy the previous tag manually."
  - Why it matters: rollback under pressure is when ad hoc procedures fail. The Knight Capital incident lost $440M in 45 minutes precisely because the recovery procedure was ambiguous and the wrong remediation made the situation worse. Automated rollback is cheap to build during the calm and priceless during the incident.
  - Cite: The Knight Capital incident (2012, $440M loss in 45 minutes), the canonical bad-deploy parable. Cite also: *Continuous Delivery* (Jez Humble and David Farley, 2010), automated rollback as a pipeline requirement.

- **Deploys without health-check gating.**
  - What to flag: a deploy step that completes on "process started" rather than on "health endpoint returns OK and key SLOs are within bounds for N minutes."
  - Why it matters: a process can start and still be broken (config missing, dependency unreachable, latency 10x baseline). Health-gated deploys catch the regression at the deploy boundary, where automated rollback is still cheap; ungated deploys catch it via customer reports, which is the wrong moment.
  - Cite: *Site Reliability Engineering* (Beyer, Jones, Petoff, Murphy, eds., Google, 2016), error budgets and gradual rollouts. Cite also: Charity Majors on observability-driven deploys.

- **New risky behavior shipped without a feature flag for kill-switch.**
  - What to flag: a high-stakes change (new payment path, new permissions logic, new index that affects query plans) wired directly into the request path with no flag, no gradual rollout, and no per-tenant override.
  - Why it matters: deploying and releasing are different acts; conflating them means the only kill-switch is rollback, and rollback may be expensive (data migration, in-flight requests). A flag separates the concerns: ship the binary cold, turn the behavior on for 1%, then 10%, then 100%, with the abort path being a flag flip rather than a redeploy.
  - Cite: LaunchDarkly and feature-flag pattern docs on decoupling deploy from release. Cite also: *Site Reliability Engineering* on gradual rollouts as a default discipline.

- **Different artifacts in staging vs prod (rebuilds rather than promotes).**
  - What to flag: a pipeline where staging and prod each run their own build of the same source, producing artifacts that are not bit-identical, with no audit that the prod artifact was the one that passed staging.
  - Why it matters: rebuild-per-environment means the artifact that was tested is not the artifact that shipped. The deployment pipeline pattern is build-once, promote-the-artifact; everything else is faith. Cross-reference: see the `environments` LP for the parity side of the same discipline.
  - Cite: *Continuous Delivery* (Humble and Farley, 2010), the artifact-promotion model as the canonical pipeline shape.

- **Deploy frequency much lower than commit frequency (releases batched into rare big-bang events).**
  - What to flag: a team committing daily but releasing weekly or monthly, with no measured rationale for the gap.
  - Why it matters: large infrequent releases concentrate risk: more changes per deploy means more variables when something breaks, and the rollback decision becomes "revert what?" DORA's empirical case is that elite performers deploy on demand and recover faster, because each deploy carries less. The fix is smaller, more frequent releases, which require the rest of the LP (rollback, flags, gating) to be in place.
  - Cite: *Accelerate* (Forsgren, Humble, Kim, 2018) and DORA's *State of DevOps* reports for the empirical link between deploy frequency and reliability.

- **Rollback runbook never exercised.**
  - What to flag: a documented rollback procedure that has not been run in a game day, staging drill, or recent real incident, with no scheduled cadence to verify it still works.
  - Why it matters: untested recovery procedures rot. Tooling changes, secrets rotate, the previous-version artifact gets garbage-collected, and the runbook silently goes stale. The Chaos Engineering discipline is to verify the recovery path on a calendar, not on a pager.
  - Cite: Netflix Chaos Engineering (Casey Rosenthal et al.), the "test the rollback" discipline.

- **Deploy step has implicit secrets or hard-coded credentials.**
  - What to flag: a deploy script that reads an API token from a plaintext file checked into the repo, or that depends on a developer's local credentials, with no scoped CI-side secret store.
  - Why it matters: a deploy is privileged; its credentials are the keys to production. Implicit credentials mean nobody can rotate, audit, or revoke cleanly, and a stolen laptop is a production breach. Cross-reference: see the `security` LP for the secret-handling stance and the `continuous-integration` LP for CI-side scoping.
  - Cite: *Continuous Delivery* (Humble and Farley, 2010), on access control over the deployment pipeline as a first-class concern.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- ***Continuous Delivery* (Jez Humble and David Farley, 2010).** The canonical text on deployment pipelines: artifact promotion, automated rollback, access control, and the deployment pipeline as the production-readiness gate. Use this as the foundational stance behind every check in this LP.
- ***Accelerate* (Nicole Forsgren, Jez Humble, Gene Kim, 2018) and DORA's *State of DevOps* reports.** The empirical metrics framing: deployment frequency, lead time for change, change failure rate, mean time to restore. Use this when justifying frequency and rollback-time targets.
- ***Site Reliability Engineering* (Betsy Beyer, Chris Jones, Jennifer Petoff, Niall Richard Murphy, eds., Google, 2016).** Error budgets, gradual rollouts, canary analysis, the operational stance behind safe deploys. Use this when justifying health-gated and gradual rollouts.
- **Charity Majors on observability-driven deploys.** The framing that you cannot safely deploy what you cannot observe; deploy is a question, observability is the answer. Use this when justifying observability-gated deploys.
- **LaunchDarkly and feature-flag pattern docs.** The decoupling of deploy from release; flags as the kill-switch primitive. Use this when justifying flag-wrapped risky changes.
- **The Knight Capital incident (2012, $440M loss in 45 minutes).** The canonical bad-deploy parable: ambiguous rollback procedures plus a partial deploy plus a reused feature flag turned a routine release into a near-bankruptcy event. Use this when justifying automated, tested rollback.
- **Netflix Chaos Engineering (Casey Rosenthal et al.).** The "test the rollback" discipline: verify recovery on a calendar, not on a pager. Use this when justifying scheduled game days.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the rollback script to add, the health check to gate on, the feature flag to wrap, the artifact-promotion step to introduce, the DORA metric to start tracking, or the game day to schedule.
