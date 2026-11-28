# D0020 The PR review's verdict lines are computed by a script

- **Status:** Accepted, 2026-11-24 (devflow review 2.5; GATE-F1-03)
- **Decision:** Verdict, Route and Sign-off are the output of a script over the confirmed findings, the `pr-facts` JSON, the prior review and the round. The skill gathers findings and writes wording; it applies no verdict rule. Sign-off triggers that need a reading (security-relevant code, an undeclared public API) are inputs to the script.
- **Evidence:** `pr-review` §5 is a pure function of its inputs, stated as prose a model applies. The merge step acts on `Verdict: approve` and `Sign-off: agent` (D0017). No mis-assembly has been observed; the measured review noise (same-head agreement on 5 of 10 cards) is in the finders.
- **Replay check (2026-11-28):** the 67 reviews posted on moho's agent PRs (2026-11-13 to 2026-11-28) were parsed back into findings files and run through `pr-verdict`. 66 give the recorded Verdict, Route, Sign-off and Round; the parser stood in for the skill's findings step, so it covers the rules and not that step. The one difference (#1029) is a finder's B6 that the reviewer settled as a follow-up; the script promotes a B6 follow-up, so the findings file must carry the settled class. The dry-run replay of heads through the new skill is not done.
- **Sources:** S16 (prefer scripts for deterministic operations), S17.
- **Reopen when:** a verdict rule needs judgment the findings file cannot carry.
