# Overview

devflow is a spec-driven, test-first workflow in which humans approve specs and merge,
and agents implement behind deterministic gates. It is project-agnostic: everything
project-specific lives in the consumer's `CLAUDE.md` ([project contract](project-contract.md)).

## Principles

| Principle | Mechanism |
|---|---|
| Humans decide and merge | Agents never merge, enable auto-merge, or push to the base branch. Feature approval and merge are always human. |
| The spec is the issue | The published GitHub issue is the accepted spec; local files are drafts or working copies. The issue wins on disagreement. |
| Tests before code | `test-writer` produces failing tests first; `implementer` sees them as the definition of done. |
| Gates are not negotiable | No agent edits, skips or weakens a test or lint to get green. The project gate runs after every change set. |
| Independent judgment | Test review and final review run in fresh context (`test-critic`, `reviewer`) and never see the author's reasoning. |
| Cheapest capable model | Haiku for mechanical work, Sonnet for spec-driven work, Opus for judgment and review. |
| Review points are switches | Each human pause is a setting in `CLAUDE.md`, so a project can move toward unattended runs one switch at a time. |

## Roles

| Role | Entry point | Owns |
|---|---|---|
| Business Analyst | `/devflow:business-analyst` | What and why: narrow scope, Gherkin acceptance criteria |
| Tech Lead | `/devflow:tech-lead` | How: tech spec, test map, gate class, ADRs |
| Refiner | `/devflow:refine` | Both of the above, headless, for one approved feature |
| Orchestrator | `/devflow:orchestrate` | Driving one ready work item to a PR |
| Workers | `devflow:*` agents | Bounded tasks delegated by the orchestrator; implementation may fan out to one `implementer` per disjoint part |

Role skills run in the main session and change its behavior for the rest of it. Worker
agents run in their own context and return a report.

## Flow

```
feature (human approves)
   │
   ▼
Business Analyst ──► cards: Gherkin acceptance criteria
   │
Tech Lead ────────► tech spec: design, out of scope, test map, gate class
   │                (refine does both headlessly)
   ▼
published issue  [Ready, Agent-eligible]  ◄── card review (switch)
   │
   ▼
Orchestrator
   1 intake and claim
   2 failing tests ──► domain-test review (switch: human | test-critic | none)
   3 implementation (one implementer, or one per disjoint part, then merge + gate)
   4 adversarial challenges as tests (≤2 rounds)
   5 refactor under green + /simplify
   6 mutation testing
   7 comment audit
   8 wiki
   9 full-platform CI (if platform-sensitive)
  10 independent review (≤2 rounds)
  11 ship ──► PR into base branch
   │
   ▼
human review and merge
```

Planning detail: [Planning](planning.md). Pipeline detail: [Orchestration](orchestration.md).

## Human review points

| Point | Setting | Values | Effect when relaxed |
|---|---|---|---|
| Feature approval | none | always human | n/a |
| Card review | `Card review` | `required` (default), `not required` | BA and Tech Lead publish cards themselves; `refine` labels eligible cards `agent-ready` |
| Domain-test review | `Domain-test review` | `required` (default), `agent`, `not required` | `agent`: `test-critic` reviews tests, no pause. `not required`: continue and flag the tests in the PR |
| PR merge | none | always human | n/a |

Items with gate class `glue` never pause for test review.

## Unattended runs

The same skills run in an interactive session, a cloud thread or CI. Rules that apply
when no person is attached:

- Subagents run in the foreground; the run ends when the orchestrator stops, and a
  background subagent would die with it.
- Questions become issue comments followed by a stop (`refine`, intake failures).
- Work is pushed after every commit so a fresh clone can resume.
- An unreachable project board is skipped, not worked around ([Board](board.md#unreachable-board)).
