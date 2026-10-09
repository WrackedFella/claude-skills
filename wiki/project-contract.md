# Project contract

devflow reads its project-specific settings from the consuming repository's `CLAUDE.md`
and the planning standards it names. Unset optional items disable the step that needs them.

| Setting | Required | Used by | Example |
|---|---|---|---|
| Gate command | yes | orchestrate, ship, agents | `just check` |
| Mutation command | yes | orchestrate step 6 | `just mutants` |
| Base branch | yes | branches, PRs, diffs | `dev` |
| Planning index and standards | yes | BA, Tech Lead, refine | where features and cards live; ID format; templates; statuses |
| Domain-logic paths | yes | gate class | crates holding game rules; matching items are `domain`, the rest `glue` |
| Full-platform CI command | no | orchestrate step 9 | `gh workflow run CI --ref <branch>` |
| Docs directory | no | `wiki`, `reviewer` | `wiki/`; without it the docs step is skipped |
| Environment setup command | no | orchestrate, ship | `bash scripts/cloud-tools.sh`; run only when `CLAUDE_CODE_REMOTE=true` |
| Project board | no | board script, orchestrate, tech-lead | owner and project number |
| `Card review` | no | BA, Tech Lead, refine | `required` (default) or `not required` |
| `Domain-test review` | no | orchestrate | `required` (default), `agent` or `not required` |
| Pre-commit change check | no | ship, agents | GitNexus `detect_changes` |

Review-point semantics are in [Overview](overview.md#human-review-points).

## Planning standards the plugin assumes

- Features are planned before cards; cards have stable IDs of the form
  `<LINE>-F<n>-<NN>`.
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

## Cloud environments

Cloud threads do not load plugins from a repository's `.claude/settings.json`. The
plugin must be provided through the environment's own plugin settings or a linked
checkout of this repository, kept at the same version as the consumer's pin.
Threads that only edit text skip the environment setup command.
