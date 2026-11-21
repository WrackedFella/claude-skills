# D0006 Builder fold

- **Status:** Accepted, 2026-11-21 (claude-skills #85, moho #857)
- **Decision:** One `devflow:builder` carries tests, implementation, challenges, refactor and review fixes in one context, resumed by SendMessage; `scripts/test-guard` keeps its step 2 tests fixed. Items split into parallel parts keep test-writer and implementer.
- **Evidence:** `fold` (5 cards x2, run 44809346227): approves 7/10 vs 4/10, gate 10/10, Sonnet cache read +54%, cost +10%, minutes +13%. `fold2` (domain, 12 vs 12, run 44858360858): approves 4 vs 1, defects 3 vs 4, cost per replay +5%. The cost gate was missed; kept under D0001.
- **Known cost:** long items re-read one large context every turn (SG-F4-03: 49-60M Sonnet cache read vs 16-21M split).
- **Reopen when:** context cuts aimed at issue re-reads, whole-file reads and `git diff` are measured (cost intent, D0011).
