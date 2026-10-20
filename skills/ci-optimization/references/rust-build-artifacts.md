# Rust build artifacts and disk

Read when Rust `target/` directories are filling disks, when choosing between
sccache, a shared target dir and cleanup tools, or when agent worktrees make
build caches multiply. The numbers come from one measured case (2026-10); use
them to rank levers, then measure your own workload.

## Outcomes we are looking for

- Disk stays bounded without anyone cleaning up. Evidence: total target-dir
  size and free space over weeks stay under a stated cap and floor, with no
  manual deletes.
- Caching keeps paying while disk stays capped. Evidence: warm and touch-rebuild
  times stay flat after a cap or cleanup is introduced.
- Cleanup never breaks a build. Evidence: no verify or land failure coincides
  with an eviction in the cleanup log.

## Why target dirs balloon

- Every checkout has its own `target/`. Agent worktrees multiply checkouts, and
  nothing removes them. In the case below, 155 target dirs on one machine held
  558 GiB, about 85% of it beyond one copy per machine.
- The dev profile keeps full debuginfo and incremental state. Debug output was
  80 to 85% of each large target dir, and incremental state alone was about 36G
  of one 69G dir.
- Each profile and target triple (release, wasm, coverage) adds its own tree.
- Cargo never garbage-collects `target/` by age. `cargo clean` can select a
  package, profile or target, but knows nothing about age or other checkouts;
  `cargo +nightly clean gc -Zgc` trims only `~/.cargo` (registry and git
  caches, a few GiB here).

## Levers, ranked by measured effect

A dated case study, not a benchmark: one 16-core Linux workstation, one large
workspace, `cargo test -p <main crate> --no-run` on nightly-2026-07-16 at `-j4`,
a fresh target dir per variant, one run each, 2026-10. At `-j16` with
line-tables-only the cold build was 72 s and the touch rebuild 37 s. Calibrate
on your own workload before quoting a number.

| Lever | Disk effect | Speed effect |
|---|---|---|
| `[profile.dev] debug = "line-tables-only"` | 38G to 14G per target dir (-63%) | cold 147 s to 104 s; touch rebuild 92 s to 47 s |
| `CARGO_INCREMENTAL=0` (one-shot builds only) | 38G to 33G | cold 147 s to 129 s; touch rebuild unchanged |
| both together | 12G | cold 94 s; touch rebuild 57 s (slower than line-tables alone) |
| cap with oldest-first eviction | bounds the total: reclaimed 347G on one machine, 195G on another | none, if warm dirs in use are skipped |
| `trim-paths = "all"` (nightly) | byte-identical artifacts across checkout paths: 55% to 89% | none measured |

Keep incremental on for persistent checkouts that rebuild the same tree (CI
verify slots, a main checkout): there it pays on rebuilds. Turn it off for
one-shot worktree builds, where it only stores state nobody reads.

`line-tables-only` keeps file and line numbers in backtraces. Coverage via
`-C instrument-coverage` does not need full debuginfo either.

## sccache: a speed tool, not a disk tool

sccache keeps its own capped store (`SCCACHE_CACHE_SIZE`, least-recently-used
eviction), but every checkout still writes a full `target/`: it adds disk, it
does not remove any. What it buys is compile time, and only when keys match:

- It skips incrementally compiled crates. Cargo builds registry dependencies
  without incremental even in dev, so those are cached; workspace crates are
  cached only with `CARGO_INCREMENTAL=0` or in release builds.
- `CARGO_*` environment variables are part of the key, including
  `CARGO_TARGET_DIR`. A target dir set through that variable gives each
  checkout its own key space: cross-checkout hits were about 0%. Set the target
  dir with `--target-dir` or `build.target-dir` instead: hits rose to about 84%.
- Proc-macro crates, binaries, tests and the final link are not cached, and
  crates downstream of proc-macros miss more often. A proc-macro that reads
  files cargo does not track can also produce a stale hit, so keep such inputs
  declared or avoid caching those crates. In the case above, with
  `CARGO_INCREMENTAL=0` at `-j4`, a build reusing the same target path (near
  100% hits) still took 94 s against a 130 s cold build: that is the
  uncacheable floor.

## Shared target dir: one copy, but serialized

Pointing every checkout at one target dir stores dependencies once (the dir
grew only 2G for a second checkout). The costs:

- Cargo holds one build lock on the dir, so concurrent builds from different
  checkouts run one at a time.
- Checkouts at different commits overwrite each other's artifacts at the same
  paths, so each build can undo the last one's work.
- Binaries at fixed paths get swapped under running processes. In the case
  above, a tool run from `target/debug` lost its binary inode mid-run whenever
  another checkout built it.

If you try it, share `build.build-dir` (intermediates, stable since cargo 1.91)
and keep `target-dir` (final artifacts) per checkout, so binaries stay private.
Fine-grained locking (`-Zfine-grain-locking`) is unstable as of this writing.

## Dedup underneath per-checkout dirs

Cargo hashes workspace members and registry dependencies independently of
where the checkout lives, so the same commit produces the same artifact names
(the hash suffix) in every checkout. Path dependencies outside the workspace
keep absolute paths in that hash. Whether the bytes match depends on embedded
absolute paths:

- Without `trim-paths`, debuginfo and panic locations embed the checkout path:
  55% of dependency bytes matched across two checkouts of one commit.
- With `trim-paths = "all"` (nightly: `-Ztrim-paths` or
  `cargo-features = ["trim-paths"]`), 89% matched. The rest came from one crate using
  `env!("CARGO_MANIFEST_DIR")` in non-test code to locate assets, which bakes
  the checkout path into the binary. Resolve such paths at runtime instead.

