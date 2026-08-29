# Syntropic137 workflows

This directory makes the repository installable as a [Syntropic137](https://github.com/syntropic137/syntropic137)
workflow package. The manifest is [`../syntropic137-plugin.json`](../syntropic137-plugin.json);
each subdirectory here is one workflow, in the `workflows/<name>/workflow.yaml`
layout the installer detects as a multi-workflow package.

## Install and run

```bash
syn workflow install syntropic137/software-leverage-points
syn workflow list
```

Installing clones this repository, reads every workflow, resolves the phase
prompt files, registers each declared skill, and uploads the resolved
definitions.

```bash
# Full leverage review of a repository
syn workflow run slp-leverage-review-v1 -R <owner>/<repo> --task "."

# Scope the fan-out to a subtree
syn workflow run slp-leverage-review-v1 -R <owner>/<repo> --task "src/payments"

# Gate a plan document before implementation
syn workflow run slp-plan-review-v1 -R <owner>/<repo> \
  --task "docs/plans/2026-08-01-payments-rework.md"
```

The repository is passed with `-R`, never as an input: repository identity is a
typed field on the execute API, and a workflow that declared `repository` as an
input would render a form field the API always rejects.

## The workflows

### `slp-leverage-review-v1` - Software leverage review

Two phases against a cloned repository.

1. **review** - invokes the `software-leverage-review` orchestrator, which fans
   out one subagent per leverage point, runs the stage-1 health and schema gate,
   dedups, applies the deterministic severity/effort floor correction, routes
   each finding through the action matrix, and renders the report. Emits
   `deliverable.md`, `leverage-review.yaml`, and the per-lens raw findings.
2. **triage** - turns the merged findings into a queue: *Do now* (auto-fix,
   high severity), *Decide* (the promoted scope decisions), *Batch* (bulk), and
   a sequencing pass naming dependencies between findings that no single lens
   could see.

Optional `maturity_hint` input (`poc`, `prototype`, `growing`, `production`,
`safety-critical`) overrides the maturity stage the orchestrator would infer.
Severity is calibrated against that stage, so it changes the output materially.

### `slp-plan-review-v1` - Software leverage review of a plan

Two phases against a plan document in a cloned repository.

1. **review-plan** - the same fan-out with the plan as the target. Plan reviews
   rate effort against what the revised plan would commit the team to, not
   against the size of the textual edit.
2. **revise-plan** - applies every `auto-fix` finding to the plan and emits a
   complete `plan-v2.md`, leaving the `promote` findings unresolved under an
   `## Open decisions` heading. The operator owns those.

## How the skills reach the agent

Both workflows declare the 17 leverage point skills plus the orchestrator at
**workflow scope**, so every phase gets them:

```yaml
skills:
  - source: https://github.com/syntropic137/software-leverage-points
    version: <commit-sha>
    names: [software-leverage-review, architecture, ...]
```

At install time the CLI clones the pinned source once per skill, locates the
skill directory (it tries `<name>/`, then `skills/<name>/`, then the clone
root - this repository is found by the second candidate), hashes the tree, and
registers it. At run time each registered tree is materialized into the
workspace under `.syn-skills/<name>/` and installed into the agent's skill
directory, so the lenses are siblings of each other exactly as the orchestrator
expects.

The version is a commit sha because `@latest` is rejected by design: a skill
ref has to denote the same bytes on every install, or the lockfile means
nothing. **When the skills change, re-pin `version:` in both `workflow.yaml`
files and bump `version` in `syntropic137-plugin.json`.** Nothing detects a
stale pin for you; the workflows will keep installing the older skills happily.

## Editing these workflows

Field names are validated with `extra="forbid"` on the Syntropic137 side: a
`prompt:` where `prompt_template:` was meant, or `tools:` where `allowed_tools:`
was meant, is a hard error rather than a silently dropped key. The same applies
to phase markdown frontmatter - only keys that map to real phase fields
(`description`, `argument-hint`, `model`, `allowed-tools`, `max-tokens`,
`timeout-seconds`, `execution-type`) are accepted.

The `review` phases deliberately declare **no** `allowed_tools`. The
orchestrator has to dispatch subagents, run its Python verification scripts, and
write files; naming a tool subset there is how a 17-lens fan-out quietly
degrades into one agent's single-pass opinion.
