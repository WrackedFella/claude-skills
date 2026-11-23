# D0022 Entry-point skills start only when named; plugin agents carry no hooks

- **Status:** Proposed, 2026-11-23 (devflow review 2.11, 2.12)
- **Decision:** `orchestrate`, `refine`, `publish`, `pr-review` and `respond` set `disable-model-invocation: true`. Skills another skill invokes (`ship`, `comment-audit`, `wiki`) and the standards skills stay model-invocable. Enforcement for an agent goes in the plugin's `hooks/hooks.json` or in a script its caller runs, never in the agent's frontmatter.
- **Evidence:** the five skills push, file issues or post reviews, and each is started by a person or a workflow prompt. `/skill-doctor` puts the 15 devflow listings at about 1,400 tokens per turn.
- **Sources:** S15 (`disable-model-invocation` removes a skill from context and blocks Skill-tool calls to it; plugin subagents ignore `hooks`, `mcpServers` and `permissionMode`).
- **Reopen when:** a skill needs to start one of the five through the Skill tool.
