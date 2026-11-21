# Decision log

Process decisions for devflow, each with the evidence and sources behind it, so a
decision can be re-examined later without re-deriving it. One file per decision;
[sources.md](sources.md) is the shared bibliography and lists which decisions cite
each source.

A record states the decision, the evidence (eval sets, runs, PRs), the sources, and
the condition that would reopen it. A decision that is replaced keeps its file with
status `Superseded by DNNNN`; the replacement links back.

| ID | Decision | Status | Date |
|---|---|---|---|
| [D0001](0001-quality-before-cost.md) | Quality gains are adopted at modest cost; cost cuts are a nice-to-have | Accepted | 2026-11-21 |
| [D0002](0002-step-compliance-is-a-hook.md) | Mandatory orchestrate steps are enforced by a Stop hook, not prose | Accepted | 2026-11-18 |
| [D0003](0003-orchestrator-on-sonnet.md) | The orchestrator runs on Sonnet; Opus is not adopted | Accepted | 2026-11-19 |
| [D0004](0004-intake-conformance-check.md) | Intake pauses only on review-rejecting conflicts two critic runs agree on | Accepted | 2026-11-20 |
| [D0005](0005-step-11-reviewer.md) | Step 11 stays `devflow:reviewer` | Under re-test (#86) | 2026-11-20 |
| [D0006](0006-builder-fold.md) | One builder agent carries an item test-first, behind a test guard | Accepted | 2026-11-21 |
| [D0007](0007-pr-review-critic-on-opus.md) | The PR-review design critic runs on Opus on every tier | Accepted | 2026-11-16 |
| [D0008](0008-eval-noise-bar.md) | Eval gaps of one run per set are noise | Accepted | 2026-11-18 |
| [D0009](0009-eval-optimization-done-line.md) | The eval-optimization effort ends with the #86 decision | Accepted | 2026-11-21 |
| [D0010](0010-evals-gate-before-merge.md) | devflow changes are evaluated before merge, on a change-gated queue | Accepted | 2026-11-21 |
| [D0011](0011-intent-based-keep-rule.md) | One replay set, two reports, a keep rule fixed by declared intent | Accepted | 2026-11-21 |
| [D0012](0012-lanes-measure-first.md) | Lighter per-card lanes wait on per-step data from normal runs | Accepted | 2026-11-21 |
| [D0013](0013-claude-skills-ci.md) | claude-skills gets deterministic CI on pull requests and an eval-tier label | Accepted | 2026-11-21 |
| [D0014](0014-rulesets-in-both-repos.md) | Branch rules are rulesets in both repositories | Accepted | 2026-11-21 |
| [D0015](0015-moho-ruleset-per-branch.md) | moho's rulesets match each branch's role | Proposed | 2026-11-21 |
| [D0016](0016-agents-may-merge.md) | Agents may merge once automated checks and review pass | Accepted | 2026-11-21 |
