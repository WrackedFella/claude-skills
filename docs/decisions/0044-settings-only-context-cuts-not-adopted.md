# D0044 `bashOutputMaxChars` and `--exclude-dynamic-system-prompt-sections` are not adopted on smoke evidence

- **Status:** Proposed, 2026-11-27.
- **Decision:** Neither settings-only cut from D0041 is adopted. Both stay open for a standard-tier run once the D0040 meter has data from real runs.
- **Why:**
  - **Quality held, cost did not clear the bar.** Smoke set (ENG-F1-10 and FPS-F9-01, 2 runs each, devflow pinned to `main` at `c8bb9a4`, moho `orchestrate-eval.yml` with the two settings as inputs): passes were 1 of 4 (baseline), 1 of 3 (`bashOutputMaxChars=10000`; one replay cancelled) and 1 of 4 (`--exclude-dynamic-system-prompt-sections`), inside the D0008 noise bar.
  - **Cost is inconclusive (D0011 cost rule: Sonnet + Opus cache read median down 15%).**
    - Exclude-dynamic: ENG-F1-10 Sonnet cache read 5% lower on average (2.9M vs 3.1M), FPS-F9-01 10% lower (18.7M vs 20.8M) with 2 to 5 fewer turns per replay; both inside the spread between the two baseline runs of one card.
    - `bashOutputMaxChars=10000`: ENG-F1-10 34% higher (4.1M vs 3.1M, same turn counts); FPS-F9-01 has one replay (8.4M, a pause 5 turns earlier), not comparable.
  - **The set could not measure it.** FPS-F9-01 now pauses with questions at 22 to 29 turns in every configuration, so its token counts reflect where it stopped, not the cut. The four glue cards are small; main-loop Bash results in the baseline records are at most about 16k characters (`just test`) or 11k (`cat`), so a 10k cap rarely bites and, where it does, hits test output that D0041 says to leave alone.
- **Evidence:** moho eval runs 46030338161 (`ctx-base`), 46030342148 (`ctx-bash`), 46030345918 (`ctx-dyn`); `scripts/eval-score.sh collect <label>` per label (a mixed-label collect merges replays of one card and run). Cross-run reuse from `--exclude-dynamic-system-prompt-sections` needs runs close in time; replays here ran in parallel and the effect, if any, is not isolated.
- **Proof for a retry:** standard tier on domain cards that do not pause, after D0040 shows which tool bulks context; keep if the D0036 gate (Sonnet cache-read median down 15%) is met with passes and defect rejects not worse.
- **Sources:** S38, S39.
- **Reopen when:** the D0040 meter shows Bash results above 20% of builder context (`bashOutputMaxChars`), or a cross-run cache measurement is possible (`--exclude-dynamic-system-prompt-sections`).
