---
name: sitrep
description: Succinct situation report on where the current session's work stands, for re-orienting after a long session or time away. Also reports on a specific feature, item or issue, or the whole project. Read-only.
argument-hint: "[feature-id | item-id | #issue | project]"
arguments: [target]
background: false
---

Report status for `$target`. Read-only: never edit, commit or comment.

This skill runs inline, not forked: it must use the conversation so far, because the
point is to recover where *this session* stands. Do not delegate it to a subagent.

## Scope

- **Empty target:** the work this session has been doing. Infer the feature, item or
  issue from the conversation and the current branch name; if it is ambiguous, name the
  candidates in one line instead of guessing.
- **`project`:** the whole project, from the planning index named in `CLAUDE.md`.
- **An ID or `#issue`:** that target only.

## Gather

- From the conversation (session scope only): what was last done, decisions reached,
  questions left open, anything promised but not yet done. Treat this as a claim to
  verify, not as ground truth.
- From the repo: the feature or item file(s) (status, exit or acceptance criteria),
  linked issue and PR state (`gh issue view`, `gh pr list --search`, `gh pr checks`),
  and branch state (commits ahead of the base branch, uncommitted changes, last gate
  run if visible).
- Where the conversation and the repo disagree (e.g. a card says ready but we planned a
  change, or work discussed is uncommitted), report the disagreement; the repo wins on
  facts, the conversation on intent.

## Report

At most ~12 lines:

- **Where we left off:** one line: the last concrete thing done and what was pending
  (session scope only; omit for `project`).
- **Status:** one line (e.g. "in progress: 2/4 items done, PR #12 awaiting review").
- **Done / in flight / not started:** item IDs only, grouped.
- **Gates:** CI and checks for open PRs; exit criteria met vs open (features).
- **Blockers / decisions needed:** only real ones, each one line, including decisions
  made in conversation but not yet recorded in a card or ADR.
- **Next:** the single most useful next action and who owns it (human or agent).

No narration, no restating the spec.

## Compaction

A skill cannot run `/compact`; it can only recommend it. Append one extra line when the
session is long enough that earlier context is likely degraded: many turns, large file
or tool outputs already read, or you were unsure of an earlier decision while gathering.
Skip it for short sessions and for `project` scope.

> Context is heavy; consider `/compact keep: <what is in flight, decisions made, open
> questions, the next step>`.

Fill the focus text from this report so the summary preserves what matters (the active
item ID, decisions not yet written down, the pending next step) rather than a generic
recap. If you are unsure whether the session is long, say so in one clause instead of
suppressing the suggestion.
