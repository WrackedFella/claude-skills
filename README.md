# claude-skills

A Claude Code plugin marketplace. It currently ships one plugin, **devflow**: a
spec-driven, test-first workflow in which humans approve specs and merge, and
agents implement.

## Install

Per project (recommended, so every collaborator gets the same plugin), from the
project root:

```bash
claude plugin marketplace add WrackedFella/claude-skills --scope project
claude plugin install devflow@claude-skills --scope project
```

Commit the resulting `.claude/settings.json`. The marketplace tracks the default
branch and the plugin has no `version` field, so Claude Code versions it by commit and
every merge to `main` is an update. Set `"autoUpdate": true` on the marketplace entry to
pick updates up without running the commands below. To freeze a project, set `ref` on the
marketplace source to a commit.

A committed `enabledPlugins` entry turns the plugin on for collaborators but does not
download it; each collaborator runs `claude plugin install devflow@claude-skills --scope project`
once.

## Upgrading

A machine without `autoUpdate` pulls the latest `main` with:

```bash
claude plugin marketplace update claude-skills
claude plugin update devflow@claude-skills --scope project
```

Then restart the session.

### Cloud threads

Cloud sessions (Claude Code Projects) do not load plugins from a repository's
`.claude/settings.json`. Give each Project the plugin through its own settings or a
linked checkout of this repo, and refresh it from `main`.

## What's in devflow

Role skills: `business-analyst` (feature negotiation and acceptance criteria), `tech-lead` (tech spec, test map, ADRs), `refine` (unattended feature splitting) and `orchestrate` (one ready item to a PR). Delivery skills: `ship`, `publish` (file approved draft cards as issues), `respond` (address PR review feedback) and `pr-review` (independent PR review with a verdict). Support skills: `comment-audit`, `wiki`, `sitrep`, `engineering-standards`, `rust-standards`, `dotnet-standards` and `azure-standards`. Agents: `test-writer`, `implementer`, `test-critic` and `reviewer`. Details are in the [wiki](wiki/README.md), [skills](wiki/skills.md) and [agents](wiki/agents.md).

## Project contract

The plugin is project-agnostic: a project states its gate, mutation and base-branch settings, planning standards and review points in its `CLAUDE.md`, as described in the [project contract](wiki/project-contract.md). The optional GitHub Project board is described in [board](wiki/board.md).

## Releasing

A merged PR into `main` is the release. Do not add a `version` to `plugin.json` or the
marketplace entry: a set `version` pins every consumer to the cached copy until the string
changes, so commits stop reaching them.

## License

MIT; see [LICENSE](LICENSE).
