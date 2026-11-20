# Acceptance review (Acceptance review: agent)

A separate reviewer that uses the running app as a user would is the check on what the
tests encode. It is black-box: it sees the spec and the app, never the code. The gate
carries everything that can be asserted; this step finds what the gate missed and turns
it into more gate.

## Each round (at most 2)

1. Start the app with the project's `App start command`. Create the scratch directory
   `/tmp/devflow-acceptance/<issue>/round-<n>`.
2. Delegate to `devflow:acceptance-reviewer`. The brief holds only the `Read work item:`
   line, the card's test plan, the feature test plan (from the parent feature issue), the
   `App URL`, the scratch directory, the `Standards:` line and the round; in round 2, the
   items to recheck. Never the diff, branch name, test files, commit messages or PR text.
3. Run the `App stop command`, whatever the outcome.
4. Triage each fail yourself. Accept it only when its evidence shows the spec, the
   standards or a plain user expectation violated; record each rejection with its reason.
   - **Assertable:** the builder (`Mode: tests`) turns the repro file into a failing
     acceptance test in the suite; commit it (`test(scope): ...`), push, and add its SHA
     to the guard's `--allow` list. Then the builder (`Mode: implement`) fixes it,
     followed by the gate, the acceptance run and both guards.
   - **Judgment:** the builder (`Mode: implement`)
     gets the screenshot and the `Visual:` statement;
     then the gate, the acceptance run and the guard.
5. Run round 2 only if round 1 had an accepted fail, rechecking those items.

## After the last round

- An acceptance test still red never ships; the gate already holds that.
- A judgment fail still standing: pause, with its screenshots and the statement.
- Each `unsure` ships, listed under manual verification with its evidence; PR review
  gives cards with `Visual:` items `Sign-off: human`.

## Evidence and budget

In GitHub Actions, the workflow uploads `/tmp/devflow-acceptance/` as a run artifact;
link the run (`$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID`).
Elsewhere, list the evidence paths. Record the reviewer's token usage per round, per
model and by kind (input, output, cache read, cache write), or say that the runtime did
not report it.

## PR section "Acceptance review"

A verdict table (each scenario, `Visual:` item and exploration finding: verdict and
evidence), accepted fails with the tests and fixes they produced, rejected fails with
reasons, `unsure` items, rounds used, tokens and the evidence link.
