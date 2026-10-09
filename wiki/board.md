# Board

A GitHub Project (v2) board is optional. When the project's `CLAUDE.md` names one, its
**Status** field is the record of item state and replaces card status and the
`agent-ready` label as the pickup mechanism.

## Fields

Single-select fields; names must match exactly.

| Field | Options | Set by |
|---|---|---|
| Status | Backlog, Needs spec, Ready, In progress, In review, Done | Tech Lead (`Ready`), orchestrator (`In progress`, `In review`), project automation |
| Priority | P0, P1, … (sorted by name; lower is more urgent) | human |
| Gate class | `domain`, `glue` | Tech Lead |
| Agent-eligible | Yes, No | Tech Lead on request; `No` when the user drives the item personally |

## Queue

The orchestrator's queue is open issues with Status `Ready`, Agent-eligible `Yes` and no
open blocking issues, ordered by Priority (missing sorts last). It claims an item by
moving it to `In progress`; an item already `In progress` belongs to another session.

## `plugins/devflow/scripts/board`

Resolves field and option names to the API's opaque IDs so skills never handle them.
Requires `gh` with the `project` scope (`gh auth refresh -s project`).

| Command | Effect |
|---|---|
| `board set <owner> <number> <issue-url> Field=Option …` | Sets fields; adds the issue to the board if absent |
| `board get <owner> <number> <issue-url>` | Read-only; reads at most 1000 items |
| `board next <owner> <number>` | Prints the URL of the queue head |
| `board probe <owner> <number>` | Read-only reachability check |

Exit codes: `1` error, `3` empty queue (`next`), `4` issue not on the board (`get`),
`5` board unreachable (any subcommand). Owners may be users or organizations.

## `plugins/devflow/scripts/card`

```
card publish <feature-issue-number> <title> <body-file> [--label <name>]... [--board <owner> <number> <Field>=<Option>...]
```

Creates the issue, links it as a sub-issue of the feature, optionally sets board fields,
and prints `#<n> <url>`. Exit `5` means the board part was unreachable: the issue is
still filed and linked, and only its board fields are missing.

## Unreachable board

Some environments (cloud threads, runners with a default app token) cannot use GraphQL
or Projects. Skills detect it by `board` exit 5 (`board probe` checks before the first
publish). When it happens:

- The orchestrator skips every board read and write and states in the PR body which
  Status changes were left to the environment (for example an Action reacting to PR
  and label events).
- The Tech Lead does not file an issue, since one without Status, Gate class and
  Agent-eligible is half-published. The card stays a local draft (`Status: Draft`,
  intended gate class and labels, full spec) for a full-access session to file with `/devflow:publish`.
- `refine` is unaffected: it never touches the board.
