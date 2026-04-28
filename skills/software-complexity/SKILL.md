---
name: software-complexity
description: Use when reviewing software complexity: cognitive load, cyclomatic and cognitive complexity, accidental coupling, premature abstraction, asymmetric simplicity
---

# Software Complexity Leverage Point

## When to Use

- A planning agent reviews a plan that adds abstractions, branchy logic, or structural changes that may pay or hide complexity cost
- A PR-review agent encounters new control-flow nesting, generics, or speculative scaffolding
- The orchestrator (`software-leverage-review`) fans out a subagent for complexity analysis

## When NOT to Use

- For runtime performance (out of scope; would belong to a future `performance` LP)
- For general code style or naming (use `developer-experience`)
- For raw duplication (use `dry`)
- For module boundaries (use `architecture`)

The lens reference at `../software-leverage-review/references/software-complexity.md` remains authoritative for the orchestrator's synthesis pass; this skill wraps the same lens for direct invocation.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect complexity signals: branching density, nesting depth, generic-parameter chains, abstractions added without three concrete cases, modules whose interface is shallow relative to their implementation.
3. Apply checks (mirroring `references/software-complexity.md`):
   - **Cognitive load:** does the function/class require more concepts in working memory than the task warrants?
   - **Cyclomatic / cognitive complexity:** is the branchy code lacking an extracted abstraction or table-driven structure?
   - **Accidental coupling:** are two modules co-varying because of an arbitrary shared assumption rather than a real dependency?
   - **Premature abstraction:** has an abstraction been introduced without three concrete cases driving it?
   - **Asymmetric simplicity:** does the abstraction make the common case harder so the rare case is easier?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"software-complexity"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"software-complexity"`.

## Red Flags (anti-patterns to surface as findings)

- **Shallow modules with wide interfaces.**
  - What to flag: a class or module whose public surface is nearly as large as its implementation; many methods, little hiding.
  - Why it matters: a shallow module spreads the implementation's complexity into every caller. Deep modules hide a lot of behavior behind a small interface, so the cost of using them stays bounded as the system grows.
  - Cite: John Ousterhout, *A Philosophy of Software Design* (2018), deep modules over shallow ones; complexity as the dominant force.

- **Cyclomatic or cognitive complexity high without a clear single purpose.**
  - What to flag: a function with deeply nested conditionals, switch ladders without a dispatch table, or cognitive-complexity scores well above the team's threshold.
  - Why it matters: branchy code is fine when each branch is genuinely a different case in a single decision; it is not fine when the branching is incidental and the function is doing several jobs interleaved.
  - Cite: Thomas McCabe, "A Complexity Measure" (IEEE TSE, 1976), the cyclomatic complexity original; Sonar's cognitive-complexity metric (G. Ann Campbell, 2017) as the modernization that weights nesting and structural patterns.

- **Accidental coupling between modules.**
  - What to flag: two modules that always change together because they share an arbitrary assumption (a magic constant, an undocumented ordering, a side effect's timing) rather than a designed contract.
  - Why it matters: the coupling is invisible until one side changes and the other silently breaks. Orthogonality is the discipline of making modules genuinely independent so a change in one cannot reach into another by surprise.
  - Cite: Frederick Brooks, "No Silver Bullet" (1986), essential vs accidental complexity; Hunt and Thomas, *The Pragmatic Programmer* (1999), the orthogonality principle.

- **Premature abstraction with fewer than three concrete cases.**
  - What to flag: a base class, generic, or strategy interface introduced "for future flexibility" with one or two callers; abstraction shaped by imagined requirements.
  - Why it matters: speculative abstraction locks the design into the wrong shape. Future requirements arrive in shapes the speculation did not anticipate, and every caller pays the cost of routing around the bad fit.
  - Cite: Martin Fowler, *Refactoring* (1999, 2018), the rule of three; Sandi Metz, "The Wrong Abstraction" (RailsConf 2016), wrong abstraction is harder to fix than duplication.

- **Asymmetric simplicity (common case hardened to make rare case easier).**
  - What to flag: an API where the typical caller writes 10 lines of boilerplate so an exotic caller can write 2; defaults that favor the unusual configuration.
  - Why it matters: most users hit the common case most of the time, so any tax there compounds. Make the common case fast and obvious; let the rare case be longer.
  - Cite: Ousterhout, *A Philosophy of Software Design*, "make the common case fast and obvious."

- **Comments that explain what the code does instead of why.**
  - What to flag: line comments restating the next statement; module headers that describe behavior already named by good identifiers.
  - Why it matters: when comments substitute for clear naming, the code stays unclear and the comments rot when the code changes. Comments are for the *why*, especially the non-obvious decisions; the *what* should live in the names.
  - Cite: Ousterhout, *A Philosophy of Software Design*, the chapter on comments; Hunt and Thomas, *Pragmatic Programmer*, on self-documenting code.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **John Ousterhout, *A Philosophy of Software Design* (2018, 2nd ed. 2021).** Complexity as the dominant force; deep modules over shallow ones; "make the common case fast and obvious"; comments are for the why. Use this as the primary modern source for complexity reasoning.
- **Thomas McCabe, "A Complexity Measure" (IEEE TSE, 1976).** Cyclomatic complexity as a structural metric. Use this when justifying a numeric ceiling on branchy code.
- **G. Ann Campbell / Sonar, "Cognitive Complexity" (2017).** A modernization of cyclomatic complexity that weights nesting and breaks-in-flow more heavily. Use this when arguing the metric should reflect human reading cost, not just decision points.
- **Frederick Brooks, "No Silver Bullet" (1986) and *The Mythical Man-Month* (1975).** Essential vs accidental complexity; the design-by-decomposition argument. Use this when classifying complexity as paid-for vs accidental.
- **Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (1999, 2019).** Orthogonality, ETC ("easier to change"), tracer bullets. Use this when arguing for module independence.
- **Martin Fowler, *Refactoring* (1999, 2018).** Code smells, the rule of three, the catalog of mechanical refactors. Use this when balancing complexity reduction against premature abstraction.
- **Sandi Metz, "The Wrong Abstraction" (RailsConf 2016).** The explicit anti-pattern: wrong abstraction is more expensive than duplication. Use this when flagging speculative scaffolding.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the abstraction to inline, the function to split, the dispatch table to introduce, or the comment to rewrite as a name.
