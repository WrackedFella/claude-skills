# Orchestration

`/devflow:orchestrate [issue]` drives one ready work item red-green-refactor to a PR. It
coordinates subagents and attacks their work; it does not write the bulk of the code.
Challenges, triage and decisions are its own judgment work.

## 1 Pipeline

The skill is the procedure; this table indexes it.

| Step | Purpose | Rules |
|---|---|---|
| Standing rules | Gate after every change set, no weakened tests, no merge, push after every commit, foreground subagents when headless, issue body as the only spec | [Skill preamble](../plugins/devflow/skills/orchestrate/SKILL.md) |
| Guards | Tests and acceptance tests stay the spec; read-only by script | [Test guard](../plugins/devflow/skills/orchestrate/SKILL.md#test-guard), [Acceptance tests](../plugins/devflow/skills/orchestrate/SKILL.md#acceptance-tests) |
| 1 Intake | Claim a ready item, resume earlier work, check the card against the written rules before any code | [1. Intake](../plugins/devflow/skills/orchestrate/SKILL.md#1-intake) |
| 2 Failing tests | Tests that fail for the right reason, then the `Domain-test review` setting | [2. Failing tests](../plugins/devflow/skills/orchestrate/SKILL.md#2-failing-tests), [Test review](../plugins/devflow/skills/orchestrate/SKILL.md#test-review-agent), [`test-review.md`](../plugins/devflow/skills/orchestrate/test-review.md) |
| 3 Implementation | Minimum code that passes, one call or one per disjoint part | [3. Implementation](../plugins/devflow/skills/orchestrate/SKILL.md#3-implementation), [Parallel parts](../plugins/devflow/skills/orchestrate/SKILL.md#parallel-parts), [`parallel-parts.md`](../plugins/devflow/skills/orchestrate/parallel-parts.md) |
| 4 Adversarial challenge | Orchestrator attacks the code; each finding becomes a test (at most 2 rounds) | [4. Adversarial challenge](../plugins/devflow/skills/orchestrate/SKILL.md#4-adversarial-challenge-at-most-2-rounds) |
| 5 Refactor | Structure improves under green, then `/simplify` | [5. Refactor](../plugins/devflow/skills/orchestrate/SKILL.md#5-refactor) |
| 6 Mutation testing | Survivors become stronger tests, never weaker code | [6. Mutation testing](../plugins/devflow/skills/orchestrate/SKILL.md#6-mutation-testing) |
| 7 Comment audit | Comments in the diff tightened | [7. Comment audit](../plugins/devflow/skills/orchestrate/SKILL.md#7-comment-audit) |
| 8 Docs | Project wiki kept current | [8. Docs](../plugins/devflow/skills/orchestrate/SKILL.md#8-docs) |
| 9 Platform coverage | Full-platform CI when behavior may differ per platform | [9. Platform coverage](../plugins/devflow/skills/orchestrate/SKILL.md#9-platform-coverage) |
| 10 Acceptance review | Black-box check of the running app (at most 2 rounds) | [10. Acceptance review](../plugins/devflow/skills/orchestrate/SKILL.md#10-acceptance-review-at-most-2-rounds), [`acceptance-review.md`](../plugins/devflow/skills/orchestrate/acceptance-review.md) |
| 11 Independent review | Fresh-context review of the diff against the issue (at most 2 rounds) | [11. Independent review](../plugins/devflow/skills/orchestrate/SKILL.md#11-independent-review-at-most-2-rounds) |
| 12 Ship | PR into the base branch, Status `In review` | [12. Ship](../plugins/devflow/skills/orchestrate/SKILL.md#12-ship) |

## 2 Delegation

| Work | Delegate | Model |
|---|---|---|
| Broad read-only sweep needed only as a conclusion | ad hoc subagent | haiku |
| Steps 2-6 of an unsplit item and fixes from steps 10-11, in one context | `devflow:builder` | sonnet |
| Tests of a split item | `devflow:test-writer` | sonnet |
| One part of a split item, its later code briefs | `devflow:implementer` | sonnet (opus for a delicate or open-design part) |
| Intake conformance check (work item against written rules), run twice | `devflow:design-critic`, `Mode: intake` | opus |
| Test review | `devflow:test-critic` | opus |
| Acceptance review | `devflow:acceptance-reviewer` | opus |
| Final review | `devflow:reviewer` | opus |
| Challenges, triage, scope decisions; running commands and reading their output | orchestrator | session model |

## 3 Why the acceptance guards exist

### 3.1 Acceptance tests

Applies when the project sets an `Acceptance command` and the item's test map has `e2e`
entries.

- Step 2 writes the `e2e` tests with the rest and verifies them red with the app
  started; a failure because the app is down does not count.
- Wherever the gate runs, the acceptance run follows: `App start command`,
  `Acceptance command`, `App stop command` (always).
- After every implementer call, [`scripts/e2e-guard`](../plugins/devflow/scripts/e2e-guard)
  fails on a change to an acceptance test path outside the step 2 and later
  test-writer commits, and on any added `test.only`, `test.skip`, `test.fixme` or
  `test.slow`. Claude models that game tests do it mostly by editing them, and read-only
  tests stop that at no cost to honest work ([ImpossibleBench](https://arxiv.org/abs/2510.20270)).

### 3.2 Acceptance review (step 10)

Applies with `Acceptance review: agent` to items with `e2e` entries or `Visual:` items.
The tests cover what can be asserted; this step checks what they encode against the
app itself. A separate evaluator that uses the running app is the strongest single
check on agent work, and agents grading their own work skew positive
([Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)).

| Rule | Why |
|---|---|
| Black-box: the brief holds the work item, test plans, `App URL` and standards; tools are Bash and Write in a scratch directory; no diff, tests, git history or PR text | Reading the code anchors the reviewer to what it does; git history leaks answers |
| Every scenario is walked through the UI, not by running the suite | Catches tests that pass against stubs or wrong routes |
| Every `Visual:` item is checked at its viewport with a screenshot | Evidence for the human sign-off |
| A fixed exploration list (empty and error states, validation, refresh and back, keyboard only, console and network errors) | Reviewers probe superficially without one, and drift without a bound |
| Verdicts `pass`, `fail`, `unsure`; any deviation is a fail; calibration examples in the prompt | Reviewers talk themselves out of defects; `unsure` keeps them from guessing |
| A fail counts only with evidence; an assertable one carries a repro test | A reviewer asked to find problems always finds something |
| Accepted assertable fails become acceptance tests (allowed in the guard), then fixes | The gate grows with every finding |
| At most 2 rounds; a standing judgment fail pauses; `unsure` ships under manual verification | More rounds raise test gaming; an exit to a person lowers it |
| Cards with `Visual:` items get `Sign-off: human` from `pr-facts` | Vision models miss most small visual defects |

## 4 PR contents

Issue link, gate output, test review (when run), mutation counts, challenges raised,
refactorings made, docs report, acceptance tests with the last acceptance run and guard
results and the Acceptance review section (when they apply), reviewer findings and resolutions, and manual
verification still required.

## 5 Failure and stop conditions

A **pause** comments the questions on the issue (with proposed defaults), labels it
`agent-paused` and stops; a person's comment starting with `Resume` restarts the run, which resumes from the
pushed branch. See [Unattended runs](runtimes.md#unattended-runs).

| Condition | Action |
|---|---|
| Issue not ready | Pause, listing what is missing |
| Board already shows `In progress` | Another session holds it; stop |
| Board queue empty (`board next` exit 3) | Report; stop |
| Ambiguous or untestable criteria | Pause |
| Fix would change scope or a public contract | Pause (interactive: ask the user) |
| `Domain-test review: required` | Pause at the checkpoint after the failing tests |
| `e2e-guard` fails | Restore the acceptance tests and re-brief the agent |
| `test-guard` fails | Restore the removed or rewritten test code and re-brief the agent |
| `step-check` blocks the stop (headless) | Run the named steps, then finish; report any the skill exempts |
| Acceptance review: a judgment fail stands after round 2 | Pause, with its screenshots |
| Headless run (`GITHUB_ACTIONS=true`) | No board call, nothing reported; Board sync moves Status |
| Board unreachable (`board` exit 5) | Skip all board steps; PR body lists only a Status change no event covers |
