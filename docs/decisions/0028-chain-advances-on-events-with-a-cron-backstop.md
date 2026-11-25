# D0028 A chain advances on issue events, with a cron backstop, through one deterministic script

- **Status:** Proposed, 2026-11-25. Builds on D0027.
- **Decision:** a workflow with no model call starts queued, unblocked cards. It runs on an issue closing (state reason completed), on the queue label being added, on a Claude run completing (a slot frees up), on a cron backstop (every 2 hours), and by hand. Each trigger runs the same script, which gathers facts by REST and decides which cards to start, fixture-tested like the merge-eligibility script. It starts a card by swapping the queue label for `agent-ready` with the reviewer App's token, and skips a card that is paused, labelled `needs-human`, human-driven (D0030), or whose blocker closed as not planned.
- **Why:**
  - **Events first.** A merged PR's `Closes #N` closes the card, and the Board sync workflow already acts on that event for human and App merges, so the next card starts within a minute of a merge.
  - **Cron as a backstop only.** Cron alone delays each step by a tick; events alone stall a chain on a dropped event or a full run cap. An idle tick reads a few issues and exits.
  - **App token for the label.** A label added with `GITHUB_TOKEN` starts no workflow; one added by an App starts the run and moves Board Status like a person's label. `workflow_dispatch` is the fallback, the one event `GITHUB_TOKEN` may start.
  - **A script, not a prompt.** Which card starts is a rule that must always hold (D0020).
- **Not used:** the `sub_issues` and `issue_dependencies` webhook events (whether Actions can trigger on them was not verified; the design does not need them) and `board next` (GraphQL, Projects).
- **Sources:** S11, S17, S27.
- **Reopen when:** a chain stalls for longer than one cron tick with an unblocked queued card, or a card starts twice.
