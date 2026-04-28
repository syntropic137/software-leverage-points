---
name: environments
description: "Use when reviewing environment concerns: parity between local/staging/production, environment-specific config, build vs runtime environment, container/VM/serverless deployment context, environment promotion"
---

# Environments Leverage Point

## When to Use

- A planning agent is reviewing a plan that introduces or alters how the app runs in different environments (local, CI, staging, production)
- A PR-review agent encounters changes to Dockerfiles, devcontainers, VM images, serverless manifests, or environment-promotion scripts
- The orchestrator (`software-leverage-review`) fans out a subagent for environments

## When NOT to Use

- For the env-var loading mechanism itself (typed config, precedence, validation): use the `configuration` LP. This LP cares about whether the environments themselves are at parity, not about how a single environment reads its variables.
- For CI orchestration (build/test gating, branch protection): use the `continuous-integration` LP.
- For release promotion mechanics (rollback, canary, feature flags at release): use the `continuous-deployment` LP.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect environment artifacts: Dockerfile(s), `docker-compose.yml`, devcontainer config, Terraform/Pulumi manifests, serverless config, runtime-version pins (`.tool-versions`, `.nvmrc`, `.python-version`), per-environment overlays.
3. Apply checks:
   - Is dev/staging/prod parity preserved (same OS family, runtime version, dependency lockfile, datastore family)?
   - Are environment-specific behaviors gated by explicit feature flags or config, not by hostname or env-name detection embedded in business logic?
   - Is the build environment isolated from the runtime environment (no leftover compilers, package managers, or debug binaries in the production image)?
   - Are containers, VMs, or serverless functions reproducible from declarative manifests checked into the repo?
   - Is the migration path between environments documented (how a change moves from dev to staging to prod, who promotes, what gates apply)?
   - Are secrets injected uniformly across environments, with the same shape and the same loader, even when the backing store differs?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"environments"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"environments"`.

## Red Flags (anti-patterns to surface as findings)

- **`if env == "production"` style branches in business logic.**
  - What to flag: code paths that fork on a detected environment name, hostname, or cloud-metadata signal, hidden inside handlers, services, or domain modules.
  - Why it matters: hostname branches make production a different program from dev. The path that actually runs in prod is the path no test ever exercises, so the first time anyone sees it is during an incident. Twelve-factor parity is the discipline that keeps the program identical and pushes variation into config.
  - Cite: The Twelve-Factor App, factor X ("Dev/prod parity"), keep environments as similar as possible. Cite also: Adam Wiggins on the twelve-factor parity rationale.

- **Different runtime versions or dependency lockfiles per environment.**
  - What to flag: a Node 18 Dockerfile in CI but Node 20 in production, or a `requirements.txt` for dev and a separately-resolved `requirements-prod.txt`.
  - Why it matters: divergent runtimes mean bugs are environment-shaped. A library subtle behavior change between minor versions, a TLS default, or a glibc difference becomes a production-only failure that no local repro can catch. One pinned runtime, one lockfile, promoted as an artifact.
  - Cite: *Continuous Delivery* (Jez Humble and David Farley, 2010), the deployment pipeline as artifact promotion rather than re-resolution.

- **Build artifacts that include dev-only tools or debug binaries.**
  - What to flag: a production image carrying compilers, package managers, shell debuggers, test fixtures, or source maps not intended for release.
  - Why it matters: every extra binary is attack surface and confusion surface. Multi-stage builds exist to keep the runtime image minimal, so what runs is exactly what was intended to run, and a forensic image diff has signal.
  - Cite: Reproducible Builds project (reproducible-builds.org), determinism as the basis for trust in what shipped.

- **"Works on my machine" reproducibility gap.**
  - What to flag: a repo with no Dockerfile, no devcontainer, no `.tool-versions`, no pinned interpreter, where onboarding is tribal-knowledge installation steps.
  - Why it matters: the absence of a declarative environment is a slow leak: every contributor's machine drifts independently, and "fix the environment" becomes a recurring tax. The Phoenix Project's environment-fragility parable is the parable for this drift.
  - Cite: *The Phoenix Project* (Gene Kim, Kevin Behr, George Spafford, 2013), the parable of environment fragility and the cost of unowned setup.

- **No explicit promotion path from staging to prod.**
  - What to flag: deploys triggered ad hoc by manual builds, or staging existing in name only with no record of which artifact is currently there or how it gets to prod.
  - Why it matters: if promotion is undefined, every deploy is a snowflake; rollback is undefined too, and audits cannot answer "what is in prod and how did it get there." A documented path turns deploys into routine, low-stakes events.
  - Cite: *The DevOps Handbook* (Gene Kim, Jez Humble, Patrick Debois, John Willis, 2016), on flow and the environment treadmill that disciplined promotion replaces.

- **Secrets injected differently per environment with no parity audit.**
  - What to flag: dev reading from `.env`, staging from a Kubernetes secret, prod from Vault, with no shared loader and no test that all three resolve the same shape.
  - Why it matters: divergent secret loaders mean a secret rename is a four-place change, and a missing prod-only secret is discovered during the prod-only deploy. Parity at the loader level keeps the failure mode local and testable. Cross-reference: see the `configuration` LP for the loader pattern itself.
  - Cite: The Twelve-Factor App, factor X ("Dev/prod parity"), parity as a discipline that extends to the secret-loading boundary.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **The Twelve-Factor App, factor X ("Dev/prod parity").** Keep dev, staging, and production as similar as possible; treat divergence as drift to be corrected. Use this as the foundational stance behind every check in this LP.
- **Adam Wiggins on twelve-factor parity rationale.** The author's framing for why parity matters and what specifically to keep aligned (time gap, personnel gap, tools gap). Use this when justifying which kinds of divergence are most expensive.
- ***The DevOps Handbook* (Gene Kim, Jez Humble, Patrick Debois, John Willis, 2016).** Flow, feedback, and continual learning; the environment treadmill and how disciplined promotion replaces ad hoc deploys. Use this when justifying explicit promotion paths.
- ***Continuous Delivery* (Jez Humble and David Farley, 2010).** The deployment pipeline as artifact promotion: build once, promote the same artifact through environments. Use this when justifying single-runtime/single-lockfile parity.
- ***The Phoenix Project* (Gene Kim, Kevin Behr, George Spafford, 2013).** The parable of environment fragility and the cost of unowned setup. Use this when justifying declarative environments over tribal install steps.
- **Reproducible Builds project (reproducible-builds.org).** Determinism as the basis for trust: the same source plus the same build environment should produce a bit-identical artifact. Use this when justifying minimal images and isolation between build and runtime.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the Dockerfile to add, the runtime pin to commit, the multi-stage stage to introduce, the promotion script to document, or the hostname branch to replace with a feature flag.
