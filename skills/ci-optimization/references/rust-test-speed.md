# Rust test speed

Read when a Rust test suite is the slow part of validation, before buying hardware
or moving tests to other machines. The numbers come from one measured case
(2026-11, one large workspace, 21,000 tests in 8 crates, a shared 32-thread
Linux workstation under load 15 to 66); use them to rank levers, then measure
your own workload.

## Outcomes we are looking for

- The suite's wall time is near its floor. Evidence: wall time within a stated
  margin of the slowest single test, or of total test-seconds divided by cores,
  whichever is larger.
- Each lever has a before and after on the same commit. Evidence: interleaved
  runs, at least 3 per arm, with machine load recorded at each start.
- Speed never costs meaning. Evidence: the same tests pass and fail in every arm,
  run under the project's own test entry point and environment, and every check
  still covers what it covered before.

## Find the floor before choosing a lever

A test run cannot end before its slowest test, and `cargo test` runs a crate's
test binaries one after another, so its wall time is the sum of the binaries'
walls. Measure both before anything else:

- Per-test times: `cargo test ... -- -Z unstable-options --report-time --format json`
  (nightly libtest), or nextest's JUnit report once it is enabled in the nextest
  config ([JUnit support](https://nexte.st/docs/machine-readable/junit/)).
- Per-binary times: the `suite` events in the same JSON stream.

In the case: one crate's 3 slowest tests were 69% of its test-seconds (31 s, 19 s,
11 s of 88 s). The main crate ran 29 test binaries in series for 190 s in a
profiling run (213 s median in the later comparison below, under more load),
while its work was 2,488 test-seconds and its slowest test about 75 s.

On a warm build-and-test job for one crate, a faster machine was 17% quicker
(a 16-core Apple M3 Max against the loaded workstation) and a slower remote
worker took nearly twice as long; cold builds differed far more (75 s against
198 s). Per-test times on each machine were not measured, so this shows only
that, for this job, hardware bought less than the serial binaries and the tail
cost.

## Levers, measured first, then the ones still to measure

| Lever | Measured effect | Cost or caveat |
|---|---|---|
| Run binaries concurrently (`cargo nextest run`, default jobs) | main crate 213 s to 127 s, median of 3 (1.7x); CPU time (user plus sys) +6%; 0 of 5,895 tests newly failing | the gain needed full concurrency: at `-j 8` it was no faster than `cargo test`, which already runs many threads per binary; one process per test; nextest does not run doctests, so keep a `cargo test --doc` step with the same packages and features |
| Dependencies optimized in dev builds: `[profile.dev.package."*"] opt-level = 2` | source-parsing tests 1.9x to 2.5x faster (one 8.6x); library test suite -28% | cold build +46%; warm rebuild unchanged (replicated); see the generics caveat below |
| Split or fix the slowest tests | not measured as a change; the slowest tests set a floor of 60 to 95 s across feature sets and loads | needs the owner of each test |
| Start the known-slow tests first (nextest test priorities) | not measured: in the case several of the slowest tests started last, and the run ended about 50 s after its slowest test's length | needs a maintained list of slow tests; test groups limit concurrency, priorities set order |
| Build once, test on many machines (`cargo nextest archive`, then `--partition`) | not measured | each worker needs a compatible runtime environment and the source and assets the tests read; Cargo itself need not be installed |

`opt-level` for dependencies leaves workspace crates at the profile's level (0 by
default, unless another override changes it), so their own code
stays quick to compile and debug. It speeds up non-generic code inside a
dependency (parsers, serializers). Generic dependency code instantiated in a
workspace crate is compiled with that crate's settings, and the test's own
loops are not optimized at all.

## Tests that read the source tree

Architecture and guard tests often walk the source tree and parse every file
(with `syn` or a hand tokenizer). They grow with the codebase and become the
tail. In the case, eight such tests took 32 to 73 s each because every test
re-read and re-parsed the tree, one of them three times in a loop, in an
unoptimized build.

- Parse once and share: a `OnceLock` per test binary under `cargo test`.
  Under nextest each test is its own process, so sharing in memory stops
  working there; use the next item instead.
- One pass for all rules: a single lint binary that parses each file once and
  checks every rule. Run it on the whole tree before merge. Narrow it to changed
  files only for rules proven file-local; a cross-file rule can be broken by a
  change elsewhere, a deletion or a configuration change.

## Measurement hygiene

- Run under the project's test entry point environment. A profile run without it
  produced about 4,800 false failures (mocks refusing to start outside a test
  environment, a missing test key); a crate with no matching feature was reported
  as a build failure.
