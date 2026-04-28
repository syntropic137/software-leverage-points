---
name: purpose-and-scope
description: "Use when reviewing purpose-and-scope concerns: project's stated purpose, in-scope vs out-of-scope boundaries, plan alignment with stated purpose, scope creep, separation of concerns at the project level"
---

# Purpose and Scope Leverage Point

## When to Use

- Before any plan or PR is implemented, to confirm alignment with the project's stated purpose
- Whenever the implementation surface seems to grow past stated scope
- Whenever a new dependency or module looks tangential to the project's reason for existing
- The orchestrator (`software-leverage-review`) fans out a subagent for purpose-and-scope as the first lens

## When NOT to Use

- For low-level architectural separation (module boundaries, layering, dependency direction): that is the `architecture` LP. This LP cares about scope at the project and plan level, not at the module level.
- For principle-level cross-cutting concerns (DRY, complexity, naming): use the `principles-and-patterns` lens.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect purpose-and-scope artifacts: `README.md` purpose section, `PURPOSE.md`, `ARCHITECTURE.md`, `ADR-0001` (project-charter ADR), explicit non-goals list, milestone/roadmap docs, plan documents.
3. Apply checks:
   - Does the repo have a clear, written statement of purpose and non-goals (README, `PURPOSE.md`, `ADR-0001`)?
   - Does the plan or PR align with that stated purpose?
   - Are out-of-scope additions surfaced explicitly, and either deferred, rejected, or accompanied by an explicit scope expansion?
   - Is the plan's scope decomposable to one axis of change?
   - Are new dependencies or modules justified by the stated purpose?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"purpose-and-scope"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"purpose-and-scope"`.

## Red Flags (anti-patterns to surface as findings)

- **No written statement of purpose or non-goals.**
  - What to flag: a repo whose README opens with install instructions but never names the problem the project solves, the users it serves, or the things it explicitly does not do.
  - Why it matters: without a stated purpose, every contributor (human or agent) extrapolates one from the code, and extrapolations diverge. The conceptual integrity Brooks names as the most important property of a system needs an anchor; a one-paragraph purpose statement is the cheapest possible anchor.
  - Cite: Frederick Brooks, *The Mythical Man-Month* (1975), on conceptual integrity as the most important consideration in system design. Cite also: the `PROJECT.md` and `ARCHITECTURE.md` conventions popularized by Andrew Gallant ("burntsushi") in canonical Rust projects.

- **Plan introduces a feature that does not match any stated user story or goal.**
  - What to flag: a plan whose motivation is "would be nice," "for completeness," or "while we are here," with no link to a stated user, problem, or goal in the project's purpose document.
  - Why it matters: unanchored features are scope debt. They consume the same review, test, and maintenance budget as anchored features but produce no purposeful value, and they make the system harder to reason about for everyone afterward. The Lean stance is to call this waste and refuse it at the plan stage.
  - Cite: Mary and Tom Poppendieck, *Lean Software Development* (2003), on eliminating waste and just-in-time scope.

- **New dependency added without a purpose-link justification.**
  - What to flag: a PR adding a library to `package.json`, `pyproject.toml`, or `Cargo.toml` whose justification is only "we needed X" with no reference to which user-facing or stated-purpose need it serves.
  - Why it matters: a dependency is a permanent commitment and a supply-chain surface; it deserves a justification at the same level as a module. Tying every dependency back to the stated purpose prevents the slow drift toward "tool-of-the-week" syndrome and keeps the dependency graph reviewable.
  - Cite: Donald Reinertsen, *Principles of Product Development Flow* (2009), on the cost of work-in-progress and the discipline of explicit acceptance criteria. Cross-reference: see the `dependencies` LP for the supply-chain cost.

- **Scope creeps within a single PR (plan said X, PR delivers X plus Y plus Z).**
  - What to flag: a PR title or plan referencing one change while the diff includes refactoring, formatting, an unrelated bug fix, or a new feature alongside.
  - Why it matters: scope-creeping PRs are unreviewable in proportion to the creep. Reviewers either skip the unrelated parts (defeating review) or block on them (delaying the original change). The discipline is one PR per axis of change, with the others extracted into their own PRs.
  - Cite: John Ousterhout, *A Philosophy of Software Design* (chapter 9, "Better Together or Better Apart?"), on the problem of crammed scope.

- **Out-of-scope concerns added "while we are here" without owner sign-off.**
  - What to flag: a plan or PR whose narrative includes "since we are touching this area" or "while refactoring," followed by changes that go beyond the original goal and were not approved as scope.
  - Why it matters: opportunistic scope creep looks efficient (saving a future PR) but compounds the review burden and delays the original change. If the additional work is genuinely valuable, it deserves its own scope decision, not a smuggled-in addition. Michael Nygard's ADR practice generalizes here: scope changes deserve the same explicit decision capture as architecture changes.
  - Cite: Michael Nygard's ADR practice generalized to scope decisions, not just architecture. Cite also: Reinertsen on WIP cost.

- **Bounded contexts blurred at the project level.**
  - What to flag: a plan that crosses concerns the repo was supposed to keep separate (e.g., a "data pipeline" repo growing a web UI, a "library" repo growing a CLI runtime that pulls in heavy dependencies).
  - Why it matters: project-level bounded contexts exist so each repo can evolve on its own clock with its own constraints. Blurring them collapses the autonomy and forces every contributor to reason about both contexts simultaneously. The Domain-Driven Design strategic stance is that the bounded-context boundary is a deliberate decision, and crossing it deserves an ADR or a new repo.
  - Cite: Eric Evans, *Domain-Driven Design* (2003), on bounded contexts at the strategic level.

- **Stated non-goals quietly violated.**
  - What to flag: a project that lists "we do not do X" in its README or charter ADR, where the plan or PR begins to do exactly X without acknowledging the contradiction.
  - Why it matters: non-goals are the highest-leverage scope discipline because they prevent drift the README cannot otherwise prevent. Quietly violating a non-goal is worse than never having stated it, because future contributors will trust the stated non-goal and be surprised. If the non-goal is genuinely changing, change the README first.
  - Cite: Brooks on conceptual integrity. Cite also: `PROJECT.md` conventions in canonical Rust projects, where non-goals are routinely listed alongside goals.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Frederick Brooks, *The Mythical Man-Month* (1975).** Conceptual integrity as the most important consideration in system design. Use this as the foundational stance behind every purpose-and-scope check.
- **Eric Evans, *Domain-Driven Design* (2003).** Bounded contexts at the strategic level. Use this when justifying project-level scope boundaries and arguing against context-blurring.
- **John Ousterhout, *A Philosophy of Software Design* (chapter 9).** "Better Together or Better Apart?" The problem of crammed scope. Use this when reviewing PRs that bundle multiple concerns.
- **Mary and Tom Poppendieck, *Lean Software Development* (2003).** Eliminating waste and just-in-time scope. Use this when arguing against speculative or unanchored features.
- **Donald Reinertsen, *Principles of Product Development Flow* (2009).** The cost of work-in-progress and explicit acceptance criteria. Use this when justifying scope-discipline at the plan stage.
- **Michael Nygard's ADR practice.** Generalized from architecture decisions to scope decisions. Use this when arguing that scope changes deserve the same capture rigor as architecture changes.
- **`PROJECT.md` and `ARCHITECTURE.md` conventions (Andrew Gallant / "burntsushi" style).** Canonical examples in popular Rust projects of explicit goals-and-non-goals documentation. Use this when recommending where to write the purpose statement.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the `PURPOSE.md` or charter ADR to author, the non-goal to add, the unrelated change to extract into its own PR, the dependency to justify or remove, or the scope expansion to capture as an ADR.
