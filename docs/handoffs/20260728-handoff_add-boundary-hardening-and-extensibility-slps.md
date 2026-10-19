# Handoff: Add `boundary-hardening` (primary) + finish `extensibility` (drafted) SLPs

**Date:** 2026-07-28
**Repo:** git@github.com:syntropic137/software-leverage-points.git   **Branch:** `main`
**Status:** executed 2026-07-28 in the originating session. Both skills are written and
registered; see "Outcome" at the bottom for what was done and where it diverged from the
plan below. The body is preserved as the original brief.

## Purpose & Vision

Add two new software leverage points. The **primary** is **`boundary-hardening`**, and
it is deeper than ordinary "clean architecture." The operator's thesis follows. This is the
irrecoverable part: capture it faithfully or the skill misses its point.

> **In a world where AI generates the implementation, the *boundary* is what's real.**
> The durable software artifact is shifting from the implementation to (a) the **boundary
> / contract between modules** and (b) the **behavioral test suite** that pins it.
> Implementations become regenerable by AI over time; the boundary + its behavior tests
> are what persist. *"The boundary plus a test suite that tests behavior is basically what
> we're building as software now."*

`boundary-hardening` is the active discipline of **finding the load-bearing seams,
extracting them into isolated modules, dependency-inverting them, and pinning them with
behavioral tests**: so the implementation behind the seam is swappable and regenerable.
The **secondary**, `extensibility` (already drafted), is *one payoff* of a hardened
boundary: the external/plugin one.

## Current State

- **`skills/extensibility/SKILL.md`**: DRAFTED, untracked. Follows the house SLP
  principle-doc shape. Needs a review pass + registration (below). Keep it as a companion
  to `boundary-hardening`, or fold it in if you judge it doesn't earn its own lines: but
  the operator sees them as distinct (boundary-hardening primary, extensibility a facet).
- **`skills/boundary-hardening/SKILL.md`**: NOT written. This is the main task.
- Neither is **registered** yet (see Do's/Don'ts: `slp-manifest.yaml` is auto-generated).

## Files Affected

- `skills/boundary-hardening/SKILL.md`: new (primary).
- `skills/extensibility/SKILL.md`: drafted; review, keep or fold.
- `skills/software-leverage-review/slp-manifest.yaml`: **regenerate, do NOT hand-edit**.
- `skills/software-leverage-review/common-types.yaml`: add both to the `CrossCuttingSLP`
  enum (both cut across concerns, like `principles-and-patterns`).
- `skills/architecture/SKILL.md` + `skills/principles-and-patterns/SKILL.md`: add
  **bidirectional** cross-references (the chassis requires symmetry).
- Optionally `skills/software-leverage-review/references/boundary-hardening.md`: the three
  cross-cutting SLPs carry peer synthesis reference docs; add one if you mark it cross-cutting.

## Rationale & Key Decisions (the framing the SLP must encode)

`boundary-hardening`'s Core Principles should carry the operator's own logic:

1. **The boundary is what's real (the AI-age thesis).** Implementations are increasingly
   AI-generated and replaceable; the boundary + behavioral test suite is the durable
   artifact. Review question: is the load-bearing seam **explicit, dependency-inverted, and
   pinned by behavior tests**, so the implementation behind it is swappable/regenerable?
2. **Active extraction, not just assessment.** It looks for parts of the code that *can be
   extracted* into isolated modules and dependency-inverted: flag code that *should* be a
   hardened boundary but isn't. (This is the net-new vs `architecture`, which reviews the
   structure that already exists.)
3. **The antithesis of the big ball of mud.** As the codebase grows, encode principles *as
   boundaries* so it doesn't rot into mud.
4. **The dual payoff.** The same hardened boundary yields **internal parallelism** (isolated
   modules → parallel agent/team work) **and external extensibility** (the `extensibility`
   SLP). Price boundary work at both returns.
5. **Leans toward Vertical Slice Architecture.** Vertical slices create boundaries around
   the vertical; VSA is the slicing that makes parallel isolation real.
6. **Boundaries encode the system's mental model**: the boundary structure *is* the
   system's understanding, stable while implementations churn. That is where the value is.
7. **Keep the two net-new mechanics** (from an earlier placement eval): **harden-vs-split by
   cohesion** (high-coupling+high-cohesion → extract a port; high-coupling+low-cohesion →
   decompose) and **"the ratchet *is* the hardening"** (a boundary you extract but don't
   fence with a gate/test silently re-couples).

**Placement decision:** `boundary-hardening` is a *separate, deeper* SLP from `architecture`.
`architecture` reviews existing boundaries/dependency-direction/layers; `boundary-hardening`
is the discipline of *extracting + dependency-inverting new seams and pinning them with
behavioral tests as the durable artifact.* **Cross-reference `architecture`; do not
re-derive** Stable-Dependencies / distance-from-main-sequence / VSA: link to it. The
AI-age boundary-is-real thesis is the strongest net-new content that earns this its lines.

## Do's and Don'ts

- **Do** follow the **house chassis** `authoring-software-leverage-points`: the SLP
  principle-doc shape (`Overview / Core Principles / Red Flags - STOP / Rationalization
  Prevention / Key Patterns / Why This Matters / Growth examples / References & rationales /
  Suggested technologies (dated) / Continual improvement`). **NOT** the generic
  `authoring-skills` chassis: their shapes differ (this repo uses `Red Flags - STOP`, etc.).
- **Do** make it a **review lens** (principle doc, consulted not invoked). Note: the
  operator's DreamShip repo has a *procedural* `boundary-hardening` skill locally
  (`dream-ship_v0/.claude/skills/boundary-hardening/SKILL.md`): read it for principle
  content, but reshape to the review-lens SLP form here.
