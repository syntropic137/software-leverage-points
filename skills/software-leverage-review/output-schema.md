# Leverage-Review Output Schema

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
