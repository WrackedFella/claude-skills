# Test review (Domain-test review: agent)

The tests are the only definition of done the implementer will see, so judge them
before they steer an implementation. Delegate to `devflow:test-critic` with the issue
number, the base branch and the `Standards:` line. It sees the spec and the tests, not the test-writer's
reasoning, and returns a verdict per test (KEEP, STRENGTHEN, MERGE, REMOVE) plus gaps.

Triage its findings yourself. Accept one only if it names a concrete wrong behavior
the tests let through, a spec scenario they don't pin, or a reason the test is not
worth keeping that you can verify. Then:

- STRENGTHEN and gaps: send to `devflow:test-writer`, which adds or tightens tests and
  confirms they fail for the right reason.
- MERGE and REMOVE: have the test-writer delete or fold the test. This is the one
  place tests are removed, before implementation, to improve them; it is never a way
  to get green. Refuse a removal that leaves a spec scenario without a pinning test.
  Never loosen an assertion to answer a finding.

Commit (`test(scope): ...`) and push, then re-run the critic only if a round changed
tests materially.

If a finding shows the acceptance criteria are ambiguous or untestable as written, that
is a spec problem: comment on the issue and stop. The PR body gets a "Test review"
section: the verdict counts, tests removed or merged with their reasons, and findings
still open or rejected with reasons. The tests are pushed before implementation
starts, so they can be read on GitHub throughout.
