# D0035 Cost work targets the builder, the orchestrator loop and intake first

- **Status:** Proposed, 2026-11-27.
- **Decision:** Cost changes are ranked by share of recorded spend, then by quality risk, and each names the eval tier that proves it (D0010, D0011; quality first, D0001).
  - **Order of spend (orchestrate, 36 runs):** builder 37%, orchestrator main loop 26%, intake (Opus) 15%, reviewer (Opus) 9%, test-critic 4%, Explore 3%, wiki 2%, comment-audit 2%. PR review and fix rounds are a further 32% of recorded spend, over orchestrate's 68%.
  - **Ranked plan:**

    | # | Change | Est. saving of recorded spend | Quality risk | Proof |
    |---|---|--:|---|---|
    | 1 | Add context sources and reviewer/test-critic yield to run records (D0036) | 0 (enabler) | none | none |
    | 2 | Cut early bulky tool output in builder and orchestrator (D0036) | 5-8% | low | standard |
    | 3 | Scope intake and critic context (D0036) | 2-3% | low-medium | standard |
    | 4 | Scope PR-review rounds 2+ to the delta (D0037) | 3-5% | low-medium | `pr-verdict` replay set, then standard |
    | 5 | Move mechanical steps to Haiku: comment-audit, Explore (D0036) | about 1% | low | smoke |
    | 6 | Lower effort for the orchestrator loop (D0038) | 1-3% | medium | standard |
    | 7 | Parked: intake or reviewer on Sonnet, reviewer overlap with PR review, trivial lane, turn caps (D0038) | | | blocked on evidence |

  - Savings are the estimate of `cost-per-item/breakdown.md` and are re-measured by the eval that proves each change.
- **Evidence:**
  - 36 production orchestrate runs, 24-27 Nov (run records): builder 132.5M cache read, 5.1M cache write, about 1.0M output over 1,251 calls; orchestrator 109.8M, 2.7M, 0.6M over 1,557 calls; intake 14.9M, 1.8M, 0.3M over 530 calls; spend shares are fitted dollars ($122 fitted against $110 reported).
  - Per token kind, Sonnet orchestrate spend is 54% cache read, 27% cache write, 19% output; Opus is 30%, 46%, 23% because its steps are fresh-context agents.
  - Run cost has no heavy tail (25 of 36 runs between $2.2 and $5.2), so a cap saves little; the cost is the per-call context times the number of calls.
  - Gate class barely moves cost (glue $2.92, domain $3.21 per orchestrate run); size does so sublinearly (<500 lines $3.88, 500-1000 $5.83, >1000 $6.29 per issue).
- **Sources:** S37 (cache read and write prices relative to input).
- **Reopen when:** run records carry context sources and PR-review per-role tokens, or the per-step shares shift by more than 5 points.
