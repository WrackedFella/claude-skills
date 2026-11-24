# Runtimes

The same skills run in four places. They differ in how devflow is delivered, what
tooling exists, and whether the board is reachable.

| Runtime | Start | devflow comes from | Board | Notes |
|---|---|---|---|---|
| Local terminal | Slash commands | The project's `.claude/settings.json` | Reachable with `gh` `project` scope | Project hooks (formatting, gate on stop) apply |
| Cloud thread | Slash commands in a Claude Code Project | Environment setup (user-scope install) or a linked checkout of this repo | Usually unreachable | Fresh clone and own branch per thread; project hooks and plugin settings do not load |
| GitHub Actions run | Label `agent-ready` or manual dispatch | The runner's own install, typically the marketplace default branch | Unreachable with the default app token | Unattended; bounded by time and turn limits |
| Comment-triggered run | A `@claude` comment by a repository owner, member or collaborator | As the Actions run | As the Actions run | Small jobs, such as resolving a PR's merge conflict; an `@claude /devflow:respond` comment runs the respond skill, `@claude /devflow:pr-review` the review skill |

## Cloud threads

- **Plugin delivery.** Plugins enabled in a repository's `.claude/settings.json` are not
  loaded. The environment's setup script installs devflow at user scope from the default
  branch. The script runs only when the environment's snapshot is built (when the script
  changes, or after a few days), not per session, so a merge to `main` reaches threads only
  after a rebuild. Bumping the script's `devflow-stamp:` line forces one
  ([Getting started](getting-started.md#7-set-up-the-cloud-environment-optional)).
- **Stale-plugin warning.** The `SessionStart` hook
  ([`version-check`](../plugins/devflow/scripts/version-check)) compares the loaded plugin
  with the default branch and, when they differ, tells the user and the model which files
  differ and how to refresh. A session can't reload its plugin, so it asks before starting
  a devflow skill or agent on the old version.
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

- Projects with an `Acceptance command` need a browser on the runner (for Playwright,
  `npx playwright install --with-deps chromium`, cached) and allow-list entries for the
  app start, acceptance and app stop commands and `scripts/e2e-guard`. Keep the
  acceptance runner's traces on failure and upload them, with `/tmp/devflow-acceptance/`
  (the acceptance reviewer's evidence), as a run artifact. The acceptance reviewer also
  needs `playwright-cli` on the runner and in its allow-list.
- Headless runs match Bash commands against the allow-list by prefix, so `orchestrate` and `respond` issue one command per call; a compound is denied unless every part is allowed, and each denial costs a turn.
- Plugin hooks load wherever the plugin does, including a user-scope install in a cloud thread. The `SessionStart` hook (`version-check`) skips GitHub Actions, which installs the default branch per run. The `Stop` hook ([`step-check`](../plugins/devflow/scripts/step-check)) enforces only when `GITHUB_ACTIONS=true`; it needs `jq` on the runner. Run it on an execution log (`step-check <log>`) to score a finished run.
- Headless runs force foreground subagents. Parallel implementer calls issued in one message run concurrently where the host allows and serially otherwise; correctness does not depend on concurrency, only wall-clock does.
- Only the default app token is available; no board access.
- One run per issue at a time; refine needs a shorter budget than orchestrate.
- Run output lives in the runner's logs or step summary, not in the issue, except a pause.
- **Pause and resume.** A run that needs a person's answer comments its questions on the
  issue, labels it `agent-paused` and stops. A comment starting with `Resume` from an owner, member or collaborator
  makes the runner start the same skill again; other comments do not. Intake removes the label, reads the answers (every comment since the pause, the Resume comment included) and continues from the pushed
  branch or published cards. PR-side runs (`respond`, `pr-review`) reply on the PR, and an `@claude`
  comment resumes them. The runner must start on issue comments whose body starts with `Resume` for this to work.
- Workflow file edits need a human merge.
- Under `Card review: required`, a human applies `agent-ready` to each card; under
  `not required`, the Tech Lead, `refine` and `publish` apply it to cards that pass the promotion checks and the runner
  dispatches a run per card.

## Status automation

With no board access from agents, a workflow (for example Moho's Board sync action) reacts to events and moves Status forward
only: label on a work item or draft PR → In progress; PR ready for review → In review;
merged PR or closed issue → Done. Humans set Ready and Agent-eligible.

Runtimes that use `Tracker: azure-devops` need the `az` CLI with the `azure-devops` extension and credentials for the organization; the GitHub Actions rows apply only to GitHub projects. Commands are in [operations](../plugins/devflow/operations.md) and are Unverified.
