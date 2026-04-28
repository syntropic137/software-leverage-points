# Local testing

How to install this plugin locally while iterating on it, and how to drive it against a target repo for evals before the plugin is published.

This doc covers Claude Code, since that is the primary development environment. For Codex, Cursor, and Gemini install patterns, see [`docs/README.codex.md`](README.codex.md) and the vendor manifests at the repo root.

## Prerequisites

- A local clone of this repo at a stable absolute path. The path is passed to Claude Code as a marketplace source, so it must not move while the plugin is installed.
- Claude Code, recent enough to support `/plugin marketplace add` and `/reload-plugins`.

## Persistent install (development loop)

Run these inside a Claude Code session.

```text
/plugin marketplace add /absolute/path/to/software-leverage-points
/plugin install software-leverage-points
```

Verification:

```text
/plugin
```

Navigate to the **Installed** tab; confirm `software-leverage-points` is present. Skills appear under the namespace `/software-leverage-points:<skill>`. Run `/help` to list the namespaced skills.

After editing skills, scripts, or operator skills:

```text
/reload-plugins
```

Reload is near-instant; no Claude Code restart required. There is no `npm link`-style symlink mode as of early 2026; reload is the contract.

## Ephemeral install (one-off iteration)

When you want a session-scoped install without registering the plugin globally:

```bash
claude --plugin-dir /absolute/path/to/software-leverage-points
```

Skills are namespaced the same way (`/software-leverage-points:<skill>`) and disappear when the session ends. Useful for quick experiments or for testing on a colleague's machine without polluting their config.

## Driving the plugin against a target repo

The plugin reviews other repos; install it as above, then start Claude Code from inside the target repo.

```bash
cd /path/to/target-repo
claude
```

Inside the session:

```text
/software-leverage-points:software-leverage-review
```

The orchestrator fans out parallel subagents per leverage-point skill. Wall-clock time tracks the slowest skill in the fan-out, not the sum.

For two-stage flows where a target repo needs L2 (repo-specific) skills first:

```text
/software-leverage-points:skill-builder
```

This generates `.claude/skills/<lp>/SKILL.md` files in the target repo, calibrated to its observed maturity. Subsequent reviews then prefer L2 over the L1 in this plugin.

## Three review modes

Once the plugin is installed and (optionally) bootstrapped with L2 skills, three review modes are supported:

1. **Plan review.** Pass a plan document; the orchestrator produces a structured artifact under `reviews/plan-<slug>-<date>.md`.
2. **Diff review (commit-to-commit).** Pass a base ref and head ref (or `HEAD~N`); produces an artifact under `reviews/diff-<base>..<head>-<date>.md`.
3. **PR review.** Pass a PR number or URL; produces the same artifact and (where applicable) leaves inline review comments on the PR via `gh pr review`.

All three modes share a uniform finding shape (skill, severity, priority, location, finding, rationale, suggested fix) so triage stays consistent across modes.

## Settings.json (optional, for stable development)

To pin the marketplace registration in your shared `.claude/settings.json` instead of re-adding it each setup:

```json
{
  "extraKnownMarketplaces": {
    "software-leverage-points": {
      "source": {
        "source": "local",
        "path": "/absolute/path/to/software-leverage-points"
      }
    }
  }
}
```

The `path` field is absolute, so this entry is per-machine. Once the plugin is published on GitHub, switch the source to:

```json
{
  "source": {
    "source": "github",
    "repo": "syntropic137/software-leverage-points"
  }
}
```

## Common issues

- **Skills do not appear after editing.** Run `/reload-plugins`. If still absent, run `bash scripts/audit.sh` from the plugin repo to verify the manifest, catalog, and link-integrity checks pass; a malformed `plugin.json` or missing `SKILL.md` will silently exclude the plugin.
- **Cross-references break with "broken link" warnings.** The plugin uses relative markdown links between skills (`../X/SKILL.md`); if you moved a skill directory, run `bash scripts/check-backlinks.sh` to surface broken or asymmetric cross-references.
- **Orchestrator fan-out is slow.** Wall time tracks the slowest skill. If one skill consistently bottlenecks, either narrow the fan-out at invocation time or check that skill's deep-dive material for unnecessary depth.

## Iterating on the plugin while testing

A typical inner loop:

1. Edit a SKILL.md or script in this repo.
2. From the plugin repo, run `just regenerate-catalogs && just qa` to keep README, catalog, and cross-references in sync.
3. In the Claude Code session running against the target repo, run `/reload-plugins`.
4. Re-invoke the orchestrator (or a single skill via `/software-leverage-points:<name>`) and observe the change.

The `just qa` step is fast and catches the drift classes the audit covers (em-dashes, broken links, asymmetric cross-references, manifest version skew, stale catalog). Running it as part of the inner loop avoids round-tripping through CI.
