---
name: testing
description: Use when reviewing testing concerns (coverage, framework presence, test layout, mocking discipline) in a codebase, plan, or PR diff
---

# Testing Leverage Point

## When to Use

- A planning or PR-review agent is checking testing concerns
- A user explicitly asks for a testing-focused review
- The orchestrator (`software-leverage-review`) fans out a subagent for testing

## When NOT to Use

- For non-test code review unrelated to testing infrastructure
- For test execution or debugging individual test failures (different concern)

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect testing artifacts: test framework config, test directory layout, coverage tool, CI test invocations.
3. Apply checks:
   - Is there a test framework configured?
   - Is there a tests directory and does it mirror source layout?
   - Is coverage measured?
   - Are tests using mocks where integration would catch real bugs (red flag)?
4. Emit findings using the schema documented at `../software-leverage-review/output-schema.md`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"testing"`.

## Red Flags (anti-patterns to surface as findings)

- Mocked database in integration tests when a real one is feasible
- Test files exist but never invoked in CI
- Coverage configured but no enforcement threshold

## References & rationales

The "why" behind the checks above:

- **Test framework presence:** without a declared framework, every contributor reinvents test discovery and runner config. Cite: pytest's "framework as convention" model.
- **Tests mirror source layout:** discoverability. When `src/auth/login.py` has its tests at `tests/auth/test_login.py`, navigation is mechanical. Cite: pytest convention; Kent Beck (TDD) on test locality.
- **Coverage with enforcement threshold:** coverage measured but not gated drifts down silently. Cite: Martin Fowler on coverage as feedback, not goal; Kent Beck on tests as design pressure.
- **Mocked DB in integration tests:** mocks let bugs hide. The whole point of integration tests is the integration boundary. Cite: Vladimir Khorikov, *Unit Testing: Principles, Practices, and Patterns* (chapter on classical vs London-school TDD; argues integration tests should hit real collaborators where feasible). Cite: J.B. Rainsberger on "integrated tests are a scam" applies to the inverse: when you call a thing an integration test, integrate.
- **Tests not invoked in CI:** dead test files give false confidence. Cite: Continuous Integration discipline (Fowler).

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete (name the framework, the test path, the CI step).
