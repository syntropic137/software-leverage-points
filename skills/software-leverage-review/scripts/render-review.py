#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Deterministic three-section markdown renderer for orchestrator output.

Reads a routed-findings YAML document (Stage 2: each finding carries
severity, effort, action, software_leverage_point) and emits the
human-readable review.md per the canonical severity-action policy at
skills/software-leverage-review/severity-action-policy.md (the "Stage 2:
Orchestrator output" section).

This replaces what was previously a Haiku LLM call. The transform is
mechanical (action -> section, finding -> bullet) and the variance an
LLM introduces is pure downside (invented sections, malformed enum
values, dropped findings).

Usage:
    python3 render-review.py <routed.yaml> <output.md>
"""
import sys
import yaml
from pathlib import Path


HEADER_TEMPLATE = "# Review of {target}\n"

SECTION_AUTO_FIX = "Headline (auto-handled)"
SECTION_PROMOTE = "Promoted for human review"
SECTION_BULK = "Low-priority and info-only items"

EMPTY_SECTION = "_None._\n"


def slps_for(finding):
    """Return the comma-joined list of SLPs that contributed to a finding."""
    contributing = finding.get("contributing_slps") or []
    if contributing:
        return ",".join(contributing)
    primary = finding.get("software_leverage_point", "?")
    return primary


def render_auto_fix(findings):
    """Render the headline section: numbered list with full canonical detail."""
    if not findings:
        return EMPTY_SECTION
    lines = []
    for i, f in enumerate(findings, 1):
        sev = f.get("severity", "?")
        eff = f.get("effort", "?")
        slps = slps_for(f)
        issue = f.get("issue", "").strip()
        fix = f.get("suggested_fix", "").strip()
        lines.append(
            f"{i}. [severity: {sev} | effort: {eff} | slp(s): {slps}] {issue}"
        )
        lines.append(f"   - **Suggested fix:** {fix}")
    return "\n".join(lines) + "\n"


def render_promote(findings):
    """Render the promoted section: numbered list with promotion rationale."""
    if not findings:
        return EMPTY_SECTION
    lines = []
    for i, f in enumerate(findings, 1):
        sev = f.get("severity", "?")
        eff = f.get("effort", "?")
        slps = slps_for(f)
        issue = f.get("issue", "").strip()
        fix = f.get("suggested_fix", "").strip()
        rationale = f.get(
            "promotion_rationale",
            "large effort, scope decision needed",
        )
        lines.append(
            f"{i}. [severity: {sev} | effort: {eff} | slp(s): {slps}] {issue}"
        )
        lines.append(f"   - **Promotion rationale:** {rationale}")
        lines.append(f"   - **Suggested fix:** {fix}")
    return "\n".join(lines) + "\n"


def render_bulk(findings):
    """Render the bulk section: one line per item, severity + slp tagged."""
    if not findings:
        return EMPTY_SECTION
    lines = []
    for i, f in enumerate(findings, 1):
        sev = f.get("severity", "?")
        slps = slps_for(f)
        issue = f.get("issue", "").strip()
        # Truncate to keep the bulk section compact (audit-only).
        truncated = issue if len(issue) <= 140 else issue[:137].rstrip() + "..."
        lines.append(f"{i}. {truncated} [{sev} | {slps}]")
    return "\n".join(lines) + "\n"


def render(routed: dict) -> str:
    """Render the full three-section review markdown."""
    target = routed.get("target", "<unknown>")
    findings = routed.get("findings", []) or []

    by_action = {"auto-fix": [], "promote": [], "bulk": []}
    invalid_action = []
    for f in findings:
        action = f.get("action")
        if action in by_action:
            by_action[action].append(f)
        else:
            invalid_action.append(f)

    out_parts = []
    out_parts.append(HEADER_TEMPLATE.format(target=target))

    out_parts.append(f"## {SECTION_AUTO_FIX}\n")
    out_parts.append(render_auto_fix(by_action["auto-fix"]))

    out_parts.append(f"## {SECTION_PROMOTE}\n")
    out_parts.append(render_promote(by_action["promote"]))

    out_parts.append(f"## {SECTION_BULK}\n")
    out_parts.append(render_bulk(by_action["bulk"]))

    if invalid_action:
        out_parts.append("\n## (Schema violation) Findings with unrecognized action\n")
        out_parts.append(
            f"_{len(invalid_action)} finding(s) carried an action value "
            f"outside [auto-fix, promote, bulk]; they are not in any section "
            f"above. Inspect routed.yaml._\n"
        )

    return "\n".join(out_parts)


def main():
    if len(sys.argv) != 3:
        print(
            "usage: python3 render-review.py <routed.yaml> <output.md>",
            file=sys.stderr,
        )
        sys.exit(1)
    routed_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2])
    with routed_path.open() as f:
        routed = yaml.safe_load(f)
    if not isinstance(routed, dict):
        print(
            f"error: {routed_path} did not parse to a YAML mapping",
            file=sys.stderr,
        )
        sys.exit(2)
    rendered = render(routed)
    output_path.write_text(rendered)
    findings = routed.get("findings", []) or []
    by_action = {"auto-fix": 0, "promote": 0, "bulk": 0, "invalid": 0}
    for f in findings:
        action = f.get("action")
        if action in by_action:
            by_action[action] += 1
        else:
            by_action["invalid"] += 1
    print(
        f"wrote {output_path} "
        f"({by_action['auto-fix']} auto-fix, "
        f"{by_action['promote']} promoted, "
        f"{by_action['bulk']} bulk"
        + (
            f", {by_action['invalid']} schema violations"
            if by_action["invalid"]
            else ""
        )
        + ")"
    )


if __name__ == "__main__":
    main()
