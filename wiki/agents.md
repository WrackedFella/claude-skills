# Agents

Worker agents are launched by the orchestrator (the review agents by `pr-review`), run in their own context, and return a
report. All preload `engineering-standards`, apply the further standards named in their brief
(the orchestrator resolves the project's `Standards` setting to skill file paths), see the repository and the project's
`CLAUDE.md`, and do not see the orchestrator's conversation. Definitions:
`plugins/devflow/agents/`.

| Agent | Model | Tools | Writes | Role |
|---|---|---|---|---|
| `devflow:test-writer` | sonnet | Read, Grep, Glob, Edit, Write, Bash | tests only | Failing tests from criteria and test map |
| `devflow:implementer` | sonnet | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context`/`detect_changes` | production code | Minimum code to pass; behavior-preserving refactors |
| `devflow:test-critic` | opus | Read, Grep, Glob, Bash | nothing | Portfolio review of fresh tests |
| `devflow:reviewer` | opus | Read, Grep, Glob, Bash, GitNexus `impact`/`context`/`detect_changes` | nothing | Diff review against the spec, in orchestrate |
| `devflow:defect-finder` | opus | Read, Grep, Glob, Edit, Write, Bash, GitNexus `impact`/`context` | scratch tests | Demonstrated defects in a PR (full tier) |
| `devflow:design-critic` | opus; `pr-review` runs it on fable for the full tier | Read, Grep, Glob, Bash, GitNexus `impact`/`context` | nothing | Structure against written rules and Changeability |
| `devflow:refuter` | opus | Read, Grep, Glob, Edit, Write, Bash | scratch tests | Disproves one finding, or confirms a fix |

No worker's tool list includes `Agent`, so workers cannot spawn subagents; that keeps
fan-out at the orchestrator. `test-critic` and `reviewer` carry `maxTurns: 40`,
`defect-finder` 60, `design-critic` 50 and `refuter` 30.

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

Sees only the diff (`git diff <base>...HEAD` plus uncommitted work) and the issue body. Called by `orchestrate` before the PR.
Reports only:

- correctness bugs, with the triggering input or sequence;
- acceptance criteria unmet, or met only by a test that does not assert them;
- missing or weak tests for new behavior;
- API misuse, swallowed errors, and violations of the Standards listed in the brief (for example unsound low-level/unsafe code, hot-path regressions where the standards name them);
- scope creep beyond the spec;
- docs drift, when the project names a docs directory.

Each finding cites `file:line` with a one-line failure scenario. If nothing material
remains, it says exactly that.

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
  from `engineering-standards` Changeability, broken ADR or architecture rules (B4),
  scope beyond the spec. On the light tier it also checks B2 and B3.
- **refuter.** One finding per call, with a mandate to disprove it: reruns the test
  itself (B2 also on reverted code), checks the rule, the code path and the named item,
  and may lower the severity. Mode `fixed` rechecks an earlier blocker at a new head.
  Reports `CONFIRMED`, `REFUTED`, `FIXED` or `NOT FIXED` with what it ran.
