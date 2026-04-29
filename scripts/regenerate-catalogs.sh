#!/usr/bin/env bash
# regenerate-catalogs.sh: rewrite marker-bounded blocks in docs/leverage-points.md
# and README.md from skills/*/SKILL.md frontmatter. Idempotent and safe to re-run.
#
# Source of truth: each skills/<name>/SKILL.md frontmatter (the `name:` field).
# Classification: operator skills are software-leverage-review, skill-builder,
# skill-auditor; everything else is an SLP.
#
# Lens references are read from skills/software-leverage-review/references/*.md
# (a fixed location).
#
# Markers in docs/leverage-points.md:
#   <!-- begin:operator-catalog --> ... <!-- end:operator-catalog -->
#   <!-- begin:slp-catalog -->      ... <!-- end:slp-catalog -->
#   <!-- begin:lens-catalog -->     ... <!-- end:lens-catalog -->
#
# Exit 0 on success. The script writes in place; pair with `git diff --exit-code`
# in pre-commit hooks or CI to detect stale output.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

CATALOG_FILE="docs/leverage-points.md"
README_FILE="README.md"
OPERATOR_REGEX='^(software-leverage-review|skill-builder|skill-auditor)$'

# -----------------------------------------------------------------------------
# Build sorted lists of operator and SLP skill names.
# -----------------------------------------------------------------------------
OPERATORS=()
SLPS=()
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [[ "$name" =~ $OPERATOR_REGEX ]]; then
    OPERATORS+=("$name")
  else
    SLPS+=("$name")
  fi
done < <(find skills -mindepth 1 -maxdepth 1 -type d | sort)

# Stable order: operators by canonical sequence, SLPs alphabetical.
# The canonical operator order (review, builder, auditor) reflects the
# typical workflow: review first, then bootstrap missing L2s, then audit drift.
OPERATOR_ORDER=("software-leverage-review" "skill-builder" "skill-auditor")
SORTED_OPERATORS=()
for op in "${OPERATOR_ORDER[@]}"; do
  for found in "${OPERATORS[@]:-}"; do
    if [[ "$found" == "$op" ]]; then
      SORTED_OPERATORS+=("$op")
    fi
  done
done

SORTED_SLPS=()
while IFS= read -r s; do SORTED_SLPS+=("$s"); done < <(printf '%s\n' "${SLPS[@]:-}" | sort)

# -----------------------------------------------------------------------------
# Helpers.
# -----------------------------------------------------------------------------
extract_description() {
  local file="$1"
  awk '/^---$/{c++; next} c==1 && /^description:/{
    sub(/^description:[[:space:]]*/, "")
    sub(/^"/, "")
    sub(/"$/, "")
    print
    exit
  }' "$file"
}

# Short purpose summaries for operator skills (hand-curated; operator skills
# are a fixed set of 3, so these do not need to be auto-derived).
operator_purpose() {
  case "$1" in
    software-leverage-review) echo "Orchestrator: fans out subagents per leverage point, synthesizes findings using lens references" ;;
    skill-builder)            echo "Bootstrap repo-specific (L2) skills from generic (L1) meta-skills, customized per repo's stack" ;;
    skill-auditor)            echo "Detect drift between L2 skills and current code/docs; flag the kind of cross-doc inconsistency the evals keep finding" ;;
    *)                        echo "" ;;
  esac
}

# -----------------------------------------------------------------------------
# Build the three table blocks.
# -----------------------------------------------------------------------------
build_operator_table() {
  printf '| Skill | Purpose |\n'
  printf '|---|---|\n'
  for op in "${SORTED_OPERATORS[@]}"; do
    printf '| [`%s`](../skills/%s/SKILL.md) | %s |\n' "$op" "$op" "$(operator_purpose "$op")"
  done
}

build_slp_table() {
  local count=${#SORTED_SLPS[@]}
  printf '## Leverage-point skills (%s)\n\n' "$count"
  printf '| LP |\n'
  printf '|---|\n'
  for slp in "${SORTED_SLPS[@]}"; do
    printf '| [%s](../skills/%s/SKILL.md) |\n' "$slp" "$slp"
  done
}

lens_title() {
  case "$1" in
    dry)                     echo "DRY" ;;
    principles-and-patterns) echo "Principles and patterns" ;;
    software-complexity)     echo "Software complexity" ;;
    *)                       echo "$1" ;;
  esac
}

