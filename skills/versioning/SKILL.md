---
name: versioning
description: "Use when reviewing versioning concerns: semver discipline, changelog hygiene, deprecation policy, migration path, backward compatibility, version locking and resolution"
---

# Versioning Leverage Point

## When to Use

- A planning agent is reviewing a plan that introduces breaking changes, deprecations, version bumps, or alters changelog/release-notes practice
- A PR-review agent encounters changes to public-API surface, version manifests, or deprecation markers
- The orchestrator (`software-leverage-review`) fans out a subagent for versioning

## When NOT to Use

- For dependency version pinning and lockfile resolution: that is the `dependencies` LP. This LP cares about the project's own versioning contract with consumers; the two LPs cross-reference at the manifest boundary.
- For release deployment mechanics (canaries, rollbacks, environments): that is the `continuous-deployment` LP.
- For implicit-contract drift in PRIVATE packages or internal CLIs (Hyrum's Law applies, but the versioning LP is scoped to publicly-versioned surfaces with a stated semver/calver/etc. discipline; for private contracts, use the `architecture` LP for layer-boundary review).

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect versioning artifacts: version field(s) in `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `CHANGELOG.md`, `RELEASE-NOTES.md`, deprecation markers, public-API stability classifications, version-bump scripts, conventional-commit config.
3. Apply checks:
   - Does the project follow semver, or another explicit and documented versioning policy?
   - Is there a `CHANGELOG` or `RELEASE-NOTES` that names breaking changes, new features, and fixes per release?
   - Are deprecations announced before removal, with a migration path?
   - Are version bumps automated or scripted, not manual edits across multiple manifest files?
   - Does the public API surface track versioning explicitly (e.g., `v1` URL prefix, exported types tagged with stability)?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"versioning"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"versioning"`.

## Red Flags (anti-patterns to surface as findings)

- **Version field bumped manually with drift across multiple manifest files.**
  - What to flag: a version edited by hand in `package.json` but not in `pyproject.toml`, in `Cargo.toml` but not in `__init__.py`, or in the manifest but not in the docs site config.
  - Why it matters: manual bumps drift; drifted versions confuse consumers, package managers, and observability. A single source of truth (a script, a `bump-version` tool, or a release-please bot) keeps every manifest in lockstep with one command.
  - Cite: Conventional Commits (conventionalcommits.org) for the commit-driven version-bump automation hook. Cite also: `release-please` and `semantic-release` as canonical implementations.

- **Breaking changes shipped without a major-version bump.**
  - What to flag: a change to a public function signature, a removed export, a renamed CLI flag, or an incompatible config schema, in a release that bumps only patch or minor.
  - Why it matters: semver is a social contract; consumers pin on the contract, not on the changelog. A breaking change at minor is a silent foot-gun for every downstream caller. The fix is either to bump major or to keep the old surface as a deprecated alias for one minor cycle.
  - Cite: Tom Preston-Werner, semver.org (Semantic Versioning 2.0.0), the canonical contract: MAJOR for incompatible API changes, MINOR for additions, PATCH for fixes.

- **Deprecations removed without prior announcement.**
  - What to flag: a function, flag, or config key removed in version N where N-1 did not mark it deprecated and did not name a removal version.
  - Why it matters: an undocumented removal forces every consumer to discover the change at upgrade time, often in production. The deprecation discipline is one minor cycle of warnings before removal at the next major; that is the cheapest possible migration aid and the canonical norm.
  - Cite: Rich Hickey, "Spec-ulation" (2016), on the social contract of versioning: accretion and relaxation are safe, breaking is not, and deprecation is the bridge between them.

- **Changelog entries that say "various improvements" instead of named user-visible changes.**
  - What to flag: a `CHANGELOG.md` release section that lists "bug fixes," "improvements," or "internal cleanup" with no specific user-visible items, or entries that describe the implementation rather than the user-facing change.
  - Why it matters: an opaque changelog forces consumers to read the diff to decide whether to upgrade. The "Keep a Changelog" format names six categories (Added, Changed, Deprecated, Removed, Fixed, Security) and demands user-visible language. The discipline is what makes the changelog actually useful at upgrade time.
  - Cite: Olivier Lacan and contributors, "Keep a Changelog" (keepachangelog.com), the canonical changelog format.

- **No public-API stability classification (everything is implicitly stable).**
  - What to flag: a library exporting every internal helper alongside its public types, with no `@public` or `@internal` annotation, no `_underscore_prefix` convention, and no stability tag in the docs.
  - Why it matters: without a public-vs-internal boundary, every export is a de facto stability commitment, and refactoring the internals becomes a breaking change. Naming the surface (whether by convention, decorator, or documented list) is the prerequisite for honest semver.
  - Cite: Andrew Hunt and David Thomas, *The Pragmatic Programmer*, on stability and explicit versioning. Cite also: Linus Torvalds on the "we don't break userspace" rule of the Linux kernel as the upper bound of the discipline.

- **"0.x" used as a permanent state to avoid semver discipline.**
  - What to flag: a project past its first production users still on `0.x.y` with no plan to ship 1.0, citing "we might still break things" as the reason.
  - Why it matters: semver's pre-1.0 license is a brief one. A project with real users that stays at 0.x is choosing to opt out of the social contract, which costs consumers more than it saves the maintainer. The right move is either to commit to 1.0 (and the discipline that follows) or to document the policy explicitly so consumers can plan.
  - Cite: David Heinemeier Hansson on the cost of premature 1.0; the inverse argument applies to the cost of permanent 0.x. Cite also: semver.org section 4 on initial development.

- **Version bumps automated but changelog or release notes are not.**
  - What to flag: a `release-please` or `semantic-release` setup that bumps the version cleanly but produces a generic or empty changelog.
  - Why it matters: half-automation is worse than none, because it produces the appearance of a changelog without the content. Conventional Commits plus an automated changelog generator should produce categorized, human-readable entries; if it does not, the commit messages or the config need a fix.
  - Cite: Conventional Commits and "Keep a Changelog" together as the canonical pairing.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Tom Preston-Werner, semver.org (Semantic Versioning 2.0.0).** The canonical versioning contract. Use this as the foundational stance behind every check in this LP.
- **Olivier Lacan and contributors, "Keep a Changelog" (keepachangelog.com).** The canonical changelog format with six named categories. Use this when justifying changelog-content checks.
- **Andrew Hunt and David Thomas, *The Pragmatic Programmer*.** Stability and explicit versioning as design principles. Use this when justifying public-API stability classification.
- **Rich Hickey, "Spec-ulation" (2016).** The social contract of versioning, accretion vs breaking. Use this when justifying deprecation policy and the cost of breaking changes.
- **Conventional Commits (conventionalcommits.org).** The commit-driven version-bump automation hook. Use this when justifying automated version bumps and changelog generation.
- **Linus Torvalds, "we don't break userspace" (Linux kernel mailing list).** The upper bound of versioning discipline; the kernel's stability promise as a thought experiment for library maintainers. Use this when arguing for stricter discipline on public APIs.
- **David Heinemeier Hansson on the cost of premature 1.0.** The inverse argument applies to permanent 0.x; both are failure modes of the same axis.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the version-bump script to introduce, the changelog category to populate, the deprecation marker to add, the stability annotation to apply, or the conventional-commits config to wire in.
