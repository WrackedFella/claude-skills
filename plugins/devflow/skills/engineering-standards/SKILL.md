---
name: engineering-standards
description: "Language-neutral engineering standards: layering, domain modeling, error handling, async, observability, testing (TDD, mutation), comment hygiene, complexity and abstraction rules. Load before writing, refactoring or reviewing code in any language; language skills add their own deltas."
user-invocable: false
---

# Engineering standards

Principle-first, language-neutral standards. A project's own `CLAUDE.md` may narrow or
override them; it wins. A language skill adds only what is specific to that language.

## Architecture and layering

- **Dependencies point inward:** entry/presentation → domain/simulation →
  infrastructure (I/O, assets, platform, GPU). Domain code never names concrete
  infrastructure types in its public surface; it depends on abstractions it defines.
- **SOLID, weighted to SRP and DIP.** If a type's single responsibility can't be named
  in one sentence, split it.
- **Lightweight domain modeling.** Wrapper types with validating constructors where a
  primitive carries rules; plain data types otherwise. No builder/factory ceremony where
  a literal or a default value will do.
- **Variation lives in data, not type hierarchies.** Prefer closed sets of alternatives and
  data-driven composition over type hierarchies. Use open polymorphism only for genuinely open,
  plugin-like sets.
- **Extend by registration, not a growing conditional chain.** Pluggable subsystems use a
  registry or a table keyed by id, so adding a variant touches the variant only.

## Resources and memory

- **Stream, don't materialize** unbounded or large data; stream or memory-map large
  assets.
- **Keep I/O and platform types behind the infrastructure boundary.**

## Validation and errors

- **Validate at the boundary** (parsing, deserialization, config/asset load) into a
  typed failure value, not a crash.
- **Types enforce their invariants** in a validating constructor or conversion. Make
  illegal states unrepresentable.
- **Failure values for recoverable failures; fail fast only for broken invariants**
  (programmer error). Prefer stating why the failure cannot happen in the fail-fast
  message.
- **Never silently drop, truncate or skip:** no discarded fallible results, no
  swallowing a required value (into a default or into absence/null), no
  log-and-continue in a loop. Malformed
  required data is a typed error naming the offending item.

## Dependencies and conversions

- **Pass dependencies explicitly** (fields, parameters, constrained generics). No
  service locators or global mutable singletons; wire everything at composition.
- **Too many parameters means too many responsibilities.** Split the type.
- **Hand-written conversions between layers**, next to the target type.

## Async and cancellation

- **Never block the runtime:** blocking or CPU-heavy work goes to a dedicated worker
  pool or the engine's workers.
- **Propagate cancellation through the task tree.**

## Type system

- An explicit optional type for absence, closed sets of alternatives for choices, never
  sentinel values.
- Warnings are errors in CI (a curated lint set); lints don't rot.

## Observability

- **Structured logging fields**, not interpolated strings.
- **Spans around meaningful units of work** (frame stages, asset loads, jobs).
- **Intentional levels:** `error` an operator must see; `warn` recoverable degradation;
  `info` state transitions; `debug`/`trace` off by default.
- **Emit counts, durations and deltas** so anomalies show without reading code.

## Error contracts at library/package boundaries

- A library's public error type is its contract; callers can branch on it.
- Don't leak dependency error types; wrap them.
- The error type is a versioned surface: additive alternatives behind a
  forward-compatibility marker.

## Events and decoupling

- Call follow-on effects directly in an obvious sequence by default.
- Use an event channel only for real decoupling needs: many independent
  consumers, cross-system fan-out, or frame-deferred handling.
- Event names are past tense (`EntitySpawned`); payloads are immutable and carry
  enough data that consumers needn't re-fetch. A published event shape is a contract.

## Testing

- **Priority:** domain/simulation rules and regression-prone contracts (math,
  serialization formats, state machines), not a line-coverage number.
- **Test-first for domain logic and bug fixes touching it.** The project defines which
  tests need human review before implementation; tests are the spec.
- **Test-after is fine** for thin adapters, plumbing and trivial conversions.
- **Tests must prove behavior:** agent-written tests must survive mutation testing on
  the changed code. Strengthen a test when a mutant survives; never weaken code to
  dodge one.
- **Bug fixes:** reproduce as a failing regression test when feasible; if skipped, say
  why.
- **Ask what failure a test prevents.** No tests that only assert a value constructs.
- **Naming:** test names state the scenario and the expected result, in the language's
  convention. Unit tests grouped by behavior; integration tests kept apart from unit
  tests.
- **Structure:** arrange / act / assert as blank-line-separated blocks, no labels.
- **Gate slow tests** with an ignore marker (with a reason) or a feature flag.

## Comments

A comment earns its place only by preserving what the code cannot: why it is shaped
this way, a constraint, invariant, tradeoff, workaround or gotcha.

- **Keep:** why-comments; doc comments that state an item's contract (behavior, errors,
  failures, invariants); canonical reference links; `TODO:` with what to do.
- **Remove:** narration of what the next line does; restated names or signatures;
  history (what it used to be, what changed); settled decisions and alternatives
  considered (they belong in an ADR or work item); references to work-item IDs,
  phases, PRs or sessions; commented-out code.
- **Flag, don't change:** bare `TODO`, `FIXME`, `HACK`, `XXX`.
- When unsure whether a comment is "why" or "what", keep it and flag it.

## Complexity and abstraction

- **Weigh changes by parts and depth** (types, interfaces, modules, library/package
  boundaries, indirection hops), not lines. LOC is a tie-breaker.
- **Extract a helper at the third reuse,** and only if it saves more than it costs.
  Don't extract when the raw line is clearer than any name.
- **Exception:** in application entry/initialization code, fold multi-line wiring into a
  named helper even at one call site, kept beside the setup code.
- **Abstractions are faithfully named** with no hidden clauses; docs match behavior.
