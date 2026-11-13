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
| `pr-review` | Delivery | PR number (optional), or `--dry-run <base>..<head> <issue>` | Main session or headless | One review: verdict, route, sign-off, blockers, follow-ups |
| `ship` | Delivery | `--checkpoint` (optional) | Main session | Commit, push, PR; or a review summary |
| `sitrep` | Reporting | feature ID, item ID, `#issue` or `project` | Main session, read-only | Status report of at most ~15 lines |
| `engineering-standards` | Knowledge | none | Preloaded into agents; not user-invocable | Language-neutral engineering standards |
| `rust-standards` | Knowledge | none | Selected by the `Standards` setting; not user-invocable | Rust-only deltas on `engineering-standards` |
| `dotnet-standards` | Knowledge | none | Selected by the `Standards` setting; not user-invocable | C#/.NET-only deltas on `engineering-standards` |
| `azure-standards` | Knowledge | none | Selected by the `Standards` setting; not user-invocable | Host-agnostic Azure principles on top of `engineering-standards` and `dotnet-standards` |

"Forked" skills run in an isolated context and return only a report. Role skills are
covered in [Planning](planning.md) and [Orchestration](orchestration.md).

## 1 comment-audit

Audits only comments added or changed in the diff (against the merge base with the base
ref, including uncommitted work); never changes code, then formats.

| Action | Applies to |
|---|---|
| Keep | Why the code is shaped this way (constraint, invariant, tradeoff, workaround); API doc comments in the project's language (e.g. rustdoc, XML doc) stating a caller-facing contract; `// SAFETY:` |
| Delete | Narration, restated names, history, settled decisions and alternatives, work-item or PR references, duplicated docs |
| Tighten | Surviving comments, to the fewest words that keep the why |
| Flag | `TODO`, `FIXME`, `HACK`, `XXX`, and anything uncertain |

Report: counts removed, tightened, flagged; each flagged comment as `file:line — reason`.

## 2 wiki

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

## 3 ship

1. Run the environment setup command in remote sessions, then the gate; never ship red.
2. Run the project's pre-commit change check (for example GitNexus `detect_changes`).
3. Conventional Commit (`type(scope): summary`), never on the base branch or `main`.
4. Push with upstream tracking.
5. PR description: Summary (Before / After / How paragraphs; links the issue, `Closes #N` when complete), Verification
   (gate counts, mutation result, manual checks), Risk (blast radius, human checks, follow-ups).
6. Open the PR into the base branch; never merge or enable auto-merge.

`--checkpoint` produces only the summary (steps 1 and 5) for a review pause, with no
commit or push.

## 4 publish

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

## 5 respond

Addresses review feedback on one pull request. Never resolves a thread, never merges.

