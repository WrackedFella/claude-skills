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
| [D0017](0017-agent-merge-step.md) | The PR review workflow merges an eligible agent PR, pinned to the reviewed SHA | Accepted | 2026-11-21 |
| [D0018](0018-skill-scripts-on-allow-list.md) | Every script a skill calls is on the runner's allow-list, and deciding scripts are checked | Proposed | 2026-11-23 |
| [D0019](0019-fix-loop-under-test-guard.md) | The review fix loop runs under the test guard | Proposed | 2026-11-23 |
| [D0020](0020-verdict-from-a-script.md) | The PR review's verdict lines are computed by a script | Proposed | 2026-11-23 |
| [D0021](0021-wiki-does-not-restate-skills.md) | The wiki explains and links; it does not restate a skill's procedure | Proposed | 2026-11-23 |
| [D0022](0022-entry-point-skills-not-model-invocable.md) | Entry-point skills start only when named; plugin agents carry no hooks | Accepted | 2026-11-23 |
| [D0023](0023-stale-plugin-check.md) | A SessionStart hook reports a stale devflow; a cloud environment refreshes by a setup-script change | Accepted | 2026-11-23 |
| [D0024](0024-cloud-refresh-needs-one-tap.md) | Nothing outside a session can refresh a cloud environment's devflow; staleness is detected and a stamp bump is one approval | Accepted | 2026-11-23 |
| [D0025](0025-advisory-reviewer-comments-go-to-the-refuter.md) | An advisory reviewer's comments are candidates for the refuter, never findings; the trial counts what only it found | Proposed | 2026-11-24 |
| [D0026](0026-resume-needs-a-resume-comment.md) | A paused run restarts only on a comment starting with `Resume` | Accepted | 2026-11-24 |
| [D0027](0027-chains-are-queued-dependencies.md) | A chain is the set of queued cards over their issue dependencies | Accepted | 2026-11-25 |
| [D0028](0028-chain-advances-on-events-with-a-cron-backstop.md) | A chain advances on issue events, with a cron backstop, through one deterministic script | Accepted | 2026-11-25 |
| [D0029](0029-chain-cards-merge-into-dev.md) | Chain cards merge into the base branch one by one; no chain branch, no stacked PRs | Accepted | 2026-11-25 |
| [D0030](0030-chain-stops-at-human-driven-cards.md) | A chain stops at a human-driven card and runs at most a set number of cards at once | Accepted | 2026-11-25 |
| [D0031](0031-conflicts-resolved-only-when-present.md) | An agent PR's conflict with the base is resolved by a run only when one exists | Accepted | 2026-11-25 |
