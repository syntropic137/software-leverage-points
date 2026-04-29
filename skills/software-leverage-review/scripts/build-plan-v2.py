#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Deterministic plan-v2 builder.

When the orchestrator's target is a plan document, this script emits a
"plan v2" that prepends a review-driven amendments callout, preserves the
original plan verbatim, and appends two appendices: promoted-for-review
items and bulk (low/info) items.

Reads the routed findings YAML (Stage 2 schema, conforms to
orchestrator-output-schema.yaml) plus the original plan markdown; writes
plan-v2.md.

This replaces what was previously an LLM call (Opus or Haiku) emitting
~76KB of text to re-render the plan with annotations. The transform is
mechanical: the plan content is unchanged, only the surrounding callouts
and appendices are computed from the findings.

Usage:
    build-plan-v2.py <findings.yaml> <original-plan.md> <plan-v2.md>
"""
import sys
import yaml
from pathlib import Path


HEADER_HINT = (
    "# Plan v2 with review-driven amendments\n"
    "\n"
    "> **Review summary:** {auto_fix} auto-handled, "
    "{promote} promoted for human review, "
    "{bulk} bulk (low/info, audit-only).\n"
)


AUTO_HANDLED_HEADER = "## Auto-handled amendments (top of headline)\n"
PROMOTED_HEADER = "## Promoted for human review\n"
BULK_HEADER = "## Bulk: low-priority and info-only\n"
EMPTY = "_None._\n"
DIVIDER = "\n---\n\n"


def slps_for(finding):
    """Return a comma-joined SLP list for a finding, with a sensible fallback."""
    contributing = finding.get("contributing_slps") or []
    if contributing:
        return ",".join(contributing[:6])
    primary = finding.get("software_leverage_point", "?")
    return primary


def render_callout(auto_fix):
    if not auto_fix:
        return AUTO_HANDLED_HEADER + EMPTY
    lines = [AUTO_HANDLED_HEADER]
    for i, f in enumerate(auto_fix[:10], 1):
        sev = f.get("severity", "?")
        eff = f.get("effort", "?")
        issue = f.get("issue", "")
        excerpt = issue if len(issue) <= 200 else issue[:200] + "..."
        lines.append(f"{i}. [{sev}/{eff}] {excerpt}")
    return "\n".join(lines) + "\n"


def render_promoted_appendix(promote):
    if not promote:
        return PROMOTED_HEADER + EMPTY
    lines = [PROMOTED_HEADER]
    for i, f in enumerate(promote, 1):
        sev = f.get("severity", "?")
        slps = slps_for(f)
        issue = f.get("issue", "").strip()
        fix = f.get("suggested_fix", "").strip()
        lines.append(f"{i}. [{sev}/large | slp(s): {slps}] {issue}")
        lines.append(f"   - **Suggested fix:** {fix}")
    return "\n".join(lines) + "\n"


def render_bulk_appendix(bulk):
    if not bulk:
        return BULK_HEADER + EMPTY
    lines = [BULK_HEADER]
    for i, f in enumerate(bulk, 1):
        sev = f.get("severity", "?")
        slps = slps_for(f)
        issue = f.get("issue", "").strip()
        truncated = issue if len(issue) <= 140 else issue[:137].rstrip() + "..."
        lines.append(f"{i}. {truncated} [{sev} | {slps}]")
    return "\n".join(lines) + "\n"


def build(findings_yaml: dict, plan_text: str) -> str:
    findings = findings_yaml.get("findings", []) or []
    by_action = {"auto-fix": [], "promote": [], "bulk": []}
    for f in findings:
        action = f.get("action")
        if action in by_action:
            by_action[action].append(f)

    header = HEADER_HINT.format(
        auto_fix=len(by_action["auto-fix"]),
        promote=len(by_action["promote"]),
        bulk=len(by_action["bulk"]),
    )
    callout = render_callout(by_action["auto-fix"])
    promoted = render_promoted_appendix(by_action["promote"])
    bulk = render_bulk_appendix(by_action["bulk"])

    return (
        header
        + "\n"
        + callout
        + DIVIDER
        + plan_text
        + "\n\n"
        + promoted
        + "\n"
        + bulk
    )


def main():
    if len(sys.argv) != 4:
        print(
            "usage: build-plan-v2.py <findings.yaml> <original-plan.md> <plan-v2.md>",
            file=sys.stderr,
        )
        sys.exit(1)
    findings_path = Path(sys.argv[1])
    plan_path = Path(sys.argv[2])
    output_path = Path(sys.argv[3])

    with findings_path.open() as f:
        findings_yaml = yaml.safe_load(f) or {}
    plan_text = plan_path.read_text()

    rendered = build(findings_yaml, plan_text)
    output_path.write_text(rendered)

    findings = findings_yaml.get("findings", []) or []
    counts = {"auto-fix": 0, "promote": 0, "bulk": 0}
    for f in findings:
        action = f.get("action")
        if action in counts:
            counts[action] += 1
    print(
        f"wrote {output_path} "
        f"({counts['auto-fix']} auto-fix, "
        f"{counts['promote']} promoted, "
        f"{counts['bulk']} bulk; "
        f"{len(plan_text)} bytes of original plan preserved)"
    )


if __name__ == "__main__":
    main()
