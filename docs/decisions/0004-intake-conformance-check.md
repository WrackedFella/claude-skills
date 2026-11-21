# D0004 Intake conformance check

- **Status:** Accepted, 2026-11-20 (claude-skills #76, narrowed by #80, agreement by #84)
- **Decision:** Before tests, `devflow:design-critic` checks the work item against written rules and sibling items, twice in parallel; `scripts/intake-agree` pauses only on blockers both runs raise, and only on conflicts the review would reject. Questions and card-format rules never pause.
- **Evidence:**
  - `intake` (#76, run 44429426286): fails, 10 of 11 replays paused, on questions and card-format rules.
  - `intake2` (#80, run 44527239951): no noise pauses; the known conflict cards (SG-F5-03, FPS-F15-01, ENG-F18-16) pause.
  - `intake_only` A/B, 10 cards x4 per arm (runs 44761621896 vs 44767966886): pause decisions stable on 10/10 cards with agreement vs 8/10 single; about +$0.17 per run.
- **Known cost:** a real conflict only one critic catches no longer pauses; the review must catch it.
- **Reopen when:** a conflict reaches review that a single critic raised at intake.
