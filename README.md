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

## Compatibility

This plugin has been developed against `obra/superpowers` at HEAD as of 2026-04-27. The two plugins compose at runtime via vendor-native plugin discovery; no version pin is enforced today. If superpowers introduces breaking changes to its scaffolding conventions, this plugin's `upstream` git remote (pinned to `obra/superpowers`) makes selectively merging only the scaffolding changes straightforward. Skill compatibility is informal: this plugin invokes `superpowers:brainstorming`, `superpowers:writing-plans`, `superpowers:subagent-driven-development`, and `superpowers:writing-skills` by name. Breaking changes to those skills' descriptions or interfaces will require this plugin's docs to be updated.

## Status

v0.1.0 (alpha). 18 leverage-point skills shipped, 3 operator skills (`software-leverage-review`, `skill-builder`, `skill-auditor`), 3 lens reference docs. Four evals run: the three orchestrator runs scored upward on the 12-point rubric (10/12, 11/12, 12/12), and eval-004 is a single-skill `skill-auditor` self-audit (Specificity 3/3; the other rubric dimensions do not apply to a single-skill run). See `MIGRATION.md` for the migration plan and `docs/evals/` for evidence.

## Install

This README is the explanation layer: mental model, rationale, and install instructions. The reference inventory of all shipped skills lives in `docs/leverage-points.md`. How-to guides for individual skills live in each skill's own `SKILL.md`. The split follows Diátaxis (explanation, how-to, reference) so each document has one job.

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

## Skills

The full inventory of shipped skills (18 leverage points, 3 operator skills, 3 lens reference docs) is the reference doc at `docs/leverage-points.md`. When invoked through a vendor's plugin discovery, skills are namespaced (e.g., `/software-leverage-points:testing`).

### Layers

- **L1 (meta-skills):** generic skills that ship in this plugin. Repo-agnostic.
- **L2 (repo skills):** skills that `skill-builder` generates inside a target repo's `.claude/skills/`, customized for that repo's stack and conventions.
- **L3 (active reviews):** the orchestrator's runtime: parallel subagents reviewing a target through every lens.

## Roadmap and skill catalog

The full skill catalog (all 18 leverage points, plus operator and lens docs) lives in `docs/leverage-points.md`. This README is the explanation layer (mental model, why this exists). Install instructions are below; the catalog is its own reference.

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
