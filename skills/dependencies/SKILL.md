---
name: dependencies
description: "Use when reviewing dependency concerns: lockfile health, version pinning, immutable references, maintenance signals, transitive audit gates, monorepo version skew, reviewable lockfiles, license posture"
---

# Dependencies

## Overview

Dependencies are the part of the codebase the team did not write but ships anyway. Done well, the dependency graph reproduces deterministically, every reference is immutable, advisories are gated in CI, and license posture is documented. Done poorly, an unpinned transitive can change the build silently between two CI runs, and a moved tag can swap a maintainer without anyone noticing.

**Core principle:** The dependency graph is reproducible, reviewable, and audited. Provenance and integrity are joined; if you cannot answer where a dependency came from, you cannot answer whether it is safe to ship.

## Core Principles

### 1. The lockfile pins what the manifest does not

A manifest declares the top of the graph; a lockfile pins everything beneath it. Without a committed lockfile, every install resolves the graph fresh, so two contributors (or two CI runs) install different transitive trees from the same manifest. Reproducibility, the precondition for both debugging and supply-chain auditing, is gone.

**Multiple valid pinning styles exist:** exact pins on direct dependencies, or ranges-with-lockfile. The principle is: the resolved graph reproduces deterministically. The red flag is "graph does not reproduce," not "did not pin every direct dep to an exact version."

**Multiple valid lockfile-commit policies exist:** always-committed (the conventional default), or CI-generated and verified. Either is defensible; pick one and apply it consistently.

### 2. No floating ranges without a lockfile

Caret, tilde, or wildcard ranges on direct dependencies in an ecosystem with no committed lockfile mean a transitive change in any sub-dependency can ship to production without anyone noticing. A floating range plus no lockfile turns external maintainers into uncredentialed committers on your build.

### 3. References to external sources are immutable (scope: git-URL and external-source dependencies)

This principle scopes to dependencies pulled from a git URL, a tarball URL, or any source that is not a versioned registry artifact. When the scope applies: pin to an immutable reference (a commit SHA), not a tag or branch. A tag can be moved; a branch certainly can. Pulling from a moving target means the package built today is not the package built yesterday, lockfile or not, since git refs can lie.

### 4. Track maintenance signals on direct dependencies

A direct dependency whose upstream has had no release in two years, is archived, has a single maintainer who has gone silent, or whose homepage 404s is a CVE incubator and a future incident. Trust shifts in projects whose maintenance signals have already degraded; the historical record is consistent on this point.

### 5. Audit the transitive surface in CI

The bulk of vulnerabilities reachable from an application live in transitive dependencies the team never directly chose. A CI step that scans the resolved tree against an advisory database is non-negotiable for any project past the prototype stage. Without an audit gate, vulnerabilities accumulate silently between scans.

This principle scopes to projects with CI; cross-reference the `security` lens for the runtime-CVE side of the same gate.

### 6. One version per dependency in a workspace (scope: monorepos)

This principle scopes to monorepos and workspace-style projects. When the scope applies: a given dependency resolves to a single version across all workspace packages. Version skew inside a single deployable unit means two copies of the same library ship together, doubling attack surface and silently changing behavior at module boundaries. Drift here also defeats license-audit and CVE tooling, which assumes one resolved version per name.

### 7. Lockfiles are reviewable

A lockfile is a code-review artifact: a reviewer must be able to tell whether a PR is bumping one patch version or quietly swapping a maintainer. Binary-only lockfiles save bytes but make the supply chain opaque to code review; a four-line dependency change and a four-thousand-line one look identical in `git diff`.

This principle scopes to ecosystems that admit binary lockfiles; in ecosystems with text-only lockfiles it is satisfied by construction. Where the scope applies, commit a paired text-format lockfile alongside the binary one.

### 8. License posture is declared and gated

License obligations are contractual; a copyleft transitive in a closed-source product can force disclosure or relicensing. A license audit step in CI, plus a documented allowlist or denylist, makes the obligation explicit. Provenance and licensing are joined: the same posture that answers "where did this come from" answers "are we allowed to ship it."

## Red Flags - STOP

- Lockfile not committed in an ecosystem that has one, or out of sync with the manifest
- Floating ranges on direct dependencies in an ecosystem with no lockfile pinning the resolved tree
- Git-URL or tarball-URL dependencies with no commit SHA (a tag or branch reference is not enough)
- Direct dependencies with no release in 24+ months, archived upstream, single-maintainer-gone-silent, or 404'd homepage
- CI configuration with no step scanning the resolved tree against an advisory database
- Monorepo where the same dependency resolves to multiple versions across workspace packages without a documented reason
- Binary lockfile committed without a paired text-format counterpart in an ecosystem that admits one
- No license audit gate in CI; no `LICENSES.md` or equivalent posture document; copyleft transitive shipped into a proprietary product without legal review

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The manifest is the lockfile" | It is not; a manifest declares the top of the graph, the lockfile pins the rest |
| "We'll add the audit gate later" | Vulnerabilities accumulate between scans; later is not free |
| "The tag won't move" | Tags move; the historical record agrees |
| "The package hasn't been updated because it's stable" | Stable and unmaintained look identical from the outside; the difference is whether a patch ships if needed |
| "Version skew in the monorepo is harmless" | Two copies double the attack surface and break audit tooling |
| "The binary lockfile is fine; trust the diff" | Reviewers cannot review what they cannot read |
| "Licenses are a legal problem, not an engineering one" | The obligation is engineered when the dependency lands; legal can only triage what engineering exposes |

## Key Patterns

```
✅ Manifest + committed lockfile; clean install on a fresh machine reproduces the tree
❌ Manifest only; every install resolves fresh; transitive drift ships silently
```

