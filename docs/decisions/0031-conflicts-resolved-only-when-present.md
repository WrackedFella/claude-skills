# D0031 An agent PR's conflict with the base is resolved by a run only when one exists

- **Status:** Accepted, 2026-11-25 (Justin asked for automatic conflict handling without a run per merge).
- **Decision:** on every push to the base branch, a script reads each open agent PR's `mergeable_state` (one REST read per PR, no model call). A PR that still merges is left alone. A PR in conflict (`dirty`) starts one run that merges the base into its branch, resolves the conflict, runs the gate and pushes; the PR review then runs on the new head. A conflict that needs a product or design decision, or would change what a test asserts, is aborted and the PR labelled `needs-human`. Branches are never rebased or force-pushed.
- **Why:**
  - **Cost scales with conflicts, not merges.** The per-merge check is a few REST reads; a model run happens only on a real textual conflict.
  - **A stale but clean branch needs nothing.** The base's required checks are not strict, and the agent merge is pinned to the reviewed SHA (D0017), so updating every open branch after each merge (the "update branch" button, or the auto-update of Mergify-style bots) would only restart CI and invalidate reviews.
  - **A merge queue does not solve this.** It tests PRs against the queue's combined head and removes a PR that conflicts; resolving the conflict is still someone's job. bors-style and Mergify-style bots likewise rebase or update clean branches and stop on a conflict.
  - **Merge, not rebase.** A merge commit keeps the reviewed commits and the history the review and `test-guard` read; a rebase rewrites a branch another run may hold (moho CLAUDE.md: merge commits on shared branches).
- **Prevention comes first.** The first conflict (moho #941 vs #950, 2026-11-25) was a shared wiki table edited by two cards running side by side; card footprints don't list wiki pages. Under the chain's run cap of 1 (D0030), chained cards don't overlap, so conflicts come from parallel work.
- **Evidence:** moho #941 went `dirty` after #950 merged; the only conflict was one row pair in `wiki/searchlight/architecture.md`, resolved by keeping both sides.
- **Sources:** S12, S29, S30, S31.
- **Reopen when:** resolve runs exceed about one per five agent merges (then shared hot files need restructuring, or footprints should list wiki pages), or a resolution lands a change a person would have stopped.
