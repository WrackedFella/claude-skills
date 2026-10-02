---
name: comment-audit
description: Audit and tighten the code comments added or changed in the current diff, removing narration, history, settled decisions and ephemeral references. Run after implementation and before review or a PR.
argument-hint: "[base-ref]"
arguments: [base]
context: fork
model: sonnet
background: false
---

Audit only the comments added or changed in this diff. Never change code.

1. Find the base: use `$base` if given, else the project's base branch from its
   `CLAUDE.md`, else `origin/main`. Diff with
   `git diff "$(git merge-base <base> HEAD)"` so uncommitted work is included.
2. For each added or modified comment line (including `///` and `//!` docs):

   **Keep** it only if it carries information the code cannot:
   - why the code is shaped this way: a constraint, invariant, tradeoff, workaround
     or gotcha;
   - rustdoc stating an item's contract for its callers (behavior, errors, panics,
     invariants);
   - `// SAFETY:` on `unsafe` (always keep).

   **Delete** it if it:
   - narrates what the code does or restates a name or signature;
   - records history: what it used to be, what changed, what was tried;
   - records a settled decision or alternatives considered (that belongs in an ADR
     or the work item); a one-line reason for code that would otherwise look wrong
     is a "why" and stays;
   - references work-item IDs, phases, PRs, issues or sessions;
   - duplicates documentation that exists elsewhere.

   **Tighten** survivors to the fewest words that keep the "why".

   **Flag, don't edit:** `TODO`, `FIXME`, `HACK`, `XXX`, and any comment you are unsure
   about.
3. Edit the files. Then run the project's formatter so the diff stays clean.

Report counts (removed / tightened / flagged) and list each flagged comment as
`file:line — reason`.
