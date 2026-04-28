# Leverage-Review Output Schema

> **Schema validator:** see `output-schema.json` (draft-07) for the formal JSON Schema. Validate a finding-output JSON file with:
> ```
> bun scripts/validate-output.ts --file path/to/output.json
> ```
> Run from the repo root. The markdown below is the human-readable version; the JSON Schema is authoritative.

All software leverage point skills and the auditor emit findings conforming to this shape:

```json
{
  "software_leverage_point": "<software-leverage-point-name>",
  "findings": [
    {
      "severity": "error" | "warn" | "info",
      "file": "<path>",
      "line": <number, optional>,
      "issue": "<short description>",
      "suggested_fix": "<actionable suggestion>",
      "lens_violations": ["dry" | "principles-and-patterns" | "software-complexity"]
    }
  ],
  "summary": "<1-2 sentence overall assessment>"
}
```

Severity guidance:
- `error`: violates a hard rule or breaks behavior
- `warn`: violates a guideline; reasonable to defer with justification
- `info`: observation, no action required

`lens_violations` is optional; populate when a finding maps to a cross-cutting lens.
