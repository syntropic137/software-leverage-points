# software-leverage-points: Contributor Guidelines

This plugin ships a "mixture of experts on software design": a set of skills,
each focused on a single software leverage point (testing, logging, architecture,
dependencies, security, etc.), plus an orchestrator that fans them out at
plan-time and PR-time.

**Canonical references** (read these before substantive work):

- [`VISION.md`](VISION.md): what this plugin is for, the end state, the severity-action policy, and the acceptance tests.
- [`docs/ADRs/ADR-0001-three-layer-skill-pattern.md`](docs/ADRs/ADR-0001-three-layer-skill-pattern.md): the architectural decision behind L1 / L2 / orchestrator.

Scaffolding patterns in this repo are adapted from
[obra/superpowers](https://github.com/obra/superpowers), which is also a runtime
peer: this plugin expects superpowers to be installed alongside it for shared
workflow skills (e.g. `subagent-driven-development`, `brainstorming`).

## Project rules

1. **NEVER use em-dashes.** Restructure the sentence, or substitute a colon, comma,
   or parentheses. This applies to all prose: skills, READMEs, commit messages,
   PR bodies.
2. **One problem per PR.** Bundled, unrelated changes should be split.
3. **Skills are code, not prose.** Behavior-shaping content (red flags,
   when-to-use, rationalizations) should not be reworded without eval evidence.
4. **Cite your sources.** Each leverage-point skill should reference the ADRs,
   books, or practitioners that ground its red flags (Fowler, Beck, Brooks,
   Khorikov, Ousterhout, Hejlsberg, etc.).
5. **L2 SKILL.md files are context, not reviewers.** When editing or generating
   any `.claude/skills/<lp>/SKILL.md` for a target repo, do not include `error`
   / `warn` / `info` severity labels in the body. Severity is the orchestrator's
   job (`software-leverage-review`). L2 records observations, conventions, and
   gaps; the orchestrator reads them and assigns severity at review time.

## Where things live

- `.claude-plugin/plugin.json`: Claude Code plugin manifest.
- `skills/<name>/SKILL.md`: each leverage-point skill.
- `skills/software-leverage-review/`: the orchestrator that fans out per-LP subagents.
- `MIGRATION.md`: canonical task list for the migration/integration effort.
- `upstream` git remote: tracks `obra/superpowers` for selective scaffolding sync.

## Before opening a PR

- Read `.github/PULL_REQUEST_TEMPLATE.md` and fill every section.
- Search open and closed PRs for prior art.
- A human must review the complete diff.
- Test the change against at least one harness and report results.
