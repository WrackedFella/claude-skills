# D0021 The wiki explains and links; it does not restate a skill's procedure

- **Status:** Proposed, 2026-11-23 (devflow review 2.8)
- **Decision:** A rule or step lives in the skill or agent that applies it. Wiki pages hold what those files cannot: why the workflow is shaped this way, how the parts fit, and setup. A step table links to the skill's heading instead of repeating its text.
- **Evidence:** `wiki/orchestration.md` §1 and §3 repeat `orchestrate/SKILL.md`. Four statements had drifted by 2026-11-23: README's agent list without `builder`; `wiki/overview.md` on human-only merge (against D0016) and on test-writer then implementer (against D0006); `wiki/getting-started.md` "a human does".
- **Sources:** S16 (don't include information that will become outdated).
- **Reopen when:** a reader of the wiki cannot follow a run without opening a skill file.
