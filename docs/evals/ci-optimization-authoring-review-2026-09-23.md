# CI optimization authoring review

Reviewed against `.claude/skills/authoring-skills/references/audit-checklist.md`.
Scope: the new CI optimization skill and its reference, not a repository-wide
skill rewrite. The user requested this review and authorized merge after green
checks. No complete-diff human review is claimed.

## Findings and changes

- Criterion 9: outcomes lacked explicit evidence for preserved guarantees.
  Added concrete signals to each of the three outcomes.
- Criterion 11: principles were scattered across several headings. Consolidated
  the existing guidance into six named principles, each with rationale.
- Criterion 12: renamed the existing observational Red flags section to
  Anti-patterns; retained all six observations.
- Criteria 13-14: the optimization menu was undated and ungrouped. Grouped dated
  practices under the outcomes they support, preserving the candidate techniques.
- Criterion 29: added an orientation sentence at the start of the reference.
- Criterion 36: added separate positive, negative, and mixed routing exercises.

## Checklist after changes

| Criteria | Result | Evidence |
|---|---|---|
| 1-5 | Pass | Valid name/description-only skill YAML; matching directory; at least five CI triggers; release-policy non-trigger; no marketing language |
| 6-10 | Pass | Short Overview, three early goal-shaped outcomes, each with one or two observable evidence signals |
| 11 | Pass | Six Principles entries, each two to five sentences, with reasons for the guidance |
| 12 | Pass | Six observational anti-patterns; no commandment block |
| 13-14 | Pass | Recommendations dated 2026-09-23, grouped under all three named outcomes with rationale |
| 15-16 | Pass | Named local reference linked with reading context; canonical repository improvement link |
| 17-21 | N/A | Principle document, not a procedural skill |
| 22-26 | Pass | Measurement, cache, and runner paragraphs explain why; no duplicated routing section; source attribution and verifiable log/config evidence |
| 27-29 | Pass | 137-line body; deeper case-study material in a named reference with orientation, provenance, and a summary label |
| 30-31 | N/A | No bundled scripts or assets |
| 32-35 | Pass | Relative local links, no em-dashes or promotional language, observational anti-patterns |
| 36 | Pass, scoped | Three independent harness sessions selected skills from their frontmatter and applied selected bodies; results below |

## Harness evaluation

Codex CLI 0.155.1, gpt-5.6-sol, medium reasoning, read-only. Each session first
read only the CI optimization and continuous-delivery frontmatter, selected
applicable skills, then read selected bodies. Network and actions were disabled.
This tests selection between these two descriptions, not installed-plugin
autodiscovery across a full catalog or statistical routing reliability.

| User request | Expected selection and behavior | Observed |
|---|---|---|
| Six-minute successful CI, thirty-second cancellations, report combined median; reuse binary after unversioned source change | CI optimization only; separate outcomes and rebuild stale binary | Pass |
| Release branch policy, staged artifact promotion and rollback; CI cost/performance explicitly fine | Continuous delivery only; exclude CI optimization | Pass |
| Cut CI costs and plan rollback; add eight shards and a personal Mac runner without setup/pricing/visibility measurements | Both skills; require evidence before adopting the proposed topology and preserve validation/isolation | Pass |

The earlier pressure evaluation remains in `ci-optimization-2026-09-23.md`.
These are directed checks, not a paired before/after performance benchmark.

## Captured responses

Whitespace-only formatting normalized for repository checks.

### positive

Selected: `ci-optimization`.

Not selected: `continuous-delivery`.

Do not combine cancelled and successful runs. Report successful required-check median separately; cancellation time is a distinct outcome.

Rebuild the compiler. Source changes invalidate the cached binary even without a version bump. Cache keys must include source revision and relevant build inputs.

### negative

Selected: `continuous-delivery`
Not selected: `ci-optimization`, because CI speed and runner cost are explicitly out of scope.

Policy:

- `main` remains the integration branch.
- Cut `release/x.y` only for stabilization. No new features.
- Fixes land on `main`, then cherry-pick to the release branch. Emergency fixes require immediate backport to `main`.
- Build each release candidate once from a signed tag. Assign an immutable artifact digest.
- Promote that exact artifact through staging, canary, then production. Never rebuild per environment.
- Require health and SLO gates at each stage. Automatically stop or roll back on breach.
- Production rollback redeploys the previous known-good digest. Exercise this path regularly.
- Use expand-contract database migrations so old and new artifacts remain compatible during rollback.
- Decouple deployment from user release with feature flags and progressive exposure.
- Protect release branches, restrict direct pushes, audit approvals, and use short-lived deploy credentials.
- Delete temporary release branches after GA. Retain supported maintenance branches only while their version receives patches.

### mixed

Selected:

- `ci-optimization`: CI cost, sharding, runner selection.
- `continuous-delivery`: production rollback.

Not selected: none.

Recommendation:

- Do not add eight shards yet. First measure setup time, test distribution, queue time, runner-minutes, billed cost, and available concurrency.
- Do not register the personal Mac runner. Persistent registration requires explicit authorization plus verified pricing, repository visibility, workload concurrency, platform compatibility, and isolation from personal files, credentials, Docker socket, and LAN.
- Benchmark candidate shard counts on equivalent workloads, preserving coverage and test isolation.
- Plan rollback as a scripted, one-step promotion of the previous immutable artifact, triggered by health and SLO failures. Exercise it in staging. If deployment includes irreversible migrations or calls, document forward-fix instead.
- Establish baselines and rollback criteria before implementation.

No files changed, network used, or actions performed.
