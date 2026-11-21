# Sources

External sources cite the claim they support. Internal evidence (eval sets, runs) is
cited in each decision; scored set reports live outside this repository, so each
decision quotes the numbers it relies on.

| ID | Source | Supports | Cited by |
|---|---|---|---|
| S1 | Anthropic, [Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (2026-01-09) | Grade outcomes, not paths; read transcripts to validate graders; pass@k / pass^k measure reliability over repeated runs | D0008, D0010, D0011, D0012 |
| S2 | Anthropic, [Building effective agents](https://www.anthropic.com/research/building-effective-agents) (2024-12) | Start with the simplest workflow; routing sends easy inputs to a cheaper path when classification is reliable | D0002, D0012 |
| S3 | Claude Code docs, [Plugin evals](https://code.claude.com/docs/en/plugin-evals) | `claude plugin eval`: cases plus graders in isolated sessions, CI gating; runs count toward plan usage | D0010, D0013 |
| S4 | AgentAssay, [arXiv 2603.02601](https://arxiv.org/abs/2603.02601) (2026-03, not peer reviewed) | Agent CI gates as pass / fail / inconclusive with sequential tests to cut trials | D0010, D0011 |
| S5 | Claude Code docs, [GitHub Actions](https://code.claude.com/docs/en/github-actions); [claude-code-base-action](https://github.com/anthropics/claude-code-base-action) inputs and outputs | Headless runs in Actions; the `execution_file` JSON execution log is the source of run records | D0012 |
| S6 | GitHub Security Lab, [Preventing pwn requests](https://securitylab.github.com/resources/github-actions-preventing-pwn-requests/) | `pull_request_target` runs with a write token in the base repository's context; it is safe only when it never checks out or runs the PR's code | D0013 |
