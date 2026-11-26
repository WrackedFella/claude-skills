# D0032 A PR review the usage limit cut off is dispatched again after the reset

- **Status:** Accepted, 2026-11-26 (Justin approved after the overnight failures).
- **Decision:** the PR review workflow reads the reset time from a cut-off review's last result and a `Resume after usage limit` job, after sleeping until the reset plus five minutes, dispatches `pr-review.yml` for the same PR with an `attempt` counter (three runs at most). Only the review step resumes; a fix round the limit cuts off goes to `needs-human` as any unfinished fix round does.
- **Why:**
  - **Same mechanism as orchestrate.** The sleeping Resume job in `claude.yml` (moho #918) resumed both orchestrate runs cut off on 2026-11-25 at 23:24 UTC and they succeeded at 03:19; a review cut off at the same moment (moho runs 45720726822, 45721067984) had no equivalent and stayed red.
  - **Re-dispatch is idempotent.** The review's PR step already skips a closed PR, a lost head branch, or a head that has a review, so a late dispatch costs nothing and a moved head is reviewed on its new SHA.
  - **Not a resumed session.** A review is one short run pinned to a SHA; starting it again loses less than a session resume would save, and needs no state.
  - **A fix round is not resumed.** A new review of an unchanged head would spend one of one of the capped review rounds, so a person decides.
  - **Detection is inline.** The job checks out the PR branch, whose `scripts/` can predate the helper, so the pipeline lives in the workflow.
- **Also recorded (amends D0031):** the model action does not run on a `push` event (moho run 45815783014: `Unsupported event type: push`), so the push-triggered scan dispatches `conflicts.yml` once per conflicted PR and the dispatched run resolves it. The decision itself is unchanged.
- **Evidence:** moho runs 45721142314 and 45721062313 (orchestrate: 0.4 s, 0 tokens, `is_error`, then the Resume job and a successful run at 03:19); 45720726822 and 45721067984 (review: same cut-off, no resume); 45815783014 (conflicts on push).
- **Sources:** S32.
- **Reopen when:** a resumed review lands on a PR a person already reviewed or merged more than rarely, or sleeping runners become a cost.
