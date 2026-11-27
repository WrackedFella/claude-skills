# D0037 PR-review rounds 2 and later read the delta, not the whole PR

- **Status:** Proposed, 2026-11-27.
- **Decision:** From round 2, the finders get the diff between the last reviewed SHA and the head, the carried blockers, and the full PR only on request; the refuter's `fixed` check on each earlier blocker is unchanged. A finder that wants the surrounding code reads it. The verdict script and the changed-lines goalpost (`pr-review` §4) are unchanged.
- **Why:** The skill already ignores new blockers outside the changed lines, yet the round-2 Opus review is almost as large as round 1 (PR #1081: round 1 $1.72, 28 turns, 152k cache write; round 2 $1.38, 28 turns, 128k). The reads outside the delta cannot produce a counting blocker.
- **Evidence:** `pr-review-usage` on PR #1081 (issue #1019); about 15 of 49 issues in the window needed 2+ rounds; review plus fix is 32% of recorded spend.
- **Risk and guard:** a fix can break code outside its lines. The B1/B2 failing-test route stays open for that, and the first round still reads everything.
- **Proof:** replay the `pr-verdict` replay set (#113, moho) with round-2 inputs under the new brief; keep if verdict and route agree on every case that had a counting blocker, then a standard-tier run for the saving.
- **Reopen when:** a round-2 review misses a blocker that a full read finds in the replay set.
