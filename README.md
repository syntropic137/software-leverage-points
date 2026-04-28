# software-leverage-points

A Claude Code plugin that ships a library of skills for reviewing software through high-leverage lenses: testing, logging, architecture, dependencies, security, configuration, types, documentation, and more. Each lens is its own skill, and an orchestrator (`software-leverage-review`) fans out parallel subagents (one per lens) to review a plan, a PR, or a whole codebase.

## Mental model: a mixture of experts on software design

Most software-quality reviews are single-pass: one agent reads a plan or a diff and tries to weigh every concern at once. That is where issues slip through. Cross-cutting concerns (DRY, complexity, separation of scope) get washed out by domain ones (a missing test, an over-mocked integration, an unpinned dependency).

This plugin treats each high-leverage concern as its own meta-skill, so an autonomous agent can invoke a *committee of experts* in parallel and synthesize the findings:

- **Plan-time gate.** Before implementation begins, fan out the lenses against the plan document. Each lens flags issues from its perspective. The author either revises the plan or proceeds with the issues acknowledged.
- **PR-time gate.** After implementation, fan out against the diff. Each lens flags issues that should block, warn, or inform.
- **Codebase audit.** Run periodically against the whole repo to surface drift and accumulated debt.

The skills compose with [obra/superpowers](https://github.com/obra/superpowers), a sibling plugin that provides the cross-cutting workflow skills (`brainstorming`, `subagent-driven-development`, `writing-plans`, etc.). This plugin focuses purely on the *what to review*; superpowers provides the *how to dispatch and review*.

## Credit

Multi-vendor scaffolding patterns adapted from [obra/superpowers](https://github.com/obra/superpowers). We track superpowers as a git `upstream` remote so we can selectively pull scaffolding improvements over time. Skills, agents, and commands are entirely our own.

## Status

v0.1.0 (alpha). Four skills shipped, ported from a validated POC. Roadmap is to grow the leverage-point inventory toward 18. See `MIGRATION.md` for the migration plan and current state.

## Install

This plugin runs alongside `obra/superpowers`. Install both:

### Claude Code

```bash
claude --plugin-dir /path/to/software-leverage-points --plugin-dir /path/to/superpowers
```

For other vendors, see:
- Codex: `docs/README.codex.md`
- OpenCode: `docs/README.opencode.md`
- Cursor: `.cursor-plugin/plugin.json` describes the plugin to Cursor's plugin loader
- Gemini: `gemini-extension.json` registers the extension

### Marketplace install (future)

A `.claude-plugin/marketplace.json` listing is planned for v0.2.

## Skills shipped at v0.1

| Skill | Layer | Purpose |
|---|---|---|
| `testing` | leverage point | Review testing concerns: framework presence, test layout, coverage, mocking discipline |
| `documentation` | leverage point | Review documentation: README, API docs, ADRs, TBD markers |
| `software-leverage-review` | orchestrator | Fan out subagents per leverage point, synthesize findings using lens references (DRY first; principles-and-patterns and software-complexity to follow) |
| `skill-builder` | operator | Bootstrap repo-specific (L2) skills from the plugin's generic (L1) meta-skills, customized per repo's stack |

When invoked through a vendor's plugin discovery, skills are namespaced (e.g., `/software-leverage-points:testing`).

### Layers

- **L1 (meta-skills):** generic skills that ship in this plugin. Repo-agnostic.
- **L2 (repo skills):** skills that `skill-builder` generates inside a target repo's `.claude/skills/`, customized for that repo's stack and conventions.
- **L3 (active reviews):** the orchestrator's runtime: parallel subagents reviewing a target through every lens.

## Roadmap to 18 leverage points

The goal is one skill per high-leverage concern. The shape is the same for each: a SKILL.md with frontmatter, when-to-use, structured checks, references to ADRs/books/thinkers, and an output schema all subagents conform to.

Targeted leverage-point set (count to be reconciled with the user, currently 14 confirmed plus 3 promoted lenses plus 1 TBD = 18):

| LP | Status | LP | Status |
|---|---|---|---|
| testing | shipped (v0.1) | continuous-deployment | shipped (v0.1) |
| documentation | shipped (v0.1) | types | planned |
| logging | shipped (v0.1) | developer-experience | planned |
| architecture | shipped (v0.1) | versioning | planned |
| configuration | shipped (v0.1) | purpose-and-scope | planned |
| dependencies | shipped (v0.1) | dry | planned (lens promoted) |
| security | shipped (v0.1) | principles-and-patterns | planned (lens promoted) |
| environments | shipped (v0.1) | software-complexity | planned (lens promoted) |
| continuous-integration | shipped (v0.1) | (TBD 18th) | open |

## Authoring style

Each leverage-point skill is more than a checklist. It cites the canonical references for the concern (books, ADR patterns, named thinkers) and explains *why* each red flag matters. The intent is for an agent reading the skill to operate with the same reasoning a senior engineer would, not just pattern-match.

Examples:
- The `testing` skill cites Beck (Test-Driven Development), Khorikov (Unit Testing Principles), and surfaces the integration-vs-mock discipline distinction.
- The `architecture` skill cites Brooks (No Silver Bullet), Fowler (Patterns of Enterprise Application Architecture), and asks for ADRs.
- The `types` skill cites Hejlsberg, Ousterhout (A Philosophy of Software Design), and asks how the type system is being used as documentation.

## Local development

```bash
git clone https://github.com/syntropic137/software-leverage-points
cd software-leverage-points

# Test locally without installing
claude --plugin-dir $(pwd)
```

Run alongside superpowers (recommended):
```bash
claude --plugin-dir $(pwd) --plugin-dir /path/to/superpowers
```

## Project rules

See `CLAUDE.md` for the rules contributors and agents should follow when editing this plugin.

## License

MIT. See `LICENSE`. Scaffolding patterns adapted from `obra/superpowers` (also MIT).
