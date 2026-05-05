<!--
BEFORE SUBMITTING: Read every word of this template. PRs that leave
sections blank, contain multiple unrelated changes, or show no evidence
of human involvement will be closed without review.
-->

## What problem are you trying to solve?
<!-- Describe the specific problem you encountered. If this was a session
     issue, include: what you were doing, what went wrong, the model's
     exact failure mode, and ideally a transcript or session log.

     "Improving" something is not a problem statement. What broke? What
     failed? What was the user experience that motivated this? -->

## What does this PR change?
<!-- 1-3 sentences. What, not why: the "why" belongs above. -->

## Is this change appropriate for this plugin?
<!-- software-leverage-points ships skills focused on the high-impact
     concerns of software projects (testing, logging, architecture,
     dependencies, security, etc.) and an orchestrator that fans them
     out at plan-time and PR-time. Ask yourself:

     - Is this a new leverage-point lens, or a refinement of an existing one?
     - Does it cite rationale (ADRs, books, practitioners) for its red flags?
     - Or is it project-specific, team-specific, or harness-specific?

     If your change is a workflow skill or harness adapter not specific to
     a software leverage point, it likely belongs in its own plugin. -->

## What alternatives did you consider?
<!-- What other approaches did you try or evaluate before landing on this
     one? Why were they worse? If you didn't consider alternatives, say so,
     but know that's a red flag. -->

## Does this PR contain multiple unrelated changes?
<!-- If yes: stop. Split it into separate PRs. Bundled PRs will be closed.
     If you believe the changes are related, explain the dependency. -->

## Existing PRs
- [ ] I have reviewed all open AND closed PRs for duplicates or prior art
- Related PRs: <!-- #number, #number, or "none found" -->

<!-- If a related closed PR exists, explain what's different about your
     approach and why it should succeed where the other didn't. -->

## Environment tested

| Harness (e.g. Claude Code, Cursor) | Harness version | Model | Model version/ID |
|-------------------------------------|-----------------|-------|------------------|
|                                     |                 |       |                  |

## Evaluation
- What was the initial prompt you (or your human partner) used to start
  the session that led to this change?
- How many eval sessions did you run AFTER making the change?
- How did outcomes change compared to before the change?

<!-- "It works" is not evaluation. Describe the before/after difference
     you observed across multiple sessions. -->

## Rigor

- [ ] If this is a skills change: I followed our skill-authoring discipline
      and completed adversarial pressure testing (paste results below)
- [ ] This change was tested adversarially, not just on the happy path
- [ ] I did not modify carefully-tuned content (Red Flags table,
      rationalizations, "human partner" language) without extensive evals
      showing the change is an improvement

<!-- If you changed wording in skills that shape agent behavior, show your
     eval methodology and results. These are not prose: they are code. -->

## Human review
- [ ] A human has reviewed the COMPLETE proposed diff before submission

<!--
STOP. If the checkbox above is not checked, do not submit this PR.

PRs will be closed without review if they:
- Show no evidence of human involvement
- Contain multiple unrelated changes
- Promote or integrate third-party services or tools
- Submit project-specific or personal configuration as core changes
- Leave required sections blank or use placeholder text
- Modify behavior-shaping content without eval evidence
-->
