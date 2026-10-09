# Agents

Worker agents are launched by the orchestrator, run in their own context, and return a
report. All load the `rust-standards` skill, see the repository and the project's
`CLAUDE.md`, and do not see the orchestrator's conversation. Definitions:
`plugins/devflow/agents/`.

| Agent | Model | Tools | Writes | Role |
|---|---|---|---|---|
| `devflow:test-writer` | sonnet | Read, Grep, Glob, Edit, Write, Bash | tests only | Failing tests from criteria and test map |
| `devflow:implementer` | sonnet | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context`/`detect_changes` | production code | Minimum code to pass; behavior-preserving refactors |
| `devflow:test-critic` | opus | Read, Grep, Glob, Bash | nothing | Portfolio review of fresh tests |
| `devflow:reviewer` | opus | Read, Grep, Glob, Bash, GitNexus `impact`/`context`/`detect_changes` | nothing | Diff review against the spec |

No worker's tool list includes `Agent`, so workers cannot spawn subagents; that keeps
fan-out at the orchestrator. `test-critic` and `reviewer` carry `maxTurns: 40`.

GitNexus tools are used when available; when the project's `CLAUDE.md` calls for
code-graph checks and the tools are missing, the agent says so in its report.

## test-writer

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

## reviewer

Sees only the diff (`git diff <base>...HEAD` plus uncommitted work) and the issue body.
Reports only:

- correctness bugs, with the triggering input or sequence;
- acceptance criteria unmet, or met only by a test that does not assert them;
- missing or weak tests for new behavior;
- unsound `unsafe`, API misuse, swallowed errors, panics in library code;
- frame-budget regressions in hot paths;
- scope creep beyond the spec;
- docs drift, when the project names a docs directory.

Each finding cites `file:line` with a one-line failure scenario. If nothing material
remains, it says exactly that.
