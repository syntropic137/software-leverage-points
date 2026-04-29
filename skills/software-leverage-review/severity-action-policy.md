# Severity / action policy

> **Canonical.** This file is the single source of truth for severity levels, effort levels, the action matrix, and the output structure used by the `software-leverage-review` orchestrator. Edit this file to change the policy; downstream consumers (output schema, orchestrator skill, per-SLP prompts) reference it. Run `just qa` after edits; the consistency validator fails loud on drift.

## Severity enum

Five levels, ranked by impact. Severity is the absolute weight of the issue, independent of how easy it is to fix.

| Severity | Definition |
|---|---|
| **critical** | An incident-class issue. Security boundary failure, data-loss risk, production outage, regulatory violation, or a defect that would block a current customer. Cannot ship; cannot defer. |
| **high** | A significant correctness or trust risk. Wrong behavior in a non-edge case, missing test coverage on a load-bearing path, broken contract, or hygiene gap that compounds quickly. Ships within the same change cycle. |
| **medium** | A real concern with bounded blast radius. Code smell with a clear refactor path, missing documentation on a non-public surface, performance regression in a non-critical path. Worth addressing; not a blocker. |
| **low** | A minor concern. Style nit, cosmetic inconsistency, optional optimization, or a suggestion that depends on context the orchestrator cannot verify. |
| **info** | An observation, not an issue. "This pattern would be useful here," "consider X if Y becomes true." Surfaced for awareness; no action expected. |

## Effort enum

Three levels. Effort is the cost of *executing what the `suggested_fix` actually implies*, orthogonal to severity.

The distinction matters because plan-review findings and codebase-review findings rate effort against different surfaces:

- **Codebase review.** The `suggested_fix` typically describes a code change. Effort rates the implementation cost of that code change.
- **Plan review.** The `suggested_fix` typically asks for a plan revision (add a section, name an ADR, choose between options, verify an upstream surface). The textual edit to the plan is almost always trivial; what matters is the cost of what the revised plan actually commits to. Rate effort as the implementation cost of what the plan would commit to once the revision lands. Writing a new ADR is `medium`; verifying an upstream API surface that may not exist is `medium`; introducing a load-bearing cross-cutting pattern is `large`.

| Effort | Definition |
|---|---|
| **small** | One file or a small set of related changes. A maintainer ships it within an hour. For plan reviews: a textual clarification with no implementation consequence (rename a section, fix a typo, add a Non-goals bullet). |
| **medium** | Multiple files but a bounded scope. A maintainer ships it within a day. For plan reviews: writing a new ADR, verifying an upstream API surface, choosing between two designs the plan left open. |
| **large** | Broad blast radius, multi-PR sequencing, or scope decisions that require operator judgment. The system does not auto-fix large items. For plan reviews: introducing a new cross-cutting pattern, restructuring the phased delivery, committing to a dependency the plan deferred. |

The action matrix promotes large-effort items so the operator weighs the scope decision before the work commits. This applies equally to plan reviews and codebase reviews; only the surface against which effort is rated differs.

## Action enum

Three actions. Each finding receives exactly one.

| Action | Meaning |
|---|---|
| **auto-fix** | Downstream workflow phase (plan-revision, PR-revision) incorporates the fix without operator authoring code. Operator confirms ship. |
| **promote** | Orchestrator surfaces the finding for operator review. The system explicitly hands the decision back. Operator decides ship-now-anyway, split into smaller PRs, defer with reason, or escalate further. |
| **bulk** | Finding is visible but not acted on in this phase. Numbered list under one heading, no individual context. Preserves audit trail without paying reader-attention cost. |

## Action matrix

Severity and effort together determine the action. The hard rule: **any large-effort finding promotes to the operator, regardless of severity.** The system never makes scope decisions on large changes.

| Severity | Effort | Action |
|---|---|---|
| critical | small | auto-fix |
| critical | medium | auto-fix |
| critical | large | promote |
| high | small | auto-fix |
| high | medium | auto-fix |
| high | large | promote |
| medium | small | auto-fix |
| medium | medium | auto-fix |
| medium | large | promote |
| low | small | bulk |
| low | medium | bulk |
| low | large | bulk |
| info | small | bulk |
| info | medium | bulk |
| info | large | bulk |

Three actions, three output sections. Maintainer reads the headline section and acts; scans the promoted section to make scope calls on large items; ignores bulk unless audit-driving.

## Output structures (two stages)

There are two output stages in a review run. Each has its own schema shape and its own consumer. Do not confuse them.

### Stage 1: Per-SLP output

Emitted by each SLP subagent during the parallel review phase. **YAML only**, no markdown. Contains raw findings the SLP identified, each with `severity` and `effort` assigned but NO `action` field (the orchestrator computes that in stage 2). No sectioning: a flat findings list plus a one-paragraph summary.

Conforms to [`./slp-output-schema.yaml`](./slp-output-schema.yaml). Shape:

