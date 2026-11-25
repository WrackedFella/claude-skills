# D0029 Chain cards merge into the base branch one by one; no chain branch, no stacked PRs

- **Status:** Proposed, 2026-11-25. Builds on D0017.
- **Decision:** each card in a chain opens its PR into the base branch (`dev` in moho) and merges through the existing agent merge or a person. The next card starts only after its blocker's issue closes, so it always branches from a base that holds the previous card. A chain gets no feature integration branch, and no card starts before the card it depends on merges. A card the agent merge won't take (domain under `PR_AUTOMERGE=glue`, `Sign-off: human`) waits for a person, and the chain resumes on that merge.
- **Why:**
  - **Agent merge was about to fire.** The last four agent PRs (moho #903, #908, #910, #914) were all glue with no deny path; their sign-off triggers were the 400-line size limit, plus an open question on #903. claude-skills #128 waives the size trigger up to 3000 non-test lines for light-tier PRs whose gate and mutation passed, so three of the four would now merge.
  - **A chain branch moves the human review, it doesn't remove it.** Its final PR into the base is one large review. It also needs the merge rules, the ruleset and the chain trigger changed, because `Closes #N` closes nothing when a PR merges into a non-default branch.
  - **Stacked PRs fight the SHA-pinned merge.** Every fix round on card N rebases N+1 and invalidates its review, and a reject of N cascades.
- **Trade-off accepted:** a bad chain lands in the base card by card. The green-base rule (D0017) stops further agent merges once CI on it goes red.
- **Sources:** S11, S12, S28.
- **Reopen when:** domain chains pile up waiting on people after `PR_AUTOMERGE=all` is reached or refused; a chain branch with agent merges into it is the alternative to measure then.
