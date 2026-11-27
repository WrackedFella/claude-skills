# D0036 Context cuts target early tool output, issue and file re-reads, and critic context

- **Status:** Proposed, 2026-11-27.
- **Decision:**
  - **Measure first:** the run record gains per-step context sources (tokens entering context by tool: Read, Bash, `gh`, `git diff`, MCP) and reviewer and test-critic yield (findings count). No model call; no eval.
  - **Then cut where the sources say:** each issue body read once and passed on; `Read` with ranges for files over a size threshold; `git diff --stat` and per-file diffs in place of whole diffs; large command output to a file with a digest. Gate and test output are not a target (D0006 evidence: small).
  - **Scope what fresh agents load:** intake and the critics receive the ADRs and standards sections their spec names instead of every ADR; Opus steps are write-heavy (intake writes about 56k new tokens a run, reviewer 45k).
  - **Mechanical steps on Haiku:** comment-audit (edited no file in 23 of 30 runs) and Explore run on Haiku, per the haiku rule for mechanical work.
- **Why:**
  - A token costs its write once and a read on every later call; a bulky early result costs about five times its write price, so early output is the leverage.
  - The earlier cut (gate output to a file, capped reports) lowered the Sonnet cache-read sum 22% but not the per-replay median, because gate output was never the bulk; the next cut aims at reads.
- **Evidence:** `ctxcut` set (moho run 44768177454): sum -22%, median flat (8.0M vs 7.9M), gate not met; `fold` set context sources: Read, issue re-reads and `git diff` dominate. Production records: builder context 106k per call over a median 43 calls; orchestrator 71k over 49; intake 28k over 17.
- **Proof:** standard tier on the pause-free orchestrate set; keep if Sonnet cache-read median falls 15% and passes and defect rejects do not drop by more than one (D0008, D0011 cost rule).
- **Sources:** S37.
- **Reopen when:** the context-source record shows no tool above 20% of builder context, or the standard-tier run misses the 15% gate.
