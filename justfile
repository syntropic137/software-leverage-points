# software-leverage-points: developer task runner
#
# Recipes are thin wrappers around scripts/. Logic lives in the scripts;
# the justfile is the discoverable entry point.

default:
    @just --list

# Run the full audit (count consistency, link integrity, em-dashes, backlink symmetry).
audit:
    bash scripts/audit.sh

# Regenerate the auto-generated tables in docs/leverage-points.md from skills/*/SKILL.md.
regenerate-catalogs:
    bash scripts/regenerate-catalogs.sh

# Verify the generated catalogs are in sync with the filesystem (CI / pre-commit).
check-catalogs:
    bash scripts/regenerate-catalogs.sh
    git diff --exit-code docs/leverage-points.md

# Verify SLP-to-SLP cross-references are bidirectional.
check-backlinks:
    bash scripts/check-backlinks.sh
