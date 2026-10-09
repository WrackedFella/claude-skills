# Coordination

Rules for running several agents at once without them talking to each other. Each
kind of information has one home, so lanes never need a side channel.

## Lanes

A lane is a long-lived workstream with its own context, such as one per product line or
component (for example engine, strategy game, FPS), plus an optional lane for cheap
work against a written spec. In Claude Code Projects a lane is a project; its threads
hold design discussion, planning and implementation.

| Layer | Holds | Written by |
|---|---|---|
| Lane projects | Design discussion, planning and implementation threads | Humans and the lane's coordinator; decisions leave as cards, ADRs or hand-off blocks |
| Issues | Specs (body), deviations and decisions (comments) | Planning threads file them; any thread edits the body when scope changes and comments on deviations |
| Planning drafts, ADRs, roadmap | Unapproved drafts, decisions, order of work | Planning sessions |
| Wiki | Documentation (source of truth) | Orchestrator through `/devflow:wiki`, planning sessions |
| Project board | State and priority | Automation (Status); humans (Ready, Agent-eligible, priority) |
| Session transcripts | Nothing durable | none |

## Rules

- **One thread per card.** A cloud thread has its own branch and its own copy of the
  repo, so it sees only what is committed. Hand-offs travel through issues and the
  board, not project files. Independent cards may run in parallel; cards that depend on
  each other or share files run in sequence or on a feature integration branch.
- **Parallelism is bounded by review.** Add threads only while the review queue stays
  short; human review is the bottleneck, not agents.
- **Approval precedes implementation.** Planning threads leave cards as drafts for
  review (unless `Card review` is `not required`); on approval the thread files the
  issue with `gh` and deletes the draft. Where a thread must also set board fields it
  cannot reach, the Tech Lead skill keeps the draft instead ([Board](board.md#unreachable-board)). An implementation thread starts only for a published card.
- **Cross-lane needs go through a request,** not a shared edit. The requesting lane
  files an issue; the owning lane designs the answer. Dependency direction is enforced
  by a layering check in the gate, not by convention.
- **Shared files belong to planning.** Roadmap, planning index, `CLAUDE.md`, workspace
  manifests and layering config are edited only by planning sessions. An implementation
  PR edits code and docs, and records deviations in an issue comment and scope changes
  in the issue body.
- **Broad moves are announced and kept short.** A change spanning many files across
  lanes pauses the affected lanes, lands on a short-lived integration branch, and lanes
  rebase afterwards.
- **Lane context loads by directory.** A short `CLAUDE.md` at a lane's root points at
  its design doc and constraints, so an agent working there picks it up unprompted.
- **After a batch of merges:** `/devflow:sitrep project`, then update lane project
  instructions if a lane's rules changed. Issues and the board are already current, so
  there is no sync step.

## Work items agents can implement

Agents implement exactly what the card says, so vague cards produce vague code.

- Name the observable outcome, not the component.
- Give every acceptance scenario an observable or assertable `Then`.
- State what is out of scope.
- Put anything checkable only by hand under Verification.
