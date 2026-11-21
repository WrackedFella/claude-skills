# D0007 PR-review design critic on Opus

- **Status:** Accepted, 2026-11-16 (claude-skills #73)
- **Decision:** The pr-review design critic runs on Opus on every tier.
- **Evidence:** Stage 1 back-test, engine sample set: Opus caught every seeded and real blocker; Fable missed the ADR-0026 blocker on moho PR #831.
- **Reopen when:** a back-test set shows another model matching Opus on blocker recall.
