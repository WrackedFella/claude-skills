# D0041 Context trimming is a devflow hook on documented seams, scoped by D0040's data

- **Status:** Proposed, 2026-11-27.
- **Decision:** If D0040 shows one tool or file class above 20% of builder or orchestrator context, trim it with a devflow-owned hook script, not with prompt rules (D0036's prose cuts) or a third-party tool:
  - `PreToolUse` `updatedInput` adds `offset`/`limit` to a `Read` of a file over a line threshold that named none; the agent can read further ranges.
  - `PostToolUse` `updatedToolOutput` caps one result at a size, keeps head and tail and writes the full text to a file whose path stays in the result.
  - The hook is a deciding script on the allow-list (D0018), shows its own truncation in the result, never touches `just check` or test output, and is off for `devflow:reviewer` and the critics, whose job is to read whole diffs.
  - Settings with no code come first: `bashOutputMaxChars` lowered (spill to file with a preview), and `--exclude-dynamic-system-prompt-sections` through `claude_args` for cross-run reuse of the static prefix (S38, S39).
- **Why:**
  - **A rule that must hold belongs in a hook** (project rule, D0002); prose cuts already failed the median gate (D0036 evidence).
  - **The seams are documented**: `updatedInput` replaces a tool's arguments, `updatedToolOutput` replaces what Claude sees, both for built-in tools; the costs page shows a `tail -n 100` Bash rewrite (S39). The result is auditable code in this repository, with no supply chain beyond Claude Code.
  - **Risk is bounded**: truncation can hide the line the agent needed, so the reviewer and critics are excluded and every truncation is visible and recoverable.
- **Evidence:** the exact output shape the hook must return per tool, the introducing version and whether `-p` honours the hooks are unverified; a smoke run decides (S39).
- **Proof:** standard tier on the pause-free set; keep if Sonnet cache-read median falls 15% (D0036's gate) with passes and defect rejects not worse.
- **Sources:** S38, S39.
- **Reopen when:** the data shows no tool above 20%, or hook output is not honoured in headless runs.
