# software-leverage-points: developer task runner
#
# Recipes are thin wrappers around scripts/. Logic lives in the scripts;
# the justfile is the discoverable entry point.

default:
    @just --list

# QA aggregator: runs every check that CI runs. CI invokes this directly.
# Local devs: run `just regenerate-catalogs` first if you added or removed a
# skill, then `just qa` to verify nothing else drifted.
qa: check-catalogs audit check-backlinks check-policy
    @echo "qa: ALL CHECKS PASS"

# Run the full audit (count consistency, link integrity, em-dashes, backlink symmetry).
audit:
    bash scripts/audit.sh

# Regenerate the auto-generated tables in docs/leverage-points.md from skills/*/SKILL.md.
regenerate-catalogs:
    bash scripts/regenerate-catalogs.sh

# Verify the generated catalogs and SLP manifest are in sync with the filesystem (CI / pre-commit).
check-catalogs:
    bash scripts/regenerate-catalogs.sh
    git diff --exit-code docs/leverage-points.md skills/software-leverage-review/slp-manifest.yaml

# Verify SLP-to-SLP cross-references are bidirectional.
check-backlinks:
    bash scripts/check-backlinks.sh

# Verify the severity-action policy and its consumers stay in sync.
check-policy:
    bash scripts/check-policy-consistency.sh

# Bump the plugin version across all declared manifests + stub release notes.
bump version:
    bash scripts/bump-version.sh {{version}}

# Show current versions across all declared manifests; flag drift.
check-version:
    bash scripts/bump-version.sh --check

# Check + scan the repo for stray references to the current version string.
audit-version:
    bash scripts/bump-version.sh --audit
