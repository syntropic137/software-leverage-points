---
name: configuration
description: "Use when reviewing configuration concerns: env-var layering, defaults, validation, secret/non-secret separation, schema discoverability, twelve-factor compliance"
---

# Configuration Leverage Point

## When to Use

- A planning agent is reviewing a plan that introduces new environment variables, runtime flags, or feature toggles
- A PR-review agent encounters changes to config loaders, `.env*` files, settings classes, or default values
- The orchestrator (`software-leverage-review`) fans out a subagent for configuration

## When NOT to Use

- For whether secrets exist in source at all: that is the `security` LP. This LP cares about how secret and non-secret config are loaded, layered, and validated. The two LPs cross-reference at the secret boundary.
- For dependency-version pinning and lockfile health: that is the `dependencies` LP.

## Input

`target`: a file path, directory, plan document, or git diff to review.

## Workflow

1. Read the `target`.
2. Detect configuration artifacts: settings module(s), config loaders, `.env*` files, `.env.example`, JSON Schema or typed config object, secret-store integrations, startup validation hooks.
3. Apply checks:
   - Are configuration values loaded with explicit precedence (defaults then file then env then CLI), in one place?
   - Are required configuration values validated at startup with helpful errors, before request handling begins?
   - Are secrets stored separately from non-secret config (env, secrets manager) per the twelve-factor principle?
   - Is the configuration schema discoverable as a typed config object, `.env.example`, or JSON Schema, so a new contributor can list every variable without reading code?
   - Are configuration changes test-covered by at least a smoke test that boots the app with realistic env?
   - Are values that vary by environment expressed as configuration, or as magic numbers in code?
4. Emit findings using the schema at `../software-leverage-review/output-schema.json` (authoritative) / `output-schema.md` (human-readable). The `software_leverage_point` field MUST be `"configuration"`.

## Output

Conforms to `../software-leverage-review/output-schema.md`. The `software_leverage_point` field MUST be `"configuration"`.

## Red Flags (anti-patterns to surface as findings)

- **`os.environ["X"]` (or equivalent) scattered through code without a typed config object.**
  - What to flag: direct env-var reads inside business logic, request handlers, or utility modules, with no central settings class or struct.
  - Why it matters: scattered reads make the configuration surface impossible to enumerate; a contributor cannot answer "what env vars does this service need" without grepping. They also defeat type-checking and default handling, since each call site invents its own coercion. A typed config object is the canonical fix and the foundation for every other check in this LP.
  - Cite: Pydantic Settings docs, cattrs, and similar typed-config libraries as canonical references for the typed-config pattern. Cite also: Adam Wiggins, twelve-factor design ("Config"), explicit declaration of configuration.

- **No `.env.example` or schema documenting required vars.**
  - What to flag: a service that reads env vars at runtime but ships no committed example file, JSON Schema, or generated reference listing every variable, its type, and whether it is required.
  - Why it matters: undocumented configuration is a tribal-knowledge tax. New contributors and agents discover required vars by hitting startup errors one at a time, and the production deploy discovers missing vars under load. The example file is the cheapest possible schema and belongs in version control.
  - Cite: The Twelve-Factor App, factor III ("Config"), strict separation of config from code, with config explicit and external.

- **Required config not validated at startup; failures surface during request handling.**
  - What to flag: a service that boots successfully with missing or malformed env vars and then throws on the first request that needs them, often deep in a handler.
  - Why it matters: late-binding configuration failures are release-blocking surface area pretending to be runtime errors. They corrupt observability (the failure looks like a request bug, not a deploy bug), and they often half-process traffic before failing. Validate at startup so a misconfigured deploy refuses to come up.
  - Cite: Michael Nygard, *Release It!* (2nd ed., 2018), on configuration as a release-blocking surface and the fail-fast-at-startup pattern.

