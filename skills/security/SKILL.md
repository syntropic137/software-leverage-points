---
name: security
description: "Use when reviewing security concerns: secrets in code, SAST coverage, input validation, authn/authz boundaries, sensitive-data handling, dependency CVEs, SSRF, hand-rolled escaping, threat modeling for high-stakes changes"
---

# Security

## Overview

Security is the lens that asks who can reach this code, with what input, and what they can do once they are inside. Done well, secrets live in a managed store, input is validated at the edge, authorization is centralized, sensitive data does not leak through logs or errors, and outbound calls cannot be coerced into reaching internal services. Done poorly, a single missed boundary or a hardcoded credential is enough to lose the customer database.

**Core principle:** Trust boundaries are explicit, decisions are centralized at them, and every input crossing them is validated. Security failures are the ones the codebase forgets to make explicit.

## Core Principles

### 1. Secrets do not live in source

API keys, tokens, private keys, passwords, and connection strings with embedded credentials never live in tracked files, including `.env` files that fail to make it into `.gitignore`. A secret in git history is compromised the moment the repo is read; rotation is the only remediation, and scanners harvest public hosting continuously.

**Multiple valid secret stores exist:** centralized secret manager, cloud-provider native, envelope-encrypted files. The principle is: secrets live in a managed store, not in source. The red flag is "secret in source," not "did not use a particular vendor." See the `configuration` lens for how secrets and non-secrets share (or do not share) a namespace. Cross-reference: the `continuous-deployment` lens carries the deploy-time credential-scoping and rotation stance that consumes these stored secrets at release time.

### 2. Static analysis runs in CI (scope: projects with CI)

This principle scopes to projects with a CI pipeline. When the scope applies: a static-analysis pass with security rules runs on every PR. Humans miss patterns that machines catch deterministically: tainted-flow violations, unsafe deserialization, weak crypto choices, dangerous defaults. Without a SAST gate, every PR relies on every reviewer remembering every class of bug.

**Multiple valid SAST stacks exist:** a single general-purpose tool, a stack of language-specific tools, or a managed service. The principle is: a SAST gate is present in CI; the choice between stacks depends on language mix and maturity.

### 3. Use parameterization, not hand-rolled escaping

String concatenation or interpolation building a SQL query, an HTML response, an LDAP filter, a shell command, or a template, with user-controlled values, is injection waiting to happen. Use the platform's parameterization API (prepared statements, contextual auto-escaping templates, argv-style command invocation), not string concatenation.

In-repo `escapeYaml`, `escapeJson`, `escapeSql`, `escapeHtml`, or `escapeShell` helpers with bespoke quoting logic are a closely related red flag. An escape function encodes the assumption that the author understands every edge case the target format admits; YAML (block vs flow scalars, anchors, tags) and shell (word splitting, glob, history expansion) are particularly hostile to this assumption. Use a parser/serializer library that round-trips through the format's grammar.

### 4. Centralize authorization at trust boundaries

Authorization checks live at a single chokepoint (middleware, policy layer, framework guard), not sprinkled ad hoc through views and handlers. Scattered auth logic is how broken access control happens: an endpoint added without remembering the check, or two endpoints implementing the same authorization with two different rules.

### 5. Redact sensitive data before it reaches logs and error responses

Log statements and error handlers are exfiltration channels: they propagate into systems with broader read access (log aggregators, support tools, backups) where the original access controls do not apply. Email addresses, government IDs, full credit-card numbers, auth tokens, and session cookies must be redacted at the boundary; error responses to clients must not echo user input or stack traces unredacted.

This principle scopes to data classified as sensitive under the project's data-classification policy. Cross-reference the `logging` lens for the redaction-at-the-boundary mechanic.

### 6. Gate dependency CVEs in CI

A CI step that scans the resolved dependency tree against an advisory database is non-negotiable. The runtime-attack side of the same gate the `dependencies` lens carries from the supply-chain side: a known, cataloged, two-months-old CVE that nobody's automated gate caught is the canonical breach pattern.

### 7. Constrain outbound requests built from untrusted input (SSRF)

When an outbound HTTP request URL is influenced by user input, remote content, or a redirect target, the server can be coerced into reaching internal services (cloud metadata endpoints, internal admin APIs) or attacker-controlled hosts. Outbound calls with untrusted URL components require an allowlist on host or scheme and a block on internal IP ranges (RFC 1918, link-local, loopback).

**Multiple valid allowlist scopes exist:** host-based, scheme-based, IP-class-based, or a combination. The principle is: untrusted URL components are constrained at the call site, not "we used a sensible URL parser." The choice depends on what the call legitimately needs to reach; a more permissive allowlist requires a stronger justification.

### 8. Threat-model high-stakes changes (scope: new external interfaces, auth flows, data classifications, third-party integrations)

