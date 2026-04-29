#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Verify Stage 1 outputs (per-SLP raw-findings YAML) against the schema and
the manifest. Used by the orchestrator after Stage 1 fan-out to detect:

  1. Health gap: fewer than the manifest-listed N SLPs returned a file.
  2. Schema drift: an SLP wrapped its YAML in a markdown fence, set the
     forbidden `action` field, used an invalid severity/effort enum value,
     or omitted a required field.

Exit code:
  0 if every manifest SLP has a valid raw-findings file.
  1 if any SLP is missing or invalid.

Stdout is a JSON document with shape:

  {
    "healthy": <bool>,
    "expected_count": <int>,
    "received_count": <int>,
    "valid": ["<slp>", ...],
    "invalid": [{"slp": "...", "issues": ["..."]}],
    "missing": ["<slp>", ...]
  }

The orchestrator's workflow consumes this to decide whether to retry the
invalid/missing SLPs or fail loud with a partial-coverage signal.

Usage:
    verify-stage1.py <raw-findings-dir> <slp-manifest.yaml>
"""
import json
import sys
import yaml
from pathlib import Path


VALID_SEVERITY = {"critical", "high", "medium", "low", "info"}
VALID_EFFORT = {"small", "medium", "large"}
REQUIRED_FINDING_FIELDS = ("severity", "effort", "issue", "suggested_fix")
REQUIRED_TOP_LEVEL = ("software_leverage_point", "findings", "summary")


def validate_one(slp_name: str, path: Path) -> list[str]:
    """Validate one per-SLP raw-findings YAML file. Returns a list of issue strings (empty = valid)."""
    issues: list[str] = []
    if not path.exists():
        return [f"file does not exist: {path}"]

    raw = path.read_text()
    # Catch markdown-fence wrapping. The contents inside the fence may be
    # valid YAML but the wrapper itself is a contract violation.
    stripped = raw.lstrip()
    if stripped.startswith("```"):
        issues.append("output wrapped in markdown fence (forbidden)")

    try:
        doc = yaml.safe_load(raw)
    except yaml.YAMLError as e:
        return [f"YAML parse error: {e}"]

    if not isinstance(doc, dict):
        return [f"top-level YAML is not a mapping (got {type(doc).__name__})"]

    for k in REQUIRED_TOP_LEVEL:
        if k not in doc:
            issues.append(f"missing required top-level field '{k}'")

    if doc.get("software_leverage_point") and doc["software_leverage_point"] != slp_name:
        issues.append(
            f"software_leverage_point mismatch: file is for '{slp_name}' "
            f"but document says '{doc['software_leverage_point']}'"
        )

    findings = doc.get("findings")
    if not isinstance(findings, list):
        issues.append("'findings' must be a list")
    else:
        for i, f in enumerate(findings):
            if not isinstance(f, dict):
                issues.append(f"findings[{i}] is not a mapping")
                continue
            if "action" in f:
                issues.append(
                    f"findings[{i}] has 'action' field "
                    "(Stage 1 forbidden; orchestrator computes action at Stage 1.5)"
                )
            for k in REQUIRED_FINDING_FIELDS:
                if k not in f:
                    issues.append(f"findings[{i}] missing required field '{k}'")
            if "severity" in f and f["severity"] not in VALID_SEVERITY:
                issues.append(
                    f"findings[{i}].severity '{f['severity']}' "
                    f"not in {sorted(VALID_SEVERITY)}"
                )
            if "effort" in f and f["effort"] not in VALID_EFFORT:
                issues.append(
                    f"findings[{i}].effort '{f['effort']}' "
                    f"not in {sorted(VALID_EFFORT)}"
                )
            if "issue" in f and (not isinstance(f["issue"], str) or not f["issue"].strip()):
                issues.append(f"findings[{i}].issue must be non-empty string")
            if "suggested_fix" in f and (not isinstance(f["suggested_fix"], str) or not f["suggested_fix"].strip()):
                issues.append(f"findings[{i}].suggested_fix must be non-empty string")
    return issues


def main():
    if len(sys.argv) != 3:
        print("usage: verify-stage1.py <raw-findings-dir> <slp-manifest.yaml>", file=sys.stderr)
        sys.exit(2)
    raw_dir = Path(sys.argv[1])
    manifest_path = Path(sys.argv[2])

    if not raw_dir.is_dir():
        print(f"raw-findings dir does not exist: {raw_dir}", file=sys.stderr)
        sys.exit(2)
    if not manifest_path.is_file():
        print(f"manifest file does not exist: {manifest_path}", file=sys.stderr)
        sys.exit(2)

    with manifest_path.open() as f:
        manifest = yaml.safe_load(f) or {}
    expected_slps: list[str] = manifest.get("slps") or []

    valid: list[str] = []
    invalid: list[dict] = []
    missing: list[str] = []

    for slp in expected_slps:
        path = raw_dir / f"{slp}.yaml"
        if not path.exists():
            missing.append(slp)
            continue
        issues = validate_one(slp, path)
        if issues:
            invalid.append({"slp": slp, "issues": issues})
        else:
            valid.append(slp)

    received_count = len(valid) + len(invalid)
    healthy = (len(missing) == 0 and len(invalid) == 0)

    report = {
        "healthy": healthy,
        "expected_count": len(expected_slps),
        "received_count": received_count,
        "valid": valid,
        "invalid": invalid,
        "missing": missing,
    }
    json.dump(report, sys.stdout, indent=2)
    sys.stdout.write("\n")
    sys.exit(0 if healthy else 1)


if __name__ == "__main__":
    main()
