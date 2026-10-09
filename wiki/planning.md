# Planning

Planning turns an approved feature into published, agent-ready work items (cards).
It follows the planning standards the consuming project names in its `CLAUDE.md`
(file locations, ID format, card template, statuses).

## Features and cards

- A **feature** is the smallest deliverable that moves toward the end state and works
  end to end. It carries the end state, exit criteria, scope, decisions, deferred scope
  and an item table. Approval publishes it as a parent issue labeled `feature`.
- A **card** is one vertical slice named after the behavior it delivers, sized to one
  reviewable PR. Its body holds acceptance criteria and a tech spec.
- Features come first: cards are not cut until the feature is approved.

## Business Analyst (`/devflow:business-analyst`)

Owns what and why; never names packages, modules, types, algorithms or paths.

1. **Understand the end state.** Reads vision, design and roadmap; states the long-term
   goal and where the feature fits. Walks concrete use cases and asks direction-setting
   questions first (forks that are expensive to reverse), one at a time, with a
   proposed default and what each answer costs or rules out.
2. **Negotiate the increment.** Proposes the smallest cut and defends it; every
   addition must be argued in. Prefers a walking skeleton to finishing one layer.
   Creep (polish, configurability, speculative generality) is named and deferred; every
   deferral is recorded with a reason. The user's call is final once the cost is stated.
3. **Write it down.** Gherkin (`Scenario`, `Given/When/Then`, `Scenario Outline`) for
   observable behavior; checklists for refactors and upgrades; unassertable qualities
   become manual verification steps. Hands the Tech Lead the decisions taken and left open.

## Tech Lead (`/devflow:tech-lead`)

Owns how. Applies `CLAUDE.md`, the skills in the project's `Standards` setting, existing ADRs and domain practice.
Drafts left by a thread without board access are filed later with `/devflow:publish`.

- **Scope check first.** Challenges size against cost; designs for the next increment,
  keeping deferred options open with a cheap seam rather than machinery; splits items
  larger than one PR; routes cuts back to the BA with the cost stated.
- **Slicing by footprint.** Slice boundaries follow files and modules so slices of one
  feature have disjoint footprints. Disjoint cards run as parallel runs; cards that share
  a file run in sequence, the later one listing the earlier as a dependency. A file every
  slice needs (registry, prelude, manifest) goes in the first slice or its own.
- **Tech spec** per card:

  | Section | Content |
  |---|---|
  | Design | Modules and public interfaces touched, data flow, why this approach |
  | Footprint | Files and modules the implementation edits, tests included, one line each. Where the test map splits into groups with non-overlapping footprints, the groups are **parts** (`A`, `B`, …) and each test-map entry is tagged with its part. Overlap in one file means one part |
  | Out of scope | Concrete tempting changes the implementer must not make |
  | Test map | Each scenario → (example name: `module::tests::scenario_expected_result`), plus implied edge cases |
  | Gate class | `domain` (rules in the project's domain-logic paths; test review applies) or `glue` |
  | Risks | Blast radius, performance, migration or save-format concerns |

- **Verification before approval.** Load-bearing claims (trait bounds, API existence,
  `Send`/`Sync`, that kept code still has callers, what a gate script actually reads)
  are checked against source, not assumed. The report carries a **Checked** list; it
  stays out of the card, where file references would rot.
- **ADRs** record decisions that constrain future work: decision and consequences, not
  deliberation.

### Hand-off to the queue

1. Create the work branch from the base branch and commit the spec there.
2. Publish the card with [`scripts/card publish`](board.md#pluginsdevflowscriptscard): it files the issue,
   links it as a sub-issue of the feature and, with a board, sets `Status=Ready`,
   `Gate class` and `Agent-eligible`. Without a board, the card's status line and labels
   are the record.
4. Report the issue number and branch. Next step: `/devflow:orchestrate`.

## Published issues

The issue is the accepted spec; local files are drafts until published and working
copies afterward.

- The body is the whole spec, readable alone: no header lines, no template comments,
  no repository paths. Other work is referenced as `#N` with its ID and a few words.
- Editing a filed spec means editing the issue body in the same step as the card. From
  `Ready` on, also comment what changed and why.

## Headless refinement (`/devflow:refine`)

One approved `feature` issue in, published card issues out, with no conversation. Reads
the BA and Tech Lead skills and applies their rules, escalating where they would ask.

- **Writes only issues.** No branches, files, ADRs or PRs; never touches the board.
- **Decomposes the uncovered.** Slice boundaries follow files and modules, so cards have
  disjoint footprints where the behavior allows; cards that must share a file are ordered by dependency. Existing sub-issues are treated as done or in flight
  and are never edited; only uncovered exit criteria are cut. More than eight new cards
  means the feature is too big: it comments a proposed split and stops.
- **Escalates instead of guessing.** Unanswered direction-setting questions, criteria
  that conflict with an ADR, or untestable criteria produce one comment (questions,
  proposed defaults, costs) and a stop. Independent cards may still publish.
- **Publishes** each card with `scripts/card publish` as `[<ID>] <title>`, labeled with the
  feature's line and linked as a sub-issue, then adds them to the feature's item table.
- **Labels** follow `Card review`: `required` applies no label (the user approves by
  applying `agent-ready`); `not required` labels cards the orchestrator can finish
  unattended (gate class `glue`, or `domain` with `Domain-test review` not `required`).
- **Reports** once on the feature: cards created, which can run in parallel (disjoint footprints) and which wait on another, deferrals, open questions, labels, and
  a **Checked** section.

## Trigger convention

`agent-ready` is the single label that starts unattended work; a runner routes a
`feature` issue to `refine` and anything else to `orchestrate`. The runner is the
consumer's (for example a GitHub Actions workflow); devflow defines only the skills.
