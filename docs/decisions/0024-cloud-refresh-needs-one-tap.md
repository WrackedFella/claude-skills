# D0024 Nothing outside a session can refresh a cloud environment's devflow; staleness is detected and a stamp bump is one approval

- **Status:** Accepted, 2026-11-23 (Justin asked for full automation; this is the limit of what the platform allows). Builds on D0023.
- **Decision:**
  - No Action, script or secret updates an Anthropic-hosted environment's setup script, so no devflow merge can bump `devflow-stamp:` unattended. The stamp stays a one-approval step: a session that gets the `version-check` warning proposes the script edit with `update_environment`, and Justin approves the card.
  - Staleness is bounded without any action: the snapshot rebuilds when it expires, about 7 days, and the rebuild runs the script's `marketplace update` and `plugin update`.
  - No reminder Action. `version-check` already says so at the start of the first stale session, with the SHA to use.
  - Open: whether the account-level plugin sync (claude.ai Customize > Plugins) accepts `WrackedFella/claude-skills`. Synced plugins download at session start, so they would not come from the snapshot. Nothing is built for it until that is checked.
- **Why:**
  - **No outside write path.** The docs list environments as edited in the environment selector; `/remote-env` only picks a default, and `--environment` takes only self-hosted runner IDs. The `update_environment` tool shows an approval card on every call.
  - **No refresh inside a session.** Plugins load at session start from the install cache, and a `SessionStart` hook runs after they load. A repository's `extraKnownMarketplaces` is not applied in cloud sessions. `/reload-plugins` reports that it isn't available over a remote connection.
  - **A self-updating hook gains nothing.** An update made in a cloud session is gone at the next one, which restores the snapshot. Overwriting the loaded plugin directory in place changes only what is read at call time (hook scripts), leaving skills and agents on the old text: a half-applied plugin. Plugin skills don't hot-reload; only `~/.claude/skills` does, which carries no agents or hooks.
  - **Snapshot rebuilds** on a script change, an allowed-hosts change or expiry.
- **Evidence:** retested 2026-11-24 on Claude Code 2.1.331: after `claude plugin update` (about 2 s) and after copying `main`'s files over the loaded directory, `devflow:sitrep` and a never-invoked `devflow:comment-audit` both still ran the loaded text from the old path. D0023's test of `claude plugin update` in a session ("Restart to apply"; the skill text was unchanged); the setup output in a session started 2026-11-23, dated 2026-11-18.
- **Sources:** S22, S23.
- **Reopen when:** the docs add a way to edit an environment from outside a session, the plugin sync accepts a git marketplace, or `/reload-plugins` works in a remote session.
