# Release Notes

## v0.1.1 (2026-05-05)

Docs-only patch. Clarifies `obra/superpowers` as scaffolding-only attribution; this plugin has no runtime dependency on superpowers and no skill invokes a `superpowers:*` skill by name. Removes the README "Compatibility" section and "install both" line, and the corresponding language in `CLAUDE.md`, the PR template, and `marketplace.json` keywords.

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

Five evals shipped in `docs/evals/`:
- eval-001 (self-audit, testing + documentation): 10/12
- eval-002 (design spec, testing + documentation): 11/12
- eval-003 (full 18-LP fan-out against README): 12/12
- eval-004 (skill-auditor self-audit, cross-doc + link integrity): caught the schema-path drift this release fixes, plus 5 other drift findings.
- eval-005 (full 18-LP fan-out against an external Bun + TypeScript skill with substantive code): 11/12; NO-OP rate dropped from 9/18 (README target) to 2/18 (code target) as predicted; 7 of 9 previously-NO-OP LPs fired substantively.

Score arc demonstrates that the citation discipline + lens coverage compounded; eval-005 validates the LPs hold up against actual code, not just prose.

### Credit

Multi-vendor scaffolding patterns and structural conventions adapted from [obra/superpowers](https://github.com/obra/superpowers). This is attribution only; superpowers is not a runtime dependency of this plugin.

### Known limitations

- Evals 001-004 ran serially (subagent harness did not expose a parallel-dispatch tool). The orchestrator's parallel fan-out has been validated in earlier POC work; future evals running in a Task-capable harness will produce stronger evidence.
- The `skill-builder` greenfield mode is deferred (current implementation is templated mode only).
- `marketplace.json` is deferred to v0.2.

### What's next (v0.2 roadmap)

- Marketplace listing: in progress (`.claude-plugin/marketplace.json` authored, not yet published).
- `skill-builder` greenfield mode.
- A real eval against an external project's PR diff (eval-006). (eval-005 shipped: external whole-skill target with substantive code; PR-diff target moved to eval-006.)
- Scripted version of the auditor's checks (`scripts/audit.sh`) for CI integration: in progress (script authored; runs the cross-doc, version, link, and em-dash checks deterministically).
- Skill quality cleanup from eval-005 lessons (Milestone 3.2): SSRF (OWASP A10) and hand-rolled-escape red flags added to `security`; opaque binary-lockfile red flag added to `dependencies`; `versioning` and `logging` `When NOT to Use` scopes refined to route private/CLI cases to the right LP.
- Maturity-awareness across the operator skills (Phase 2 Stream B): in progress.
  - `software-leverage-review` calibrates finding severity to the target's maturity stage (POC, growing, production, safety-critical) and accepts an optional `maturity_hint` input. The fan-out subagent prompt threads `MATURITY_STAGE` so per-LP reviews calibrate at fan-out time, not just synthesis.
  - `skill-builder` now emits L2 SKILL.md files with explicit `Maturity Assessment` and `Growth Direction` sections; Repo-Specific Checks are calibrated to the assessed stage.
  - `skill-auditor` detects maturity drift: warns when the assessed level lags actual signals, surfaces info findings when a documented growth trigger has fired without the next step being addressed, and flags stale `Last reviewed` timestamps.
- L1/L2/L3 mental-model diagram landed in `README.md` (Phase 2 Stream B): visualizes how skill-builder reads L1 + inspects the target to produce L2, how software-leverage-review fans out L3 reviews against L2, and how skill-auditor closes the loop by feeding drift back to L2.
- Phase 2 Stream A (in-flight separately): qualitative refinement of the 18 L1 leverage-point skills based on user-feedback and growth examples.
