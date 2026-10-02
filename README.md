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

## What's in devflow

| Kind | Name | Use |
|---|---|---|
| Role skill | `/devflow:business-analyst` | Plan features and write behavioral requirements (Gherkin acceptance criteria) |
| Role skill | `/devflow:tech-lead` | Turn requirements into a tech spec: design, test map, ADRs |
| Role skill | `/devflow:orchestrate <issue>` | Drive implementation of one ready work item through the gates to a PR |
| Agent | `devflow:test-writer` | Writes failing tests from acceptance criteria only |
| Agent | `devflow:implementer` | Writes the minimum code to pass the tests |
| Agent | `devflow:reviewer` | Fresh-context review of a diff against its spec |
| Skill | `/devflow:comment-audit` | Removes comments that don't earn their place from a diff |
| Skill | `/devflow:ship` | Gate, commit, push and open a PR with evidence |
| Skill | `/devflow:sitrep` | Short status report on a feature or issue (draft) |
| Knowledge | `devflow:rust-standards` | Engineering standards, loaded when writing or reviewing Rust |

## Project contract

The plugin is project-agnostic. A project using it states in its `CLAUDE.md`:

- **Gate command** that must pass before any commit (for example `just check`).
- **Mutation command** for changed code (for example `just mutants`).
- **Planning index and standards** (where features and work items live, ID format).
- **Base branch** that agent branches start from and PRs target.
- **Domain-logic paths** whose tests need human review before implementation.

## License

MIT; see [LICENSE](LICENSE).
