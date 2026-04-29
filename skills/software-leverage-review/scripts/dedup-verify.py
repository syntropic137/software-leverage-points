#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pyyaml"]
# ///
"""Verify and correct the dedup pass output.

The dedup LLM pass clusters raw findings by observation and emits a
deduped.yaml. Each cluster carries an `original_indices` array pointing
back to the raw-findings.yaml entries that contributed to the cluster.

Empirically (EVAL-001, EVAL-002), the dedup pass occasionally collapses
the effort or severity dimension when picking canonical values: it picks
the lowest member's effort instead of the highest. This causes the
action-matrix to mis-route findings (e.g. an effort=large member ends up
in an effort=medium cluster, which routes to auto-fix instead of promote,
producing the "0 promoted on plan reviews" failure mode observed in
EVAL-002 runs 1 and 4.

This script is a deterministic, mechanical correction pass. It reads the
raw findings and the dedup output, computes the max severity and max
effort across each cluster's actual members, and overrides the cluster's
reported severity/effort if they are below the computed max.

NO LLM is involved. The transform is monotone: it only ever raises
severity or effort, never lowers. This is safe because higher severity
and higher effort both move findings toward more conservative routing
(more attention from the maintainer or operator), never less.

Outputs corrected deduped.yaml (in place by default; --output to redirect)
and prints a summary of corrections to stderr.

Usage:
    dedup-verify.py <raw-findings.yaml> <deduped.yaml> [--output <out.yaml>]
"""
import sys
import yaml
from pathlib import Path


SEVERITY_RANK = {"critical": 0, "high": 1, "medium": 2, "low": 3, "info": 4}
EFFORT_RANK = {"large": 0, "medium": 1, "small": 2}


def max_severity(values):
    """Return the strongest severity in `values` (i.e. lowest rank number)."""
    valid = [v for v in values if v in SEVERITY_RANK]
    if not valid:
        return None
    return min(valid, key=lambda v: SEVERITY_RANK[v])


def max_effort(values):
    """Return the largest effort in `values` (i.e. lowest rank number)."""
    valid = [v for v in values if v in EFFORT_RANK]
    if not valid:
        return None
    return min(valid, key=lambda v: EFFORT_RANK[v])


def main():
    args = sys.argv[1:]
    if "--output" in args:
        i = args.index("--output")
        if i + 1 >= len(args):
            print("error: --output requires a path", file=sys.stderr)
            sys.exit(2)
        output = Path(args[i + 1])
        positional = args[:i] + args[i + 2:]
    else:
        output = None
        positional = args

    if len(positional) != 2:
        print(
            "usage: dedup-verify.py <raw-findings.yaml> <deduped.yaml> [--output <out.yaml>]",
            file=sys.stderr,
        )
        sys.exit(2)

    raw_path = Path(positional[0])
    deduped_path = Path(positional[1])
    output_path = output or deduped_path  # default to in-place

    with raw_path.open() as f:
        raw_doc = yaml.safe_load(f) or {}
    raw_findings = raw_doc.get("collected_findings") or []

    with deduped_path.open() as f:
        dedup_doc = yaml.safe_load(f) or {}
    clusters = dedup_doc.get("deduped_findings") or []

    severity_corrections = 0
    effort_corrections = 0
    missing_indices = 0
    total_clusters = len(clusters)

    for cluster in clusters:
        indices = cluster.get("original_indices") or []
        members = []
        for idx in indices:
            if 0 <= idx < len(raw_findings):
                members.append(raw_findings[idx])
            else:
                missing_indices += 1

        if not members:
            continue

        member_severities = [m.get("severity") for m in members]
        member_efforts = [m.get("effort") for m in members]

        true_max_sev = max_severity(member_severities)
        true_max_eff = max_effort(member_efforts)

        reported_sev = cluster.get("severity")
        reported_eff = cluster.get("effort")

        if (
            true_max_sev
            and reported_sev
            and SEVERITY_RANK.get(true_max_sev, 99) < SEVERITY_RANK.get(reported_sev, 99)
        ):
            cluster["severity"] = true_max_sev
            severity_corrections += 1

        if (
            true_max_eff
            and reported_eff
            and EFFORT_RANK.get(true_max_eff, 99) < EFFORT_RANK.get(reported_eff, 99)
        ):
            cluster["effort"] = true_max_eff
            effort_corrections += 1

    # Write corrected document
    with output_path.open("w") as f:
        yaml.safe_dump(dedup_doc, f, sort_keys=False, default_flow_style=False)

    # Summary to stderr so stdout stays clean for piping
    sys.stderr.write(
        f"dedup-verify: {total_clusters} clusters; "
        f"{severity_corrections} severity corrections, "
        f"{effort_corrections} effort corrections"
    )
    if missing_indices:
        sys.stderr.write(f"; {missing_indices} dangling original_indices (raw-findings out of range)")
    sys.stderr.write(f"\nwrote {output_path}\n")


if __name__ == "__main__":
    main()
