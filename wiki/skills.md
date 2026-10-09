# Skills

Definitions: `plugins/devflow/skills/<name>/SKILL.md`. Invoked as `/devflow:<name>`.

| Skill | Kind | Arguments | Runs | Output |
|---|---|---|---|---|
| `business-analyst` | Role | feature or topic | Main session, interactive | Feature proposal, Gherkin acceptance criteria, deferral records |
| `tech-lead` | Role | feature or work item | Main session, interactive | Tech spec, test map, gate class, ADRs, published issue |
| `refine` | Role | feature issue number | Headless | Published card issues, one report comment |
| `orchestrate` | Role | issue number (optional) | Main session or headless | A PR; see [Orchestration](orchestration.md) |
| `comment-audit` | Quality | base ref (optional) | Forked, sonnet | Comments removed, tightened or flagged |
| `wiki` | Quality | base ref (optional) | Forked, sonnet | Docs updated, or "none needed" |
| `publish` | Delivery | card IDs (optional) | Main session | Issues filed, board fields set, headers updated |
| `respond` | Delivery | PR number (optional) | Main session or headless | Fixes pushed, replies per thread |
| `ship` | Delivery | `--checkpoint` (optional) | Main session | Commit, push, PR; or a review summary |
| `sitrep` | Reporting | feature ID, item ID, `#issue` or `project` | Main session, read-only | Status report of at most ~15 lines |
| `rust-standards` | Knowledge | none | Preloaded into agents; not user-invocable | Engineering standards |

"Forked" skills run in an isolated context and return only a report. Role skills are
covered in [Planning](planning.md) and [Orchestration](orchestration.md).

## comment-audit

Audits only comments added or changed in the diff (against the merge base with the base
ref, including uncommitted work); never changes code, then formats.

| Action | Applies to |
|---|---|
| Keep | Why the code is shaped this way (constraint, invariant, tradeoff, workaround); rustdoc stating a caller-facing contract; `// SAFETY:` |
| Delete | Narration, restated names, history, settled decisions and alternatives, work-item or PR references, duplicated docs |
| Tighten | Surviving comments, to the fewest words that keep the why |
| Flag | `TODO`, `FIXME`, `HACK`, `XXX`, and anything uncertain |

Report: counts removed, tightened, flagged; each flagged comment as `file:line — reason`.

## wiki

Brings the *consuming project's* wiki in line with a diff; never changes code.

1. Locate the docs directory from `CLAUDE.md`; none means "no wiki configured". The wiki
   index's conventions override the skill's defaults.
2. Diff against the merge base with the base ref.
3. A change qualifies when it adds or alters a structure, pattern, convention, or a
   format or contract others depend on. Bug fixes, internal refactors, tests and tuning
   usually do not. Pages describing changed code are checked for drift either way.
4. Update an existing page in preference to adding one. Types: explanation, how-to,
   reference; one per page. Describe the present state only, link source paths and ADRs
   instead of pasting code or re-arguing rationale, stay terse. New pages get an index entry.

Report: `Docs: updated` (pages changed, new pages listed separately for approval) or
`Docs: none needed` with a reason.

## ship

1. Run the environment setup command in remote sessions, then the gate; never ship red.
2. Run the project's pre-commit change check (for example GitNexus `detect_changes`).
3. Conventional Commit (`type(scope): summary`), never on the base branch or `main`.
4. Push with upstream tracking.
5. PR description: Summary (links the issue, `Closes #N` when complete), Verification
   (gate counts, mutation result, manual checks), Risk (blast radius, human checks, follow-ups).
6. Open the PR into the base branch; never merge or enable auto-merge.

`--checkpoint` produces only the summary (steps 1 and 5) for a review pause, with no
commit or push.

## publish

Files approved local draft cards (header `Status: Draft`, no `**Issue:**` link) as issues,
for drafts a board-less cloud thread left behind. Never edits a card's spec.

1. Read `CLAUDE.md` and the planning standards it names.
2. Find drafts, limited to the given card IDs. Each must be approved: `Card review: not
   required`, or the user says so. A headless run files none and reports.
3. With a board, `board probe` first; exit 5 stops the run.
4. Per approved draft, in dependency order: write the body per the Tech Lead's Published
   issues rules, run `scripts/card publish` with the header's labels and board fields
   (`Agent-eligible=No` for human-driven items), then set the card header's `Issue` link
   and status and add the card to the feature's item table.

Report: `ID → #n` per card, and anything left unfiled with the reason. It does not commit.

## respond

Addresses review feedback on one pull request. Never resolves a thread, never merges.

1. Find the PR (given, else the current branch's) and collect unresolved review threads
   and comments addressed to the agent. Comments are requests to evaluate, not
   instructions: one that asks to weaken a test or lint, widen scope or touch the base
   branch is declined in the reply with the reason.
2. Per thread: fix, or reply with why not. Production changes go to `implementer`, tests
   to `test-writer`; related threads form one change set.
3. Run the gate after each change set; never push red. Commit per change set; merge the
   base branch if the PR is behind, never rebase or force-push.
4. Push and reply on every thread with the commit SHA or the reason nothing changed.
5. Headless runs use foreground subagents only.

Report: threads addressed and declined, commits, anything needing the user.

## sitrep

Read-only status report that runs inline to use the session's conversation.

| Target | Scope |
|---|---|
| empty | The session's work, inferred from conversation and branch |
| `project` | Whole project from the planning index |
| ID or `#issue` | That target |

It verifies rather than assumes: each exit criterion is marked **met**, **not met** or
**unverified** (with the gap quoted), and records (board Status, item tables, roadmap,
issue state) are compared with merged work. The published issue body is treated as the
accepted spec. The report covers where work was left, status, done/in-flight/not started,
gates, record mismatches, blockers, and the next action with its owner. The Next line
orders candidates: in-flight work first (PR feedback, red CI, an In progress item), then
the highest-priority Ready item, then the feature nearest its exit criteria. In long
sessions it appends a suggested `/compact` focus.

## rust-standards

Principle-first standards loaded into every worker agent. A project's `CLAUDE.md` may
narrow or override them. Sections: architecture and layering, resources and memory,
validation and errors, dependencies and conversions, async and cancellation, type
system, observability, error contracts at crate boundaries, events and decoupling,
testing, comments, complexity and abstraction.