- **Secrets and non-secrets in the same file or env namespace.**
  - What to flag: a `config.yaml` or `.env` mixing API keys with feature flags and tunables, with no separation of read scope.
  - Why it matters: mixing collapses the trust boundary. A developer who needs to read or change a non-secret tunable is forced through the secret-handling path, and a tool that needs to dump non-secret config for debugging accidentally dumps secrets too. The twelve-factor stance is that secrets live in a manager (Vault, Secrets Manager) and non-secrets live in the environment or a tracked file; one rule, two stores.
  - Cite: HashiCorp Vault and AWS Secrets Manager docs as canonical references for the secret-handling pattern. Cross-reference: see the `security` LP for whether secrets exist in source at all.

- **Defaults that are environment-dependent without explicit overrides.**
  - What to flag: a default of `localhost` for a database host, `dev` for an environment name, or a permissive CORS list, with no requirement that production override it. Even worse: a default that silently changes behavior based on a detected hostname.
  - Why it matters: an unsafe default plus a forgotten override equals an outage or a security incident. The fail-safe stance is that production-relevant values have no default, so the deploy refuses to start if the override is missing. Defaults belong to development and test, not production.
  - Cite: Michael Nygard, *Release It!* (2nd ed., 2018), specifically the configuration-as-release-surface chapter on dangerous defaults.

- **Magic numbers in code that should be configuration.**
  - What to flag: timeouts, retry counts, batch sizes, rate limits, or feature toggles hardcoded in source where a deploy-time change would be appropriate.
  - Why it matters: every magic number is a future incident waiting on a value change that requires a deploy. The Pragmatic Programmer's "configurability" principle is to surface knobs that operators may need to turn, but only those: configurability has a cost (more surface to validate and document) so the tradeoff is real, and the tell is whether the value has plausibly changed across environments.
  - Cite: Andrew Hunt and David Thomas, *The Pragmatic Programmer*, on configurability as a deliberate tradeoff.

- **No precedence rule, or the precedence rule is implicit.**
  - What to flag: two config sources (env and file, or env and CLI) where it is unclear which wins, or where the answer depends on import order.
  - Why it matters: implicit precedence means a contributor changes a value in the "obvious" place and nothing happens, because a different source is overriding it silently. The canonical rule is defaults then file then env then CLI, applied in one place by the typed config object.
  - Cite: Pydantic Settings docs and similar typed-config libraries for the canonical precedence chain. Cite also: The Twelve-Factor App, factor III ("Config"), on configuration as a single explicit surface.

## References & rationales

The "why" behind the checks above, named so an agent can reason like a senior engineer:

- **The Twelve-Factor App, factor III ("Config").** Strict separation of config from code; configuration is explicit, external, and the same code artifact deploys to every environment. Use this as the foundational stance behind every check in this LP.
- **Adam Wiggins on the twelve-factor design.** The original framing for config-as-environment and the deploy-as-environment-binding model. Use this when justifying why config is not source.
- **Michael Nygard, *Release It!* (2nd ed., 2018).** Configuration as a release-blocking surface; fail-fast-at-startup; the chapter on dangerous defaults. Use this when justifying startup validation and the absence-of-production-defaults stance.
- **Pydantic Settings docs, cattrs, typed-config patterns.** Canonical references for the typed-config object: precedence chains, validation, and discoverable schema. Use this when justifying centralization of env reads.
- **HashiCorp Vault, AWS Secrets Manager docs.** Canonical references for the secret-handling pattern; secrets live in a manager, not in the env namespace alongside tunables. Use this when justifying secret/non-secret separation.
- **Andrew Hunt and David Thomas, *The Pragmatic Programmer*.** The "configurability" principle as a deliberate tradeoff: surface the knobs operators need, but no more. Use this when justifying which values become configuration and which stay in code.

Each red flag is a finding the agent emits with `severity: warn` or `severity: error` per the output schema, plus a `suggested_fix` that is concrete: name the typed config object to introduce, the `.env.example` to commit, the startup check to add, the secret to migrate to a manager, or the magic number to lift to config.
