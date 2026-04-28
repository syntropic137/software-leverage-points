# Software Leverage Points for OpenCode

Complete guide for using Software Leverage Points with [OpenCode.ai](https://opencode.ai).

Scaffolding patterns adapted from [obra/superpowers](https://github.com/obra/superpowers).

## Installation

Add software-leverage-points to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["software-leverage-points@git+https://github.com/NeuralEmpowerment/software-leverage-points.git"]
}
```

Restart OpenCode. The plugin auto-installs via Bun and registers all skills automatically.

Verify by asking: "List the software leverage point skills."

## Usage

### Finding Skills

Use OpenCode's native `skill` tool to list all available skills:

```
use skill tool to list skills
```

### Loading a Skill

```
use skill tool to load software-leverage-points/software-leverage-review
```

### Personal Skills

Create your own skills in `~/.config/opencode/skills/`:

```bash
mkdir -p ~/.config/opencode/skills/my-skill
```

Create `~/.config/opencode/skills/my-skill/SKILL.md`:

```markdown
---
name: my-skill
description: Use when [condition], [what it does]
---

# My Skill

[Your skill content here]
```

### Project Skills

Create project-specific skills in `.opencode/skills/` within your project.

**Skill Priority:** Project skills > Personal skills > Software Leverage Points skills

## Updating

Software Leverage Points updates automatically when you restart OpenCode. The plugin is re-installed from the git repository on each launch.

To pin a specific version, use a branch or tag:

```json
{
  "plugin": ["software-leverage-points@git+https://github.com/NeuralEmpowerment/software-leverage-points.git#v0.1.0"]
}
```

## How It Works

The plugin does two things:

1. **Registers the skills directory** via the `config` hook, so OpenCode discovers all software-leverage-points skills without symlinks or manual config.
2. **Surfaces the orchestrator and per-leverage-point skills** so they can be invoked at plan time or during PR review.

### Tool Mapping

Skills written for Claude Code are automatically adapted for OpenCode:

- `TodoWrite` becomes `todowrite`
- `Task` with subagents becomes OpenCode's `@mention` system
- `Skill` tool becomes OpenCode's native `skill` tool
- File operations use native OpenCode tools

## Troubleshooting

### Plugin not loading

1. Check OpenCode logs: `opencode run --print-logs "hello" 2>&1 | grep -i software-leverage-points`
2. Verify the plugin line in your `opencode.json` is correct
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use OpenCode's `skill` tool to list available skills
2. Check that the plugin is loading (see above)
3. Each skill needs a `SKILL.md` file with valid YAML frontmatter

## Getting Help

- Report issues: https://github.com/NeuralEmpowerment/software-leverage-points/issues
- Main documentation: https://github.com/NeuralEmpowerment/software-leverage-points
- OpenCode docs: https://opencode.ai/docs/
