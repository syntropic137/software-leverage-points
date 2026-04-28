# software-leverage-points

A Claude Code plugin that ships skills for reviewing software through leverage-point lenses. Designed to run alongside [obra/superpowers](https://github.com/obra/superpowers), which provides cross-cutting workflow skills (`brainstorming`, `subagent-driven-development`, etc.).

## Status

v0.1.0 (alpha). Four skills ported from a validated POC: `testing`, `documentation`, `software-leverage-review` (orchestrator), `skill-builder`. The full v1 ships 14 leverage-point skills plus operator skills.

## Install (local development)

```bash
claude --plugin-dir /path/to/software-leverage-points
```

To run alongside superpowers:

```bash
claude --plugin-dir /path/to/software-leverage-points --plugin-dir /path/to/superpowers
```

## Skills

| Skill | Purpose |
|---|---|
| `testing` | Review testing concerns (coverage, framework, layout, mocking discipline) |
| `documentation` | Review documentation concerns (README, API docs, ADRs, TBD markers) |
| `software-leverage-review` | Orchestrator: fans out subagents per leverage point in parallel |
| `skill-builder` | Bootstrap repo-specific (L2) leverage skills from generic (L1) meta-skills |

When invoked as a plugin, skills are namespaced: `/software-leverage-points:testing`, etc.

## License

TBD.
