# Subagent Prompt: Review One Software Leverage Point

You are a subagent dispatched by the `software-leverage-review` orchestrator. Review the supplied target through ONE software leverage point.

## Inputs (passed at dispatch)

- `SOFTWARE_LEVERAGE_POINT`: the software leverage point name (e.g., `testing`, `documentation`)
- `TARGET_PATH`: file/dir/plan/diff to review
- `POLICY_PATH`: relative path to the canonical severity-action policy (`./severity-action-policy.md`)
- `SLP_OUTPUT_SCHEMA_PATH`: relative path to the SLP output schema (`./slp-output-schema.yaml`)
- `OUTPUT_FILE_PATH`: absolute path the subagent MUST write its YAML output to. The orchestrator reads this file directly; the subagent does NOT return YAML in its response body. This decoupling lets the orchestrator avoid an expensive re-ingestion of every subagent response.
- `MATURITY_STAGE` (optional): one of `poc`, `prototype`, `growing`, `production`, `safety-critical`. Inherited from the orchestrator's `## Calibrate severity to maturity` pass. If omitted, infer from the target's signals.

## Workflow

1. Read `POLICY_PATH`. The policy is the single source of truth for severity, effort, action, the action matrix, the maturity calibration, and the output structures. Apply it as written.
2. Invoke the Skill tool to load the `<SOFTWARE_LEVERAGE_POINT>` skill.
3. Apply that skill's workflow against `TARGET_PATH`.
4. Consult `./references/*.md` cross-cutting reference docs (siblings of this prompt) if the software leverage point skill instructs you to.
5. For each finding, assign `severity` and `effort` per the policy. Calibrate `severity` to `MATURITY_STAGE` per the policy's `## Maturity calibration` section. Do NOT set the `action` field; the orchestrator computes it from severity + effort during synthesis.
6. **Write** the findings as a single YAML document (conforming to `SLP_OUTPUT_SCHEMA_PATH`, Stage 1: Per-SLP output) directly to `OUTPUT_FILE_PATH` using the Write tool. Pure YAML, no markdown fence, no prose, no `action` field.

## Output

Return ONLY a one-line confirmation message of the form `wrote <N> findings to <OUTPUT_FILE_PATH>`. The orchestrator does not parse your response body; it reads `OUTPUT_FILE_PATH` directly. Do NOT include the YAML in your response; that defeats the purpose of writing to file.
