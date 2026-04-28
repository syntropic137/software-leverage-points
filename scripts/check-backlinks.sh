#!/usr/bin/env bash
# check-backlinks.sh: verify SLP-to-SLP cross-references are bidirectional.
#
# An SLP "A" references SLP "B" when A's SKILL.md uses one of the canonical
# cross-reference forms:
#   `B` skill         (the current canonical phrasing)
#   `B` lens          (legacy phrasing; kept for transition)
#   `B` SLP           (legacy phrasing; kept for transition)
#   skills/B/         (absolute-style path reference)
#   ../B/SKILL.md     (relative-link path; only the SKILL.md target counts)
#
# A bare backtick mention `B` without one of those suffixes is treated as a
# topical mention, not a cross-reference, to avoid false positives from SLPs
# listing concerns by name without intending a cross-link.
#
# When A -> B exists but B -> A does not, the relationship is asymmetric and
# this script reports the missing back-edge. It does not auto-fix; the author
# decides whether to add the cross-link or remove the original.
#
# Operator skills (software-leverage-review, skill-builder, skill-auditor) are
# excluded from the SLP set: they are procedural, not principle docs, so they
# legitimately reference SLPs without being referenced back.
#
# Exit 0 if symmetric, 1 if asymmetric edges exist.

set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

OPERATOR_REGEX='^(software-leverage-review|skill-builder|skill-auditor)$'

SLPS=()
while IFS= read -r dir; do
  name=$(basename "$dir")
  if [[ ! "$name" =~ $OPERATOR_REGEX ]]; then
    SLPS+=("$name")
  fi
done < <(find skills -mindepth 1 -maxdepth 1 -type d | sort)

# Build the directed edge list as plain text: one "A B" line per A -> B edge.
EDGES=$(mktemp)
trap 'rm -f "$EDGES"' EXIT

for a in "${SLPS[@]}"; do
  src="skills/$a/SKILL.md"
  [[ -f "$src" ]] || continue
  for b in "${SLPS[@]}"; do
    [[ "$a" == "$b" ]] && continue
    if grep -qE "(\`$b\` (skill|lens|SLP)|skills/$b/|\.\./$b/SKILL\.md)" "$src"; then
      printf '%s %s\n' "$a" "$b" >> "$EDGES"
    fi
  done
done

# An edge "A B" is asymmetric if "B A" is not in the file.
ASYMMETRIC=()
while IFS=' ' read -r a b; do
  if ! grep -qE "^${b} ${a}$" "$EDGES"; then
    ASYMMETRIC+=("$a -> $b (missing back-edge $b -> $a)")
  fi
done < "$EDGES"

if [[ ${#ASYMMETRIC[@]} -eq 0 ]]; then
  printf 'OK: all SLP cross-references are bidirectional (%d SLPs scanned)\n' "${#SLPS[@]}"
  exit 0
fi

printf 'FAIL: %d asymmetric SLP cross-reference(s) found:\n' "${#ASYMMETRIC[@]}"
for edge in "${ASYMMETRIC[@]}"; do
  printf '  %s\n' "$edge"
done
echo ""
echo "Fix: add the missing back-reference in the target SLP's SKILL.md, or remove the original reference."
exit 1
