# D0001 Quality before cost

- **Status:** Accepted, 2026-11-21 (Justin)
- **Decision:** A change that improves results (pass rate, review approves, fewer defect rejects) is adopted even at modest extra cost. Cost cuts are adopted when cheap to make and free of quality risk; a token gate never blocks a quality gain.
- **Evidence:** Builder fold set (`fold`, moho run 44809346227): approves 7/10 vs 4/10, cost +10%; domain confirm (`fold2`, run 44858360858): approves 4 vs 1, cost per replay +5%. Kept as D0006.
- **Why:** The goal is autonomous feature-to-PR with confidence; review quality is the bottleneck, tokens are not.
- **Reopen when:** usage limits, not quality, become what stops runs from finishing.