build_readme_slp_list() {
  for slp in "${SORTED_SLPS[@]}"; do
    src="skills/$slp/SKILL.md"
    desc=""
    [[ -f "$src" ]] && desc=$(extract_description "$src")
    if [[ -n "$desc" ]]; then
      printf -- '- **[%s](skills/%s/SKILL.md)**: %s\n' "$slp" "$slp" "$desc"
    else
      printf -- '- **[%s](skills/%s/SKILL.md)**\n' "$slp" "$slp"
    fi
  done
}

build_lens_table() {
  printf '| Lens | File |\n'
  printf '|---|---|\n'
  for f in skills/software-leverage-review/references/*.md; do
    [[ -f "$f" ]] || continue
    base=$(basename "$f" .md)
    printf '| %s | `%s` |\n' "$(lens_title "$base")" "$f"
  done
}

# -----------------------------------------------------------------------------
# Replace marker-bounded blocks in CATALOG_FILE.
# -----------------------------------------------------------------------------
replace_block() {
  local file="$1" begin_marker="$2" end_marker="$3" content_file="$4"
  local tmp
  tmp=$(mktemp)
  awk -v begin="$begin_marker" -v end="$end_marker" -v cf="$content_file" '
    index($0, begin) {
      print
      while ((getline line < cf) > 0) print line
      close(cf)
      in_block=1
      next
    }
    index($0, end) { in_block=0; print; next }
    !in_block      { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

OP_FILE=$(mktemp)
SLP_FILE=$(mktemp)
LENS_FILE=$(mktemp)
README_SLP_FILE=$(mktemp)
trap 'rm -f "$OP_FILE" "$SLP_FILE" "$LENS_FILE" "$README_SLP_FILE"' EXIT

build_operator_table   > "$OP_FILE"
build_slp_table        > "$SLP_FILE"
build_lens_table       > "$LENS_FILE"
build_readme_slp_list  > "$README_SLP_FILE"

replace_block "$CATALOG_FILE" '<!-- begin:operator-catalog -->' '<!-- end:operator-catalog -->' "$OP_FILE"
replace_block "$CATALOG_FILE" '<!-- begin:slp-catalog -->'      '<!-- end:slp-catalog -->'      "$SLP_FILE"
replace_block "$CATALOG_FILE" '<!-- begin:lens-catalog -->'     '<!-- end:lens-catalog -->'     "$LENS_FILE"
replace_block "$README_FILE"  '<!-- begin:readme-slp-catalog -->' '<!-- end:readme-slp-catalog -->' "$README_SLP_FILE"

# -----------------------------------------------------------------------------
# Generate the SLP manifest consumed by the software-leverage-review orchestrator.
# The orchestrator iterates over this manifest (not over filesystem siblings) so
# unrelated skills installed in the same scope cannot be invoked as SLPs.
# -----------------------------------------------------------------------------
MANIFEST_FILE="skills/software-leverage-review/slp-manifest.yaml"
{
  echo "# Software Leverage Point Manifest"
  echo "#"
  echo "# AUTO-GENERATED by scripts/regenerate-catalogs.sh from the SLP skill directories."
  echo "# DO NOT EDIT BY HAND. Regenerate via \`just regenerate-catalogs\`."
  echo "#"
  echo "# This file is the canonical list of SLPs available to the software-leverage-review"
  echo "# orchestrator. The orchestrator iterates over this manifest, NOT over filesystem"
  echo "# listing of sibling directories. Decoupling membership from filesystem layout"
  echo "# prevents unrelated skills installed in the same scope (other plugins,"
  echo "# project-local skills, globally-installed skills) from being accidentally"
  echo "# invoked as SLPs."
  echo "#"
  echo "# Cross-cutting SLPs (dry, principles-and-patterns, software-complexity) are"
  echo "# identified separately in ./common-types.yaml's CrossCuttingSLP enum."
  echo ""
  echo "version: 1"
  echo "generated_by: scripts/regenerate-catalogs.sh"
  echo "slps:"
  for slp in "${SORTED_SLPS[@]}"; do
    echo "  - $slp"
  done
} > "$MANIFEST_FILE"

echo "regenerate-catalogs.sh: wrote ${#SORTED_OPERATORS[@]} operators, ${#SORTED_SLPS[@]} SLPs, $(ls skills/software-leverage-review/references/*.md 2>/dev/null | wc -l | tr -d ' ') lens refs to $CATALOG_FILE and $README_FILE; wrote SLP manifest to $MANIFEST_FILE"
