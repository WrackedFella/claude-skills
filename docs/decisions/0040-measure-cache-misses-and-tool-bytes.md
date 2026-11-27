# D0040 Measure cache misses and tool-result bytes per tool before any new cut

- **Status:** Proposed, 2026-11-27.
- **Decision:** The run record gains three fields, all from data the run already produces, with no model call:
  - **Cache split:** per model and agent, `cache_creation` by TTL (`ephemeral_5m`, `ephemeral_1h`) from the execution log, and the count of mid-conversation calls whose cache write exceeds 20k tokens (a cache miss).
  - **Tool bytes:** tool-result bytes per tool name and agent, from a `PostToolUse` hook that appends `tool,agent,bytes` to a file and does not change the output.
  - **Context peak** per agent.
  This extends D0036's measure-first step; D0036's context sources are provided by the hook.
- **Why:**
  - **Subagents get a 5-minute cache.** On a subscription only the main conversation gets the one-hour TTL; subagents, compaction and forks get 5 minutes, and a subagent's first request does not read the parent's cache (S38). The builder (37% of spend) is a subagent resumed by `SendMessage` after the Opus test-critic; a gap over five minutes re-writes its roughly 100k context at 1.25x input instead of reading it at 0.05x to 0.1x (S38, S37). Nothing in the records shows whether this happens.
  - **Which tool bulks context is unknown.** `ctxcut` showed the gate and test output are not it; Read, issue re-reads and `git diff` are inferred, not measured (D0036).
  - **Hooks reach subagents.** Hooks from settings and plugins run inside subagents (S39), so one hook meters builder and critics; whether the hook input names the agent is the first thing to verify.
  - **The OTel pilot may overlap.** D0033's `tool_result` events carry duration and success; if they carry result size, the hook is unnecessary.
- **Evidence:** S38 and S39 are read from the docs through a subagent's extraction; the `-p` and Actions behaviour of the TTL rule is inferred (the page says `-p` turns are main conversation) and unconfirmed for `claude-code-action`.
- **Proof:** none; no model call.
- **Sources:** S37, S38, S39.
- **Reopen when:** the pilot's `tool_result` events already carry size, or the hook input lacks an agent identifier and per-agent attribution needs another route.
