# D0005 Step 11 reviewer

- **Status:** Under re-test: claude-skills #86 (step 11 as the pr-review dry run, on the builder), eval set `step11c`, moho run 44914151274. Decided 2026-11-20 (claude-skills #82, reverting #81).
- **Decision:** Step 11 stays `devflow:reviewer`.
- **Evidence:** `step11` and `step11b` (with #80 intake): real-defect rejects 33% to 27%, one run per set, which is noise by D0008. Needs-decision blockers moved from conflict rejects to pre-PR pauses (3/20 to 2/38). Domain runs grew to 140-174 min.
- **Caveat for the re-test:** step 11 and the eval grader share the pr-review rubric, so approves overstate gains; weigh gate, reference tests and minutes too.
- **Reopen when:** `step11c` scores: keep #86 if real-defect rejects fall beyond noise against the `fold` control (approves 7/10, defects 2, conflicts 1).
