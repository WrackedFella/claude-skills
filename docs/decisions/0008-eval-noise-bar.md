# D0008 Eval noise bar

- **Status:** Accepted, 2026-11-18
- **Decision:** In an eval set of 2 runs per card, a gap of one run in a count (approves, defect rejects, passes) is noise. A borderline result grows the set rather than deciding. A set loads devflow from one fixed ref (`devflow_ref` or a frozen `main`) for all its replays.
- **Evidence:** Review self-agreement on the same head is 5-8 of 10 cards; same cause on every run of a card in 4 of 7-10 cards (`sonnet-hook`, `step11b`). `sonnet-hook` was split by a mid-set merge of #76.
- **Sources:** S1 (pass^k: reliability needs repeated trials); S4 (inconclusive as a verdict).
- **Reopen when:** sequential extension (D0010) gives enough runs to use a statistical test instead of a fixed bar.
