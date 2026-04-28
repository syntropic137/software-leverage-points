---
name: security
description: "Use when reviewing security concerns: secrets in code, SAST coverage, input validation, authn/authz boundaries, sensitive-data handling, dependency CVEs"
---

# Security Leverage Point

## When to Use

- A planning agent is reviewing a plan that touches authentication, authorization, secrets, input boundaries, or sensitive data
- A PR-review agent encounters changes to handlers, auth middleware, query builders, log statements, or `.env` files
- The orchestrator (`software-leverage-review`) fans out a subagent for security

## When NOT to Use

- For supply-chain provenance, lockfile health, and dependency pinning: that is the `dependencies` LP. CVE gates on the resolved tree are flagged here from the runtime-attack side and there from the supply-chain side; cross-reference rather than duplicate.
- For configuration layering and secret-vs-non-secret separation: that is the `configuration` LP. This LP cares whether secrets exist in source; that LP cares how config is loaded and validated.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect security-relevant artifacts: source files, CI configuration, auth middleware, query construction sites, log statements, `.env*` files, error handlers.
3. Apply checks:
   - Are there secrets in the source tree (API keys, tokens, private keys, hardcoded credentials, committed `.env` files)?
   - Does CI run a SAST tool (Semgrep, CodeQL, language-specific linters with security rules)?
   - Are input boundaries (HTTP request bodies, CLI args, environment variables, message-queue payloads) validated and sanitized at the edge?
   - Is authn/authz logic centralized at a single chokepoint, or sprinkled across handlers?
   - Is sensitive data (PII, financial, health) handled per a data-classification policy, including in logs and error responses?
   - Are dependency CVEs gated by CI (cross-reference the `dependencies` LP)?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"security"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"security"`.

## Red Flags (anti-patterns to surface as findings)

- **Hardcoded secrets in source or committed `.env` files.**
  - What to flag: an API key, token, private key, password, or connection string with embedded credentials in a tracked file. Includes `.env` files that are not in `.gitignore`.
  - Why it matters: a secret in git history is compromised the moment the repo is read, and rotation is the only remediation. CWE-798 (Use of Hard-coded Credentials) is on the CWE Top 25 because it is both common and trivially exploitable: scanners harvest GitHub continuously.
  - Cite: CWE Top 25 (MITRE), CWE-798. Cite also: OWASP ASVS V2 (Authentication) and V14 (Configuration), which require secrets to live in a managed store.

- **No SAST in CI.**
  - What to flag: a CI pipeline that runs tests and lint but has no static-analysis pass with security rules (Semgrep, CodeQL, Bandit, gosec, etc.).
  - Why it matters: humans miss patterns that machines catch deterministically: tainted-flow violations, unsafe deserialization, weak crypto choices, dangerous defaults. Without a SAST gate, every PR relies on every reviewer remembering every class of bug.
  - Cite: OWASP Top 10 (2021), specifically A06 (Vulnerable and Outdated Components) and A04 (Insecure Design); both are reliably surfaced by SAST when SAST is present and silent when it is not.

- **Manual SQL or HTML construction without parameterization or escaping.**
  - What to flag: string concatenation or interpolation building a SQL query, an HTML response, an LDAP filter, a shell command, or a template, with user-controlled values.
  - Why it matters: injection (SQLi, XSS, command injection) is OWASP A03 and the canonical class of "untrusted input crosses an interpreter boundary." Equifax's 2017 breach via CVE-2017-5638 (Apache Struts) is the canonical reminder that one missed boundary at the edge can cost the entire customer database.
  - Cite: OWASP Top 10 (2021), A03 (Injection). Cite also: Michal Zalewski, *The Tangled Web* (2011), for the browser-side threat surface where escaping discipline is non-negotiable.

- **Auth checks done in views or controllers ad hoc rather than at a single chokepoint.**
  - What to flag: an `if user.is_admin` check inside a view function, with no equivalent check at a middleware or policy layer; or two endpoints implementing the same authorization with two different rules.
  - Why it matters: scattered auth logic is how broken access control happens. OWASP A01 (Broken Access Control) is the most prevalent category in the 2021 Top 10, and the typical mechanism is exactly this: an endpoint added without remembering the check, or two endpoints with two slightly different checks.
  - Cite: OWASP Top 10 (2021), A01 (Broken Access Control). Cite also: Adam Shostack, *Threat Modeling: Designing for Security* (2014), on identifying trust boundaries and centralizing decisions at them.

- **PII logged or returned in error messages.**
  - What to flag: log statements that emit email addresses, government IDs, full credit-card numbers, auth tokens, or session cookies; error handlers that echo user input or stack traces back to the client unredacted.
  - Why it matters: logs and error responses are exfiltration channels, and they propagate into systems with broader read access (log aggregators, support tools, backups) where the original access controls do not apply. Modern privacy regimes treat unredacted PII in logs as a data-handling violation per se.
  - Cite: NIST SP 800-53, control AU-9 (Protection of Audit Information) and SI-11 (Error Handling), for the explicit pairing of log protection and error-message hygiene.

- **No CVE gate on dependencies (cross-reference: `dependencies` LP).**
  - What to flag: a CI pipeline with no step that scans the resolved dependency tree against an advisory database, or a known-CVE finding from the `dependencies` review with no remediation plan.
  - Why it matters: the Equifax 2017 breach (CVE-2017-5638, Apache Struts) is the textbook lesson: a patch had been available for two months, the CVE was cataloged, and no automated gate caught the unpatched build. The runtime cost was 147 million records.
  - Cite: the 2017 Equifax breach (CVE-2017-5638, Apache Struts). Cite also: OWASP Top 10 (2021), A06 (Vulnerable and Outdated Components). See the `dependencies` LP for the supply-chain side of the same gate.

- **Missing threat-model artifact for high-stakes changes.**
  - What to flag: a plan or PR that introduces a new external interface, a new auth flow, a new data classification, or a new third-party integration, with no STRIDE-style or attack-tree analysis attached.
  - Why it matters: security decisions made implicitly are security decisions that nobody owns. Threat modeling at design time is the cheapest place to discover that the proposed authentication is replayable, that the new endpoint is missing rate limiting, or that the integration leaks tenant identifiers.
  - Cite: Adam Shostack, *Threat Modeling: Designing for Security* (2014), STRIDE and the four-question framework. Cite also: NIST SP 800-53 control PL-8 (Security and Privacy Architectures) for the high-stakes contexts where this is mandated.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **OWASP Top 10 (2021).** The canonical web-application vulnerability list, ordered by prevalence and impact. Use this as the high-level taxonomy when classifying findings (A01 Broken Access Control, A03 Injection, A06 Vulnerable Components, etc.).
- **OWASP ASVS (Application Security Verification Standard).** Structured controls organized by chapter (V2 Authentication, V3 Session, V5 Validation, V14 Configuration, etc.). Use this when a finding needs a specific verification requirement, not just a category.
- **CWE Top 25 (MITRE).** The software-weakness taxonomy at the code-pattern level (CWE-798 hardcoded credentials, CWE-89 SQL injection, CWE-79 XSS). Use this when the finding is a specific code shape, not a category.
- **Adam Shostack, *Threat Modeling: Designing for Security* (2014).** STRIDE, the four-question framework ("what are we working on, what can go wrong, what are we going to do about it, did we do a good job"), and trust-boundary analysis. Use this when justifying threat-model artifacts and centralized decision points.
- **Michal Zalewski, *The Tangled Web* (2011).** Browser-side threat surface; same-origin policy, content sniffing, the long history of escaping mistakes. Use this when justifying escaping and CSP discipline.
- **The 2017 Equifax breach (CVE-2017-5638, Apache Struts).** The canonical "patch dependency CVEs" lesson: a known, cataloged, two-months-old vulnerability went unpatched. Use this when justifying CVE gates and patch SLAs.
- **NIST SP 800-53 control catalog.** The controls catalog for high-stakes contexts (AU-9 audit protection, SI-11 error handling, PL-8 security architectures). Use this when the target operates under a compliance regime that requires named control mappings.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the secret to rotate and the manager to move it into, the SAST tool to add, the parameterization API to use, the middleware to centralize the check in, or the field to redact.
