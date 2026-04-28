---
name: maintaining-software-leverage-points
description: Use when maintaining the plugin chassis (not the SLP content): bumping versions, regenerating catalogs, running QA, configuring CI, shipping releases, or onboarding a contributor to the repo's automation surface.
---

# Maintaining Software Leverage Points

## Overview

The plugin has two contracts and they answer different questions.

`authoring-software-leverage-points` is the **content contract**: what shape an SLP takes, how principles are scoped, where citations belong, what red flags pair with what rationale. Read it when you are writing or refining the substance of a skill.

This skill is the **chassis contract**: what scripts maintain the cross-doc invariants, how `just qa` is composed, what CI enforces, how a release moves through the four vendor manifests. Read it when you are adding an SLP, bumping a version, wiring CI, debugging a failing audit, or onboarding to the repo's automation.

**Core principle:** The filesystem is the source of truth. Everything else (catalogs, counts, cross-references, CI assertions) is derived. If a doc carries a fact the filesystem already implies, that fact will drift; auto-derive it instead.

## When to Use

- Adding or removing a leverage-point skill.
- Bumping the plugin version for a release.
- Wiring a new vendor manifest, a new CI workflow, or a new audit check.
- Debugging a failing `just qa`, audit, or CI run.
- Onboarding a contributor who needs the "how does this repo stay consistent" map.
- Deciding whether a new fact belongs in prose, frontmatter, or a generated artifact.

## The Automation Surface

Three layers of automation, each with one job.

### 1. Generators (filesystem -> docs)

`scripts/regenerate-catalogs.sh` reads frontmatter from every `skills/<name>/SKILL.md` and rewrites three marker-bounded blocks: the operator and SLP and lens reference tables in `docs/leverage-points.md`, plus the SLP catalog list in `README.md`. Output is deterministic (alphabetical SLPs, fixed-order operators and lens references) and idempotent (running twice produces no further diff).

When to run: after adding or removing a skill, or after editing frontmatter (`name`, `description`).

How to invoke: `just regenerate-catalogs`.

### 2. Validators (filesystem + docs -> pass/fail)

`scripts/audit.sh` performs five mechanical drift checks: leverage-point count consistency across docs, version-string parity across the four vendor manifests, broken-link integrity for relative paths, em-dash and en-dash sweep, and SLP-to-SLP cross-reference symmetry. Each check prints `OK:` or `FAIL:` and the script exits non-zero if any check failed.

`scripts/check-backlinks.sh` is the cross-reference validator that audit's Check 5 invokes. It builds the directed graph from canonical phrasings (`` `<other>` lens ``, `` `<other>` SLP ``, or `skills/<other>/`) and reports any one-way edge.

`scripts/bump-version.sh --check` reports the version of every file declared in `.version-bump.json` and flags drift.

`scripts/bump-version.sh --audit` runs `--check` plus a repo-wide grep for the current version string, surfacing files that mention the version but are not declared in the bump set.

When to run: before every commit; CI runs them on every PR.

How to invoke: `just qa` (which runs `check-catalogs`, `audit`, `check-backlinks`).

### 3. Mutators (the only scripts that change state on purpose)