- **Don't** hand-edit `slp-manifest.yaml`: run **`just regenerate-catalogs`**, then
  **`just qa`**, then commit (per `maintaining-software-leverage-points`).
- **Don't** duplicate `architecture`: cross-reference. The dual-payoff framing is where
  `boundary-hardening`, `architecture`, and `extensibility` connect.
- **Don't** lose the AI-age thesis: a generic "extract modules" skill without it misses
  the operator's whole point.

## Important Context

- The dual-payoff + plugin-seam framing (source of the `extensibility` draft) is written up
  in the operator's DreamShip repo at `dream-ship_v0/docs/design/dreamship-dimensions.md`
  (Extensibility section): good background for both SLPs.
- An earlier sub-agent placement eval concluded the *durable* boundary content overlaps
  `architecture` heavily; the **AI-age "boundary + behavioral tests = the real artifact"
  thesis** is what makes `boundary-hardening` earn its own skill now. Lead with that.

## Suggested Skills

- `authoring-software-leverage-points`: the house chassis; read first, it defines the shape.
- `maintaining-software-leverage-points`: the regenerate-catalogs → `just qa` → commit flow.
- `skill-auditor`: to check the two new SLPs conform before PR.

## References

- `skills/extensibility/SKILL.md`: the drafted companion SLP (external-payoff facet).
- `dream-ship_v0/.claude/skills/boundary-hardening/SKILL.md`: the operator's procedural
  local version (principle content to reshape).
- `dream-ship_v0/docs/design/dreamship-dimensions.md`: the dual-payoff / plugin insight.
- `skills/software-leverage-review/{slp-manifest.yaml,common-types.yaml}`: registration.
- `.claude/skills/authoring-software-leverage-points/SKILL.md`: the SLP shape + house rules.

## Outcome (executed 2026-07-28)

Both skills shipped. The SLP count moved from 17 to 19.

- **`skills/boundary-hardening/SKILL.md`** written in the L1 principle-doc shape, leading
  with the AI-age thesis (boundary + behavioral suite as the durable artifact) and carrying
  the eight principles: durable artifact, behavior-pinning, active extraction, harden-vs-split
  by cohesion, the ratchet, payoff pricing at both returns, horizontal-port vs vertical-slice
  naming, and boundaries as the written-down mental model.
- **`skills/extensibility/SKILL.md`** kept as its own skill rather than folded in. The two
  overlap only on the dual-payoff framing, which is now a cross-reference in both directions.
  The draft's em-dashes were stripped (house rule), its description was fenced against
  `boundary-hardening`, and two of its citations were rewritten to be load-bearing rather
  than decorative (consumer-driven contracts, object-capability security).
- **Back-edges added** to `architecture` (both new skills), `testing`, `software-complexity`,
  and `principles-and-patterns`. `check-backlinks.sh` passes at 19 SLPs.

### Divergences from the brief

- **Neither skill was added to the `CrossCuttingSLP` enum.** That enum means "a finding from
  any other SLP may also violate this one," which holds for `dry`, `software-complexity`, and
  `principles-and-patterns` because they are universal properties of any code. Boundary
  hardening and extensibility are substantive structural concerns, like `architecture`, not
  properties every finding can also violate. Adding them would have made the annotation
  meaningless and implied a peer synthesis reference doc neither needs.
- **No `references/boundary-hardening.md` synthesis doc** was added, for the same reason:
  those docs exist only for the three cross-cutting SLPs.

### Adversarial review pass (Codex, read-only, 2026-07-28)

Both skills were reviewed by `codex exec` with the authoring chassis injected as the
rubric, revised against the findings, then re-verified by a second Codex pass
(18 of 20 findings addressed, 2 partially, 0 open). What the review changed:

- **boundary-hardening** gained three things it was missing: contract *design* (error
  taxonomy, operational semantics, consumer-level abstraction, leaked vendor types,
  chatty and temporally coupled contracts), safe *migration* of a live seam
  (characterization tests, branch by abstraction, side-effect-free shadow comparison,
  cutover and rollback, deleting the old path), and seam *forms* beyond in-process ports
  (process, schema, data-ownership, and peer contracts, where dependency inversion does
  not apply). Its central thesis was scoped: behavioral tests pin sampled behavior, so
  regenerability is conditional on the contract naming the characteristics callers
  actually depend on.
- **extensibility** was rebuilt around the exposure decision and gained compatibility
  and evolution, trust tiers with matching controls, failure containment, and the
  author's experience. Its "one consistent extension level" rule was wrong and is now
  per-surface; its trust model no longer prescribes sandboxing universally.
- **The dual-payoff rule was wrong as originally stated.** "A boundary usually pays
  twice" is not true, and treating single-payoff pricing as a defect would have produced
  bad findings. The payoffs are now priced independently, with option value able to raise
  priority or tip a marginal case but never to supply the justification alone.
- **Citations were repaired**, since several red flags had no named source: Constantine
  and Yourdon for cohesion kinds, Tornhill for change coupling, Bloch and Hyrum's Law for
  contract design, Newman and Fowler for migration patterns, Baldwin and Clark for option
  value, Kleppmann for extension-state compatibility, Nygard and Hohpe/Woolf for failure
  containment and delivery semantics, SLSA and Sigstore for provenance. Two decorative
  citations were replaced outright.

Known tradeoff: boundary-hardening is 299 lines, longer than any existing SLP. The review
flagged some repetition across the principle, red-flag, and pattern sections. The content
is load-bearing, but a future tightening pass is reasonable.
