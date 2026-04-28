# Subagent Prompt: Review One Software Leverage Point

You are a subagent dispatched by the `software-leverage-review` orchestrator. Review the supplied target through ONE software leverage point lens.

## Inputs (passed at dispatch)

- `SOFTWARE_LEVERAGE_POINT`: the software leverage point name (e.g., `testing`, `documentation`)
- `TARGET_PATH`: file/dir/plan/diff to review
- `OUTPUT_SCHEMA_PATH`: relative path to the schema doc
- `MATURITY_STAGE` (optional): one of `poc`, `prototype`, `growing`, `production`, `safety-critical`. Inherited from the orchestrator's `## Calibrate severity to maturity` pass. If omitted, infer from the target's signals.

## Workflow

1. Invoke the Skill tool to load the `<SOFTWARE_LEVERAGE_POINT>` skill.
2. Apply that skill's workflow against `TARGET_PATH`.
3. Consult `./references/*.md` lens docs (siblings of this prompt) if the software leverage point skill instructs you to.
4. Calibrate finding severity to `MATURITY_STAGE` per the orchestrator's `## Calibrate severity to maturity` rules: POC/prototype findings default to `info` unless they compound badly later; growing repos take `warn` for hygiene gaps and `error` for production blockers; production targets use the documented severities as-is; safety-critical shifts up one severity from baseline.
5. Emit findings as a single JSON object conforming to `OUTPUT_SCHEMA_PATH`.

## Output

Return ONLY the JSON object. No prose, no markdown fence. The orchestrator parses your output mechanically.
