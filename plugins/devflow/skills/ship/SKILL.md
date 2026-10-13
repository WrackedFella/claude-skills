---
name: ship
description: Ship the current branch - run the project gate, write a Conventional Commit, push, and open a PR into the project's base branch with summary, verification and risk. Also produces the PR-style checkpoint summary used when pausing for review.
argument-hint: "[--checkpoint]"
---

Ship the work on the current branch. With `--checkpoint`, produce only the summary
(steps 1 and 5) for a review pause, without committing or pushing.

1. If the project names an environment setup command and `CLAUDE_CODE_REMOTE` is
   `true`, run it before the gate; otherwise skip it. Run the project's gate command
   from its `CLAUDE.md`. If it fails, stop and fix or report; never ship red.
2. If the project defines a pre-commit change check (for example GitNexus
   `detect_changes`), run it. Report a high risk rating with its reason; escalate only
   if signatures, public APIs or behavior changed unexpectedly.
3. Commit with a Conventional Commit message (`type(scope): summary`, body explains
   why). Never commit on the base branch or `main`; create a branch first.
4. Push with upstream tracking.
5. Write the PR description:
   - **Summary:** three short paragraphs, each led by its label, then the links. Link the
     work item and issue (`Closes #N` when it completes the item).
     - **Before:** the behavior or gap, as a reader of the change would have seen it.
     - **After:** what a reader sees now, in observable terms (API, behavior), not a diff recap.
     - **How:** the mechanism and the choices that are not obvious from the diff.
     Deviations from the spec go after these, as one short paragraph.
   - **Verification:** the gate result with counts, mutation-testing result for changed
     code (caught / missed / unviable), anything checked by hand.
   - **Risk:** blast radius, anything that needs a human check (for example an in-game
     playtest), known follow-ups and where they are tracked.
6. Open the PR into the project's base branch with `${CLAUDE_PLUGIN_ROOT}/operations.md`'s *Open PR* operation. Never merge and
   never enable auto-merge.

Report the PR link and anything the reviewer must look at first.
