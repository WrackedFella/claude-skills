# D0046 A feature-level review is tested by replaying merged features through the dry-run review

- **Status:** Proposed, 2026-11-27.
- **Decision:** Before any change to branch structure, replay 3-4 merged moho features (3+ cards each, mixed gate class) through `pr-review --dry-run <feature base>..<last card merge>` (moho #1105) as one full-tier review, and compare with the per-card reviews already posted. Nothing is merged, relabelled or posted.
- **Measures (quality first):**
  - **Recall:** every counting blocker (B1/B2 and X-routed) of the per-card reviews that the feature review also finds, by file and line.
  - **Integration yield:** blockers only the feature review finds (cross-card), each refuted or confirmed by the refuter.
  - **Sign-off:** the route the verdict script gives the combined diff (size triggers).
  - **Cost:** the replay's tokens against the sum of the per-card reviews' `pr-review-usage`, per feature.
- **Bar to proceed:** recall of counting blockers at or above the per-card reviews' on every feature, a verdict route no more human than the cards' together, and cost below the sum. A miss on any feature ends the idea (D0045 stands). Integration yield above zero is reported as a separate case for an added, not substituted, feature review.
- **Evidence for the design:** the dry-run mode and the later-round replay exist (moho #1105); D0008 treats one-run gaps as noise, so the bar is stated per blocker, not per cost.
- **Reopen when:** per-card review yield (D0036) shows card reviews rarely find blockers (then the question is the step-11 overlap, not batching).

## Variance rerun (2026-11-27)

- Same two ranges rerun (runs 46067678913 as merged, 46067687215 at round-1 heads). The `rotation_of` defect reproduced in both (a follow-up each time; it was a blocker in the first round-1 run), so it appeared in 3 of 4 feature-level runs and was refuter-confirmed each time. It is real code on `dev`: filed as moho #1109 (ENG-F39-11). The first as-merged run was the only one that missed it, and the per-card review of #1006 approved it.
- Run-to-run variance is in classification, not only in recall: the `release` doc naming `ClipPlayer` instead of `Animator` was a question in the first as-merged run and a blocker in the second. The `Region::From` silent drop was found in every round-1 run. Cost: $3.42 for the as-merged rerun (the other not read), against $3.11, $2.80 before.
- **Reading:** on this feature the feature-level review is at least as good as the per-card reviews on recall, finds a defect all three per-card reviews approved, and costs about a third of them. The sign-off route stays `human` at 700-1000 lines. Still one feature and four runs, so it supports a pilot (D0045 changes first), not adoption.

