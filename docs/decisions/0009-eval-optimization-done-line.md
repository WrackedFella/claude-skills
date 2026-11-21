# D0009 Eval-optimization done line

- **Status:** Accepted, 2026-11-21 (Justin)
- **Decision:** The manual eval-optimization sequence ends when claude-skills #86 is kept or reverted (D0005). Retargeted context cuts and `--max-budget-usd` budgets leave the sequence and go through the automated pipeline (D0010) once it exists. Product work is not held for them.
- **Why:** Each manual set costs about one 5-hour usage window; the remaining items are cost cuts, which D0001 ranks below shipping.
