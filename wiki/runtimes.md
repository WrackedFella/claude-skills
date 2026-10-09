# Runtimes

The same skills run in four places. They differ in how devflow is delivered, what
tooling exists, and whether the board is reachable.

| Runtime | Start | devflow comes from | Board | Notes |
|---|---|---|---|---|
| Local terminal | Slash commands | The project's pinned `.claude/settings.json` | Reachable with `gh` `project` scope | Project hooks (formatting, gate on stop) apply |
| Cloud thread | Slash commands in a Claude Code Project | Environment setup (user-scope install) or a linked checkout of this repo | Usually unreachable | Fresh clone and own branch per thread; project hooks and plugin pins do not load |
| GitHub Actions run | Label `agent-ready` or manual dispatch | The runner's own install, typically the marketplace default branch | Unreachable with the default app token | Unattended; bounded by time and turn limits |
| Comment-triggered run | An authorized `@claude` comment | As the Actions run | As the Actions run | Small jobs, such as resolving a PR's merge conflict |

## Cloud threads

- **Plugin delivery.** Plugins enabled in a repository's `.claude/settings.json` are not
  loaded. The environment's setup script installs devflow at user scope, pinned to a tag,
  or the Project links this repository. The environment is a snapshot rebuilt when the
  script changes or after a few days, so a new tag reaches threads only then. Keep the
  script's ref in step with the consumer's pin.
- **Toolchain on demand.** The environment setup command from the
  [project contract](project-contract.md) installs the build toolchain. Threads that only
  edit text skip it and start faster.
- **No board.** GraphQL and Projects v2 are blocked, so `scripts/board` fails. Skills
  skip board steps ([Board](board.md#unreachable-board)); automation outside the thread
  moves Status instead.
- **MCP servers** start before a thread runs anything and are not restarted, so a
  server that needs installing must install itself on launch.
- **Everything unpushed is lost** if the sandbox cannot resume; skills push after each commit.

## Unattended runs

A runner (for example `claude-code-action`) reacts to a label and invokes a skill:

| Trigger | Skill |
|---|---|
| `agent-ready` on a `feature` issue | `/devflow:refine <issue>` |
| `agent-ready` on any other issue | `/devflow:orchestrate <issue>` |

- Only the default app token is available; no board access.
- One run per issue at a time; refine needs a shorter budget than orchestrate.
- Run output lives in the runner's logs or step summary, not in the issue.
- Workflow file edits need a human merge.
- Under `Card review: required`, a human applies `agent-ready` to each card; under
  `not required`, `refine` applies it to cards that need no person and the runner
  dispatches a run per card.

## Status automation

With no board access from agents, a workflow reacts to events and moves Status forward
only: label on a work item or draft PR → In progress; PR ready for review → In review;
merged PR or closed issue → Done. Humans set Ready and Agent-eligible.
