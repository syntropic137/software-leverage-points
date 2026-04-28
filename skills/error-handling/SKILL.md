---
name: error-handling
description: Use when reviewing error-handling concerns: error taxonomy, propagation discipline, retry semantics, exit codes, exception boundaries, error messages as a contract
---

# Error Handling Leverage Point

## When to Use

- A planning agent reviews a plan that introduces or alters error types, exception boundaries, or retry policies
- A PR-review agent encounters new throws, catches, `Result`/`Either` types, or changes to CLI exit codes
- The orchestrator (`software-leverage-review`) fans out a subagent for error-handling analysis

## When NOT to Use

- For input validation as a security concern (use `security`); error handling assumes inputs have already been classified as failure modes
- For logging the error events themselves (use `logging`); this LP owns the *shape* of the error, not the *record* of it
- For dependency-failure resilience patterns at the architectural level, e.g., circuit breakers across services (use `architecture`)

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect error-handling artifacts: typed error definitions, try/catch blocks, `Result`/`Either` returns, retry helpers, exit-code constants, error-message strings exposed to users or logs.
3. Apply checks:
   - Are errors typed (a named taxonomy) rather than generic `Error` / `Exception` / strings?
   - Is the taxonomy explicit about recoverable vs unrecoverable, transient vs permanent, user-facing vs system?
   - Is propagation deliberate (`Result`/`Either`, explicit catch boundaries) rather than implicit (uncaught exceptions bubbling)?
   - Are retry policies bounded with max attempts, backoff, and jitter? Is idempotency required where retries fire?
   - Are exit codes meaningful in CLI/CI contexts: zero for success, distinct non-zero codes for distinct failure modes?
   - Are error messages part of the contract: user-facing vs log-facing vs machine-parseable distinguished?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"error-handling"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"error-handling"`.

## Red Flags (anti-patterns to surface as findings)

- **Generic `Exception` / `Error` / `panic` without a typed taxonomy.**
  - What to flag: `throw new Error("...")`, `raise Exception(...)`, or `panic!(...)` used as the only error mechanism, with no named error types or discriminated union.
  - Why it matters: callers cannot distinguish failure modes, so they either catch everything (and silently mishandle) or catch nothing (and crash on anything). A taxonomy is the contract that lets callers act differently for different reasons.
  - Cite: Bruce Eckel, *Thinking in Java* (4th ed.), chapter on exceptions, on the checked-vs-unchecked design pressure; Rust's `Result<T, E>` and `?` operator as the modern reference for typed propagation.

- **Bare `except:` or catch-all blocks that swallow the error.**
  - What to flag: `try: ... except: pass`, `catch (e) {}`, or any catch site that drops the error without rethrowing, logging structurally, or recording it.
  - Why it matters: silenced errors become ghost bugs. The system limps on in a broken state and the operator has no thread to pull on when behavior diverges later. "Crash early" is the assertive-programming counter-discipline.
  - Cite: Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (1999), assertive programming and "crash early"; Joe Armstrong, "Let It Crash" (Erlang philosophy), supervise and restart rather than mask.

- **Retry without bound, or without backoff, on transient failure.**
  - What to flag: `while True: try: call(); break except: continue` style loops; retries with no `max_attempts`, no exponential backoff, no jitter; retry of non-idempotent operations.
  - Why it matters: unbounded retries amplify the failure into a self-DOS; retries without backoff synchronize across clients into thundering-herd waves; retries of non-idempotent operations corrupt state. Bounded backoff with jitter is the production-grade pattern.
  - Cite: Google SRE Book, chapter on handling overload and the "retry budget" pattern; AWS Architecture Blog, "Exponential Backoff and Jitter" (Marc Brooker, 2015).

- **Error messages that say "Something went wrong" without the something.**
  - What to flag: user-facing or operator-facing strings that name no entity, no operation, no actionable next step.
  - Why it matters: the error message is a contract with whoever reads it. A useless message is the difference between "user retries with a fix" and "user files a ticket"; between "operator restarts the right service" and "operator restarts everything."
  - Cite: Cindy Sridharan, *Distributed Systems Observability* (2018), on errors as observable events; Charity Majors on operator-facing error quality.

- **Same exit code for distinct failure modes (CLI/CI).**
  - What to flag: a CLI that returns `1` for "config missing," "network unreachable," and "validation failed" alike; a script whose `$?` carries no information.
  - Why it matters: CI pipelines and shell harnesses act on exit codes. Collapsing distinct modes into one code throws away the dispatch signal and forces text scraping of stderr, which is brittle.
  - Cite: POSIX/sysexits.h conventions (Eric Allman, BSD sendmail, 1980s) for the canonical small-integer exit-code taxonomy; Joel Spolsky, "Exceptions" (2003), on exceptions vs return codes as a spectrum debate.

- **Re-raising loses the original cause.**
  - What to flag: `raise NewError("wrapped")` without `from e`; `throw new Error("wrapped: " + e.message)` that drops the stack; Go's `fmt.Errorf("...: %v", err)` instead of `%w`.
  - Why it matters: the wrapped-cause chain is the breadcrumb trail for debugging. Losing it forces a re-creation of the failure to understand it, which is sometimes impossible (transient, environment-specific).
  - Cite: Python's PEP 3134 (exception chaining); Go 1.13's `errors.Is`/`errors.As` and `%w` verb; Rust's `source()` chain on `std::error::Error`.

- **Error string built from unsanitized user input.**
  - What to flag: error messages constructed via string interpolation of user-provided values, especially when those messages flow into HTML, SQL, or shell contexts.
  - Why it matters: the error path is an injection vector. Cross-references the `security` LP. Sanitize, escape, or structure the message; don't concatenate.
  - Cite: OWASP Top 10 A03 (Injection); see `security` LP for full treatment.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Joe Armstrong, "Let It Crash" (Erlang).** The supervisor/restart model: design components to fail cleanly and let a supervisor decide recovery; do not paper over errors with defensive code. Use this when arguing against catch-all swallowing.
- **Andy Hunt and Dave Thomas, *The Pragmatic Programmer* (1999, 2019).** Assertive programming and "crash early." Use this when arguing for visible failure over silent degradation.
- **Bruce Eckel, *Thinking in Java*.** The chapter on exceptions: checked vs unchecked, the design pressure of forced handling. Use this when justifying a typed taxonomy.
- **Joel Spolsky, "Exceptions" (Joel on Software, 2003).** The spectrum debate between exceptions and return codes. Use this when discussing propagation style with a team that has a strong stance.
- **Roberto Ierusalimschy, *Programming in Lua*.** The `pcall`/`xpcall` model and the explicit-error-handling lineage. Use this when arguing that error handling deserves first-class language treatment.
- **Rust's `Result<T, E>` and `?` operator.** The modern reference for typed propagation discipline; the compiler enforces that errors are either handled or propagated. Use this when justifying explicit-propagation patterns in any language.
- **Kent Beck, *Test-Driven Development by Example* (2002).** Tests that name the failure mode, so the failure mode becomes part of the design vocabulary. Use this when arguing the taxonomy should be testable.
- **Cindy Sridharan, *Distributed Systems Observability* (2018).** Errors as observable events; the operator-facing quality bar. Use this when arguing error messages are a contract.
- **Google SRE Book (Beyer et al., 2016) and AWS "Exponential Backoff and Jitter" (Brooker, 2015).** Bounded retries with backoff and jitter; retry budgets. Use this when justifying retry-policy discipline.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the error type to introduce, the catch boundary to narrow, the backoff parameters to add, the exit code to allocate, or the cause-wrapping idiom to use.
