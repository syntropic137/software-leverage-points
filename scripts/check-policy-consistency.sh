#!/usr/bin/env bash
# Check that the canonical severity-action policy and its consumers stay in sync.
# Wired into `just qa`. Fails loud on drift.
#
# Canonical: skills/software-leverage-review/severity-action-policy.md
# Consumers checked:
#   - skills/software-leverage-review/common-types.yaml
#   - skills/software-leverage-review/slp-output-schema.yaml
#   - skills/software-leverage-review/orchestrator-output-schema.yaml
#   - scripts/validate-output.ts
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$ROOT/skills/software-leverage-review/severity-action-policy.md"
COMMON_YAML="$ROOT/skills/software-leverage-review/common-types.yaml"
SLP_YAML="$ROOT/skills/software-leverage-review/slp-output-schema.yaml"
ORCH_YAML="$ROOT/skills/software-leverage-review/orchestrator-output-schema.yaml"
VALIDATOR="$ROOT/scripts/validate-output.ts"

EXPECTED_SEVERITIES=(critical high medium low info)
EXPECTED_EFFORTS=(small medium large)
EXPECTED_ACTIONS=(auto-fix promote bulk)

failures=0
fail() { echo "FAIL: $*" >&2; failures=$((failures + 1)); }

# --- 1. Canonical exists and lists every enum value ---
[ -f "$POLICY" ] || { fail "canonical policy missing: $POLICY"; exit 1; }

for v in "${EXPECTED_SEVERITIES[@]}"; do
  grep -q "^| \*\*$v\*\* |" "$POLICY" || fail "policy missing severity row for: $v"
done
for v in "${EXPECTED_EFFORTS[@]}"; do
  grep -q "^| \*\*$v\*\* |" "$POLICY" || fail "policy missing effort row for: $v"
done
for v in "${EXPECTED_ACTIONS[@]}"; do
  grep -q "^| \*\*$v\*\* |" "$POLICY" || fail "policy missing action row for: $v"
done

# --- 2. common-types.yaml enum lines match canonical ---
if grep -q "^    enum: \[critical, high, medium, low, info\]" "$COMMON_YAML"; then :; else
  fail "common-types.yaml severity enum drifted from policy (expected: [critical, high, medium, low, info])"
fi
if grep -q "^    enum: \[small, medium, large\]" "$COMMON_YAML"; then :; else
  fail "common-types.yaml effort enum drifted from policy (expected: [small, medium, large])"
fi
if grep -q "^    enum: \[auto-fix, promote, bulk\]" "$COMMON_YAML"; then :; else
  fail "common-types.yaml action enum drifted from policy (expected: [auto-fix, promote, bulk])"
fi

# --- 3. common-types.yaml does not still reference legacy enum values ---
for legacy in error warn now next someday priority; do
  if grep "^    enum:" "$COMMON_YAML" | grep -q "\b$legacy\b"; then
    fail "common-types.yaml still references legacy enum value: $legacy"
  fi
done

# --- 4. validate-output.ts SEVERITIES and EFFORTS arrays match canonical ---
if grep -q 'const SEVERITIES = \["critical", "high", "medium", "low", "info"\];' "$VALIDATOR"; then :; else
  fail "scripts/validate-output.ts SEVERITIES drifted from policy"
fi
if grep -q 'const EFFORTS = \["small", "medium", "large"\];' "$VALIDATOR"; then :; else
  fail "scripts/validate-output.ts EFFORTS drifted from policy"
fi
if grep -q 'const ACTIONS = \["auto-fix", "promote", "bulk"\];' "$VALIDATOR"; then :; else
  fail "scripts/validate-output.ts ACTIONS drifted from policy"
fi

# --- 5. consumers reference the canonical policy explicitly ---
ORCHESTRATOR_SKILL="$ROOT/skills/software-leverage-review/SKILL.md"
LENS_PROMPT="$ROOT/skills/software-leverage-review/prompt_review-one-software-leverage-point.md"
grep -q "severity-action-policy.md" "$ORCHESTRATOR_SKILL" || fail "orchestrator SKILL.md does not reference severity-action-policy.md"
grep -q "severity-action-policy.md" "$LENS_PROMPT" || fail "lens subagent prompt does not reference severity-action-policy.md"
grep -q "severity-action-policy.md" "$COMMON_YAML" || fail "common-types.yaml does not reference severity-action-policy.md"
grep -q "severity-action-policy.md" "$SLP_YAML" || fail "slp-output-schema.yaml does not reference severity-action-policy.md"
grep -q "severity-action-policy.md" "$ORCH_YAML" || fail "orchestrator-output-schema.yaml does not reference severity-action-policy.md"

if [ "$failures" -eq 0 ]; then
  echo "OK: severity-action policy and consumers are consistent (5 severities, 3 efforts, 3 actions)"
  exit 0
fi
echo "policy-consistency: $failures FAILURE(S)" >&2
exit 1