```yaml
software_leverage_point: <slp-name>
findings:
  - severity: critical
    effort: small
    issue: <concrete description, citing file:line or plan section>
    suggested_fix: <actionable next move>
    file: <optional path>
    line: <optional integer>
  - severity: medium
    effort: medium
    issue: ...
    suggested_fix: ...
summary: <1-2 sentences on overall SLP findings>
```

The orchestrator parses these mechanically. SLP subagents return ONLY this YAML document, no prose around it, no markdown fence.

### Stage 2: Orchestrator output

Emitted by the orchestrator after dedup + action-matrix routing. Two artifacts: a merged YAML document (machine contract) AND a human-readable markdown report (maintainer reading surface). The orchestrator emits both in the same run.

The YAML conforms to [`./orchestrator-output-schema.yaml`](./orchestrator-output-schema.yaml). Each finding carries an `action` field assigned per the action matrix and a `software_leverage_point` field naming the SLP that emitted it.

```yaml
target: <plan path | PR ref range | "codebase HEAD">
software_leverage_points_reviewed: [testing, security, configuration, ...]
findings:
  - software_leverage_point: testing
    severity: critical
    effort: small
    action: auto-fix
    issue: ...
    suggested_fix: ...
    file: ...
    line: ...
cross_cutting_synthesis: []   # optional cross-cutting findings flagged by 3+ SLPs
summary: <3-5 sentences naming load-bearing items and cross-cutting patterns>
```

The markdown report follows this shape, derived directly from the YAML:

```markdown
# Review of <target>

## Headline (auto-handled)

Findings with action `auto-fix`. Full canonical issue + suggested fix per item.

1. [severity: critical | effort: small | slp(s): testing] <canonical issue>
   - **Suggested fix:** <actionable description>
2. <next finding>
...

## Promoted for human review

Findings with action `promote`. Operator decision required before the workflow proceeds.

1. [severity: critical | effort: large | slp(s): architecture] <canonical issue>
   - **Promotion rationale:** <why operator review is needed; usually "large effort, scope decision">
2. <next promoted finding>
...

## Low-priority and info-only items

Findings with action `bulk`. One line per item, no individual context.

1. <one-line summary> [low | testing]
2. <one-line summary> [info | logging]
...
```

The three sections are stable; the orchestrator emits all three even if one is empty (write "_None._" under an empty heading).

## How a finding gets its severity and effort

Per-SLP subagents emit findings during the parallel review phase. Each subagent assigns:

- **Severity:** based on the L1 principles (what kinds of issues are critical for this SLP) plus the maturity calibration below (what counts as "production blocker" at this repo's stage).
- **Effort:** based on the cost-to-fix estimate for the suggested fix. `small` when a fix is a one-file change; `medium` when multiple files but bounded scope; `large` when scope decisions are required.

The orchestrator does NOT re-assign severity or effort during dedup. It groups findings, picks a canonical, and applies the action matrix to determine routing.

## Maturity calibration

Severity is calibrated to the target's maturity stage. The stage is sensed from signals (size, age, deploy frequency, contributor count, public consumers, presence of CI, language toolchain, visible roadmap), or supplied explicitly via the orchestrator's `maturity_hint` input.

| Stage | Calibration rule |
|---|---|
| POC / prototype | Most findings default to `info` or `low`. Reserve `medium` and above for things that compound badly later (data shape lock-in, security holes that ship to users). |
| Growing internal tool | `medium` or `low` for hygiene gaps; `high` for things that will hurt production migration; `critical` for incident-class issues. |
| Production service | All severities apply at the documented rigor without offset. |
| Safety-critical | Every finding shifts up one severity from baseline. |

The fan-out subagents inherit the stage from the orchestrator; the synthesis pass re-applies the calibration as a sanity check.

## Update procedure

1. Edit this file.
2. Update the severity or effort enum values in `./output-schema.yaml` to match.
3. Run `just qa`. The `scripts/check-policy-consistency.sh` validator surfaces any remaining drift across consumers.
4. Fix anything the validator reports.
5. Commit.

The validator is the safety net. If you change `critical` to `blocker` in this file, the validator names every place the old value still appears.

## Consumers (where this policy lands at runtime)

- **`./output-schema.yaml`** : severity enum, effort enum, finding shape.
- **`./SKILL.md`** : the orchestrator's workflow references the action matrix for routing.
- **`./prompt_review-one-software-leverage-point.md`** : per-SLP subagent prompt instructs SLPs to assign severity + effort per this policy.
- **`../../VISION.md`** : high-level summary; defers to this file as canonical.
- **`../../docs/severity-action-policy.md`** : discovery stub pointing here.

## Non-goals

- This file does not define how SLPs *interpret* severity for their specific concern. That is per-SLP; lives in each L1 SKILL.md (e.g., the testing SLP has its own definition of when missing coverage is `critical` vs `high`).
- This file does not encode SLP-count thresholds, maturity-tier escalation rules, or workflow-phase handoff contracts. Those are downstream of this policy and live in the orchestrator's SKILL.md.
- This file does not list which SLPs ship in the plugin. That is `docs/leverage-points.md`.
