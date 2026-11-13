# Project contract

devflow reads its project-specific settings from the consuming repository's `CLAUDE.md`
and the planning standards it names. Unset optional items disable the step that needs them.

| Setting | Required | Used by | Example |
|---|---|---|---|
| Gate command | yes | orchestrate, ship, agents | `just check` |
| Mutation command | yes | orchestrate step 6 | `just mutants` |
| Base branch | yes | branches, PRs, diffs | `dev` |
| Planning index and standards | yes | BA, Tech Lead, refine | where features and cards live; ID format; templates; statuses |
| Domain-logic paths | yes | gate class, `pr-review` tier | crates holding game rules; matching items are `domain`, the rest `glue`. `scripts/pr-facts` reads the backticked globs of the nested list under the line naming the setting (`**` and `*` match across directories) |
| Full-platform CI command | no | orchestrate step 9 | `gh workflow run CI --ref <branch>` |
| Docs directory | no | `wiki`, `reviewer` | `wiki/`; without it the docs step is skipped |
| Environment setup command | no | orchestrate, ship | `bash scripts/cloud-tools.sh`; run only when `CLAUDE_CODE_REMOTE=true` |
| `Tracker` | no | every skill and agent that touches work items or PRs | `github` (default) or `azure-devops`; selects the column of the [operations table](#operations) |
| Project board | no | board script, orchestrate, tech-lead | owner and project number; none declared = no board, and every board step is skipped |
| `Board header` | no | tech-lead, refine, publish | `yes`: the project's automation applies a `<!-- board: gate=<class>; eligible=<yes\|no>; priority=<P?> -->` comment at the top of an issue body to the board (`priority` optional). Skills write it and, when the board is unreachable, still file the issue; unset = no header, board fields are set with `scripts/board` |
| `Card review` | no | BA, Tech Lead, refine, publish | `required` (default) or `not required`: `not required` also lets skills apply `agent-ready` to cards that pass the [promotion checks](planning.md#6-promotion) |
| `Domain-test review` | no | orchestrate, pr-review | `required` (default), `agent` or `not required` |
| `PR approval` | no | pr-review | `off` (default) or `agent`: `agent` lets a verdict of `approve` with `Sign-off: agent` be submitted as a forge approval; `off` posts it as a comment. A `reject` requests changes under either value |
| `PR follow-ups` | no | pr-review | `comment` (default): follow-ups are listed in the review; `issue`: also filed (at most 3 per review, label `follow-up`, never `agent-ready`); `off`: omitted |
| `Human-only paths` | no | pr-review | globs, in the same format as the domain-logic paths, whose changes always set `Sign-off: human`, on top of the built-in triggers |
| `Standards` | no | orchestrate, respond, pr-review, tech-lead, refine, BA, sitrep | ordered devflow skill names, e.g. `engineering-standards, dotnet-standards, azure-standards`; each resolves to `${CLAUDE_PLUGIN_ROOT}/skills/<name>/SKILL.md` (devflow skills only), and workers receive only the paths in their brief; unset = `engineering-standards, rust-standards` |
| Pre-commit change check | no | ship, agents | GitNexus `detect_changes` |
| `PR_REVIEW_MAX_ROUNDS` (repository variable, not `CLAUDE.md`) | no | pr-review | fix rounds before a reject routes to a person; default 3 |

Review-point semantics are in [Overview](overview.md#human-review-points).

## Operations

The operations skills perform on work items and PRs (read work item, edit body, comment on
work item, add label, create child work item, list children, set state, open PR, read PR, read review threads, reply
to thread, read PR review context, submit review, resolve review thread, label PR, find open
issues, file follow-up) are defined once, per tracker, in
[`plugins/devflow/operations.md`](../plugins/devflow/operations.md). Skills name the
operation; the `Tracker` column supplies the command. `scripts/board` and `scripts/card`
stay GitHub-only. A project that declares no board skips every board step. `Tracker` is `github` or `azure-devops`; the Azure DevOps column is Unverified.

## Planning standards the plugin assumes

- Features are planned before cards; cards have stable IDs of the form
  `<LINE>-F<n>-<NN>`. Milestones are `<LINE>-M<n>` and document sections follow the
  numbering rules in `engineering-standards`.
- A card has acceptance criteria and a tech spec (design, out of scope, test map, gate
  class, risks). Issue titles are `[<ID>] <title>`.
- A published issue's body is the complete spec. Finished items' local files are
  removed per the standards.
- Feature integration branches, where the project uses them, are declared in
  `CLAUDE.md`; card PRs into such a branch do not auto-close issues.

## Labels

| Label | Meaning |
|---|---|
| `feature` | Parent issue; `refine` accepts only this |
| `agent-ready` | Starts an unattended run (routed by issue type); with `Card review: required`, applied by the user to approve a card |
| line label (for example `strategy`) | Copied from the feature onto its cards |
| `follow-up` | Filed by `pr-review` from a confirmed non-blocking finding; a backlog observation, never `agent-ready` |
| `needs-human` | Set by `pr-review` on a PR whose reject is routed to a person |
| `review:full` | On a PR, forces the full review tier |

## Cloud environments

Cloud threads do not load plugins from a repository's `.claude/settings.json`. The
plugin must be provided through the environment's own plugin settings or a linked
checkout of this repository, kept current with `main`.
Threads that only edit text skip the environment setup command.
