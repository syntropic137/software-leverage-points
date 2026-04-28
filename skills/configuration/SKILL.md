---
name: configuration
description: "Use when reviewing configuration concerns: env-var layering, typed config objects, startup validation, secret/non-secret separation, schema discoverability, environment-dependent defaults, twelve-factor compliance, magic numbers"
---

# Configuration

## Overview

Configuration is the seam between the same code artifact and every environment it deploys into. Done well, configuration is a single typed surface, validated at startup, with a documented schema and explicit precedence. Done poorly, configuration is a scatter of `os.environ` reads, an unsafe default that silently ships to production, and a tribal-knowledge tax paid by every new contributor.

**Core principle:** Configuration is one explicit, validated, discoverable surface. The application declares it; the environment binds it; startup refuses to proceed if the binding is incomplete.

## Core Principles

### 1. Centralize configuration in a typed object

Direct env-var reads (`os.environ["X"]` or equivalent) scattered through business logic and request handlers defeat type-checking, default handling, and enumeration. A single typed config object is the canonical fix and the foundation every other principle in this lens rests on. A contributor should be able to answer "what configuration does this service need" by reading one file, not by grepping the codebase.

### 2. Document the schema as a committed artifact

A service that reads configuration at runtime must ship a discoverable schema: a committed example file, a JSON Schema, a typed config class, or a generated reference. Undocumented configuration is a tax paid one startup error at a time, and production discovers missing values under load. The example file is the cheapest possible schema and belongs in version control.

### 3. Validate required configuration at startup (scope: long-lived services)

This principle scopes to services with a startup phase that precedes request handling. Long-lived services validate every required value before the first request: a misconfigured deploy must refuse to come up, not half-process traffic and crash deep in a handler. CLI tools and scripts may legitimately validate at first use; document the choice.

Late-binding configuration failures are release-blocking surface area pretending to be runtime errors. They corrupt observability and produce partial outages.

### 4. Separate secrets from non-secret configuration

Secrets and tunables live in different stores. Mixing them collapses the trust boundary: a developer changing a non-secret tunable is forced through the secret-handling path, and a debugging tool that dumps non-secret config accidentally dumps secrets. The twelve-factor stance is one rule, two stores: secrets in a managed secret store, non-secrets in the environment or a tracked file.

**Multiple valid secret stores exist:** centralized secret manager, cloud-provider native, envelope-encrypted files in source. The principle is: pick one and apply it consistently. The red flag is "secrets and non-secrets in the same namespace," not "did not pick a particular vendor." See the `security` lens for whether secrets exist in source at all.

### 5. No production-relevant defaults

Production-relevant values have no default: the deploy refuses to start if the override is missing. Defaults belong to development and test, where a forgotten override produces a local error rather than an outage or a security incident. A default of `localhost`, `dev`, or a permissive CORS list is fail-open by construction.

### 6. Lift environment-varying values out of code

Timeouts, retry counts, batch sizes, rate limits, and feature toggles that plausibly change across environments belong in configuration, not as magic numbers in source. The tell is whether the value has changed across environments before, or plausibly might. Configurability has a cost (more surface to validate and document), so the test is "does this knob need to turn at deploy time," not "could this conceivably be tuned."

### 7. State the precedence chain explicitly

When two or more configuration sources combine (defaults, files, environment, CLI flags), the order of precedence is documented and applied in one place by the typed config object. Implicit precedence means a contributor changes a value in the obvious place and nothing happens because a different source overrides it silently.

**Multiple valid precedence chains exist:** defaults-then-file-then-env-then-CLI is conventional; other orderings are defensible. The principle is: state the chain and apply it consistently. The red flag is "no stated precedence," not "did not pick the canonical chain."

## Red Flags - STOP

- Direct env-var reads (`os.environ["X"]` or equivalent) scattered through business logic and handlers without a central typed config object
- No committed `.env.example`, JSON Schema, or generated reference listing every variable, its type, and whether it is required
- Required configuration not validated at startup; failures surface during request handling
- Secrets and non-secret tunables share a single file or environment namespace
- Defaults that are environment-dependent (`localhost`, `dev`, permissive CORS) without a requirement that production override them
- Magic numbers in code (timeouts, retry counts, rate limits) where deploy-time variation is plausible
- Two or more configuration sources combine with no stated precedence rule, or precedence depends on import order

## Rationalization Prevention

| Excuse | Reality |
|---|---|
| "It's just one env-var read inline" | Each ad-hoc read forks the configuration surface; a year later there are forty |
| "We'll write the example file later" | Until then, every onboarding starts with a startup-error scavenger hunt |
| "Validation at startup is over-engineering" | The alternative is partial outages where the misconfiguration looks like a request bug |
| "Secrets in the env are fine; nobody can see it" | Logs, debug dumps, and process listings disagree |
| "The default of localhost is harmless" | Until production deploys without the override and silently talks to itself |
| "These constants will never change" | They change at the worst possible moment, and now it's a deploy not a config flip |
| "Precedence is obvious from the code" | Until two sources collide and the loser is wrong silently |

