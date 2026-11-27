# D0038 Cost levers held back until evidence supports them

- **Status:** Proposed, 2026-11-27.
- **Decision:** These stay out of the plan; each lists what would reopen it.

  | Lever | Why held | Reopen when |
  |---|---|---|
  | Intake or reviewer on Sonnet (about 3.5% and 2% of recorded spend) | D0007 saw a weaker critic miss an ADR blocker; intake exists to catch one (D0004) | an intake canary set (disputed ENG-F18-16) passes on Sonnet |
  | Drop the orchestrate reviewer, or intake on glue | D0005 and its step-11 dry run were dropped; no reviewer yield is recorded | reviewer yield (D0036) shows it leaves nothing on most glue runs |
  | Trivial lane (skip intake, wiki, comment-audit, reviewer under 3 files) | D0012: lanes wait for about 10 runs per gate class; tiny cards still cost $1.7-$2.4 | the digest has that many runs and a canary (FPS-F9-01) is defined |
  | Turn or budget caps | the tail is flat (25 of 36 runs $2.2-$5.2), so a cap saves little | a run exceeds 2x the median |
  | Lower effort for the orchestrator loop | output is 19-23% of spend; effect on pass rate is unmeasured | proposed as a standard-tier eval, not adopted |
  | Splitting cards to cut cost | cost is sublinear in size | never; split for review size only |
- **Evidence:** `cost-per-item/breakdown.md` (steps, tails, size); D0004, D0005, D0007, D0012.
- **Reopen when:** per the table.
