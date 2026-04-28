---
name: logging
description: Use when reviewing logging concerns: structured-vs-unstructured logs, log levels, observability boundaries, secret leakage, retention
---

# Logging Leverage Point

## When to Use

- A planning or PR-review agent is checking logging or observability concerns
- The orchestrator (`software-leverage-review`) fans out a subagent for logging
- A user explicitly asks for a logging-focused or observability-focused review

## When NOT to Use

- For metrics/tracing instrumentation that does not pass through the log pipeline (closer to a `metrics` or `tracing` LP, when those ship)
- For log analysis or incident triage on existing log data (a runtime concern, not a code-review concern)

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect logging artifacts: logger configuration, log calls, log level policy, redaction helpers, structured-log adapters, correlation/trace ID propagation, log-shipping config.
3. Apply checks:
   - Are logs structured (key-value or JSON) or free-form strings?
   - Is there a documented log-level policy, and do call sites follow it?
   - Are secrets and PII redacted before they reach the logger?
   - Do logs carry correlation IDs (request ID, trace ID) in distributed contexts?
   - Are logs tied into traces (trace ID, span ID) so a single event can be navigated across pillars?
   - Is `print()` (or equivalent) leaking into production code paths?
4. Emit findings using the schema at `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"logging"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"logging"`.

## Red Flags (anti-patterns to surface as findings)

- **Unstructured logs.**
  - What to flag: free-form strings (`logger.info("user " + id + " did " + action)`) instead of key-value or JSON (`logger.info("user_action", user_id=id, action=action)`).
  - Why it matters: without structure the log pipeline collapses into greppable text and you lose the ability to query by field, aggregate by user, or compute high-cardinality slices.
  - Cite: Charity Majors and Liz Fong-Jones, *Observability Engineering* (O'Reilly), on high-cardinality structured events as the foundation of observability. Cite also: Adam Wiggins on structured logging in 12-factor.
- **`print()` (or equivalent) in production code.**
  - What to flag: `print`, `console.log`, `fmt.Println`, or `System.out.println` in non-test code.
  - Why it matters: a `print` is a logger that bypasses level filtering, formatting, redaction, and shipping. It writes to stdout but tells the rest of the system nothing.
  - Cite: Twelve-Factor App, factor XI ("Logs"): the app writes event streams unbuffered to stdout via a logging interface, not ad-hoc prints, so the execution environment can route them.
- **Log levels chosen by feel.**
  - What to flag: everything at `info`, nothing at `debug` or `warn`, or `error` used for non-error events.
  - Why it matters: without a documented level policy, levels lose signal value and on-call engineers stop trusting them; alerts wired to `error` then go quiet or fire constantly.
  - Cite: Cindy Sridharan, *Distributed Systems Observability* (O'Reilly), on log levels as a deliberate filter rather than decoration.
- **PII or secrets logged unredacted.**
  - What to flag: passwords, tokens, API keys, full request bodies, full headers (especially `Authorization`), full SQL with bound parameters.
  - Why it matters: a security and compliance failure independent of observability quality. Logs are often shipped to systems with weaker access control than the primary store.
  - Cite: OWASP Top 10 A09 (Security Logging and Monitoring Failures). Cite: GDPR Article 5(1)(c), data-minimization principle: do not collect, and therefore do not log, more than is necessary.
- **No correlation IDs in distributed systems.**
  - What to flag: a request crosses two or more services and no shared identifier links the logs.
  - Why it matters: without correlation you cannot answer "what happened to this request"; debugging degrades to timestamp-correlation across services.
  - Cite: Sridharan on the three pillars; the fix is to generate a correlation ID at the edge and propagate it through every hop's MDC/context (e.g., `X-Request-ID`, `traceparent`).
- **Logs untied to traces.**
  - What to flag: logs and traces stored in separate systems with no shared trace ID or span ID.
  - Why it matters: you can see a slow span or a noisy log line, but cannot pivot from one to the other.
  - Cite: Majors and Fong-Jones on events as the substrate that unifies the pillars; trace-aware logs are the cheapest way to make that substrate real.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **Charity Majors and Liz Fong-Jones, *Observability Engineering* (O'Reilly).** The canonical argument for structured, high-cardinality event logging as the foundation of debuggable production systems. Use this when justifying structure-over-grep.
- **Cindy Sridharan, *Distributed Systems Observability* (O'Reilly).** The three-pillars framing (logs, metrics, traces) and how they relate. Use this when justifying correlation IDs, trace linking, and level discipline.
- **Twelve-Factor App, factor XI ("Logs"), Adam Wiggins.** Treat logs as event streams; the app writes; the environment routes. Use this when justifying "no in-app log file paths" and "no `print()` in production".
- **Brendan Gregg, USE method; Tom Wilkie, RED method.** Logs feed metrics in well-instrumented systems. If a log line is the source of a metric, it must be structured and stable. Use this when justifying field-name discipline.
- **OWASP Top 10 A09 (Security Logging and Monitoring Failures).** The category that pairs "log too little to investigate" with "log too much and leak secrets". Use this when justifying redaction and audit-log presence in the same review.
- **GDPR Article 5(1)(c), data minimization.** Logs are processing. Do not log more PII than the purpose requires. Use this when justifying redaction at the boundary, not in the sink.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the logger, name the redaction helper, point at the propagation header (e.g., `traceparent`, `X-Request-ID`), or name the level policy doc.
