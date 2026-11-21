# D0016 "Only humans merge" is a ruleset on moho `dev`

- **Status:** Proposed, 2026-11-21; needs Justin's go-ahead (changes how he merges)
- **Decision:** a second ruleset on moho `dev`, `dev: human merge`: 1 approval, code-owner review, dismiss stale approvals, approval of the last push; bypass Repository admin, pull requests only. The `dev` ruleset keeps the required checks with no bypass.
- **Why:**
  - With 0 approvals, any token with write access can merge a green PR; the rule was prose. While `PR approval: off`, no bot approves, so no bot can merge.
  - A separate ruleset scopes the bypass to the approval rule: the admin merges their own PRs without an approval, but never past a red required check.
  - At the auto-merge stage the `moho-reviewer` approval satisfies the rule, except on code-owned paths (`.github/`, `.claude/`, gate files), which keep needing a human: the auto-merge plan's deny-list, enforced by GitHub. The plan's stage 2 ruleset edit becomes a `PR approval` switch.
  - Dismiss-stale and last-push approval stop a push after an approval (respond, CI fix) from riding on it.
- **Cost:** agent PRs take an Approve before Merge; the admin's own PRs take the bypass checkbox.
- **Unverified:** role bypass on a user-owned repository (docs describe it generally; community reports are mixed). Exit check: the admin's next own PR offers the bypass merge, and the next agent PR waits for an approval. If the bypass is unavailable, the ruleset is not created.
- **Sources:** S7, S9, S10.
- **Reopen when:** the bypass is unavailable, or the auto-merge stage starts.