`scripts/bump-version.sh <new-version>` rewrites the version field in every declared file (`.version-bump.json`'s `files` list), then runs `--audit` to surface stray references. Emits a summary and the next-step commands; does not commit or tag.

When to run: when shipping a release. Always go through this script; never edit manifest versions by hand.

How to invoke: `just bump <new-version>`.

## File Layout

```
software-leverage-points/
  .claude-plugin/
    plugin.json              vendor manifest (Claude Code)
    marketplace.json         marketplace listing (nested plugins.0.version)
  .codex-plugin/plugin.json  vendor manifest (Codex)
  .cursor-plugin/plugin.json vendor manifest (Cursor)
  gemini-extension.json      vendor manifest (Gemini)

  .version-bump.json         declares which files carry the version, which to skip in audits
  justfile                   discoverable entry point; recipes wrap scripts/

  .github/workflows/
    qa.yml                   runs `just qa` on PR and push to main
    plugin-version-check.yml enforces version bump on content change + manifest parity

  scripts/
    audit.sh                 the five mechanical checks
    check-backlinks.sh       SLP-to-SLP cross-reference symmetry
    regenerate-catalogs.sh   filesystem -> docs/leverage-points.md + README.md
    bump-version.sh          mutator: bumps all declared files

  skills/
    <slp>/SKILL.md           leverage-point skills (content contract)
    software-leverage-review/ operator skill: review orchestrator
    skill-builder/           operator skill: L2 bootstrap
    skill-auditor/           operator skill: drift detection

  .claude/skills/
    authoring-software-leverage-points/  meta-skill: content contract (this skill's sibling)
    maintaining-software-leverage-points/ meta-skill: chassis contract (this skill)

  docs/leverage-points.md    canonical reference catalog (auto-regenerated)
  README.md                  explanation layer (mental model + auto-generated SLP list)
  RELEASE-NOTES.md           per-release summaries
  MIGRATION.md               historical migration plan
```

## Adding a Leverage-Point Skill

1. Create `skills/<new-slp>/SKILL.md` following the principle-doc shape from `authoring-software-leverage-points`. Frontmatter must include a discriminating `name` and `description`.
2. Run `just regenerate-catalogs`. The new skill appears in `docs/leverage-points.md` and the README list.
3. Run `just qa`. If the new skill cross-references existing SLPs, the backlink check tells you which back-edges to add.
4. Commit. CI runs `just qa` on the PR and gates the merge.

There is no other place to update. Counts, catalogs, and cross-reference lists all derive from the filesystem.

## Bumping the Version

1. Decide the new version per semver. Adding skills is at minimum a minor bump; breaking changes to operator interfaces or output schema are a major bump; pure-bugfix or doc-only changes are a patch.
2. Run `just bump <new-version>`. The script rewrites all five declared files and runs `--audit` to surface stray references.
3. Edit `RELEASE-NOTES.md` and replace the TODO stub with the actual summary. Keep the format consistent with prior entries (header, summary paragraph, `### What's in this release`, dated separator).
4. Run `just qa`. Confirm everything is consistent.
5. Commit with message `release: v<version>`.
6. After merge to `main`: tag locally (`git tag -a v<version> -m "v<version>"`) and push tags. Claude Code's update detector keys off `.claude-plugin/plugin.json`'s version, so a published tag matters; CI does not auto-tag today.

## CI Map

Two workflows under `.github/workflows/`.

`qa.yml`: triggered by `pull_request` and `push` to `main`. Installs `just` and runs `just qa`. Failure on this gate means catalogs are stale, audit checks failed, or cross-references drifted.

`plugin-version-check.yml`: triggered by `pull_request` to `main`. Two steps: `bash scripts/bump-version.sh --check` for parity across declared files, then a "did content change without a version bump" check that excludes only the declared manifest files. Failure on this gate means an unreleased plugin update would silently ship without Claude Code's update detector seeing it.

Both workflows must be marked required in branch protection (configured in the GitHub UI; not in-repo). Required check names: `QA / just qa` and `Plugin version check / Enforce version bump and manifest parity`.

## House Rules

1. **No em-dashes or en-dashes.** Audit Check 4 enforces. Use a colon, comma, or restructure.
2. **No hardcoded counts in prose.** "18" is not allowed in tracked content; the only place a count appears is the auto-regenerated `## Leverage-point skills (N)` header in `docs/leverage-points.md`. If you need a count somewhere new, derive it.
3. **`just qa` must pass before every commit.** Pre-commit and CI both run it; the local gate prevents the round-trip.
4. **Never edit manifest versions by hand.** Always go through `just bump`. The script keeps the four manifests and `marketplace.json`'s nested field in sync; manual edits are the source of the parity failures CI then catches.
5. **Generators are idempotent.** Running a regenerator twice must produce no further diff. If you change a generator and it stops being idempotent, that is the bug.
6. **One source of truth per fact.** A fact lives in one place; everywhere else, it is derived. If you find yourself updating the same number in two files, one of them needs to be auto-generated.
7. **Conventional commits.** `feat(automation): ...`, `fix(audit): ...`, `release: v<version>`, `feat(skills): ...`, `docs(...): ...`. Match existing history.
8. **Marker-bounded auto-blocks are owned by the generator.** Anything inside `<!-- begin:... -->` and `<!-- end:... -->` will be overwritten on the next regen. Edit prose outside the markers; edit content inside the markers by changing the generator or the source frontmatter.

## Red Flags - STOP

- A new fact is being added to prose in two files at once. Pick one to be canonical and derive the other.
- A manifest version is being edited by hand in a single file. The other four will drift; CI will catch it but the round-trip wastes a PR cycle.
- A literal count (`18 leverage-point skills`, `3 operator skills`) is appearing in tracked content outside the regenerated catalog header.
- An audit check is being silenced or bypassed because it is "noisy." The fix is the underlying drift; silencing the check is how the drift compounds.
- A regenerator is being changed without re-running it twice to verify idempotence.
- A new SLP is being added without running `just regenerate-catalogs` and `just qa` before commit.
- Manifest files are being added without updating `.version-bump.json`. The bump script will silently skip them on the next release.
- Branch-protection requirements are configured but the workflow files are not present, or vice versa. The two must agree or CI is theatrical.

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "I will regenerate the catalogs later" | Later means CI fails the PR; regenerate now and commit the result |
| "I will only bump one manifest for this hotfix" | The four manifests must agree or CI fails parity; bump them all |
| "Just adding the count in prose is faster" | It is; then the count drifts the next time someone adds a skill, and you cannot remember which prose location was canonical |
| "The audit check is wrong" | The audit is mechanical; if it is wrong it is wrong on every commit. Fix the check or fix the underlying state |
| "I will skip `just qa` just this once" | The drift findings the audit catches are exactly the failures CI will then catch in a slower loop |
| "Marker comments make the markdown ugly" | They are the contract that lets generation and prose coexist; remove them and one of the two takes over by drift |
| "We do not need a maintenance skill, the scripts are self-explanatory" | Scripts answer "how"; this skill answers "when and why and in what order"; the second question is the one that decays first |

## Why This Matters

A plugin's value comes from the content (the SLPs and operators); a plugin's longevity comes from the chassis. The content gets read; the chassis gets maintained. When the chassis decays, every change becomes a drift hunt: which file is canonical, which doc was last updated, why the audit fails, why CI is red.

Without this skill, every contributor reinvents the maintenance procedure. Versions drift across manifests, catalogs go stale, cross-references silently break, the README disagrees with the canonical reference doc, and a release ships with the marketplace entry pointing at last month's plugin. Each individual failure is small; together they make the plugin look untrusted.

With this skill, the procedure is one place. A contributor adding the 19th SLP runs `just regenerate-catalogs` and `just qa`; they do not need to know which seven files would otherwise need editing. A maintainer cutting v0.2.0 runs `just bump 0.2.0`; they do not need to remember which four manifests to touch. The plugin stays consistent because consistency is automated, not voluntary.

## References

- `authoring-software-leverage-points` (sibling skill): the content contract; read it when writing SLP substance.
- `scripts/audit.sh`, `scripts/check-backlinks.sh`, `scripts/regenerate-catalogs.sh`, `scripts/bump-version.sh`: the actual mechanisms this skill describes.
- `.version-bump.json`: declares which files the bump script touches; add to this file before adding a new manifest.
- `justfile`: the discoverable entry point; recipes wrap the scripts.
- `.github/workflows/qa.yml` and `.github/workflows/plugin-version-check.yml`: the CI gates that mirror local QA.
- `RELEASE-NOTES.md`: per-release human-written summaries; the bump script stubs a TODO entry that the maintainer fills in.
- `MIGRATION.md`: historical record of how the v0.1.0 chassis was built; useful context, not a live runbook.
