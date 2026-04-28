# Installing Software Leverage Points for OpenCode

## Prerequisites

- [OpenCode.ai](https://opencode.ai) installed

## Installation

Add software-leverage-points to the `plugin` array in your `opencode.json` (global or project-level):

```json
{
  "plugin": ["software-leverage-points@git+https://github.com/syntropic137/software-leverage-points.git"]
}
```

Restart OpenCode. That's it: the plugin auto-installs and registers all skills.

Verify by asking: "List the software leverage point skills."

## Usage

Use OpenCode's native `skill` tool:

```
use skill tool to list skills
use skill tool to load software-leverage-points/software-leverage-review
```

## Updating

Software Leverage Points updates automatically when you restart OpenCode.

To pin a specific version:

```json
{
  "plugin": ["software-leverage-points@git+https://github.com/syntropic137/software-leverage-points.git#v0.1.0"]
}
```

## Troubleshooting

### Plugin not loading

1. Check logs: `opencode run --print-logs "hello" 2>&1 | grep -i software-leverage-points`
2. Verify the plugin line in your `opencode.json`
3. Make sure you're running a recent version of OpenCode

### Skills not found

1. Use `skill` tool to list what's discovered
2. Check that the plugin is loading (see above)

### Tool mapping

When skills reference Claude Code tools:
- `TodoWrite` becomes `todowrite`
- `Task` with subagents becomes `@mention` syntax
- `Skill` tool becomes OpenCode's native `skill` tool
- File operations use your native tools

## Getting Help

- Report issues: https://github.com/syntropic137/software-leverage-points/issues
- Full documentation: https://github.com/syntropic137/software-leverage-points/blob/main/docs/README.opencode.md