`trim-paths` raises the share; it does not guarantee identical output (build
scripts, native tools and nondeterministic inputs still differ), so compare
content hashes before sharing anything. Matching bytes can be stored once with
copy-on-write clones (`clonefile` on
APFS, reflinks on btrfs or XFS). Each path keeps its own file, so cargo's
in-place writes and binary swaps stay isolated. Copy-on-write protects only
writes after the clone: a build that rewrites the file between the hash and the
clone would be overwritten with stale bytes. Hold cargo's locks on both target
dirs, recheck size and mtime just before an atomic rename of the clone into
place, and skip anything recently written. Hardlinks are not a substitute:
a writer that truncates one link changes every copy. Ext4 has neither clones
nor reflinks, so dedup there means a different filesystem.

Across checkouts at different commits the gain is smaller. Without
`trim-paths`, four CI verify slots shared only 16% of their dependency bytes by
name and size.

Measured on a live developer machine (2026-10), clone dedup did not pay:
with a 24-hour minimum age, nothing qualified, because every target dir that
old was one the cap evicts anyway. Without the age limit, 61G of 384G (16%)
was clonable, all of it in dirs written within the last day, so capturing it
meant swapping files under active checkouts. `debug = "line-tables-only"`
shrank one fresh target dir by 63% (see the levers table) with no live-file
changes.
Measure your own trees before building dedup; it pays when many idle
checkouts of one commit sit side by side.

## Cleanup that does not break builds

A cap is only safe if it does not delete something in use. The checks that held
up under review and fixture tests:

- Search only configured cleanup roots. Identify target dirs by cargo-specific
  evidence, never by name: a `.fingerprint` build tree plus either cargo's
  `CACHEDIR.TAG` (whose comment names cargo) or `.rustc_info.json`. A bare
  `CACHEDIR.TAG` marks any cache, not only cargo's. Refuse any tree that holds
  `Cargo.toml`, `.git` or `src/`.
- Skip a dir when a cargo build lock in it is held (`.cargo-lock`,
  `.cargo-build-lock`), when a process runs a binary from it, or when a process
  has its working directory anywhere in the owning checkout.
- Skip anything written recently (a minimum age such as 24 hours) and anything
  under an explicitly protected path, such as warm CI caches.
- Recheck all of that at the moment of deletion while holding cargo's locks,
  rename the dir aside with a no-replace rename, check what was renamed, and
  only then delete. A build that starts afterwards gets a fresh dir.

No check closes every window. A build that opens its lock file in the instant
before the rename keeps its descriptors into the renamed dir and fails. Held
locks and a minimum age make that window small; closing it fully takes
coordination with whatever launches builds, such as a lease the cleaner must
also hold.
- Make it automatic: a resident process or timer that watches free space and
  the cap. In the case above, disks refilled within two days of a manual 500 GiB delete.

Free space is a better trigger than summed sizes once clones or hardlinks are
involved, because summed sizes overcount shared blocks. On APFS, freed space
returns asynchronously, so a free-space-driven cleaner must wait and re-read
before evicting more.

## Anti-patterns

- sccache introduced to fix a disk problem: target dirs stay the same size.
- `CARGO_TARGET_DIR` exported per worktree while expecting sccache hits across
  worktrees.
- A shared target dir for concurrent agents at different commits: builds
  serialize and overwrite each other.
- Full debuginfo kept in dev builds nobody attaches a debugger to.
- Cleanup scripts that `rm -rf */target` without checking locks or running
  processes; the failures surface as unrelated flaky verifies.
- Hardlink dedup of build outputs.

## Recommended tools and practices (as of 2026-10-20)

### Outcome: disk stays bounded without anyone cleaning up

- `debug = "line-tables-only"` in the dev profile: the largest single cut, and
  it speeds up linking.
- A cap with oldest-first eviction and the in-use checks above, run
  automatically (launchd agent, systemd user service, or a resident process).
- `cargo-sweep` for per-project cleanup by age or toolchain; it is not a
  machine-wide cap. `kondo` for interactive cleanup across projects by age.
  `cargo-cache` and `cargo +nightly clean gc -Zgc` for `~/.cargo` only.

### Outcome: caching keeps paying while disk stays capped

- sccache with `CARGO_INCREMENTAL=0`, the target dir set by flag or config (not
  the environment), and an explicit `SCCACHE_CACHE_SIZE`.
- `trim-paths = "all"` and no build-time absolute paths in non-test code, so
  checkouts of one commit produce mostly identical artifacts.
- Copy-on-write clone dedup on APFS, btrfs or XFS once artifacts are identical,
  and only after measuring: in the case above it was not worth it.

### Outcome: cleanup never breaks a build

- Protect warm caches that CI depends on by path, and give the cleaner a
  minimum age.
- Keep a per-eviction log line, so a failed build can be checked against it.

## Sources

- [Cargo build cache and `build.build-dir`](https://doc.rust-lang.org/cargo/reference/build-cache.html)
- [Cargo unstable features: `-Zgc`, `trim-paths`, `-Zfine-grain-locking`](https://doc.rust-lang.org/cargo/reference/unstable.html)
- [Cargo profiles: `debug`, `incremental`](https://doc.rust-lang.org/cargo/reference/profiles.html)
- [`cargo clean`](https://doc.rust-lang.org/cargo/commands/cargo-clean.html)
- [sccache: Rust caching and its limitations](https://github.com/mozilla/sccache/blob/main/docs/Rust.md)
- [cargo-sweep](https://github.com/holmgr/cargo-sweep), [kondo](https://github.com/tbillington/kondo), [cargo-cache](https://github.com/matthiaskrgr/cargo-cache)
