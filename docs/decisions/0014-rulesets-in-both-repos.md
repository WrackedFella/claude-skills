# D0014 Branch rules are rulesets in both repositories

- **Status:** Accepted, 2026-11-21 (Justin)
- **Decision:** claude-skills and moho protect their branches with repository rulesets, not classic branch protection. Each repository's rules follow its own CI:
  - claude-skills `main`: PR required (0 approvals), no force push or deletion, no bypass, required checks `shellcheck`, `tests`, `plugin`, `links`, `workflows` and `eval tier`, all from GitHub Actions (on #89 `eval tier` reported from the Actions app on the PR head, so it is pinned like the others). Equivalent to the classic rule it replaces, which enforced it on admins.
  - moho: rulesets per protected branch (`dev`, `main`, `feature/**`), described in D0015.
- **Why:** one mechanism in both repositories; rulesets layer (each branch gets the most restrictive version of every rule across rulesets), carry per-ruleset bypass lists, and export and import as JSON. pr-review's stale-approval check already reads `rules/branches/<base>` first, which aggregates rulesets.
- **Evidence:** classic protection on claude-skills `main` applied after #88; moho `dev` (8386237) and `main` (8386235) already rulesets. Ruleset JSON kept with the project's files (`rulesets/`).
- **Sources:** S7, S8.
- **Reopen when:** a needed rule exists only in classic protection.
