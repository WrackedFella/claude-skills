# D0027 A chain is the set of queued cards over their issue dependencies

- **Status:** Proposed, 2026-11-25.
- **Decision:** a work-item chain has no structure of its own. Order is the issue dependency graph (`blocked by`) that planning already writes; the opt-in to run cards unattended is a queue label (moho: `agent-queued`, "run me when my blockers close"). A queued card with no open blocker starts; the others start as their blockers close. Queueing a card approves it, as `agent-ready` does under `Card review: required`.
- **Why:**
  - **No second record of order.** refine and the Tech Lead already add `blocked_by` for each earlier card (`operations.md`, *Add dependency*). A chain list in a body, or sub-issue order, would drift from it.
  - **One REST read.** Each issue carries `issue_dependencies_summary`, whose `blocked_by` counts open blockers only, so "unblocked" needs no GraphQL and no board, which Actions can't reach with the App token.
  - **Not sub-issue order.** Sub-issue order is display priority, a feature's cards are not always linear, and a dependency can cross features (an engine card blocking a game card).
  - **A label, not a board field.** Labels are readable and writable by REST from Actions, visible on the issue, and settable only by people with triage rights on a public repository.
  - **Parallel branches are safe.** Planning orders cards that share a file by dependency, so cards unblocked together have disjoint footprints.
- **Evidence:** live API, moho 2026-11-25: #891 (ENG-F50-02) is blocked by #890 with `blocked_by: 3`; #901 shows `blocked_by: 0`, `total_blocked_by: 1` after its blocker #758 closed. `claude.yml` already reads `issues/{n}/sub_issues`. Proposal: project file `work-chains/proposal.md`.
- **Sources:** S25, S26.
- **Reopen when:** a chain needs an order the dependency graph can't express, or cards unblocked together collide on a file.
