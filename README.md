# claude-skills

A Claude Code plugin marketplace. It currently ships one plugin, **devflow**: a
spec-driven, test-first workflow in which humans approve specs and merge, and
agents implement.

## Install

Per project (recommended, so every collaborator and CI run gets the same pinned
version), from the project root:

```bash
claude plugin marketplace add WrackedFella/claude-skills --scope project
claude plugin install devflow@claude-skills --scope project
```

Commit the resulting `.claude/settings.json`. Pin the marketplace to a tag or
commit so a standards change never silently changes agent behavior.

A committed `enabledPlugins` entry turns the plugin on for collaborators but does not
download it; each collaborator runs `claude plugin install devflow@claude-skills --scope project`
once.

## Upgrading

After the project's pinned ref changes, each machine that already has the plugin runs
(a first-time machine uses Install instead):

```bash
claude plugin marketplace add "<owner>/claude-skills#<tag>" --scope project
claude plugin update devflow@claude-skills --scope project
```

Then restart the session. The first command may rewrite `.claude/settings.json` with
only a key-order change; revert that rewrite.

### Cloud threads

Cloud sessions (Claude Code Projects) do not load plugins from a repository's
`.claude/settings.json`. Give each Project the plugin through its own settings or a
linked checkout of this repo, and keep that in step with the consumer's pin.

## What's in devflow

| Kind | Name | Use |
|---|---|---|
| Role skill | `/devflow:business-analyst` | Negotiate features down to a minimal increment and write behavioral requirements (Gherkin acceptance criteria) |
| Role skill | `/devflow:tech-lead` | Turn requirements into a tech spec: design, test map, ADRs |
| Role skill | `/devflow:refine [feature-issue]` | Unattended refinement: split an approved feature into work-item issues with the BA's and Tech Lead's rules, escalating open questions as a comment instead of asking |
| Role skill | `/devflow:orchestrate [issue]` | Drive one ready work item red-green-refactor through the gates to a PR; with no issue, take the board's queue head |
| Agent | `devflow:test-writer` | Writes failing tests from acceptance criteria only |
| Agent | `devflow:implementer` | Writes the minimum code to pass the tests, then refactors under green |
| Agent | `devflow:reviewer` | Fresh-context review of a diff against its spec |
| Skill | `/devflow:comment-audit` | Removes comments that don't earn their place from a diff |
| Skill | `/devflow:wiki` | Updates onboarding docs where a diff adds or alters a structure, pattern or convention; otherwise reports why none is needed |
| Skill | `/devflow:ship` | Gate, commit, push and open a PR with evidence |
| Skill | `/devflow:sitrep` | Short status report on a feature or issue, checking each exit criterion and record (draft) |
| Knowledge | `devflow:rust-standards` | Engineering standards, loaded when writing or reviewing Rust |

## Project contract

The plugin is project-agnostic. A project using it states in its `CLAUDE.md`:

- **Gate command** that must pass before any commit (for example `just check`).
- **Mutation command** for changed code (for example `just mutants`).
- **Full-platform CI command**, if PR CI covers fewer targets than release (for example
  `gh workflow run CI --ref <branch>`).
- **Planning index and standards** (where features and work items live, ID format).
- **Base branch** that agent branches start from and PRs target.
- **Docs directory** (optional): the wiki the orchestrator keeps current through
  `/devflow:wiki`. Its index page states sections and conventions. Without one, the
  docs step is skipped.
- **Environment setup command** (optional): what a cloud thread runs before it builds or
  tests when the environment image lacks the toolchain (for example
  `bash scripts/cloud-tools.sh`). Threads that only edit text skip it. The orchestrator
  reads it like the gate command.
- **Domain-logic paths:** items whose rules live there get gate class `domain`.
- **Human review points** (optional; each defaults to `required`):
  - `Card review`: the user approves each card's local draft (acceptance criteria and
    tech spec) before it is published. When `not required`, the Business Analyst and
    Tech Lead publish cards themselves and escalate only open questions. `/devflow:refine`
    also applies `agent-ready` to published cards the orchestrator can finish unattended.
  - `Domain-test review`: the orchestrator pauses on `domain` items for the user to
    review the failing tests. When `not required`, it continues and flags those tests
    in the PR.

  Approving a feature and merging a PR are always the user's.
- **Project board** (optional): the GitHub Project's owner and number. When set, its
  Status field replaces card status as the record of item state.

### Project board

A board needs these single-select fields; names must match exactly:

| Field | Options |
|---|---|
| Status | Backlog, Needs spec, Ready, In progress, In review, Done |
| Priority | P0, P1, … (sorted by name; lower is more urgent) |
| Gate class | domain, glue |
| Agent-eligible | Yes, No |

Skills change fields only through `plugins/devflow/scripts/board`, which resolves names
to the API's IDs. `gh` needs the `project` scope (`gh auth refresh -s project`). The
orchestrator's queue is open issues with Status Ready and Agent-eligible Yes and no open
blocking issues, highest Priority first; it claims an item by moving it to In progress.

## Releasing

1. Bump `version` in `plugins/devflow/.claude-plugin/plugin.json`.
2. PR into `main`; after merge, tag `v<version>` on `main`.
3. In each consumer: update the marketplace `ref` in `.claude/settings.json`, run the
   Upgrading commands, and update any Project that serves the plugin from a checkout.

## License

MIT; see [LICENSE](LICENSE).
