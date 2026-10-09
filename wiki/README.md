# devflow wiki

How the **devflow** plugin (`plugins/devflow/`) works. Audience: developers who know
agentic workflows and want the mechanics, contracts and reasons. Installation and
release steps are in the [root README](../README.md). Describes devflow 0.17.0.

| Page | Type | Covers |
|---|---|---|
| [Getting started](getting-started.md) | How-to | Install, project contract, gates, board, Actions, cloud environment, first commands |
| [Overview](overview.md) | Explanation | Principles, roles, the end-to-end flow, where humans stay in the loop |
| [Planning](planning.md) | Explanation | Business Analyst, Tech Lead, `refine`, cards, published issues |
| [Orchestration](orchestration.md) | Explanation | The `orchestrate` pipeline step by step, delegation, headless behavior |
| [Coordination](coordination.md) | Explanation | Lanes, one thread per card, shared-file ownership |
| [Runtimes](runtimes.md) | Explanation | Local, cloud thread, Actions; plugin delivery; unattended triggers |
| [Agents](agents.md) | Reference | The four worker agents: contract, model, tools |
| [Skills](skills.md) | Reference | Every skill: kind, trigger, arguments, output |
| [Project contract](project-contract.md) | Reference | What a consuming project's `CLAUDE.md` must state |
| [Board](board.md) | Reference | Project board fields and the `board` script |

## Conventions

- Pages describe the current plugin; no history, changelogs or session references.
- One page, one type (how-to, explanation or reference).
- Skill and agent behavior is defined by the files under `plugins/devflow/`; when a
  page and a file disagree, the file wins and the page is a bug.
- `/devflow:wiki` is the skill that keeps a *consuming project's* wiki current. This
  wiki documents the plugin itself and is edited by hand.
- Moho (the project devflow was built in) appears only as an example.
