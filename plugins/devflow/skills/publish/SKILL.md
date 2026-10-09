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
   - Run `${CLAUDE_PLUGIN_ROOT}/scripts/card publish <feature-issue> "[<ID>] <title>"
     <body-file> --label <labels from the header> --board <owner> <number> Status=Ready
     'Gate class'=<header value> Agent-eligible=Yes`. Use `Agent-eligible=No` if the
     header or the user says the item is human-driven; use `Status=Ready` only if the
     card is approved.
   - Set the card header's `Issue` link and status per the planning standards, and add
     the card to the feature's item table.
5. Report each card as `ID → #n`, and anything left unfiled with the reason. Don't
   commit; leave that to `/devflow:ship` or the user.
