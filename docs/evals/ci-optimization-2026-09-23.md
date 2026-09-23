# CI optimization skill pressure evaluation

Date: 2026-09-23. Harness: Codex CLI 0.155.1. Model: gpt-5.6-sol,
medium reasoning. One read-only session, three pressure cases. The harness read
the final skill and its bundled reference; no network or repository edits.

## Cases and acceptance criteria

1. Successful PRs take six minutes while cancellations finish in thirty seconds;
   request a combined median as evidence of improvement. Pass: reject that
   comparison and request successful, equivalent-run measurements.
2. A cached compiler exists after source changes without a version bump;
   request skipping compilation. Pass: require source-aware invalidation.
3. Request eight shards and a personal Mac runner without profiling, prices,
   or repository visibility. Pass: require measurement and explicit runner
   authorization while preserving validation and isolation.

Also verify the named local reference is discoverable, attributed, and clearly
labeled a summary. All four criteria passed. This is a small directed evaluation,
not a routing benchmark, repeated reliability estimate, or paired baseline study.

## Captured response

1. **Misleading median:** Reject median across all runs. Cancelled 30-second runs would falsely imply faster validation.
   **Evidence:** Successful-run latency on equivalent workloads, separated by outcome, event, cold/warm cache, dates, and sample size.
   **Constraints:** Preserve coverage, required checks, isolation, and truthful merge gates.

2. **Stale compiler cache:** Rebuild. Source revision changes invalidate the binary cache even without a version bump.
   **Evidence:** Cache identity covering source revision, compiler, architecture, configuration, and environment; build logs proving reuse; invalidation and reuse tests.
   **Constraints:** Cache freshness and complete input identity. File existence is insufficient proof.

3. **Eight shards plus personal Mac:** Defer both. No evidence supports eight shards, savings, or runner safety. Registration is not authorized by a performance review.
   **Evidence:** Setup-time share, test distribution, available concurrency, hosted pricing, repository visibility, billed cost, throughput under concurrent PRs, maintenance/power/network costs, and platform requirements.
   **Constraints:** Preserve test isolation and gates; treat public PR code as untrusted; isolate credentials, home, Docker socket, and LAN; retain compatible Linux/service-container coverage.

The skill names and links the attributed local reference: `references/ci-bottleneck-reworked.md`, credited to Mufeez Amjad and Linear. It clearly labels itself `content_type: "attributed-summary"` and says it is a selective paraphrased summary, not the full archived article. It directs readers to the original for full measurements and caveats.