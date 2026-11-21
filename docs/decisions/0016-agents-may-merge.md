# D0016 Agents may merge once automated checks and review pass

- **Status:** Accepted, 2026-11-21 (Justin). Replaces the rule that only humans merge.
- **Decision:** an agent may merge a PR after its required checks and the automated review pass. moho's rulesets impose no human step on `dev` or `feature/**`: 0 required approvals, no code-owner review, no bypass list. The auto-merge mechanism (who merges, which token, eligibility) is designed separately.
- **Why:** humans merged only because merging hadn't been automated yet. A ruleset that demands a human approval would block that automation.
- **Constraints the auto-merge design inherits:**
  - Required checks stay the floor: `dev` and `feature/**` require `Gate (ubuntu-latest)`, `Deny`, `Mutants (diff)` with no bypass, so no merge skips them.
  - The merging token must start push CI and Board sync. A merge made with the workflow's `GITHUB_TOKEN` starts neither; the `moho-reviewer` App token does.
  - If the design adds a required approval, the approver must differ from the PR's author and last pusher (authors can't approve their own PRs).
  - `require_extra_approval_for_unattributed_changes` is on in moho's rulesets; the first agent merge confirms it doesn't hold back agent commits.
  - `main` requires resolved review threads, which agents never resolve, so promotions stay a human merge until that rule is revisited.
- **Sources:** S7, S9, S10.
- **Reopen when:** an agent merge lands a change a human review would have stopped.
