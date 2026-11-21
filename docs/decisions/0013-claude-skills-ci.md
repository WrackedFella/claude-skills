# D0013 claude-skills CI

- **Status:** Proposed, 2026-11-21
- **Decision:** claude-skills pull requests run deterministic checks, with no model calls:
  - shellcheck, plus fixture tests for `plugins/devflow/scripts/*` (intake-agree, step-check, test-guard, e2e-guard, card, board, pr-facts)
  - validation of the plugin and marketplace manifests and of agent and skill frontmatter (name, model, tools)
  - every `${CLAUDE_PLUGIN_ROOT}/...` and `${CLAUDE_SKILL_DIR}/...` path a skill names exists
  - relative links in `wiki/` and `docs/` resolve
  - a tier job labels the PR for D0010

  Branch protection on `main` requires these checks. `claude plugin eval` suites for skills that orchestrate replays don't exercise (refine, publish, comment-audit) come later, run inside the D0010 tiers.
- **Why:** a merge is the release, and today nothing checks a claude-skills PR before it ships.
- **Sources:** S3.
