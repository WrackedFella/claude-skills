# D0015 moho's rulesets match each branch's role

- **Status:** Proposed, 2026-11-21
- **Decision:**
  - `dev` (unchanged): PR required, squash only, required checks `Gate (ubuntu-latest)`, `Deny`, `Mutants (diff)`, non-strict, no force push or deletion, no bypass.
  - `main`: merge commits only; required checks `Gate (ubuntu-latest)`, `Gate (macos-latest)`, `Gate (windows-latest)`, `Deny`; review threads resolved; one Copilot review rule; no code-owner review.
  - `feature/**`: PR required, squash (card PRs) or merge (taking `dev`), no force push, the `dev` checks; deletion allowed.
  - The disabled `CI Pass` ruleset is deleted.
- **Why:**
  - `main` had no required checks, though promotions are the only three-OS run. `Mutants (diff)` is skipped on PRs into `main`; a job skipped by `if:` reports success, so requiring it adds nothing.
  - A squashed or rebased promotion leaves `main` with commits `dev` lacks, so the next promotion conflicts.
  - Code-owner review reads CODEOWNERS from the base branch and an author can't approve their own PR; with one owner, a promotion that owner opens could never merge. Owned files are already reviewed on `dev`.
  - CLAUDE.md makes `feature/**` PR targets that take `dev` by merge commit and are deleted after merging. CI fix can't push to a `feature/` head, so a red integration PR is fixed by a card PR into it.
  - Bot branches (`claude/*`, `eval/*`, `eval-base/*`) stay untargeted, so claude-code-action, CI fix, the eval workflow and Board sync push and open PRs as before.
- **Sources:** S7, S8, S9, S10.
- **Reopen when:** `main` takes changes from anything but promotions, or CI's job names change.
