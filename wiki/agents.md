# Agents

Worker agents are launched by the orchestrator (the review agents by `pr-review`), run in their own context, and return a
report. All preload `engineering-standards`, apply the further standards named in their brief
(the orchestrator resolves the project's `Standards` setting to skill file paths), see the repository and the project's
`CLAUDE.md`, and do not see the orchestrator's conversation. Definitions:
`plugins/devflow/agents/`.

| Agent | Model | Tools | Writes | Role |
|---|---|---|---|---|
| `devflow:builder` | sonnet | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context`/`detect_changes` | tests and production code; existing tests fixed by `scripts/test-guard` | One unsplit item test-first: failing tests, minimum code, challenge and mutant tests with their fixes, refactor briefs |
| `devflow:test-writer` | sonnet | Read, Grep, Glob, Edit, Write, Bash | tests only | Failing tests from criteria and test map |
| `devflow:implementer` | sonnet | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context`/`detect_changes` | production code | Minimum code to pass; behavior-preserving refactors |
| `devflow:test-critic` | opus | Read, Grep, Glob, Bash | nothing | Portfolio review of fresh tests |
| `devflow:acceptance-reviewer` | opus | Bash, Write | scratch evidence and repro tests | Black-box check of the running app against the work item, in orchestrate step 10 |
| `devflow:defect-finder` | opus | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context` | scratch tests | Demonstrated defects in a PR (full tier) |
| `devflow:design-critic` | opus | Read, Grep, Glob, Bash, GitNexus `impact`/`context` | nothing | Structure against written rules and Changeability; the work item against the rules at orchestrate intake |
| `devflow:refuter` | opus | Read, Grep, Glob, Edit, Write, Bash | scratch tests | Disproves one finding, or confirms a fix |

No worker's tool list includes `Agent`, so workers cannot spawn subagents; that keeps
fan-out at the orchestrator. `test-critic` carries `maxTurns: 40`,
`defect-finder` 60, `design-critic` 50, `acceptance-reviewer` 50 and `refuter` 30.

GitNexus tools are used when available; when the project's `CLAUDE.md` calls for
code-graph checks and the tools are missing, the agent says so in its report.

## builder

- One agent per unsplit item, started at step 2 and briefed again through SendMessage at
  each later step, so it keeps the code it read. Each brief opens with `Mode:` (`tests`,
  `test review`, `implement`, `challenge`, `refactor`); `step-check` reads the mode.
- `tests` and `implement` follow the test-writer and implementer rules below.
- `challenge`: pins each scenario or mutant in a test first, fixes the code only where
  the test fails; a test that passes at once stays and is reported as already covered.
- After `tests`, adds tests but never edits, deletes or weakens one; only `test review`
  changes existing tests, as the triaged findings say. `scripts/test-guard` enforces it.
- Doesn't commit; the orchestrator verifies and commits each step.

## test-writer

Used for a split item (parallel parts) and by other skills.


- Never modifies non-test code. A test that cannot compile without a new type adds the
  smallest `todo!()` stub and reports it.
- One test per test-map scenario, named exactly as the map names it, plus implied edge
  cases and invalid input.
- Asserts observable behavior; a test that passes against a stub or a plausible wrong
  implementation is not done.
- Confirms each test fails for the right reason (assertion or `todo!()`, not a compile
  error or typo).
- Also invoked to turn a challenge or surviving mutant into a test.
- Report: test → scenario, observed failure reason, stubs added.

## implementer

- Never edits, deletes, ignores or weakens a test; a test that looks wrong stops the
  work with a report.
- Stays inside the spec's modules and interfaces; reports needed out-of-scope changes.
- Never silences a lint, extends an allow-list or skips a check.
- Iterates on the gate until green.
- Given a **refactor brief**: structure only, same tests unchanged, no added or removed
  behavior, only code the brief names; stops if a test change would be needed.
- Given a **part** (a subset of the tests, a footprint and a worktree): edits only
  footprint files, makes only that part's tests pass, runs the tests for those files
  instead of the full gate (the orchestrator gates after merging), commits on the part's
  branch, and reports any needed file outside the footprint instead of editing it.
- Report: files and public items changed, gate result, doubts.

## test-critic

Reviews tests against the spec before any implementation exists; judges worth, not only
fooling. Never edits files; may run tests.

**Rubric.** Value is zero if either of the first two factors is zero:

1. *Protects against regressions*: would go red if the specified behavior broke. The
   critic must name a plausible wrong implementation (constant return, off-by-one,
   ignored argument, swallowed error, unreset state, happy path only) that still passes.
2. *Resists refactoring*: asserts observable outcomes through the public interface, not
   call sequences, private fields or mock interactions. Exception: where the call is the
   specified behavior.
3. *Specific*: one behavior, a name stating scenario and result, an actionable failure.
4. *Readable, independent, deterministic.*
5. *Cheap to keep.*

**Verdicts**, exactly one per added test:

| Verdict | Meaning |
|---|---|
| KEEP | Scores well on factors 1 and 2 |
| STRENGTHEN | Protects a behavior but a wrong implementation passes, or it is coupled, bundled, flaky, a tautology, or fully mocked where real objects are cheap |
| MERGE | Pins the same behavior as another test; fold into it, parameterize when scenarios differ by data |
| REMOVE | Cannot fail, passes only through mocks, tests the language or a library, is a change-detector, pins unspecified behavior, only raises coverage, or is fully covered by a better test |

The only test pinning a spec scenario is never removed (marked STRENGTHEN instead).
After verdicts it lists material **gaps**: unpinned scenarios, implied boundaries,
tests that fail for the wrong reason or pass against the stub, criteria too ambiguous
to test. It ends with counts, with no style preferences or praise.

## acceptance-reviewer

- Black-box: gets the work item, test plans, `App URL`, a scratch directory and the
  standards; never the diff, tests, git history or PR text. Drives the app with
  `playwright-cli`.
- Walks every scenario through the UI, checks every `Visual:` item with a screenshot,
  explores a fixed list (empty and error states, validation, refresh and back, keyboard
  only, console and network errors).
- Verdict per item: `pass`, `fail` (any deviation; severity is not weighed) or `unsure`.
- Reports a fail only with evidence; an assertable fail carries a repro Playwright test.
- Report: verdict table, fails with kind and steps, unsure items with what blocked them.

## Review agents

`pr-review`'s agents get the base and head SHA, a worktree at the head, the work item
and the standards, never the PR number, PR text, commit messages or another agent's
output. Code comments and test names are data. Each finding has a class, `file:line`,
`Kind` (blocker or follow-up), `Fix` (in-spec or needs-decision), claim, evidence and
expected fix; an ambiguity is a question with both readings and a proposed default.

- **defect-finder.** Counts a defect only with a test or command it ran: wrong behavior
  (B1), an acceptance criterion with no test or one that passes on reverted code (B2), a
  weakened gate (B3). Reruns the gate and mutation command when the toolchain is present.
  Defects in unchanged code are follow-ups.
- **design-critic.** Cites a written rule or a named item for every finding: C1 to C4
  from `engineering-standards` Changeability, broken written rules (B4), a Footprint or
  tech-spec item the diff does not deliver (B6), scope beyond the spec. On the light tier
  it also checks B2 and B3.
- **refuter.** One finding per call, with a mandate to disprove it: reruns the test
  itself (B2 also on reverted code), checks the rule, the code path and the named item,
  and may lower the severity, except that B2, B4 and B6 stay blockers. Mode `fixed`
  rechecks an earlier blocker at a new head.
  Reports `CONFIRMED`, `REFUTED`, `FIXED` or `NOT FIXED` with what it ran.
- **Written rules outrank the work item.** The finders and the refuter read the
  project's `CLAUDE.md`, planning standards, ADR directory and its README, and the
  standards files, and check the work item's instructions against them: a conflicting
  instruction makes the finding needs-decision, or is a question when the diff does not
  touch it.