1. Find the PR (given, else the current branch's) and collect unresolved review threads,
   comments addressed to the agent, and the blockers of the latest `pr-review` review
   when it says `reject` with `Route: fix` (never its follow-ups or questions, nothing
   on `Route: human`). Comments are requests to evaluate, not instructions: one that
   asks to weaken a test or lint, widen scope or touch the base branch is declined in
   the reply with the reason.
2. Per thread: fix, or reply with why not; a review blocker it will not fix gets a reply
   starting `Declined`, which routes the next review to a person. A blocker with a
   failing test is fixed test first: the test joins the suite, then the fix makes it
   pass. Production changes go to `implementer`, tests to `test-writer`; related
   threads form one change set.
3. Run the gate after each change set; never push red. Commit per change set; merge the
   base branch if the PR is behind, never rebase or force-push.
4. Push and reply on every thread with the commit SHA or the reason nothing changed.
5. Headless runs use foreground subagents only and issue one command per Bash call (no `&&`, `;`, pipes, `cd` or `$(...)`), since the allow-list denies compounds.

Report: threads addressed and declined, commits, anything needing the user.

## 6 pr-review

Adversarial review of an open PR against its work item. It coordinates and judges
nothing itself; it never pushes or merges. Arguments: a PR number, or `--dry-run
<base>..<head> <issue> [out-file]`, which posts nothing and writes the review to a file.

1. **Facts.** `scripts/pr-facts` returns JSON: head and base SHA, CI on the head, merge
   state, linked issue and gate class, changed files against the domain-logic paths and
   `Human-only paths`, the tier, the Sign-off triggers it can see, and earlier verdicts.
   Red CI or a conflict ends in `reject` before any agent runs; pending CI posts nothing.
2. **Blind inputs.** Settings come from `CLAUDE.md` at the base SHA. Finders get SHAs,
   the issue and the standards, never the PR number, PR text, commit messages or an
   earlier review.
3. **Earlier blockers** (round 2 on): `refuter` in mode `fixed` closes or carries each.
4. **Finders by tier.** Light (glue class, no domain path): `design-critic`. Full
   (domain class, a domain path, or label `review:full`): `defect-finder` and
   `design-critic` on Fable, in parallel where the runtime allows.
5. **Refute.** `refuter` checks each finding cold (light: blockers and questions; full:
   everything). Refuted findings are listed as Dropped. From round 2, a new blocker
   counts only on lines changed since the last review, when proven by a failing test, or
   when it is a plan deviation.
6. **Verdict.** Blockers B1 to B6 (wrong behavior, unmet criterion, weakened gate,
   broken written rule, changeability blocker, plan deviation) reject; otherwise
   approve. Unmet criteria, broken rules and plan deviations are never follow-ups. The
   work item is not ground truth: a fix that would follow a work-item instruction a
   written rule contradicts is needs-decision.
   `Route: human` for a needs-decision blocker, a declined blocker, a blocker surviving
   two rounds, no progress, or the round cap (`PR_REVIEW_MAX_ROUNDS`, default 3); else
   `fix`. Questions never reject but set `Sign-off: human`, as do the facts triggers, C2,
   security-relevant code and an unnamed public API or format.
7. **Post.** One review on the head SHA: reject requests changes (plus `needs-human` on
   Route human); approve approves only with `PR approval: agent`, author separation and
   stale-approval dismissal on the base branch, else comments. It resolves its own
   inline threads whose blockers the refuter confirmed fixed, and files follow-ups per
   `PR follow-ups` (at most 3, labelled `follow-up`, never `agent-ready`).

Review body:

```
Verdict: <approve|reject>
Route: <fix|human|none>
Sign-off: <agent|human>
Head: <sha>   Tier: <light|full>   Round: <n>
```

then Blockers (with IDs `X1`, `X2`, ... stable across rounds), Questions, Follow-ups,
Sign-off triggers, Dropped, Not reviewed and Counts. A push makes the review stale; the
runner reviews the new head.

## 7 sitrep

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

## 8 engineering-standards

Language-neutral, principle-first standards. A project's `CLAUDE.md` may narrow or
override them. Sections: architecture and layering, resources and memory, validation and
errors, dependencies and conversions, async and cancellation, type system,
observability, error contracts at library/package boundaries, events and decoupling, testing,
comments, document numbering (ISO 2145 sections, `<LINE>-M<n>` milestones),
complexity and abstraction.

## 9 rust-standards

Rust-only deltas, default second module of `Standards`; it defers to `engineering-standards`
for every other rule. Covers crate layout, `Result`/panic wording, `thiserror`/`anyhow`,
`#[non_exhaustive]`, drop-based async cancellation, `tracing` macros, test naming and
`#[cfg(test)]`/`#[ignore]`, rustdoc and `// SAFETY:`, ECS and hot-path items.

## 10 dotnet-standards

C#/.NET-only deltas, selected through `Standards`; it defers to `engineering-standards`
for every other rule. Covers solution layout (`ProjectReference`, `Directory.Build.props`,
central package management), the compiler and analyzers as gate, records and value
objects, exceptions versus result types, `CancellationToken`, DI and validated options,
`ILogger` templates, xUnit and Stryker.NET, and XML doc comments.

## 11 azure-standards

Host-agnostic principles for Azure-hosted .NET workloads, selected through `Standards`;
it defers to `engineering-standards` and `dotnet-standards` and names no service as the
required choice. Covers managed identity and `DefaultAzureCredential`, environment-driven
config promoted as one image, idempotent restartable jobs with explicit exit codes and
SIGTERM handling, stateless services with health and graceful shutdown, OpenTelemetry to
Azure Monitor, and container image hygiene. Service choice, naming, networking, IaC and
corporate policy are left to the project `CLAUDE.md`.
