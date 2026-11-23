# D0023 A SessionStart hook reports a stale devflow; a cloud environment refreshes by a setup-script change

- **Status:** Accepted, 2026-11-23 (Justin raised cloud threads on a stale devflow as a blocker)
- **Decision:**
  - devflow's `hooks/hooks.json` runs [`scripts/version-check`](../../plugins/devflow/scripts/version-check) on `SessionStart` (`startup|resume`). It compares the loaded plugin directory with `plugins/<name>` on the repository's default branch (a depth-1 clone) and, when files differ, tells the user (`systemMessage`) and the model (`additionalContext`): the session keeps the loaded version, so ask before starting a devflow skill or agent, and how to refresh.
  - It is silent when the plugin matches (commits outside the plugin directory don't count), under GitHub Actions, for a plugin root inside a git checkout, and when the upstream can't be read. It always exits 0.
  - A cloud environment's setup script carries a `devflow-stamp: <sha>` comment. Bumping it changes the script, which rebuilds the snapshot; new sessions then load the current plugin.
- **Why:**
  - **The setup script does not run per session.** A thread started 2026-11-23 20:27 UTC had its setup output and plugin install dated 2026-11-18 22:19: sessions restore the snapshot built when the script last changed. The script already ran `marketplace update` and `plugin update`; it simply did not run.
  - **Nothing in a session can refresh it.** `claude plugin update` in the session installs the new version and reports "Restart to apply changes"; a skill invoked afterwards still had the old text, read at startup. A SessionStart hook runs after plugins load. So the hook detects and reports; it doesn't update.
  - **Diff the plugin directory, not the SHA.** Most merges to `main` touch only docs or CI; comparing SHAs would warn on each. A depth-1 clone takes about 1 s and needs no token.
  - **A hook, not prose.** The check must run in every session whatever the model does (S17). Verified: a session with the hook installed and a differing plugin directory repeated the warning from its context.
- **Evidence:** this thread's install (`e5679fc`, 31 commits and 10 plugin files behind `8585cbc`); fixture tests in `tests/version-check.test.sh`.
- **Sources:** S17, S21.
- **Reopen when:** Project settings can deliver a plugin that tracks a git branch per session, or the cloud runs the setup script at each session start.