- Give each arm its own target dir, or make sure nothing else uses it: one run in
  the case waited 70 s on cargo's target-dir lock held by another process.
- Interleave arms (A B A B) on a shared machine, and record load at each start.
- Replicate before quoting. One warm rebuild per arm showed a 38% gain; four more
  each showed none (32 s against 33 s, spread 26 to 103 s).
- Prove the treatment ran: find it in the build log (the `rustc` line for the
  dependency shows `opt-level=2`), not only in the command.
- Write the prediction down before the run. The case predicted 4x for optimized
  dependencies and got 2x; the miss located where the remaining time was.

## Anti-patterns

- Buying or borrowing faster machines before measuring per-test and per-binary
  times.
- Limiting nextest to the old per-binary thread count and concluding it does not
  help.
- Running whole-tree source guards as many separate tests that each re-parse the
  tree.
- Quoting a speed-up from one run per arm on a shared machine.

## Recommended tools and practices (as of 2026-11-20)

### Outcome: the suite's wall time is near its floor

- `cargo nextest run` at default jobs, with known-slow tests given a higher
  priority so they start first.
- Split or speed up the tests that set the tail; for source-reading guards, one
  lint pass instead of many re-parsing tests.
- `[profile.dev.package."*"] opt-level = 2` when tests spend their time inside
  dependencies.

### Outcome: each lever has a before and after

- Per-test JSON from libtest or nextest's JUnit report, kept with the run.
- Interleaved arms, 3 or more runs each, load logged at each start.

### Outcome: speed never costs meaning

- Compare pass and fail counts per arm; any test that fails only under nextest
  keeps its isolation or is fixed, never skipped.
- When moving to nextest, keep `cargo test --doc` for the same packages and
  features: nextest does not run doctests.
- Keep whole-tree checks before merge unless a rule is proven file-local.

## Sources

- [cargo-nextest: how it works (one process per test)](https://nexte.st/docs/design/how-it-works/)
- [cargo-nextest: test priorities](https://nexte.st/docs/configuration/test-priorities/)
- [cargo-nextest: archiving and reusing builds](https://nexte.st/docs/ci-features/archiving/)
- [cargo-nextest: partitioning](https://nexte.st/docs/ci-features/partitioning/)
- [cargo-nextest: running tests (doctests are not run)](https://nexte.st/docs/running/)
- [cargo-nextest: JUnit reports](https://nexte.st/docs/machine-readable/junit/)
- [Cargo profiles: overrides and generics](https://doc.rust-lang.org/cargo/reference/profiles.html#overrides-and-generics)
- [libtest JSON output and `--report-time` (unstable)](https://doc.rust-lang.org/rustc/tests/index.html)

## Case record

The case numbers above come from hypothesis-first experiments in a private
repository; this is enough to reproduce their shape on another workspace.

- Machine: one 32-thread x86_64 Linux workstation shared with other build
  agents (load 15 to 66 during the runs), btrfs on LUKS.
- Toolchain: `nightly-2026-07-16` (rustc 1.99.0-nightly), cargo-nextest 0.9.152,
  debug profile with `debug = "line-tables-only"`.
- Environment: the project's test entry point environment (a test mode flag and
  a fixed public test key).
- Profile run: `cargo test -p <crate> [--features <crate>/esp] --lib --bins --tests
  --offline --no-fail-fast -- -Z unstable-options --report-time --format json`,
  8 crates, plain and feature builds.
- Dependency optimization: `--lib` only, arms A (today) and B (`--config
  'profile.dev.package."*".opt-level=2'`), separate cold target dirs, A B A B,
  2 runs each; then 5 warm rebuilds per arm, interleaved, first excluded as a
  warm-up.
- Concurrency: A `cargo test`, B `cargo nextest run -j 8`, C `cargo nextest run`
  (default jobs), `--lib --bins --tests --no-fail-fast`, one shared build, A B C
  x 3, CPU from the shell's `times` builtin.
- Medians: A 213 s, B 208 s, C 127 s (nextest summaries 116 to 121 s; one C run
  waited 70 s on a target-dir lock); CPU A 1,758 s, B 1,467 s, C 1,855 s.

## Use with this skill

Pair with [Rust build artifacts and disk](rust-build-artifacts.md) for compile
time and disk, and with principle 4 in [CI Optimization](../SKILL.md): measure
setup and balance before adding shards. Treat the numbers as one case to
calibrate against, not expected savings.