## Key Patterns

```
✅ Settings = TypedConfig(); from settings import settings; settings.db_url
❌ os.environ["DB_URL"] scattered across modules
```

```
✅ .env.example committed; every required variable listed with type and example
❌ Required variables documented only in the startup error you hit when you forget one
```

```
✅ App refuses to start if DATABASE_URL is missing; clear error names the variable
❌ App starts; first DB-touching request crashes with KeyError deep in a handler
```

```
✅ Secrets in a managed store; non-secret tunables in env or a tracked file
❌ API keys and feature flags share .env, with no separation of read scope
```

```
✅ No default for PRODUCTION_API_URL; deploy fails closed if missing
❌ Default of "http://localhost:8080" silently ships to prod when override is forgotten
```

```
✅ TIMEOUT_SECONDS = settings.timeout_seconds  (configurable)
❌ requests.get(url, timeout=30)  (magic number; cannot tune without a deploy)
```

```
✅ Documented chain: defaults → file → env → CLI; applied in one place
❌ Some values read from env, some from file; precedence varies by import order
```

## Why This Matters

Configuration is the surface where the same code meets every environment. The cost of getting it wrong is paid at deploy time, in incidents, and in the slow tax of every contributor who cannot tell what the service needs to run.

Without disciplined configuration:

- Onboarding is a scavenger hunt across grep results and startup errors.
- Production discovers missing values under load; partial outages look like request bugs.
- Secrets leak into debug dumps because they share a namespace with tunables.
- Forgotten overrides plus permissive defaults produce outages and security incidents.
- Tuning a value requires a code change and a deploy, not a config flip.

With disciplined configuration:

- Every variable is enumerable from a single typed surface.
- Misconfigured deploys refuse to come up; the failure is loud and at startup.
- Secrets and tunables are separated by construction.
- Production-relevant values have no defaults; the deploy fails closed.
- Operators can turn the knobs the application exposes, and only those.

## Growth examples

Soft sketch; not a checklist. Where appropriate is shaped by the target's maturity.

- **POC / prototype:** a `.env.example` exists; configuration is read in one place even if the typed object is rudimentary. Awareness that the schema will need to be discoverable as the surface grows.
- **Growing internal tool:** typed config object in place; required values validated at startup; `.env.example` kept current. Secrets at least separated into their own file even if not yet in a managed store.
- **Shared library:** the library exposes its configuration as part of its public surface (a typed settings object the consuming application instantiates), does not read env-vars itself, and documents every required value.
- **Production service:** typed config object; startup validation enforced; `.env.example` reviewed in CI; secrets in a managed store; precedence chain documented; no production-relevant defaults. Magic numbers reviewed and lifted to config when environment-varying.
- **Safety-critical:** configuration schema is part of the release artifact; changes go through change control; secret rotation is automated; configuration drift is detected by tooling. Every required value has provenance: who set it, when, and why.

## References & rationales

- **The Twelve-Factor App, factor III ("Config"); Adam Wiggins.** Backs principles 1 (centralize), 2 (document the schema), and 7 (state the precedence chain). The foundational stance that configuration is explicit, external, and the same code artifact deploys to every environment.
- **Michael Nygard, *Release It!* (2nd ed., 2018).** Backs principles 3 (validate at startup) and 5 (no production-relevant defaults). The chapter on dangerous defaults and configuration as a release-blocking surface is the canonical source for fail-fast-at-startup discipline.
- **Andrew Hunt and David Thomas, *The Pragmatic Programmer*.** Backs principle 6 (lift environment-varying values out of code). Configurability as a deliberate tradeoff: surface the knobs operators need, but no more.
- **Twelve-factor stance on secret handling.** Backs principle 4 (separate secrets from non-secrets). Cross-reference: the `security` lens carries the "secrets in source" check; this lens carries the "secrets share a namespace with tunables" check.

## Suggested technologies (as of 2026-04-28)

These go stale fast; the date is the "as-of." Verify currency before adopting. The principles above outlast specific libraries; if a tool here is no longer maintained, the patterns transfer to its replacement.

- **Python:** Pydantic Settings or typed-settings for centralized typed config; cattrs for structured deserialization; `python-dotenv` for `.env` file loading in development.
- **JS/TS:** zod or io-ts for runtime-validated schemas; convict for layered config; framework-native config (Next.js, NestJS) where the framework provides one.
- **Go:** `viper` or `koanf` for layered config; `envconfig` for typed env-var loading.
- **Rust:** `figment`, `config-rs`, or `envy` for layered/typed config.
- **Java/Kotlin:** Spring Boot configuration properties; MicroProfile Config; Typesafe Config (HOCON).
- **Secret stores:** centralized secret managers (e.g., HashiCorp Vault), cloud-provider native (AWS/GCP/Azure secret services), envelope-encrypted files (sops with age or KMS). Choice depends on deployment context; consistency within a project matters more than vendor.
- **Schema discoverability:** committed `.env.example`; JSON Schema generated from the typed config object; `--print-config` CLI flag that emits the resolved configuration with secrets redacted.
