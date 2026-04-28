---
name: dry
description: Use when reviewing DRY (Don't Repeat Yourself) concerns: duplicated logic, scattered constants, copy-pasted fixtures, configuration repetition; balanced against the rule of three
---

# DRY Leverage Point

## When to Use

- A planning agent or PR-review agent encounters logic, configuration, or constants that appear in multiple places
- The orchestrator (`software-leverage-review`) fans out a subagent for DRY analysis
- A refactor proposal claims to "factor out" common code and the reviewer needs to check whether the abstraction is earned

## When NOT to Use

- For premature-abstraction concerns more broadly (use `software-complexity`); DRY focuses on duplication you can name, complexity focuses on shape that hides cost
- For module/layer separation (use `architecture`)
- For test-fixture mocking discipline beyond raw duplication (use `testing`)

The lens reference at `../software-leverage-review/references/dry.md` remains authoritative for the orchestrator's synthesis pass; this skill wraps the same lens for direct invocation.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect repetition signals: identical or near-identical code blocks, repeated constants, parallel configuration blocks, copy-pasted test fixtures, validation rules duplicated across boundaries.
3. Apply checks (mirroring `references/dry.md`):
   - Does the same logic appear in 3+ places without justification?
   - Are constants inlined as magic numbers/strings rather than named?
   - Are configuration values duplicated across files (env defaults, URLs, timeouts)?
   - Are test fixtures copy-pasted rather than factored into builders or shared helpers?
   - Conversely: is an abstraction being introduced for only 1-2 cases (rule-of-three violation in the other direction)?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"dry"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"dry"`.

## Red Flags (anti-patterns to surface as findings)

- **Same logic in 3+ places without justification.**
  - What to flag: identical or near-identical blocks of business logic, parsing, or validation in three or more locations.
  - Why it matters: every duplicate is a future bug paid three times. Behavior drifts when one site is patched and the others are forgotten, and the divergence is invisible until production surfaces it.
  - Cite: Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (1999), the original DRY framing: "every piece of knowledge must have a single, unambiguous, authoritative representation within a system."

- **Magic constants inlined instead of named.**
  - What to flag: literal numbers, strings, or regexes repeated across files (timeouts, retry counts, URL paths, status codes) with no shared named constant.
  - Why it matters: a number that means "the timeout we agreed on" is a knowledge artifact. Inlining it strips the meaning, so a future change has no anchor and the literal is hunted across the codebase by grep luck.
  - Cite: Martin Fowler, *Refactoring* (1999, 2018), "Magic Number" and "Duplicated Code" code smells.

- **Configuration values duplicated across files.**
  - What to flag: the same default port, timeout, URL, or feature flag declared independently in `.env`, a settings module, a CI config, and a Docker file.
  - Why it matters: configuration drift is silent until an environment goes off-script. One source of truth (a typed config module reading env, with everything else referring to it) is the only durable answer.
  - Cite: Hunt and Thomas, *Pragmatic Programmer*, on the DRY principle applied to configuration as well as code.

- **Test fixtures copy-pasted rather than factored.**
  - What to flag: the same user/order/event payload constructed verbatim in dozens of test files instead of via a builder, factory, or shared helper.
  - Why it matters: when the fixture's shape changes (a required field added), every copy must be updated. The cost is borne at refactor time, exactly when you most need confidence the tests still test what they claim.
  - Cite: Kent Beck, *Test-Driven Development by Example* (2002), on test fixtures as production-grade code; Fowler, *Refactoring*, on the test-code smell of duplicated setup.

- **Validation or business rules duplicated across boundaries.**
  - What to flag: an email-validation regex, a permission check, or a pricing rule implemented independently in the API layer, the domain layer, and the UI layer.
  - Why it matters: one of those copies will be subtly wrong, and the wrong one will be the one a user hits. Rules belong to the domain, with adapters delegating, not reimplementing.
  - Cite: Hunt and Thomas, *Pragmatic Programmer*, DRY framing; Fowler, *Refactoring*, on duplicate code as the smell to extract.

- **Premature abstraction (the inverse failure mode).**
  - What to flag: a base class, generic, or shared helper introduced to support 1-2 cases, often with comments like "for future flexibility."
  - Why it matters: the wrong abstraction is more expensive to remove than duplication is to maintain; future requirements rarely fit the speculative shape, so the abstraction warps every caller. Wait for three concrete cases before extracting.
  - Cite: Sandi Metz, "The Wrong Abstraction" (RailsConf 2016), the canonical statement that duplication is far cheaper than the wrong abstraction; Fowler, *Refactoring*, the rule of three; Joel Spolsky, *Joel on Software*, on the cost of architecture astronautics.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (1999, 20th-anniversary ed. 2019).** The original DRY framing: every piece of knowledge has a single authoritative representation. Use this when justifying the core principle.
- **Martin Fowler, *Refactoring* (1999, 2018).** "Duplicated Code" and "Magic Number" code smells; the rule of three as the antidote to over-abstraction. Use this when balancing DRY against premature abstraction.
- **Sandi Metz, "The Wrong Abstraction" (RailsConf 2016).** Wrong abstraction is harder to fix than duplication; the explicit anti-pattern statement. Use this when arguing for tolerating duplication until the third case lands.
- **Joel Spolsky, *Joel on Software* (2004) and the "architecture astronauts" essays.** On the cost of speculative abstraction. Use this when flagging an abstraction added for imagined future cases.
- **Kent Beck, "make it work, make it right, make it fast" (Smalltalk lineage; restated in TDD).** Sequencing on when to factor common code: only after it works and the duplication becomes a real maintenance signal. Use this when ordering refactors.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the constant to extract, the helper to introduce, the builder to factor out, or (for premature abstraction) the abstraction to inline back.