This principle scopes to changes that introduce a new external interface, a new authentication flow, a new data classification, or a new third-party integration. When the scope applies: a STRIDE-style or attack-tree analysis is attached to the design. Security decisions made implicitly are security decisions that nobody owns; threat modeling at design time is the cheapest place to discover that the proposed authentication is replayable or the new endpoint is missing rate limiting.

## Red Flags - STOP

- Hardcoded secrets in source: API keys, tokens, private keys, passwords, connection strings with embedded credentials, or `.env` files outside `.gitignore`
- No SAST gate in a CI-equipped project; security rules absent from the lint/static-analysis pass
- String concatenation building SQL, HTML, LDAP, shell, or template output with user-controlled values; in-repo hand-rolled escape/quoting helpers used at injection boundaries
- Authorization checks done ad hoc inside views or handlers, with no centralized chokepoint; or two endpoints implementing the same authorization with two different rules
- PII, auth tokens, or session cookies in log statements; user input or stack traces echoed unredacted in error responses
- No CI step scanning the resolved dependency tree against an advisory database; known-CVE findings with no remediation plan
- Outbound HTTP calls with user-influenced URL components and no allowlist on host or scheme, no block on internal IP ranges (SSRF surface)
- New external interface, auth flow, data classification, or third-party integration shipped with no STRIDE-style threat-model artifact

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "The secret is in a private repo, it's safe" | Private becomes public via exfiltration, mistakes, or open-sourcing; rotation is the only remediation |
| "SAST has too many false positives" | Tune the rules; the alternative is human reviewers remembering every bug class |
| "Our escape function is fine; we wrote it carefully" | Escape functions encode every edge case of a hostile grammar; parser libraries round-trip them |
| "The auth check is right there in the handler" | And in forty other handlers, with three subtly different rules |
| "Logging the user object is just for debugging" | Debug logs ship to aggregators with weaker access control; the leak is durable |
| "We patch CVEs when we hear about them" | The Equifax patch was available for two months; the runtime cost was 147M records |
| "The URL parameter is fine; users wouldn't abuse it" | Capital One agrees in retrospect: 100M+ records via SSRF to the metadata endpoint |
| "Threat modeling is overhead for a small change" | Until the small change is the new auth flow that admits replay attacks |

## Key Patterns

```
✅ Secret pulled from a managed secret store at runtime
❌ Secret hardcoded in source or committed in .env
```

```
✅ CI step: SAST scan with security rules on every PR
❌ Lint passes; no security rules; reviewer is the only gate
```

