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

Role skills: `business-analyst` (feature negotiation and acceptance criteria), `tech-lead` (tech spec, test map, ADRs), `refine` (unattended feature splitting) and `orchestrate` (one ready item to a PR). Delivery skills: `ship`, `publish` (file approved draft cards as issues) and `respond` (address PR review feedback). Support skills: `comment-audit`, `wiki`, `sitrep` and `rust-standards`. Agents: `test-writer`, `implementer`, `test-critic` and `reviewer`. Details are in the [wiki](wiki/README.md), [skills](wiki/skills.md) and [agents](wiki/agents.md).

## Project contract

The plugin is project-agnostic: a project states its gate, mutation and base-branch settings, planning standards and review points in its `CLAUDE.md`, as described in the [project contract](wiki/project-contract.md). The optional GitHub Project board is described in [board](wiki/board.md).

## Releasing

1. Bump `version` in `plugins/devflow/.claude-plugin/plugin.json`.
2. PR into `main`; after merge, tag `v<version>` on `main`.
3. In each consumer: update the marketplace `ref` in `.claude/settings.json`, run the
   Upgrading commands, and update any Project that serves the plugin from a checkout.

## License

MIT; see [LICENSE](LICENSE).
