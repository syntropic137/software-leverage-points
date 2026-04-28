---
name: developer-experience
description: "Use when reviewing developer experience concerns: onboarding time, dev-loop speed, error message quality, documentation discoverability, scripting/task-runner ergonomics, IDE/editor support"
---

# Developer Experience Leverage Point

## When to Use

- A planning agent is reviewing a plan that alters how developers (or AI agents) interact with the codebase: README, build scripts, task runners, devcontainers, error messages, formatter/linter, IDE config
- A PR-review agent encounters changes to onboarding instructions, dev-loop tooling, or contributor-facing scripts
- The orchestrator (`software-leverage-review`) fans out a subagent for developer experience

## When NOT to Use

- For end-user UX: that is a product concern, not this LP
- For API documentation as a contract surface: that is the `documentation` LP. This LP cares about contributor-facing ergonomics; the two LPs cross-reference at the README and example boundaries.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect DX artifacts: `README.md`, `CONTRIBUTING.md`, task runner (`Makefile`, `justfile`, `package.json` scripts, `pyproject.toml` `[tool]`), devcontainer, `.editorconfig`, recommended-extensions file, formatter and linter config, error-message helpers.
3. Apply checks:
   - Can a new contributor (or agent) reach a working state in under 30 minutes from a fresh clone?
   - Is the inner loop (edit then check then test) fast enough to support flow, targeting under 30 seconds for a single-file change?
   - Are error messages actionable, naming the cause and a suggested next step, not just stack traces?
   - Is the task runner self-documenting? Does `make help`, `just --list`, or `npm run` show every useful target?
   - Are formatter and linter rules autofixed, not bickered about in PR review?
   - Are IDE configurations checked in (devcontainer, `.editorconfig`, recommended extensions)?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"developer-experience"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"developer-experience"`.

## Red Flags (anti-patterns to surface as findings)

- **README missing install or run-locally instructions, or instructions out of date.**
  - What to flag: a `README.md` that does not name the prerequisites, the install command, the run-locally command, and the test command, or instructions that no longer match the current scripts.
  - Why it matters: the README is the onboarding contract; if it lies or omits, every new contributor and every agent wastes time reverse-engineering setup. Diátaxis names this the tutorial mode, and a working tutorial is the difference between a 20-minute onboarding and a 2-hour one.
  - Cite: Daniele Procida, the Diátaxis framework, on tutorials as the onboarding documentation mode. Cite also: Andrew Hunt and David Thomas, *The Pragmatic Programmer* (2nd ed., 2019), on personal automation and the cost of friction at the inner loop.

- **Dev loop slow without parallelization, caching, or incremental compilation.**
  - What to flag: a single-file change that triggers a full-project rebuild or a full-suite test run, with no watch mode, no incremental cache, and no targeted-test command.
  - Why it matters: iteration speed is a design dimension. A 30-second loop supports flow; a 5-minute loop drives developers to context-switch, batch changes, and lose the tight feedback that catches bugs early. The fix is usually known (incremental builds, test selection) but never prioritized until DX is reviewed as a leverage point.
  - Cite: Jonathan Blow and Casey Muratori on compile-time as a design dimension and the value of fast iteration loops. Cite also: *The Pragmatic Programmer* on the inner loop.

- **Error messages that say "something went wrong" without the something.**
  - What to flag: catch-all error handlers that log a generic message, exceptions re-raised without context, or CLI failures that print only "Error" with no cause or suggestion.
  - Why it matters: an unactionable error message is an unbounded debugging session. A good error names what was attempted, what went wrong, and what the developer can try next. Charity Majors' "developers in production" argues the operational loop is part of DX, and error quality is the highest-leverage point in that loop.
  - Cite: Charity Majors on developers in production and operational DX. Cite also: Brett Slatkin and the *Effective Python* tradition on error message quality.

- **Task runner full of opaque one-liners with no `help` target.**
  - What to flag: a `Makefile` or `package.json` `scripts` block where target names are abbreviated, undocumented, and there is no `make help` or `just --list` showing what each target does and when to use it.
  - Why it matters: a task runner is the project's CLI for contributors; an undocumented CLI is rediscovered by every new contributor, and the most useful targets stay tribal. Self-documentation is cheap (one comment per target) and the leverage is daily.
  - Cite: Kelsey Hightower on the principle of least surprise as a tooling design constraint.

- **Formatter rules debated in PR threads.**
  - What to flag: review comments arguing about whitespace, import order, quote style, or semicolons, in a project with no autoformatter run on save and in CI.
  - Why it matters: formatter debate is pure waste. The decision is arbitrary, but the cost of relitigating it on every PR is real. An autoformatter (`prettier`, `black`, `gofmt`, `rustfmt`) plus a pre-commit hook ends the debate and frees review attention for substance.
  - Cite: Adrienne Friend on Developer Experience as a measurable engineering concern; formatter automation is the canonical zero-thought DX win.

- **New contributor must reverse-engineer environment setup from scattered docs.**
  - What to flag: required env vars, tool versions, or system deps mentioned only in obscure files, comments, or chat history, with no single source of truth.
  - Why it matters: scattered setup is tribal-knowledge tax. A devcontainer or a single `bin/setup` script that bootstraps the whole environment is the canonical fix; failing that, a single section of the README that names every tool and version is the minimum bar.
  - Cite: *The Pragmatic Programmer* (Hunt and Thomas) on personal automation and reproducible environments.

- **AI agents cannot onboard from the README alone.**
  - What to flag: a project where an autonomous agent reading the README cannot identify the entry points, the test command, the dev loop, or where to file findings.
  - Why it matters: agentic contributors are now part of the DX surface. A README that assumes prior context fails for agents the same way it fails for new humans, but agents fail silently (they hallucinate) where humans ask. Treating the README as a machine-readable onboarding contract is the forward-compatible stance.
  - Cite: Adrienne Friend on DX measurement and Charity Majors on the operational loop, generalized to non-human contributors.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Andrew Hunt and David Thomas, *The Pragmatic Programmer* (2nd ed., 2019).** The inner loop, personal automation, and the cost of friction at the smallest scale of work. Use this as the foundational stance behind every DX check.
- **Jonathan Blow and Casey Muratori on compile-time as a design dimension.** Fast iteration loops as a design property of the tooling, not a happy accident. Use this when justifying watch modes, incremental compilation, and test selection.
- **Charity Majors on developers in production.** DX includes the operational loop; error quality and observability are part of the DX surface. Use this when justifying actionable error messages.
- **Adrienne Friend on Developer Experience.** DX as a measurable engineering concern. Use this when justifying formatter automation and devcontainer adoption.
- **Daniele Procida, the Diátaxis framework.** The four documentation modes (tutorial, how-to, reference, explanation); tutorials onboard, how-to gets work done. Use this when reviewing README structure.
- **Brett Slatkin, *Effective Python*.** The series-level guidance on error messages and idiomatic Python ergonomics. Use this when reviewing error helpers.
- **Kelsey Hightower on the principle of least surprise.** Tooling that behaves predictably wins the daily-use battle. Use this when reviewing task-runner ergonomics.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the README section to add, the watch-mode flag to enable, the autoformatter to wire into pre-commit, the `help` target to add, or the devcontainer to commit.
