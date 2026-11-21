# D0011 Intent-based keep rule

- **Status:** Accepted, 2026-11-21 (Justin)
- **Decision:** Cost and quality come from the same replays, scored as two reports: quality (gate, verdict by cause, reference test names, skipped steps) and cost (tokens per model, then minutes and cost). Each devflow PR declares `Eval intent: quality | cost | neutral`, and a script applies the rule:

  | Intent | Keep when | Guardrail |
  |---|---|---|
  | quality | approves up or defect rejects down by more than 1 run | cost per replay up at most 25% |
  | cost | median Sonnet + Opus cache read down at least 15% | approves not down, defects not up, by more than 1 run |
  | neutral | both inside noise | none |

  The script outputs keep, reject or inconclusive.
- **Rejected alternative:** separate evaluator agents per metric plus a synthesizer. Both metrics come from the same replays, and cost is already computed by a script, so separate agents would add cost and save no time. Mixed results come from real trade-offs and from noise, which a rule fixed before the run settles.
- **Sources:** S1 (grade outcomes with deterministic graders where possible); S4.
- **Reopen when:** a change is judged against both axes and the rule's verdict is overridden by a person.
