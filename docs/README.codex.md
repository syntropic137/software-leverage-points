# Software Leverage Points for Codex

Guide for using Software Leverage Points with OpenAI Codex via native skill discovery.

Scaffolding patterns adapted from [obra/superpowers](https://github.com/obra/superpowers).

## Quick Install

Tell Codex:

```
Fetch and follow instructions from https://raw.githubusercontent.com/syntropic137/software-leverage-points/refs/heads/main/.codex/INSTALL.md
```

## Manual Installation

### Prerequisites

- OpenAI Codex CLI
- Git

### Steps

1. Clone the repo:
   ```bash
   git clone https://github.com/syntropic137/software-leverage-points.git ~/.codex/software-leverage-points
   ```

2. Create the skills symlink:
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/software-leverage-points/skills ~/.agents/skills/software-leverage-points
   ```

3. Restart Codex.

4. **For the orchestrator skill** (optional but recommended): the `software-leverage-review` skill fans out parallel subagents, one per leverage point. This requires Codex's multi-agent feature. Add to your Codex config:
   ```toml
   [features]
   multi_agent = true
   ```

### Windows

Use a junction instead of a symlink (works without Developer Mode):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\software-leverage-points" "$env:USERPROFILE\.codex\software-leverage-points\skills"
```

## How It Works

Codex has native skill discovery: it scans `~/.agents/skills/` at startup, parses SKILL.md frontmatter, and loads skills on demand. Software-leverage-points skills are made visible through a single symlink:

```
~/.agents/skills/software-leverage-points/ -> ~/.codex/software-leverage-points/skills/
```

## Usage

Skills are discovered automatically. Codex activates them when:
- You mention a skill by name (e.g., "use software-leverage-review")
- The task matches a skill's description (e.g., "review this plan", "review this PR diff")

The plugin's value prop: a mixture of experts on software design, used at plan time and PR review. Each leverage point (testing, logging, architecture, dependencies, security, ...) is its own skill. The `software-leverage-review` orchestrator fans out parallel subagents and aggregates their findings.

### Personal Skills

Create your own skills in `~/.agents/skills/`:

```bash
mkdir -p ~/.agents/skills/my-skill
```

Create `~/.agents/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition], [what it does]
---

# My Skill

[Your skill content here]
```

The `description` field is how Codex decides when to activate a skill automatically: write it as a clear trigger condition.

## Updating

```bash
cd ~/.codex/software-leverage-points && git pull
```

Skills update instantly through the symlink.

## Uninstalling

```bash
rm ~/.agents/skills/software-leverage-points
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\software-leverage-points"
```

Optionally delete the clone: `rm -rf ~/.codex/software-leverage-points` (Windows: `Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\software-leverage-points"`).

## Troubleshooting

### Skills not showing up

1. Verify the symlink: `ls -la ~/.agents/skills/software-leverage-points`
2. Check skills exist: `ls ~/.codex/software-leverage-points/skills`
3. Restart Codex: skills are discovered at startup

### Windows junction issues

Junctions normally work without special permissions. If creation fails, try running PowerShell as administrator.

## Getting Help

- Report issues: https://github.com/syntropic137/software-leverage-points/issues
- Main documentation: https://github.com/syntropic137/software-leverage-points
