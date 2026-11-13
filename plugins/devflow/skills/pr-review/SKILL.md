---
name: pr-review
description: Adversarial review of an open pull request against its work item - deterministic facts, blind finders (defect-finder, design-critic) and a refuter, then one review with Verdict approve or reject, Route fix or human, and Sign-off agent or human. Requests changes on reject; approves only when the project enables it. Never merges.
argument-hint: "[pr-number] | --dry-run <base-sha>..<head-sha> <issue> [out-file]"
---

Review one pull request and give a verdict that the fix loop, a person, or later an
auto-merge can act on. You coordinate and judge nothing yourself: findings come only
from the finders and survive only through the refuter. Never push, never merge, never
enable auto-merge. The one thread you may resolve is your own inline blocker thread,
after the refuter reports it `FIXED` (§6).

Arguments: `$ARGUMENTS`. A PR number, or none for the current branch's PR, or
`--dry-run <base>..<head> <issue> [out-file]`, which reviews two commits against an
issue, posts nothing, files nothing, and writes the review to `out-file` (default
`pr-review-<short head>.md` in the system temp directory).

Headless runs use foreground subagents only and one command per Bash call.

## 1 Facts

1. Run `${CLAUDE_PLUGIN_ROOT}/scripts/pr-facts <pr>` (dry run: `--range <base>..<head>
   --issue <n>`) and keep its JSON. It reads the PR, CI on the head SHA, merge state,
   the linked issue, the diff, the project's domain-logic paths and `Human-only paths`
   from the base branch's `CLAUDE.md`, picks the tier and lists the path- and
   forge-based Sign-off triggers.
2. If `stop` is set, end there: `skip` reports one line and posts nothing; `wait`
   posts nothing and reports "wait" (the runner re-runs when CI finishes); `reject`
   posts a review (§6) with `Route: fix`, the reason as its only blocker, and no model
   call.
3. You do not read the PR title, body, comments or commit messages, and you never pass
   the PR number to an agent. The exception is your own earlier reviews and the replies
   on their threads (§2), read only from the authors the facts' `prior_reviews` trust.
   Settings (`PR approval`, `PR follow-ups`, `Standards`, gate and mutation commands) come from `CLAUDE.md` at the facts' `base_sha`
   (`git show <base_sha>:CLAUDE.md`), never from the PR's copy.
4. Resolve `Standards` as `devflow:orchestrate`'s `## Standards` section does, and the
   `Read work item:` line from `${CLAUDE_PLUGIN_ROOT}/operations.md` for the facts'
   issue.
5. Create a review worktree at `head_sha` (`git worktree add --detach <dir>
   <head_sha>`), separate from any branch checkout. Restore it to a clean head
   (`git -C <dir> checkout --force <head_sha>`, then `git -C <dir> clean -fdq`) before
   every refuter call.

**Round.** Round is 1 plus the number of `prior_reviews` with `Route: fix`. The cap is
the repository variable `PR_REVIEW_MAX_ROUNDS` (default 3), read from the environment.

## 2 Earlier blockers (round 2 on)

Read the latest prior review (*Read review threads* and its body). For each of its
blockers, call `devflow:refuter` in mode `fixed` with that blocker. `FIXED` blockers are
closed; `NOT FIXED` ones are carried forward with their IDs. A blocker that `respond`
declined (a reply on its thread whose first word is `Declined`, from the PR's agent
identity) is carried forward and forces `Route: human`.

## 3 Finders

