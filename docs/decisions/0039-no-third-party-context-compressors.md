# D0039 No third-party output compressor, prompt proxy or context-compression MCP is adopted

- **Status:** Proposed, 2026-11-27.
- **Decision:** RTK, context-mode, Headroom and LLMLingua stay out of devflow's runs, cloud environment and plugin. The same job is done by a devflow-owned hook (D0041) if the measurements in D0040 show a source worth cutting.
- **Why:**
  - **The target is small.** Production cost is cache read (54% of Sonnet orchestrate spend) over context that accumulates across calls; gate and test output, which these tools shrink best, are already small (D0035, D0036). Independent measurements agree: RTK cut tool-output tokens 38% yet paired cost rose 6.8%; JetBrains measured +7.6% cost at low effort and nothing at high effort; a 614M-token replay of RTK, Headroom and caveman saved 3.7% of spend (S42).
  - **Quality risk against the gate.** A summarising filter sits between the agent and `just check` output. RTK has fixed dropped build errors and missing success lines in other runners (S40); no Rust test exists for cargo, clippy or nextest. CVE-2026-45792: a project-local `.rtk/filters.toml` could hide content from an AI reviewer, which is a hiding channel on a public repository whose PRs any contributor can open (S40).
  - **Supply chain and licence.** RTK installs by `curl | sh` from `master`, ships frequent release candidates, has a same-named crate on crates.io and BUSL-licensed components. context-mode is Elastic License 2.0, has one maintainer, runs code on the host (`ctx_execute`) and blocks WebFetch and large Reads, which changes agent behaviour (S41). Headroom is a proxy (`ANTHROPIC_BASE_URL`), telemetry is on by default, and subscription OAuth through it is unconfirmed (S41). LLMLingua is lossy token pruning with no Claude Code integration (S41).
  - **Proxy and MCP paths cost cache.** A tool that rewrites or indexes content changes what is in the prefix; compression is only a saving when the agent does not re-run the command to recover what was dropped.
- **Evidence:** vendor claims are 60-99% of tool-output bytes; none measures task success or spend on a pass-rate gate (S40, S41). Not run in our evals.
- **Sources:** S40, S41, S42.
- **Reopen when:** an independent paired evaluation on cargo-based work shows lower spend at equal pass rate, the vendor pins and signs releases, and project-local filter files can be disabled.
