# D0030 A chain stops at a human-driven card and runs at most a set number of cards at once

- **Status:** Accepted, 2026-11-25 (Justin approved the proposal: `Agent-eligible: No` as the stop marker, cap 1).
- **Decision:**
  - **Stop marker:** a card with `Agent-eligible: No` (board header `eligible=no`) is never started by the chain; the chain comments once that it stops there. A person drives that card in a session; when its PR merges, the card closes and the chain continues with no resume command.
  - **Cap:** repository variable `AGENT_MAX_RUNS` (default 1) bounds unattended runs across all chains, counting in-progress and queued Claude and eval runs. A run sleeping for the usage-limit reset counts, so no chain starts a card into an exhausted window.
- **Why:**
  - **Reuse the field that already means it.** `Agent-eligible: No` already means "a person drives this item" and is written by the Tech Lead into a header the script reads by REST. A second label would be a second way to say it.
  - **Stopping costs nothing.** The next card's dependency edge already holds it; only a closed issue moves a chain.
  - **The 5-hour usage window binds** (project memory 2026-11-18); a cap of 1 keeps one card's run and its review inside it. Raise it once run records show headroom.
- **Sources:** S27.
- **Reopen when:** people want to stop a chain mid-flight more often than they plan a human card up front (then a label is cheaper to toggle), or runs regularly wait on the cap with usage to spare.