| Tier (from facts) | Finders | Refuter checks |
|---|---|---|
| `light` | `devflow:design-critic` (model: the agent's default, Opus) | blockers and questions |
| `full` | `devflow:defect-finder` and `devflow:design-critic` with model `fable` | every finding and question |

Launch the tier's finders in one message so they run in parallel where the runtime
allows (foreground; a runtime that serializes them still completes). If the `fable`
model is refused, rerun the design critic on its default model and record that under
Not reviewed. Each brief holds only: base SHA, head SHA, the worktree path, the tier,
the `Read work item:` and `Standards:` lines, and, for the defect finder, the gate and
mutation commands. Never the PR number, PR text or an earlier review.

## 4 Refute

Collect the findings. Merge duplicates (same class, file and overlapping lines) and
drop any finding that matches a carried-forward blocker. Then, for each finding the
tier's column names, call `devflow:refuter` in mode `check` with that one finding and
nothing from the other finder. Keep what it confirms, with the class and severity it
settles on; record each `REFUTED` finding and its reason under Dropped. A follow-up
the tier does not refute is listed under Follow-ups as not filed (unverified).

**Later rounds keep the goalposts.** From round 2, a new blocker counts only when its
lines changed since the last reviewed SHA (`git diff <prior commit_id> <head_sha>`), or
it is a B1 or B2 proven by a failing test, or a B6 (the work item is the goalpost).
Any other new blocker becomes a follow-up.

## 5 Verdict

Apply these rules to the surviving findings and the facts. Add nothing of your own.

| Class | Blocker | Required evidence |
|---|---|---|
| B1 | Wrong behavior on a realistic path | A failing test or command, rerun by the refuter |
| B2 | Acceptance criterion unmet, or met only by a test that passes without the change | The criterion, and the test run against reverted code |
| B3 | Gate weakened: deleted or loosened assertion, skipped test, new lint allowance, edited gate or mutation config | The diff lines |
| B4 | Written rule broken: an ADR or the ADR directory's own rules, the `CLAUDE.md` rules, the planning standards, a standards skill; also when the work item asks for it | The rule quoted, and the lines |
| B5 | Changeability blocker (C1 to C4 at blocker severity, `engineering-standards`) | The named item or missing consumer, and the lines |
| B6 | Plan deviation: a Footprint entry or tech-spec design item the diff does not deliver | The work item line quoted, and the diff at that path (or its absence) |

- **Verdict.** `reject` when at least one blocker survives (carried or new), else
  `approve`: the change leaves the codebase better and nothing blocks it. Real issues
  that are not blockers are follow-ups; preferences were never reported.
- **Never follow-ups.** B2, B4 and B6 are never follow-ups. A finder or refuter
  that rates one a follow-up is overruled: it is a blocker.
- **The work item is not ground truth.** A finding whose fix would follow a work-item
  instruction that a written rule contradicts is `Fix: needs-decision`.
- **Route** (reject only). `human` when any blocker is `Fix: needs-decision`, a carried
  blocker was declined, the same blocker survived two rounds, this round does not have
  fewer blockers than the last, or the round exceeds the cap. Otherwise `fix`. Approve has
  `Route: none`.
- **Questions** do not reject. Each confirmed question is listed with its proposed
  default and sets Sign-off to `human`.
- **Sign-off.** `human` when any facts trigger is listed, a question stands, a C2
  finding was confirmed (even as a follow-up), the change touches security-relevant code
  (authentication, input parsing at a trust boundary, `unsafe` or its equivalent) or a
  public API or persisted format the spec does not name, or a full-tier toolchain could
  not run. Else `agent`.

## 6 Post

Body, in this order, no other prose:

```
Verdict: <approve|reject>
Route: <fix|human|none>
Sign-off: <agent|human>
Head: <head_sha>   Tier: <light|full>   Round: <n>

Blockers          [Xn] class, file:line, failure scenario, evidence (test or rule), expected fix
Questions         numbered, each with a proposed default
Follow-ups        filed (issue links) and not filed
Sign-off triggers each one hit
Dropped           one line per refuted finding, and why
Not reviewed      what this run could not see or run
Counts            candidates, dropped, blockers, follow-ups, agent calls, design-critic model
```

Blocker IDs (`X1`, `X2`, ...) are unique on the PR: carried blockers keep theirs, new
ones take the next number. Each blocker on a line in the diff also gets an inline
comment with the same text.

Dry run: write the body to the out-file and stop.

Otherwise re-read the head SHA (*Read PR review context*); if it moved, discard and
start over. Then run *Submit review* with `commit_id` = the reviewed SHA:

| Outcome | Event | Then |
|---|---|---|
| reject, Route fix | request changes | the fix loop runs `devflow:respond` |
| reject, Route human | request changes, *Label PR* `needs-human` | a person decides |
| approve, Sign-off human | comment | a person reads the triggers and questions |
| approve, Sign-off agent | approve when allowed, else comment | a person merges, or auto-merge once enabled |

Requesting changes needs no setting. Approving needs all of: `PR approval: agent`; an
acting identity that is neither the PR author nor a commit author (a local run is the
person's own identity, so it comments); and the base branch dismisses stale approvals
on push (*Submit review*'s check). Any of these failing turns the approval into a
comment that says which. The forge refuses request-changes on one's own PR too: then
comment, with the verdict lines unchanged.

After submitting:

- **Resolve** (*Resolve review thread*) each of your own inline threads whose blocker
  the refuter reported `FIXED` this round. Never resolve another author's thread.
- **Follow-ups**, per the base branch's `PR follow-ups` setting (default `comment`):
  `issue` files at most 3 confirmed follow-ups, most valuable first, with *File
  follow-up* (deduplicated against open issues by title and path; a match gets a
  *Comment on work item* with the new evidence instead), and lists the rest as not
  filed; `comment` lists them in the body only; `off` omits them. A filed follow-up
  carries what was observed, `file:line`, the evidence, the PR and work item it came
  from, and a suggested acceptance criterion. It never gets `agent-ready` or a board
  header.
- Remove the review worktree.

Report: the three verdict lines, head SHA, tier, round, and the counts.