```
✅ "foo": "^1.2.3" with a committed lockfile pinning the resolved subtree
❌ "foo": "*" or "^1" with no lockfile
```

```
✅ git+https://example.com/repo#abcdef0123456789... (immutable commit SHA)
❌ git+https://example.com/repo#main (branch, mutable)
```

```
✅ CI step: audit gate scans the resolved tree on every PR
❌ Audits run quarterly by hand, if at all
```

```
✅ Monorepo: lodash@4.17.21 across all workspace packages
❌ pkg-a uses lodash@4.17.20; pkg-b uses lodash@4.17.21; no stated reason
```

```
✅ Binary lockfile committed alongside text-format counterpart for review
❌ Only the binary lockfile is committed; PR diffs are opaque
```

```
✅ License allowlist enforced in CI; LICENSES.md tracks transitive license posture
❌ Licenses unaudited; first awareness of a copyleft transitive is in legal review
```

## Why This Matters

Dependencies are where the supply chain meets the codebase. The cost of getting them wrong is paid in incidents (a moved tag, an unpublished package, a malicious update), in compliance exposure (a copyleft transitive in a SaaS), and in slow erosion (CVEs accumulating between manual scans).

Without disciplined dependency management:

- Builds reproduce only by accident; the same manifest installs different trees on different machines.
- Transitive vulnerabilities accumulate silently; the next CVE breach is the audit you did not run.
- Moved tags and abandoned upstreams turn external maintainers into uncredentialed committers.
- License obligations surface for the first time during a compliance review, with no remediation path that does not require legal.
- Monorepo version skew ships two copies of the same library and breaks audit tooling.

With disciplined dependency management:

- Every install reproduces the same tree; debugging and auditing both work.
- The advisory database is queried on every PR; CVEs surface with patches, not headlines.
- External references are immutable; what was built today rebuilds tomorrow.
- License posture is explicit and gated; obligations are engineered in, not discovered.
- Workspace packages share a single resolved version per dependency; tooling can keep up.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** a manifest exists; the lockfile is committed where the ecosystem provides one. No audit gate yet, but awareness that the supply chain becomes a concern as the project gets users.
- **Growing internal tool:** lockfile reviewed in PRs; first audit step in CI; abandoned-or-archived upstream check happens at least at upgrade time. License posture is acknowledged even if not yet gated.
- **Shared library:** dependency surface kept narrow on principle; transitive count tracked. License audit gates new dependencies. Direct dependencies are evaluated for maintenance signals before adoption.
- **Production service:** committed lockfiles; immutable references for external sources; advisory-database scan on every PR; license allowlist enforced; monorepo version-skew detection in CI.
- **Safety-critical:** vendored dependencies with attested provenance; SBOMs generated and reviewed; supply-chain levels (build integrity, source integrity, provenance) explicit per dependency; license obligations tracked per release artifact.

## References & rationales

- **The Twelve-Factor App, factor II ("Dependencies").** Backs principles 1 (lockfile pins the rest) and 2 (no floating without a lockfile). Explicit declaration and isolation; manifests pin the top of the graph, lockfiles pin the rest.
- **The 2016 left-pad incident.** Backs principle 2 (no floating without a lockfile). The canonical demonstration that floating ranges plus no lockfile turn external maintainers into uncredentialed committers on your build.
- **SLSA (Supply chain Levels for Software Artifacts) spec.** Backs principle 3 (immutable references for external sources). Source integrity at SLSA Build L2 and above requires immutable references as the precondition for build provenance.
- **The 2021 ua-parser-js, 2022 colors.js, and 2024 xz-utils incidents.** Back principle 4 (track maintenance signals). Each is a reference case for trust shifting in projects whose maintenance signals had already degraded before the compromise.
- **Snyk, *State of Open Source Security* (annual reports).** Backs principle 5 (audit the transitive surface). Empirical data showing that the bulk of reachable CVEs live in deps the team never directly chose; cross-reference the `security` lens for runtime-CVE handling.
- **OWASP Top 10 for Open Source Software (2024).** Backs principle 6 (one version per workspace) and provides the structured taxonomy for classifying findings (known vulnerabilities, unmaintained software, name confusion, unapproved changes).
- **Reviewable-lockfile rationale.** Backs principle 7. Binary lockfiles save bytes but make the supply chain opaque to code review; ecosystems with binary formats typically provide a paired text format precisely so that reviewers can read what they are approving.
- **Cassie Crossley, *Software Supply Chain Security* (2024).** Backs principle 8 (license posture is declared and gated). SLSA framing and provenance as the basis for both license and integrity posture.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **JS/TS:** `npm audit`, `pnpm audit`, `yarn audit`, or `bun audit` for advisory scanning; `license-checker` for license audits; `bun.lock` (text) committed alongside `bun.lockb` (binary) for reviewable lockfiles.
- **Python:** `pip-audit` for advisory scanning; `pip-licenses` for license inventory; lockfiles via `poetry`, `uv`, `pdm`, or `pip-tools` (`requirements.txt` with hashes).
- **Rust:** `cargo audit` (advisory database), `cargo deny` (license + advisory + duplicate detection); `Cargo.lock` always committed for binaries, optionally for libraries.
- **Go:** `go mod` with `go.sum` for resolved hashes; `govulncheck` for advisory scanning; `go-licenses` for license inventory.
- **JVM:** Maven Enforcer Plugin and OWASP Dependency-Check; Gradle's `dependency-locking`.
- **Cross-language:** SBOM generation (CycloneDX, SPDX); attestation tooling (in-toto, sigstore); dependency-update bots (Dependabot, Renovate) configured to surface upgrades for human review rather than auto-merging.
