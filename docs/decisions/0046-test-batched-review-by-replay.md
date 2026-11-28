# D0046 A feature-level review is tested by replaying merged features through the dry-run review

- **Status:** Accepted, 2026-11-27 (Justin approved the replay). Result below: promising, one feature, not conclusive.
- **Decision:** Before any change to branch structure, replay 3-4 merged moho features (3+ cards each, mixed gate class) through `pr-review --dry-run <feature base>..<last card merge>` (moho #1105) as one full-tier review, and compare with the per-card reviews already posted. Nothing is merged, relabelled or posted.
- **Measures (quality first):**
  - **Recall:** every counting blocker (B1/B2 and X-routed) of the per-card reviews that the feature review also finds, by file and line.
  - **Integration yield:** blockers only the feature review finds (cross-card), each refuted or confirmed by the refuter.
  - **Sign-off:** the route the verdict script gives the combined diff (size triggers).
  - **Cost:** the replay's tokens against the sum of the per-card reviews' `pr-review-usage`, per feature.
- **Bar to proceed:** recall of counting blockers at or above the per-card reviews' on every feature, a verdict route no more human than the cards' together, and cost below the sum. A miss on any feature ends the idea (D0045 stands). Integration yield above zero is reported as a separate case for an added, not substituted, feature review.
- **Evidence for the design:** the dry-run mode and the later-round replay exist (moho #1105); D0008 treats one-run gaps as noise, so the bar is stated per blocker, not per cost.
- **Reopen when:** per-card review yield (D0036) shows card reviews rarely find blockers (then the question is the step-11 overlap, not batching).

## Result (2026-11-27, one feature)

- **Replayable features are rare.** Of four merged features with 3+ cards (FPS-F15, FPS-F22, ENG-F48, ENG-F39), only ENG-F39's cards #945, #944 and #964 (PRs #1006, #1012, #1050) cherry-picked cleanly onto their base. The others depend on merges of other lines between their cards (conflicts at FPS-F22-02, FPS-F15-08, ENG-F48-04), so a feature branch would also need `dev` merged in regularly (D0045).
- **Setup.** Review issue was the feature issue #635 (the dry run takes one issue); the review checked the diff against the delivered cards. Runs: moho Actions 46058680449 (cards as merged, 1024 lines) and 46060704639 (#1006 and #1012 at their round-1 heads, 690 lines; #1050 omitted, it did not apply).

| | Per-card reviews (3 PRs) | Feature review, as merged | Feature review, round-1 heads |
|---|---|---|---|
| Cost | $9.1 review and fix ($1.34 + $1.94 + $0.37 + $2.41 + $1.51 + $1.52; #1012 took two rounds) | $3.11 | $2.80 |
| Verdict | #1012 reject (X1, X2), #1006 and #1050 approve | approve, 1 question | reject, 2 blockers |
| Sign-off | agent, human, agent | human (1024 lines) | human (690 lines) |

- **Recall:** 1 of 1. The per-card blocker (#1012 X1/X2, `Region::From` past the last node silently returns the base pose) was found again at round-1 heads as one blocker (X2, same file and rule). It was correctly absent from the as-merged run, which holds the fixed code.
- **Integration yield:** the as-merged run asked one question (`release` doc says to clone `ClipPlayer`, but `Animator` adds layers; a cross-card doc/design gap between #945 and #944). The round-1 run found a new blocker (X1: `rotation_of` in `socket.rs`, #1006's code, leaves scale in `release`'s rotation, so `spawn_loose` panics under a non-uniformly scaled root; reproduced by the finder and refuter) that the #1006 per-card review approved. The as-merged run, over the same #1006 code, did not find it. So the extra finding is probably review variance (D0008), not an effect of batching: one run each does not separate the two.
- **Against the bar:** recall met on the one feature; sign-off route is one human review of a large diff instead of one in three; cost is about 30-35% of the per-card sum. It does not meet "3-4 features", and a human sign-off on 700-1000 lines is the cost that the bar does not price.
- **Next:** not adopted, not dropped. A live pilot of one feature on an integration branch (D0047 proposal in the thread) needs the base-branch changes listed in D0045 first. Variance check: rerun the same two ranges once more to see whether the `rotation_of` blocker reproduces.

## Variance rerun (2026-11-27)

- Same two ranges rerun (runs 46067678913 as merged, 46067687215 at round-1 heads). The `rotation_of` defect reproduced in both (a follow-up each time; it was a blocker in the first round-1 run), so it appeared in 3 of 4 feature-level runs and was refuter-confirmed each time. It is real code on `dev`: filed as moho #1109 (ENG-F39-11). The first as-merged run was the only one that missed it, and the per-card review of #1006 approved it.
- Run-to-run variance is in classification, not only in recall: the `release` doc naming `ClipPlayer` instead of `Animator` was a question in the first as-merged run and a blocker in the second. The `Region::From` silent drop was found in every round-1 run. Cost: $3.42 for the as-merged rerun (the other not read), against $3.11, $2.80 before.
- **Reading:** on this feature the feature-level review is at least as good as the per-card reviews on recall, finds a defect all three per-card reviews approved, and costs about a third of them. The sign-off route stays `human` at 700-1000 lines. Still one feature and four runs, so it supports a pilot (D0045 changes first), not adoption.

