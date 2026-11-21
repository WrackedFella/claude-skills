# D0010 Evals gate before merge, on a change-gated queue

- **Status:** Accepted, 2026-11-21 (Justin); not built yet
- **Decision:**
  - A merge to claude-skills `main` is the release, so a devflow PR is evaluated before merge, through moho's `orchestrate-eval.yml` with `devflow_ref` set to the PR head. A human still merges.
  - The tier comes from the PR's changed paths, and a label can raise it:

    | Tier | Changes | Set | Question it answers |
    |---|---|---|---|
    | none | docs, wiki, skills orchestrate never loads | deterministic CI only | |
    | smoke | agent wording, standards, scripts | 2 glue cards x1 | still works |
    | standard | orchestrate steps, builder, critics, intake, step-check | 5 cards x2 | better or worse |
    | full | model or effort per role, delegation, added or removed steps | 10 cards x2 | the same, at a lower noise level |

  - Runs only when something changed. A nightly moho cron checks for open PRs at a tier above none whose head has no score, and for `main` moving since its last score. With nothing new it exits without a model call. Unattended runs are standard tier or lower; full is dispatched by hand.
  - When a standard result is inconclusive, the next night adds one run per card, up to 4.
  - Scores post to the PR as a comment from the `moho-reviewer` GitHub App, installed on claude-skills.
- **Sources:** S1, S3 (CI gating on eval score), S4 (sequential trials, inconclusive verdict).
- **Reopen when:** devflow changes become frequent enough that the queue regularly holds more than one standard tier per night.
