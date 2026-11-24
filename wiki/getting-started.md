# Getting started

Steps to adopt devflow in a repository, in the order to do them. Steps 1 to 4 give a
working interactive flow; 5 to 8 are optional.
[Moho](https://github.com/WrackedFella/moho) is the worked example throughout.

| # | Step | Needed for |
|---|---|---|
| 1 | Install the plugin | everything |
| 2 | Write the project contract in `CLAUDE.md` | everything |
| 3 | Provide the gate and mutation commands | `orchestrate`, `ship` |
| 4 | Add planning standards and issue templates | planning, `refine` |
| 5 | Set up the board | queue pickup, `sitrep` records |
| 6 | Add the GitHub Actions workflows | unattended runs |
| 7 | Set up the cloud environment | Claude Code Projects threads |
| 8 | Turn on acceptance tests and review | web apps checked against the running app |

## 1 Install the plugin

From the project root:

```bash
claude plugin marketplace add WrackedFella/claude-skills --scope project
claude plugin install devflow@claude-skills --scope project
```

Commit `.claude/settings.json`. The marketplace tracks the default branch and the
plugin carries no `version`, so Claude Code versions it by commit and each merge to `main`
is an update; `autoUpdate` fetches it in the background. To freeze a project, set `ref`
on the source to a commit:

```json
{
  "extraKnownMarketplaces": {
    "claude-skills": {
      "source": { "source": "github", "repo": "WrackedFella/claude-skills" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": { "devflow@claude-skills": true }
}
```

`enabledPlugins` turns the plugin on for collaborators but does not download it; each
collaborator runs the `install` command once. Upgrading and releasing are in the
[root README](../README.md#upgrading).

## 2 Write the project contract

Add the settings from the [project contract](project-contract.md) to `CLAUDE.md`. The
required ones are the gate command, the mutation command, the base branch, the planning
standards and the domain-logic paths. Start with both review points at their default
(`required`); relax one only after runs show it is safe ([Overview](overview.md#human-review-points)).

Moho's `CLAUDE.md` section, abbreviated:

```markdown
- **Base branch:** `dev`. Branch `<type>/<ID>-<slug>`, PR into `dev`. No skill merges.
- **Project board:** WrackedFella, project 1.
- **Planning:** index `_todo/README.md`, rules `_todo/_STANDARDS.md`.
- **Environment setup command:** `bash scripts/cloud-tools.sh` (cloud threads only).
- **Domain-logic paths:** rules in `moho_game`, `moho_core`.
- **Human review points:** `Card review: required`, `Domain-test review: agent`.
- **Docs directory:** `wiki/`, conventions in `wiki/README.md`.
```

A .NET project names its language module the same way and supplies its own commands:

```markdown
- **Standards:** `engineering-standards, dotnet-standards` (add `azure-standards` for Azure-hosted projects)
- **Gate command:** `dotnet build -warnaserror && dotnet format --verify-no-changes && dotnet test`
- **Mutation command:** `dotnet stryker --since:<base-branch>` (Stryker.NET diff mode; without `--since` it mutates the whole project; set `thresholds.break` in `stryker-config.json`, or pass `--break-at`, so a score below it fails)
```

## 3 Provide the gates

devflow runs whatever commands `CLAUDE.md` names; they must exit non-zero on failure.

| Gate | Moho's command | Contents |
|---|---|---|
| Gate | `just check` | fmt, clippy `-D warnings`, nextest, doctests, comment refs, layering |
| Mutation | `just mutants` | `cargo mutants` over the diff against the base branch |
| Full-platform CI | `gh workflow run CI --ref <branch>` | all target OSes, when PR CI covers fewer |

Optional enforcement outside the skills, as hooks in `.claude/settings.json`: a `Stop`
hook that runs the gate, and a `PostToolUse` hook that formats edited files. A rule that
must always hold belongs in a hook or gate script, not in prose.

## 4 Add planning standards and issue templates

The planning standards named in `CLAUDE.md` define what the plugin leaves open: where
features and cards live, the ID format (`<LINE>-F<n>-<NN>`), the card template
(acceptance criteria and tech spec), statuses, and when drafts are deleted. Moho's are in
`_todo/_STANDARDS.md`.

Create the labels the skills use: `feature`, `agent-ready`, and one label per product
line. Issue templates for a feature and a work item keep published issues uniform
(`.github/ISSUE_TEMPLATE/` in Moho).

## 5 Set up the board (optional)

1. Create a GitHub Project with the single-select fields in [Board](board.md#fields):
   Status, Priority, Gate class, Agent-eligible.
2. Authenticate `gh` with the project scope: `gh auth refresh -s project`.
3. Put the owner and project number in `CLAUDE.md`.
4. Verify: `plugins/devflow/scripts/board probe <owner> <number>` (exit 5 means the board is
   unreachable from this environment).

Agents cannot write the board from cloud threads or Actions; drafts filed without it are
later published with `/devflow:publish`. Moho moves Status with a
workflow instead (`.github/workflows/board-sync.yml`): it reacts to PR and issue events
and moves Status forward only, using a repository secret `BOARD_TOKEN` (a classic personal
access token with the `repo` and `project` scopes). Ready and Agent-eligible stay human-set.

## 6 Add GitHub Actions workflows (optional)

For unattended runs ([Runtimes](runtimes.md#unattended-runs)). Moho's examples:

| Workflow | Trigger | Runs |
|---|---|---|
| `claude.yml` | Label `agent-ready` on an issue; manual dispatch with an issue number | `/devflow:refine` for a `feature` issue, otherwise `/devflow:orchestrate` |
| `claude-comment.yml` | `@claude` comment by an owner, member or collaborator | Small jobs such as resolving a merge conflict |
| `board-sync.yml` | PR and issue events | Moves board Status |

`claude.yml` uses `anthropics/claude-code-action@v1`, loading the plugin with
`plugin_marketplaces` and `plugins: devflow@claude-skills`. Settings that matter:

- **Secret:** `CLAUDE_CODE_OAUTH_TOKEN` (or `ANTHROPIC_API_KEY`) in repository secrets.
- **Foreground subagents:** `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS: "1"` and an appended
  system prompt saying the run ends when the agent stops.
- **Budgets:** `--max-turns` (100 for refine, 200 for orchestrate) and `timeout-minutes`
  (30 and 60).
- **Allow-list:** `--allowedTools` limited to what the skills need (`git`, the gate runner,
  `gh issue`, `gh pr`, `Edit`, `Write`, `Task`, `Skill`). Compound shell commands are
  denied by an allow-list, which costs turns.
- **Toolchain:** install the build toolchain before the agent step, and restore a build
  cache read-only.
- **Concurrency:** one run per issue.
- **Plugin version:** the action rejects a ref on `plugin_marketplaces`, so the runner
  follows the marketplace's default branch.
- **Chained runs:** labels applied with the default token start no workflow, so the refine
  job dispatches an orchestrate run per card it labeled.

Workflow file edits need a human merge.

## 7 Set up the cloud environment (optional)

Claude Code Projects threads do not load plugins from `.claude/settings.json`
([Runtimes](runtimes.md#cloud-threads)).

1. In the environment's setup script, install devflow at user scope and refresh it from
   the default branch:

   ```bash
   # Runs only when the environment snapshot is built. Bump the stamp to rebuild it.
   # devflow-stamp: <sha of main>
   if ! claude plugin list 2>/dev/null | grep -q 'devflow@claude-skills'; then
     claude plugin marketplace add WrackedFella/claude-skills --scope user
     claude plugin install devflow@claude-skills --scope user
   fi
   claude plugin marketplace update claude-skills || echo "devflow: marketplace refresh failed" >&2
   claude plugin update devflow@claude-skills --scope user || echo "devflow: update failed" >&2
   ```

2. Keep the toolchain out of the boot script; name an on-demand installer as the
   environment setup command in `CLAUDE.md` (Moho: `bash scripts/cloud-tools.sh`), so
   text-only threads start fast.
3. Link the repositories to the Project. The environment is a cached snapshot, so a merge
   to `main` reaches threads only after the script changes or the snapshot expires. When a
   session starts on an older plugin, devflow's `SessionStart` hook says so and names the
   SHA to put on the `devflow-stamp:` line; the change rebuilds the snapshot for new
   sessions.

## 8 Turn on acceptance tests and review (optional)

For a project with a UI or API to check end to end, such as a web app. Acceptance tests
pin a card's user-facing criteria as end-to-end tests in the gate; acceptance review adds
an agent that uses the running app before code review
([Orchestration](orchestration.md#31-acceptance-tests)). A project that sets none of
these settings is unaffected.

1. **Make the app bootable by script.** A start command that runs non-interactively,
   loads freshly seeded data, stubs third-party services (payment, email, identity) and
   returns once a health check passes, and a stop command. It needs no external secrets.
2. **Add the acceptance suite.** For example Playwright Test, with its config, a seed test
   for shared setup (sign-in, fixtures), and the conventions in `engineering-standards`
   (Acceptance tests): user-facing locators, no fixed sleeps, isolation, a fixed clock and
   viewport, and a fixture that fails on page errors.
3. **Add the settings to `CLAUDE.md`** ([project contract](project-contract.md)):

   ```markdown
   - **Acceptance command:** `npx playwright test`
   - **Acceptance test paths:**
     - `e2e/**`
     - `playwright.config.ts`
   - **App start command:** `just serve-test`
   - **App stop command:** `just serve-test-stop`
   - **App URL:** `http://localhost:5173`
   - **Acceptance review:** `agent`
   ```

   `Acceptance command` alone gives test plans and gated acceptance tests;
   `Acceptance review: agent` adds the reviewer step.
4. **Prepare the runners.** In `claude.yml` (step 6): install the browser
   (`npx playwright install --with-deps chromium`, cached) and `playwright-cli`; add the
   app start, acceptance and app stop commands, `playwright-cli` and
   `scripts/e2e-guard` to `--allowedTools`; upload `/tmp/devflow-acceptance/` and the
   runner's traces as a run artifact. In a cloud environment, check that the browser
   and `playwright-cli` install under its network policy
   ([Runtimes](runtimes.md#unattended-runs)).
5. **Plan a feature.** With the settings in place, `business-analyst`, `tech-lead` and
   `refine` write a feature test plan into the feature issue, a test plan in each card
   (test-map entries tagged `unit`, `api` or `e2e`), `Visual:` items for judgment
   visuals, and a final journey card for journeys that cross cards
   ([Planning](planning.md#32-test-plans)).
6. **Run a card.** Label it `agent-ready`, or run `/devflow:orchestrate <issue>`. Its PR
   carries the acceptance run, the guard result and, with review on, an Acceptance review
   section with verdicts and evidence. Cards with `Visual:` items always get
   `Sign-off: human` from `pr-review`.

Start with one card whose criteria are easy to see, and read its Acceptance review
section and evidence before trusting a pass.

## 9 First commands

| Goal | Command |
|---|---|
| Shape a feature | `/devflow:business-analyst <topic>` |
| Specify its cards | `/devflow:tech-lead <feature or card>` |
| Split an approved feature headlessly | label the feature issue `agent-ready`, or `/devflow:refine <issue>` |
| Implement one ready card | `/devflow:orchestrate <issue>` |
| Review an open PR | `/devflow:pr-review [pr]` (a verdict; approvals stay off until `PR approval: agent`) |
| Address PR review feedback | `/devflow:respond [pr]` |
| File drafts a cloud thread left | `/devflow:publish [card-id ...]` |
| Check where things stand | `/devflow:sitrep project` |

Try the flow on one small `glue` card first and read the PR it produces before
relaxing any review point.
