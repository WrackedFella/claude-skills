# D0013 claude-skills CI

- **Status:** Accepted, 2026-11-21 (Justin)
- **Decision:** claude-skills pull requests and `main` run deterministic checks, with no model calls. `ci/check` runs them locally as CI does:
  - `shellcheck`: every shell script, at full severity
  - `tests`: fixture tests for each `plugins/devflow/scripts/*` and the CI scripts; GitHub calls go to a stub
  - `plugin`: the marketplace and plugin manifests, agent and skill frontmatter (valid YAML, known keys, name, description, model, tools, skills), script modes, every `${CLAUDE_PLUGIN_ROOT}/...` and `${CLAUDE_SKILL_DIR}/...` path, every `devflow:<name>`
  - `links`: relative links and heading anchors in every Markdown file
  - `workflows`: actionlint
  - `eval tier`: labels the PR `eval:none|smoke|standard|full` for D0010

  Branch protection on `main` requires all six. `claude plugin eval` suites for skills that orchestrate replays don't exercise (refine, publish, comment-audit) come later, run inside the D0010 tiers.
- **Tier rules** (`ci/eval-tiers`, first match wins, a PR takes its highest file):
  - full: an agent or skill added, removed or renamed, or a changed `model:` or `effort:` frontmatter line; delegation or step changes are raised by hand
  - standard: orchestrate, builder, test-critic, design-critic, reviewer, step-check, intake-agree, test-guard, hooks, and pr-review with its agents and `pr-facts`, because pr-review scores the replays
  - none: skills and agents moho's replays never load (BA, TL, refine, publish, respond, sitrep, dotnet, azure, acceptance review), and everything outside the plugin
  - smoke: every other plugin file and the manifests
- **Labeler:** the label only rises; a higher `eval:` label already on the PR stays, so a person raises a tier by setting it. It runs on `pull_request_target` from `main` and fetches the PR's commits as data without checking them out, so a PR can't change its own tier rules or run code with the write token.
- **Why:** a merge is the release, and nothing checked a claude-skills PR before it shipped. The first run found `design-critic`'s description was invalid YAML (an unquoted `: `).
- **Sources:** S3, S6.
- **Reopen when:** a check fails on a valid plugin feature (extend the known keys or tools), or tier labels on merged PRs disagree with what the eval queue had to run.
