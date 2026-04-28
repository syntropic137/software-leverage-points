#!/usr/bin/env bash
# audit.sh: deterministic cross-doc drift checks for software-leverage-points.
#
# Runs the mechanical subset of skill-auditor's checks (no agent reasoning):
#   1. Leverage-point count consistency across README, MIGRATION,
#      docs/leverage-points.md, and skills/ subdirectory count.
#   2. Version-string consistency across the four plugin manifests.
#   3. Broken-link integrity for relative .md paths in skill/doc/root files.
#   4. Em-dash sweep (project rule: zero em-dashes in authored content).
#
# Exit 0 if all checks PASS, 1 otherwise. Each check prints OK or FAIL.
#
# Invoke from any directory inside the repo:
#   ./scripts/audit.sh
#
# Dependencies: bash, grep, find, awk, sed, sort, wc. Optional: jq.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

FAIL=0
note_fail() { FAIL=1; printf 'FAIL: %s\n' "$1"; }
note_ok()   { printf 'OK: %s\n' "$1"; }

# -----------------------------------------------------------------------------
# Check 1: Leverage-point count consistency.
# -----------------------------------------------------------------------------
OPERATOR_SKILLS_REGEX='^(software-leverage-review|skill-builder|skill-auditor)$'
TOTAL_SKILLS=$(find skills -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ')
OPERATOR_COUNT=0
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [[ "$name" =~ $OPERATOR_SKILLS_REGEX ]]; then
    OPERATOR_COUNT=$((OPERATOR_COUNT + 1))
  fi
done < <(find skills -mindepth 1 -maxdepth 1 -type d)
LP_COUNT=$((TOTAL_SKILLS - OPERATOR_COUNT))

# LP_COUNT is derived from the filesystem; downstream cross-doc checks
# (README, MIGRATION, docs/leverage-points.md) assert that the docs match
# whatever the filesystem has. Adding or removing an SLP directory updates
# LP_COUNT automatically; the docs must be regenerated to stay in sync.
note_ok "skills/ contains $LP_COUNT leverage-point skills (excluding $OPERATOR_COUNT operator skills)"

if grep -q "$LP_COUNT leverage-point skills" README.md; then
  note_ok "README.md mentions $LP_COUNT leverage-point skills"
else
  note_fail "README.md does not mention '$LP_COUNT leverage-point skills'"
fi

if grep -q "## Leverage-point skills ($LP_COUNT)" docs/leverage-points.md; then
  note_ok "docs/leverage-points.md catalog header lists $LP_COUNT"
else
  note_fail "docs/leverage-points.md catalog header does not list $LP_COUNT"
fi

if grep -q "= $LP_COUNT" MIGRATION.md; then
  note_ok "MIGRATION.md reconciliation line mentions = $LP_COUNT"
else
  note_fail "MIGRATION.md reconciliation line missing '= $LP_COUNT'"
fi

SHIPPED_HITS=$(grep -o 'shipped (v0.1)' docs/leverage-points.md | wc -l | tr -d ' ')
EXPECTED_SHIPPED=$((LP_COUNT + 3))
if [[ "$SHIPPED_HITS" -ne "$EXPECTED_SHIPPED" ]]; then
  note_fail "docs/leverage-points.md has $SHIPPED_HITS 'shipped (v0.1)' mentions, expected $EXPECTED_SHIPPED ($LP_COUNT LPs + 3 operators)"
else
  note_ok "docs/leverage-points.md has $SHIPPED_HITS 'shipped (v0.1)' mentions"
fi

# -----------------------------------------------------------------------------
# Check 2: Version-string consistency.
# -----------------------------------------------------------------------------
MANIFESTS=(
  ".claude-plugin/plugin.json"
  ".codex-plugin/plugin.json"
  ".cursor-plugin/plugin.json"
  "gemini-extension.json"
)

extract_version() {
  local file="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -r '.version' "$file"
  else
    grep -E '"version"[[:space:]]*:' "$file" | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/'
  fi
}

VERSIONS=()
for m in "${MANIFESTS[@]}"; do
  if [[ ! -f "$m" ]]; then
    note_fail "manifest missing: $m"
    continue
  fi
  v=$(extract_version "$m")
  VERSIONS+=("$m=$v")
done

UNIQUE_VERSIONS=$(printf '%s\n' "${VERSIONS[@]}" | awk -F= '{print $2}' | sort -u | wc -l | tr -d ' ')
if [[ "$UNIQUE_VERSIONS" -eq 1 ]]; then
  note_ok "all manifests share version $(printf '%s\n' "${VERSIONS[@]}" | awk -F= '{print $2}' | head -1)"
else
  note_fail "version mismatch across manifests: ${VERSIONS[*]}"
fi

# -----------------------------------------------------------------------------
# Check 3: Broken-link integrity for relative .md paths.
# -----------------------------------------------------------------------------
SCAN_TARGETS=(
  README.md
  MIGRATION.md
  RELEASE-NOTES.md
)
while IFS= read -r f; do SCAN_TARGETS+=("$f"); done < <(find skills docs -type f -name '*.md')

BROKEN=0
BROKEN_FIRST=""
for f in "${SCAN_TARGETS[@]}"; do
  [[ -f "$f" ]] || continue
  dir=$(dirname "$f")
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    # strip anchors
    clean=${target%%#*}
    [[ -z "$clean" ]] && continue
    if [[ "$clean" = /* ]]; then
      resolved="$ROOT$clean"
    else
      resolved="$dir/$clean"
    fi
    if [[ ! -e "$resolved" ]]; then
      BROKEN=$((BROKEN + 1))
      [[ -z "$BROKEN_FIRST" ]] && BROKEN_FIRST="$f -> $target"
    fi
  done < <(grep -oE '\]\(([^)]+\.(md|json|ts|sh))\)' "$f" 2>/dev/null | sed -E 's/\]\(([^)]+)\)/\1/' | grep -vE '^https?://' || true)
done

if [[ "$BROKEN" -eq 0 ]]; then
  note_ok "all relative markdown/json/ts/sh links resolve"
else
  note_fail "$BROKEN broken relative links (first: $BROKEN_FIRST)"
fi

# -----------------------------------------------------------------------------
# Check 4: Em-dash sweep.
# -----------------------------------------------------------------------------
EM_HITS=$(grep -rn $'\xe2\x80\x94\|\xe2\x80\x93' skills docs README.md MIGRATION.md RELEASE-NOTES.md 2>/dev/null || true)
if [[ -z "$EM_HITS" ]]; then
  note_ok "no em-dashes or en-dashes in tracked content"
else
  note_fail "em-dash or en-dash found:"
  printf '%s\n' "$EM_HITS"
  FAIL=1
fi

# -----------------------------------------------------------------------------
# Summary.
# -----------------------------------------------------------------------------
if [[ "$FAIL" -eq 0 ]]; then
  echo ""
  echo "audit.sh: ALL CHECKS PASS"
  exit 0
else
  echo ""
  echo "audit.sh: ONE OR MORE CHECKS FAILED"
  exit 1
fi
