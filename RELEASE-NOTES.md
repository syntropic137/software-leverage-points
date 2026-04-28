# Release Notes

## v0.1.0 (2026-04-27)

Initial public release. Ships 18 leverage-point skills, 3 operator skills, 3 lens reference docs, formal output schema with validator, and full multi-vendor scaffolding.

### What's in this release

- **18 leverage-point skills** (in alphabetical order):
  - architecture, configuration, continuous-deployment, continuous-integration, dependencies, developer-experience, documentation, dry, environments, error-handling, logging, principles-and-patterns, purpose-and-scope, security, software-complexity, testing, types, versioning.
  - Each skill has frontmatter with discriminating description, "When to Use" / "When NOT to Use" sections, structured Workflow, named Red Flags, and a "References & rationales" section citing 5-10 named sources (books, thinkers, foundational papers).
- **3 operator skills:**
  - `software-leverage-review`: orchestrator that fans out parallel subagents per leverage point and synthesizes findings via lens reference docs.
  - `skill-builder`: bootstrap repo-specific (L2) leverage skills from the plugin's generic (L1) meta-skills.
  - `skill-auditor`: detect drift between L2 skills and target repo state, plus cross-doc inconsistency within a plugin.
- **3 lens reference docs:** `dry`, `principles-and-patterns`, `software-complexity`. Read by the orchestrator during synthesis.
- **Formal output schema** at `skills/software-leverage-review/output-schema.json` (draft-07 JSON Schema) plus `scripts/validate-output.ts` validator.
- **Multi-vendor scaffolding:** Claude Code, Codex, Cursor, OpenCode, Gemini all supported via mirrored manifests. Patterns adapted from `obra/superpowers` (linked via the `upstream` git remote).

### Validation

Four evals shipped in `docs/evals/`:
- eval-001 (self-audit, testing + documentation): 10/12
- eval-002 (design spec, testing + documentation): 11/12
- eval-003 (full 18-LP fan-out against README): 12/12
- eval-004 (skill-auditor self-audit, cross-doc + link integrity): caught the schema-path drift this release fixes, plus 5 other drift findings.

Score arc demonstrates that the citation discipline + lens coverage compounded.

### Credit

Multi-vendor scaffolding patterns and structural conventions adapted from [obra/superpowers](https://github.com/obra/superpowers). This plugin runs alongside it: superpowers ships the cross-cutting workflow skills (`brainstorming`, `subagent-driven-development`, `writing-plans`, `writing-skills`); this plugin ships the *what to review* skills.

### Known limitations

- Evals 001-004 ran serially (subagent harness did not expose a parallel-dispatch tool). The orchestrator's parallel fan-out has been validated in earlier POC work; future evals running in a Task-capable harness will produce stronger evidence.
- The `skill-builder` greenfield mode is deferred (current implementation is templated mode only).
- `marketplace.json` is deferred to v0.2.

### What's next (v0.2 roadmap)

- Marketplace listing: in progress (`.claude-plugin/marketplace.json` authored, not yet published).
- `skill-builder` greenfield mode.
- A real eval against an external project's PR diff (eval-005).
- Scripted version of the auditor's checks (`scripts/audit.sh`) for CI integration: in progress (script authored; runs the cross-doc, version, link, and em-dash checks deterministically).
