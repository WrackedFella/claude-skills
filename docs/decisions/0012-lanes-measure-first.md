# D0012 Lighter lanes wait on per-step data

- **Status:** Accepted, 2026-11-21 (Justin); lanes are not a priority
- **Decision:** No lighter orchestrate path is designed until per-step data exists. Each production `claude.yml` orchestrate run writes the same record as an eval replay. The record includes:
  - tokens per model
  - per-step tokens and yield: tests a challenge added, mutants that survived, reviewer findings, comment-audit edits, wiki pages
  - the devflow commit the run loaded

  A weekly digest per gate class shows which steps produce nothing. Replays are used only to A/B a lane change once the data names one.
- **Evidence:**
  - Glue replays cost $0.21-$4.43 and took 4-21 min; domain replays cost $2.10-$10.55 and took 14-65 min (baseline).
  - Glue runs that skipped steps 4, 5, 7 and 8 approved, except FPS-F9-01, which was rejected 2/2 on real defects.
  - Production runs keep only a denials summary today. Execution logs are not uploaded, so past runs can't be mined.
- **Candidate lanes**, set in the card header and enforced by step-check (D0002):
  - chore: docs or config only
  - fast: glue, one part, a small footprint, no new public API, no ADR; drops step 11, so the PR review is the single review
  - full: everything else
- **Sources:** S1 (read transcripts; outcome graders); S2 (route easy work to a cheaper path when the classification is reliable); S5.
- **Reopen when:** the digest has about 10 production runs per gate class.
