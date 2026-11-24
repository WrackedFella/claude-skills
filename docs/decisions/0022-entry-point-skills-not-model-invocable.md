# D0022 Entry-point skills start only when named; plugin agents carry no hooks

- **Status:** Accepted, 2026-11-24 (narrowed by smoke test); proposed 2026-11-23 (devflow review 2.11, 2.12)
- **Decision:** `publish` and `pr-review` set `disable-model-invocation: true`. `orchestrate`, `refine` and `respond` stay model-invocable. Skills another skill invokes (`ship`, `comment-audit`, `wiki`) and the standards skills stay model-invocable. Enforcement for an agent goes in the plugin's `hooks/hooks.json` or in a script its caller runs, never in the agent's frontmatter.
- **Evidence:** the five skills push, file issues or post reviews, and each is started by a person or a workflow prompt. `/skill-doctor` puts the 15 devflow listings at about 1,400 tokens per turn.
- **Smoke test, 2026-11-24 (`claude -p`, throwaway plugin, one flagged skill):** prompt `/smk:dmi 123` ran the skill; prompt `run /smk:dmi 123` in prose did not ("no skill by that name is available"). Workflow prompts therefore keep working; a coordinator brief in a project thread starts only skills that stay model-invocable, and project threads start `orchestrate`, `refine` and `respond` that way.
- **Sources:** S15 (`disable-model-invocation` removes a skill from context and blocks Skill-tool calls to it; plugin subagents ignore `hooks`, `mcpServers` and `permissionMode`).
- **Reopen when:** Claude Code lets the model start a flagged skill on a user's named request, or a skill needs to start one of the five through the Skill tool.
