---
name: dependencies
description: Use when reviewing dependency concerns: pinning, lockfile health, version pressure, supply chain provenance, transitive risk, license posture
---

# Dependencies Leverage Point

## When to Use

- A planning agent is reviewing a plan that adds, removes, or upgrades third-party packages
- A PR-review agent encounters changes to manifests (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`) or lockfiles
- The orchestrator (`software-leverage-review`) fans out a subagent for dependencies

## When NOT to Use

- For known-CVE triage on already-installed packages at runtime: that lives in the `security` LP, which owns the runtime-attack surface. This LP owns the supply-chain side (where the package came from, how it is pinned, how the graph reproduces).
- For internal-module structure: that is the `architecture` LP.

## Input

`target`: a manifest, lockfile, dependency README, plan document, or git diff to review.

## Workflow

1. Read the `target` and locate the manifest(s) and lockfile(s) for each ecosystem present.
2. Detect supply-chain artifacts: lockfile presence, registry configuration, license tooling, audit gates in CI.
3. Apply checks:
   - Is there a lockfile that is committed and current (`package-lock.json`, `poetry.lock`, `Cargo.lock`, `go.sum`, etc.)?
   - Are direct dependencies pinned to specific versions, or are floating ranges letting transitive drift in?
   - Are any dependencies pulled from non-canonical registries or git URLs without commit pinning?
   - Is there a license audit gate (e.g., `cargo deny`, `pip-licenses`, `license-checker`)?
   - Are deprecated or unmaintained dependencies flagged (no releases in 24+ months, archived upstream, single-maintainer with no successor)?
   - Is the dependency graph reproducible end-to-end from the lockfile (i.e., a clean install on a fresh machine produces the same tree)?
   - Is the same dependency held to a single version across workspace packages, or has version skew crept in?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"dependencies"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"dependencies"`.

## Red Flags (anti-patterns to surface as findings)

- **Lockfile not committed, or out of sync with the manifest.**
  - What to flag: `package.json` references versions that the committed `package-lock.json` does not resolve, or no lockfile exists at all in an ecosystem that has one.
  - Why it matters: without a committed lockfile, every install resolves the graph fresh, so two contributors (or two CI runs) can install different transitive trees from the same manifest. Reproducibility, the precondition for both debugging and supply-chain auditing, is gone.
  - Cite: The Twelve-Factor App, factor II ("Dependencies"), explicit declaration and isolation; a manifest without a lockfile declares only the top of the graph.

- **Floating ranges on direct dependencies (e.g., `"foo": "*"` or `"^1"` without a lockfile).**
  - What to flag: caret, tilde, or wildcard ranges on direct deps in an ecosystem where no lockfile pins the resolved tree.
  - Why it matters: a floating range plus no lockfile means a transitive change in any sub-dependency can ship to production without anyone noticing. The 2016 left-pad incident, where an 11-line package was unpublished and broke thousands of builds, is the canonical demonstration that floating ranges turn external maintainers into uncredentialed committers on your build.
  - Cite: the 2016 left-pad incident, the canonical "transitive trust" cautionary tale.

- **Git-URL dependencies without commit pinning.**
  - What to flag: a `git+https://...` dep with no `#sha` suffix, or a `tag` reference rather than an immutable commit.
  - Why it matters: a tag can be moved. A branch certainly can. Pulling from a moving target means the package you build today is not the package CI built yesterday, even with the lockfile, since git refs can lie.
  - Cite: SLSA spec (slsa.dev), source-integrity requirements at SLSA Build L2 and above; immutable references are the precondition for build provenance.

- **Dependencies with no recent maintenance signals.**
  - What to flag: a direct dep whose upstream has had no release in 24+ months, is archived, has a single maintainer who has gone silent, or whose homepage 404s.
  - Why it matters: an unmaintained package is a CVE incubator. The 2021 ua-parser-js, 2022 colors.js, and 2024 xz-utils incidents all involved trust shifting in projects whose maintenance signals had degraded before the compromise. A dependency you cannot get patched is a future incident waiting on a trigger.
  - Cite: the 2021 ua-parser-js, 2022 colors.js, and 2024 xz-utils incidents as reference cases for malicious-package and abandoned-package risk.

- **Transitive dependency surface unaudited (no `npm audit`, `pip-audit`, `cargo audit`, etc. in CI).**
  - What to flag: CI configuration with no step that scans the resolved tree against an advisory database.
  - Why it matters: empirical data from Snyk's State of Open Source Security shows that the bulk of vulnerabilities reachable from an application live in transitive dependencies the team never chose. Without an audit gate, those vulnerabilities accumulate silently between scans.
  - Cite: Snyk, *State of Open Source Security* (annual reports), for empirical data on the transitive-dependency vulnerability surface. Cross-reference: see the `security` LP for runtime-CVE handling.

- **Inconsistent versions of the same dependency across workspace packages.**
  - What to flag: a monorepo where `pkg-a` resolves `lodash@4.17.20` and `pkg-b` resolves `lodash@4.17.21`, with no documented reason.
  - Why it matters: version skew inside a single deployable unit means two copies of the same library ship together, doubling the attack surface and silently changing behavior at module boundaries. Drift here also defeats license-audit and CVE tooling, which assumes one resolved version per name.
  - Cite: OWASP Top 10 for Open Source Software (2024), specifically the "known vulnerabilities" and "unmaintained software" risk categories that compound when the resolved graph holds duplicates.

- **Binary lockfile committed without a human-readable equivalent (e.g., `bun.lockb` without a `bun.lock` text counterpart): drift becomes invisible in code review.**
  - What to flag: a committed binary lockfile (`bun.lockb`, or any opaque binary resolution artifact) with no paired text-format lockfile checked in alongside it.
  - Why it matters: binary lockfiles save bytes but make the supply chain opaque to code review. A 4-line dependency change and a 4000-line one look identical in `git diff`. Reviewers cannot tell whether a PR is bumping one patch version or quietly swapping a maintainer.
  - Cite: Bun's own docs note (and recommend) that `bun.lockb` has a text-format counterpart (`bun.lock`) for review purposes.

- **No license posture or no license audit gate.**
  - What to flag: a dependency tree with no `LICENSES.md`, no `cargo deny` / `pip-licenses` / `license-checker` invocation in CI, or a copyleft license shipped into a proprietary product without legal review.
  - Why it matters: license obligations are contractual; a GPL-licensed transitive dep in a closed-source SaaS can force disclosure or relicensing. Provenance and licensing are joined: if you cannot answer "where did this come from and under what terms," you cannot answer "are we allowed to ship it."
  - Cite: Cassie Crossley, *Software Supply Chain Security* (2024), on SLSA framing and provenance as the basis for both license and integrity posture.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **The Twelve-Factor App, factor II ("Dependencies").** Explicit declaration and isolation; manifests pin the top of the graph, lockfiles pin the rest. Use this when justifying the lockfile-or-it-did-not-happen stance.
- **The 2016 left-pad incident.** The canonical "transitive trust" cautionary tale: an unpublished 11-line package broke ecosystems globally because floating ranges had given an external maintainer write access to thousands of builds. Use this when justifying pinning.
- **SLSA spec (slsa.dev).** Supply-chain levels (Build L1 through L4); source integrity, build integrity, provenance. Use this when justifying immutable references and provenance metadata.
- **The 2021 ua-parser-js, 2022 colors.js, 2024 xz-utils incidents.** Reference cases for malicious-package and abandoned-package risk; each shows trust shifting in a project whose maintenance signals had already degraded. Use these when justifying maintenance-signal checks.
- **Snyk, *State of Open Source Security* (annual reports).** Empirical data on transitive-dependency vulnerability surface; the bulk of reachable CVEs live in deps the team never directly chose. Use this when justifying transitive audit gates.
- **OWASP Top 10 for Open Source Software (2024).** Risk categories including known vulnerabilities, unmaintained software, name confusion, and unapproved changes. Use this as the structured taxonomy when classifying findings.
- **Opaque lockfiles:** binary lockfiles save bytes but make the supply chain opaque to code review. A 4-line dependency change in a binary lockfile and a 4000-line one look the same in `git diff`. Cite: Bun's own docs note (and recommend) that `bun.lockb` has a text-format counterpart for review purposes.
- **Cassie Crossley, *Software Supply Chain Security* (2024).** SLSA framing, provenance, and the joined posture of integrity and licensing. Use this when justifying license-and-provenance gates as a single concern.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the lockfile to commit, the version to pin, the commit SHA to reference, the audit step to add to CI, or the dep to remove.
