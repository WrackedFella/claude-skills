# D0042 Code-index MCPs and alternative harnesses are not adopted; the GitNexus licence is flagged

- **Status:** Proposed, 2026-11-27.
- **Decision:**
  - No new code-indexing or semantic-retrieval MCP (Serena, claude-context, jCodeMunch, tokensave, Semble, ast-grep-mcp) is added. Claude Code's own lead moved from embeddings to agentic search for stale-index and permission reasons (S43). Revisit one candidate (Semble) only if D0040 shows exploratory `Read`/`Grep` above 20% of builder context.
  - Alternative harnesses (OpenCode with `opencode-dcp`, Aider's repo map) are not adopted: devflow runs on `claude-code-action` and the Claude subscription token; `opencode-dcp` is OpenCode-only and AGPL, and says it can raise cache misses (S44).
  - Context editing (`clear_tool_uses`) and the memory tool are API features with no Claude Code setting; compaction thresholds stay at the defaults (S38, S45).
  - **Licence flag, separate from cost:** GitNexus, already used by devflow's agents and moho, is PolyForm Noncommercial. Moho is a personal hobby repository; a commercial fork (the .NET devflow) needs a commercial licence or must drop the `mcp__gitnexus__*` tools (S44).
- **Why:**
  - **No independent evidence.** Every token-saving figure for these tools is vendor or blog data on retrieval, not agent task success; the one independent-leaning talk found task-dependent results (S44).
  - **Fit.** claude-context sends code to an embedding API and a vector database; jCodeMunch and tokensave have telemetry on by default (tokensave also rewrites `CLAUDE.md` and settings); Serena is GPL and says not to install through a marketplace; jCodeMunch is noncommercial. Each also adds tool definitions to the context unless tool search defers them, which is the default (S38).
  - **Compaction.** The auto-compact default is near the model limit, builder context is about 106k, and the override variable may not apply from `settings.json` `env` (S45); lowering the window would force cache-cold rewrites mid-item.
- **Sources:** S38, S43, S44, S45.
- **Reopen when:** D0040 shows exploratory reads dominate, an independent paired benchmark on Claude Code exists, or Claude Code exposes tool-result clearing.
