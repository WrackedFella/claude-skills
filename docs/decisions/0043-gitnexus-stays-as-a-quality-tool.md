# D0043 GitNexus stays as an impact-analysis tool, not a context-saving one

- **Status:** Proposed, 2026-11-27.
- **Decision:** moho keeps GitNexus for `impact` before edits and `detect_changes` before commits (quality checks). It is not counted as a cost lever. The D0040 meter records `mcp__gitnexus__*` call counts and result bytes per agent, which decides whether it earns its context.
- **Why:**
  - **No evidence either way.** `RUN-RECORD` carries no tool names, the execution log is never uploaded, and the Actions job log shows no GitNexus line; whether orchestrate runs call it is unknown.
  - **Availability.** In Actions the orchestrate job runs `cloud-tools.sh --force`, which runs `scripts/gitnexus-mcp.sh --setup`; `.claude/settings.json` approves the server and allows its tools. The `--allowedTools` list in `claude.yml` names none, so it relies on the settings allow-list. Confirming a call lands is part of D0040.
  - **The install race is already closed on `dev`.** `.mcp.json` starts `scripts/gitnexus-mcp.sh`, which installs the dependency and indexes in the background (about 20 s, first calls see no repo). A thread still without it has one of two causes: a clone older than that script, or a thread whose repository settings do not apply, as in this project's multi-repo threads, where `.claude/settings.json` and so `enabledMcpjsonServers` are ignored. Neither is a script defect.
  - **Smallest further fix, only if a thread that relies on it still misses:** build the index synchronously before `exec "$bin" mcp` (the 120 s `MCP_TIMEOUT` already covers about 20 s), at the price of a slower session start. Not recommended until a thread shows the miss on a current clone.
  - **Licence.** PolyForm Noncommercial (D0042): acceptable for moho as a personal repository; a commercial fork must license it or drop the tools.
- **Evidence:** moho `dev` files `.mcp.json`, `scripts/gitnexus-mcp.sh`, `scripts/cloud-tools.sh`, `.claude/settings.json`, `claude.yml`; run 45932924683 log (no GitNexus mention). The multi-repo settings cause is from the project instructions and is not reproduced.
- **Sources:** S44.
- **Reopen when:** the D0040 meter shows GitNexus results above 20% of a builder's context, or never called across ten runs (then drop it from the agents' tools).
