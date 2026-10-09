# Parallel parts

Implementation of a work item whose tech spec marks two or more parts with disjoint
footprints. A footprint overlap found while reading the code collapses the parts into
the single `devflow:implementer` call of step 3.

1. Confirm the footprints are disjoint by reading the spec and the code. Merge any
   parts that share a file; if one part remains, stop here and use the single call.
2. Pick the model per part: `sonnet` for bounded work against the spec; `opus` only for
   a part whose design the spec leaves open or that is delicate (concurrency, unsafe,
   numerics). Record the choice and why.
3. In one message, issue one Agent call per part, each `devflow:implementer`,
   `isolation: "worktree"`, foreground (`run_in_background: false`), with the tech
   spec, the part's tests and footprint, and the instruction to commit on its own
   branch. Calls issued in one message run concurrently when the host allows it; where
   it runs them one at a time (headless runs force foreground), the parts still
   complete, only slower, so correctness never depends on concurrency. Wait for every
   report before continuing.
4. Merge the part branches into the work branch one at a time (`git merge --no-ff`).
   Disjoint footprints merge cleanly; a conflict means the footprints were not
   disjoint: abort that merge, redo the conflicting parts as a single
   `devflow:implementer` call, and note the footprint error in the PR.
5. Run the gate on the merged result; a failure goes to a single `devflow:implementer`.
   Remove the worktrees and part branches, then push the work branch.

Every later step runs once, on the merged work.
