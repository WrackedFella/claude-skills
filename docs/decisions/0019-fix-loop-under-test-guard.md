# D0019 The review fix loop runs under the test guard

- **Status:** Proposed, 2026-11-23 (devflow review 2.3)
- **Decision:** `respond` runs `scripts/test-guard` from the reviewed head (and `e2e-guard` where the project has acceptance tests) before every push. A commit that only adds a review finding's test is the one allowed change to test code.
- **Evidence:** orchestrate guards every builder call; `respond` guards none, and its fix job's allow-list has no guard script. The loop is unattended and ends in a merge (D0017). On the light tier the next round's only check for a weakened test is the design critic's reading.
- **Sources:** S19 (agents given failing tests pass them mostly by editing the tests; read-only tests stop that), S17.
- **Reopen when:** the fix loop moves to an agent that cannot write test files.