```
✅ db.execute("SELECT * FROM users WHERE id = ?", (user_id,))
❌ db.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

```
✅ require_role("admin") middleware on every admin route; one source of truth
❌ if user.is_admin: ... scattered across handlers with subtly different rules
```

```
✅ logger.info("login_attempt", user_id=user.id)  (PII redacted; ID only)
❌ logger.info(f"User {user.email} logged in with password {password}")
```

```
✅ CI step: advisory-database scan; PR fails on critical CVEs
❌ CVE check is a manual quarterly task that slipped last quarter
```

```
✅ httpx.get(url, ...) where url passes allowlist (scheme, host, not RFC1918)
❌ httpx.get(user_supplied_url) with no validation
```

```
✅ Plan attaches a STRIDE analysis for the new third-party integration
❌ New auth flow ships with no threat-model artifact; replay attack discovered later
```

## Why This Matters

Security failures are the failures the codebase forgets to make explicit. Every check above closes a class of incident that has already happened to someone, often famously. The cost of skipping them is paid not at write time but in incident response, regulatory exposure, and customer trust.

Without disciplined security practice:

- Secrets leak via git history, log aggregators, debug dumps, and committed `.env` files.
- Injection vulnerabilities accumulate at every interpreter boundary the codebase touches.
- Broken access control surfaces every time a new endpoint forgets the auth check.
- CVE breaches catch up to the team on the timetable of attackers, not maintainers.
- SSRF, mass assignment, and replay attacks succeed because the threat model was never explicit.

With disciplined security practice:

- Secrets live in a managed store; rotation is automatable; leakage is bounded.
- Parameterization makes injection structurally impossible at the boundaries that matter.
- Authorization is centralized; adding an endpoint inherits the check by default.
- CVE gates surface vulnerabilities on their patch timetable, not the attacker's.
- Threat-model artifacts make the security posture reviewable before code lands.

Cross-reference: the `environments` lens carries the per-environment parity discipline that keeps the secret-loader and trust boundary uniform across dev, staging, and production so security posture does not silently weaken in one tier.

Cross-reference: the `error-handling` lens carries the "messages are a contract" framing this lens pairs with at the error boundary; together they ensure error responses neither echo unsanitized input nor leak internals.

Cross-reference: the `types` lens carries the soundness side of boundary validation, refining untrusted input into a typed shape exactly once at the same seam this lens guards as an attack surface.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** secrets are not committed; obvious injection sites use parameterization. Awareness that the surface will need a SAST gate and CVE scanning as soon as users arrive.
- **Growing internal tool:** secret manager in use; SAST gate in CI; CVE scan on PRs; first auth chokepoint established. Logs are checked for PII at the boundary even if redaction is not yet automated.
- **Shared library:** library exposes no secrets, never logs caller-supplied secrets even if passed them, and documents the trust boundary. Released with provenance attestations.
- **Production service:** secrets in a managed store with automated rotation; SAST + CVE gates enforced in CI; centralized authorization with policy tests; PII redaction at the logger boundary; SSRF allowlists on every outbound call from untrusted input; threat-model artifacts for high-stakes changes.
- **Safety-critical:** independent security review; structured penetration testing; explicit control mappings (where the project operates under a compliance regime); audit logs separated from operational logs; tamper-evident audit trail; threat models reviewed and updated as the system evolves.

## References & rationales

- **CWE Top 25 (MITRE), specifically CWE-798 (Use of Hard-coded Credentials).** Backs principle 1 (secrets do not live in source). On the Top 25 because it is both common and trivially exploitable.
- **OWASP ASVS V2 (Authentication) and V14 (Configuration).** Back principle 1; require secrets to live in a managed store, not in source.
- **OWASP Top 10 (2021), A06 (Vulnerable and Outdated Components) and A04 (Insecure Design).** Back principles 2 (SAST in CI) and 6 (CVE gates). Both categories are reliably surfaced when SAST and dependency scanning are present, and silent when they are not.
- **OWASP Top 10 (2021), A03 (Injection).** Backs principle 3 (parameterization, not hand-rolled escaping). The canonical class of "untrusted input crosses an interpreter boundary."
- **Michal Zalewski, *The Tangled Web* (2011); Chris Anley, "Advanced SQL Injection in SQL Server Applications" (2002).** Back principle 3 from the hand-rolled-escape direction. Browser-side and SQL-side foundational examples of context-blind escaping failures.
- **OWASP Top 10 (2021), A01 (Broken Access Control); Adam Shostack, *Threat Modeling: Designing for Security* (2014).** Back principle 4 (centralize authorization at trust boundaries). The most prevalent category in the 2021 Top 10; trust-boundary analysis is the canonical framework for centralizing decisions.
- **NIST SP 800-53, controls AU-9 (Protection of Audit Information) and SI-11 (Error Handling).** Back principle 5 (redact sensitive data in logs and errors). The explicit pairing of log protection and error-message hygiene.
- **The 2017 Equifax breach (CVE-2017-5638, Apache Struts).** Backs principle 6 (gate dependency CVEs in CI). Two-months-old patch, cataloged CVE, no automated gate; 147M records.
- **OWASP Top 10 (2021), A10 (Server-Side Request Forgery); the 2019 Capital One breach.** Back principle 7 (constrain outbound requests). 100M+ records exfiltrated via SSRF to the EC2 instance-metadata endpoint.
- **Adam Shostack, *Threat Modeling: Designing for Security* (2014); NIST SP 800-53 control PL-8 (Security and Privacy Architectures).** Back principle 8 (threat-model high-stakes changes). STRIDE, the four-question framework, and the compliance contexts where it is mandated.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific tools; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **SAST (general):** Semgrep (rule-based, multi-language), CodeQL (semantic, deeper analysis), SonarQube (managed, multi-language).
- **SAST (language-specific):** Bandit (Python), gosec (Go), Brakeman (Ruby), ESLint security plugins (JS/TS), `cargo clippy` with security-relevant lints (Rust).
- **Secret detection:** gitleaks, trufflehog, GitHub secret scanning, pre-commit hooks that block on entropy patterns.
- **Secret stores:** centralized (e.g., HashiCorp Vault), cloud-provider native (AWS Secrets Manager, GCP Secret Manager, Azure Key Vault), envelope-encrypted files (sops with age or KMS).
- **Dependency CVE scanning:** `pip-audit`, `npm audit`, `cargo audit`, `govulncheck`, OWASP Dependency-Check, Snyk, GitHub Dependabot alerts. Cross-reference: the `dependencies` lens for the supply-chain side of the same gate.
- **Threat modeling:** STRIDE, attack trees, OWASP Threat Dragon, Microsoft Threat Modeling Tool. The artifact matters more than the tool.
- **SSRF defenses:** language-specific allowlist libraries (e.g., Python `httpx` with custom transport rejecting RFC 1918), egress proxies with policy enforcement, network policy at the orchestrator level.
- **Compliance frameworks:** OWASP ASVS for verification requirements; NIST SP 800-53 for control catalogs in regulated contexts.
