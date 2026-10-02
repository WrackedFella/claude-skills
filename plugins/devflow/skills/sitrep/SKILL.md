---
name: sitrep
description: Succinct situation report on progress - for a feature, a work item or issue, or the whole project when no target is given. Read-only.
argument-hint: "[feature-id | item-id | #issue]"
arguments: [target]
context: fork
model: haiku
background: false
---

Report status for `$target` (or the whole project if empty). Read-only: never edit,
commit or comment.

Gather, using the project's planning index and standards named in its `CLAUDE.md`:
- the feature or item file(s): status, exit criteria or acceptance criteria;
- linked issue and PR state (`gh issue view`, `gh pr list --search`, `gh pr checks`);
- branch state: commits ahead of the base branch, uncommitted changes, last gate run if
  visible.

Report in at most ~12 lines:

- **Status:** one line (e.g. "in progress: 2/4 items done, PR #12 awaiting review").
- **Done / in flight / not started:** item IDs only, grouped.
- **Gates:** CI and checks for open PRs; exit criteria met vs open (features).
- **Blockers / decisions needed:** only real ones, each one line.
- **Next:** the single most useful next action and who owns it (human or agent).

No narration, no restating the spec.
