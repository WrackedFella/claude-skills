# D0003 Orchestrator on Sonnet

- **Status:** Accepted, 2026-11-19
- **Decision:** The orchestrate main loop runs on Sonnet with the step-check hook (D0002). Opus is not adopted for it; Opus stays on judgment workers (critics, reviewer).
- **Evidence:** 10 cards x2 each. Baseline Sonnet: 10/20 pass. Opus + hook: 7/20 at 2.4x replay tokens, compliance 19/20. Sonnet + hook: 8/20 at baseline cost. The compliance gain came from the hook, not the model.
- **Reopen when:** a new model generation changes the Sonnet/Opus gap, or step compliance regresses with the hook in place.
