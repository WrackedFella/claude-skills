# D0002 Step compliance is a hook

- **Status:** Accepted, 2026-11-18
- **Decision:** In headless runs a Stop hook (`scripts/step-check --hook`) blocks the first stop of a run that skipped a mandatory orchestrate step. Prose rules alone don't hold.
- **Evidence:** Baseline (2026-11-17, 10 cards x2): the adversarial challenge was skipped or folded in 15 of 18 finished runs, refactor in 10, independent review in 3. Sonnet + hook (`sonnet-hook`, run 44393777788): each run the hook objected to then ran the step; remaining flags were detector gaps.
- **Sources:** project rule "a rule that must always hold belongs in a hook or gate script"; S2 (prefer simple, enforceable structure).
- **Reopen when:** a lane (D0012) makes some steps optional; the hook must then read the lane, never the orchestrator's judgment.
