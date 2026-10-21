---
name: publish
description: File approved local draft cards (Status Draft, no issue link) as GitHub issues under their feature, set their board fields, and update the card header. Use from a session that can reach the board, after a cloud thread left drafts behind.
argument-hint: "[card-id ...]"
arguments: [cards]
---

File the project's approved draft cards as issues. Never implement, merge, or edit a
card's spec.

1. Read the project's `CLAUDE.md` (planning standards, board, `Card review`) and the
   planning standards it names (card template, issue body rules, ID format, labels).
2. Find drafts: cards whose header has `Status: Draft` and no `**Issue:**` link,
   limited to `$cards` when given. Confirm each is approved: `Card review: not
   required`, or the user says so (ask once, listing the drafts; in a headless run, file
   none and report).
3. When a board is configured, run `${CLAUDE_PLUGIN_ROOT}/scripts/board probe <owner>
   <number>` first. On exit 5, stop and report that this session cannot reach the board
   either.
4. Per approved draft, in dependency order:
   - Write the body per the Tech Lead's Published issues rules: the whole spec, no
     header lines, no template comments, other work as `#N`.
   - With `Board header: yes`, make sure the body starts with the board header for the
     card's gate class and `Agent-eligible` (same rule as below); the project's automation
     then applies it, and `--board` only needs `Status=Ready` for an approved card.
   - Run `${CLAUDE_PLUGIN_ROOT}/scripts/card publish <feature-issue> "[<ID>] <title>"
     <body-file> --label <labels from the header> --board <owner> <number> Status=Ready
     'Gate class'=<header value> Agent-eligible=Yes`. Use `Agent-eligible=No` if the
     header or the user says the item is human-driven; use `Status=Ready` only if the
     card is approved.
   - Set the card header's `Issue` link and status per the planning standards, and add
     the card to the feature's item table.
5. With `Card review: not required`, apply the tech-lead's **Promotion** checks to each filed card and add `agent-ready` (the *Add label* operation) to those that pass. With `required`, apply none.
6. Report each card as `ID → #n`, whether it was promoted (or the failed check), and anything left unfiled with the reason. Don't
   commit; leave that to `/devflow:ship` or the user.
