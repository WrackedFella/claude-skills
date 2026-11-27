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
