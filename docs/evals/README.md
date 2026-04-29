# Evaluations

This directory holds the committed, durable record of how `software-leverage-points` is evaluated. Each finding logged here is a load-bearing input to architectural decisions; ADRs in `docs/adrs/` cite specific entries here as evidence.

## Layout

```
docs/evals/
├── README.md                       # this file: methodology, layout, sanitization rules
├── EVAL-001-<short-slug>.md        # one Markdown file per eval episode
├── EVAL-002-<short-slug>.md
└── ...
```

Eval entries are numbered sequentially (`EVAL-NNN`) like ADRs are. Filenames are `EVAL-NNN-<short-slug>.md`. The slug is descriptive but bounded; date metadata lives inside the file.

Raw artifacts (full run.jsonl logs, plan-v2 outputs, intermediate findings.yaml files, per-SLP scratch dirs) live in `_archive/` at the repo root, which is gitignored. Curated summaries with the load-bearing observations are extracted and committed here as `EVAL-NNN-<slug>.md`.

## Index

| Number | Title | Date | Decision impact |
|---|---|---|---|
| [EVAL-001](EVAL-001-orchestrator-perf.md) | Orchestrator performance and dedup-strategy matrix | 2026-04-29 | ADR-0001 "Mechanical enforcement" subsection |

## What gets committed

Each `EVAL-NNN-<slug>.md` should contain:

1. **Date and scope.** What was evaluated, what was held constant, what varied.
2. **Method.** How the eval was run (which orchestrator prompt, which models per stage, which target). Concrete enough that a reader can re-run.
3. **Numbers.** Wall time, cost (USD), tokens per model tier. Compression ratios where relevant.
4. **Quality observations.** What worked, what regressed, with examples.
5. **Decision impact.** Which ADR or VISION acceptance test does this evidence support or refute.
6. **Open follow-ups.** What was deferred and why.

## What does NOT get committed

- Raw run.jsonl logs (too large; contain full repo paths and partial responses).
- Plan-v2 markdown outputs (large; contain repo-specific detail).
- Per-SLP scratch findings YAML (intermediate; recoverable from rerun).
- Intermediate experiment scaffolding (orchestrator prompt drafts, comparison reports targeted at `_archive/`).

These live in `_archive/` and are gitignored.

## Sanitization rules

Before committing a findings entry:

1. **Replace user-specific paths.** `/Users/<name>/Code/...` becomes `<repo-root>/...` or relative paths.
2. **Replace hostnames and tailnet IDs.** `macmini.tail<6-char>.ts.net` becomes `<host>.<tailnet>.ts.net` placeholders.
3. **Replace `.tmp/` scratch paths.** `/tmp/slp-eval-<date>/...` becomes `_archive/...` or omit entirely if not load-bearing.
4. **Strip secrets.** No `op://`, no API keys, no `Bearer` tokens, no environment variable values that look secret.
5. **Repo identifiers stay.** This plugin's own repo (`software-leverage-points`) and the named target repos (e.g. `openclaw-hermes`, `syntropic137`) are public and may be cited.
6. **Findings text from third-party repos.** When citing findings produced against a target repo, summarize rather than quote large blocks. Cite ADR numbers and file basenames; do not reproduce file contents.

## How findings flow into ADRs

When a findings entry produces evidence for or against an architectural choice:

1. Add a "Decision impact" subsection to the findings file naming the ADR (or VISION acceptance test) it informs.
2. Update the ADR's "References" section to cite the findings entry by relative path.
3. If a finding overturns a prior decision, write a new ADR or amend the existing one rather than silently changing direction.

## How to file a new findings entry

1. Run the eval. Capture raw artifacts under `_archive/<eval-name>/`.
2. Pick the next sequential number: look at the highest existing `EVAL-NNN-*.md` and add one.
3. Create `docs/evals/EVAL-NNN-<short-slug>.md` with the structure above.
4. Sanitize per the rules above.
5. Update the Index table in this README.
6. Reference the entry from any ADR or VISION acceptance test it impacts.
7. Run `just qa` and commit.
