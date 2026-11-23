# D0018 Every script a skill calls is on the runner's allow-list, and deciding scripts are checked

- **Status:** Proposed, 2026-11-23 (devflow review 2.1, 2.4)
- **Decision:** A script whose exit status decides a run (`intake-agree`, `test-guard`, `e2e-guard`) is allowed in every workflow that runs the skill calling it, and `step-check` requires its call as it requires a step's agent call. The consuming project checks its allow-lists against the scripts the plugin's skills name.
- **Evidence:** moho `claude.yml` allows `board`, `pr-facts`, `run-log` and `test-guard` to orchestrate; `intake-agree` is allowed only in `orchestrate-eval.yml`, so production cannot run the decision the eval measured, and `run-log` does not exist. `step-check` requires no script call. In the `fold` set a brief without a `Mode:` line was scored as three missing steps (ENG-F45-02 r2).
- **Sources:** S17.
- **Reopen when:** the runner stops matching Bash commands by allow-list prefix.
