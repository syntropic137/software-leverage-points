#!/usr/bin/env bash
#
# sync-to-codex-plugin.sh
#
# Sync the .claude-plugin/plugin.json content into .codex-plugin/plugin.json.
# These two manifests share the same name, version, description, and author
# fields, so the Claude manifest is treated as the source of truth and the
# Codex manifest is regenerated to match (preserving Codex-only fields like
# `interface`, `keywords`, `skills`, `homepage`, `repository`, `license`).
#
# Usage:
#   ./scripts/sync-to-codex-plugin.sh           # apply sync
#   ./scripts/sync-to-codex-plugin.sh --check   # report drift, exit non-zero if any
#
# Requires: bash, jq.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_MANIFEST="$REPO_ROOT/.claude-plugin/plugin.json"
CODEX_MANIFEST="$REPO_ROOT/.codex-plugin/plugin.json"

# Fields that should be mirrored from .claude-plugin/plugin.json into
# .codex-plugin/plugin.json. Anything else stays as-is in the Codex manifest.
SHARED_FIELDS=(name version description author)

die() { echo "ERROR: $*" >&2; exit 1; }

command -v jq >/dev/null || die "jq not found in PATH"
[[ -f "$CLAUDE_MANIFEST" ]] || die "missing $CLAUDE_MANIFEST"
[[ -f "$CODEX_MANIFEST" ]]  || die "missing $CODEX_MANIFEST"

CHECK=0
case "${1:-}" in
  --check) CHECK=1 ;;
  "")      ;;
  -h|--help)
    sed -n '/^# Usage:/,/^# Requires:/s/^# \{0,1\}//p' "$0"
    exit 0
    ;;
  *) die "unknown arg: $1" ;;
esac

# Compare each shared field, report drift.
drift=0
for field in "${SHARED_FIELDS[@]}"; do
  claude_val=$(jq -c ".$field" "$CLAUDE_MANIFEST")
  codex_val=$(jq -c ".$field" "$CODEX_MANIFEST")
  if [[ "$claude_val" != "$codex_val" ]]; then
    echo "drift: $field"
    echo "  claude: $claude_val"
    echo "  codex:  $codex_val"
    drift=1
  fi
done

if [[ $CHECK -eq 1 ]]; then
  if [[ $drift -eq 0 ]]; then
    echo "In sync: shared fields match between $CLAUDE_MANIFEST and $CODEX_MANIFEST."
    exit 0
  else
    echo ""
    echo "Run without --check to sync."
    exit 1
  fi
fi

if [[ $drift -eq 0 ]]; then
  echo "Already in sync. Nothing to do."
  exit 0
fi

# Build a jq filter that copies each shared field from the Claude manifest
# (passed as $src) into the Codex manifest.
filter='.'
for field in "${SHARED_FIELDS[@]}"; do
  filter+=" | .$field = (\$src.$field)"
done

tmp="${CODEX_MANIFEST}.tmp"
jq --slurpfile srcArr "$CLAUDE_MANIFEST" "$filter" \
  --argjson dummy 0 \
  --arg dummy2 "" \
  "$CODEX_MANIFEST" > /dev/null 2>&1 || true

# Use a simpler jq invocation: load source with --slurpfile to get $src[0].
jq --slurpfile src "$CLAUDE_MANIFEST" '
  . as $codex
  | $src[0] as $s
  | $codex
    | .name        = $s.name
    | .version     = $s.version
    | .description = $s.description
    | .author      = $s.author
' "$CODEX_MANIFEST" > "$tmp" && mv "$tmp" "$CODEX_MANIFEST"

echo "Synced shared fields from $CLAUDE_MANIFEST -> $CODEX_MANIFEST."
