---
name: rust-standards
description: Engineering standards for Rust work: layering, domain modeling, error handling, async, observability, testing (TDD, mutation), comment hygiene, complexity and abstraction rules. Load before writing, refactoring or reviewing Rust code.
user-invocable: false
---

# Rust engineering standards

Principle-first standards for a Cargo workspace (binary crates plus engine/shared
library crates). A project's own `CLAUDE.md` may narrow or override them; it wins.

Stack assumptions: stable Rust, a Cargo workspace, an async runtime or job pool,
`tracing` for observability, `thiserror` for library errors (`anyhow` in binaries),
`cargo test`/nextest plus `proptest`/`criterion` where they earn their keep,
`clippy` and `rustfmt` enforced in CI.

## Architecture and layering

- **A binary crate is a deployable; library crates are reusable units.** Split crates
  at deployable, reuse or compile-time boundaries. Justify any other split.
- **Dependencies point inward:** entry/presentation → domain/simulation →
  infrastructure (I/O, assets, platform, GPU). Domain code never names concrete
  infrastructure types in its public surface; it depends on traits it defines.
- **SOLID, weighted to SRP and DIP.** If a type's single responsibility can't be named
  in one sentence, split it.
- **Lightweight domain modeling.** Newtypes with smart constructors where a primitive
  carries rules; plain structs/enums otherwise. No builder/factory ceremony where a
  literal or `Default` will do.
- **Variation lives in data, not type hierarchies.** Prefer enums and data-driven/ECS
  composition over trait-object hierarchies. Use `dyn Trait` only for genuinely open,
  plugin-like sets.
- **Extend by registration, not a growing `match`.** Pluggable subsystems use a
  registry or a table keyed by id, so adding a variant touches the variant only.

## Resources and memory

- **Stream, don't materialize** unbounded or large data; stream or memory-map large
  assets.
- **Keep I/O and platform types behind the infrastructure boundary.**
- **Hot paths:** no per-frame allocation or needless dynamic dispatch in inner loops;
  reuse buffers. Measure before optimizing, but don't design allocation in.

## Validation and errors

- **Validate at the boundary** (parsing, deserialization, config/asset load) into a
  typed `Err`, not a panic.
- **Types enforce their invariants** in `new(..) -> Result` or `TryFrom`. Make illegal
  states unrepresentable.
- **`Result` for recoverable failures; `panic!`/`unwrap`/`expect` only for broken
  invariants** (programmer error). Prefer `expect("why this cannot fail")`.
- **Never silently drop, truncate or skip:** no `let _ = fallible();`, no
  `.ok()`/`.unwrap_or_default()` swallowing a required value, no log-and-continue in a
  loop. Malformed required data is a typed error naming the offending item.

## Dependencies and conversions

- **Pass dependencies explicitly** (fields, parameters, trait-bounded generics). No
  service locators or global mutable singletons; wire everything at composition.
- **Too many parameters means too many responsibilities.** Split the type.
- **Hand-written conversions between layers** (`From`/`TryFrom`, `to_domain()`),
  next to the target type.

## Async and cancellation

- **Cancellation is drop-based:** keep async code cancel-safe with RAII guards; signal
  with `select!` plus a `CancellationToken` or shutdown channel.
- **Never block the runtime:** blocking or CPU-heavy work goes to `spawn_blocking`,
  `rayon` or the engine's workers.
- **Propagate cancellation through the task tree.**

## Type system

- `Option` for absence, enums for alternatives, never sentinel values.
- Warnings are errors in CI (`-D warnings`, curated clippy set); lints don't rot.
- `#[non_exhaustive]` where forward compatibility matters.

## Observability

- **`tracing` with structured fields**, not interpolated strings:
  `info!(job_id = %id, "loaded asset")`.
- **Spans around meaningful units of work** (frame stages, asset loads, jobs).
- **Intentional levels:** `error` an operator must see; `warn` recoverable degradation;
  `info` state transitions; `debug`/`trace` off by default.
- **Emit counts, durations and deltas** so anomalies show without reading code.

## Error contracts at crate boundaries

- A library's public error enum (`thiserror`) is its contract; callers can match on it.
- Don't leak dependency error types; wrap them.
- The error enum is semver surface: additive variants behind `#[non_exhaustive]`.

## Events and decoupling

- Call follow-on effects directly in an obvious sequence by default.
- Use an event channel or ECS event only for real decoupling needs: many independent
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
- **Ask what failure a test prevents.** No tests that only assert a struct constructs.
- **Naming:** `scenario_expected_result`. Unit tests in `#[cfg(test)] mod tests`,
  grouped in nested modules by behavior; integration tests in `tests/`.
- **Structure:** arrange / act / assert as blank-line-separated blocks, no labels.
- **Gate slow tests** with `#[ignore = "reason"]` or a feature flag.

## Comments

A comment earns its place only by preserving what the code cannot: why it is shaped
this way, a constraint, invariant, tradeoff, workaround or gotcha.

- **Keep:** why-comments; rustdoc that states an item's contract (behavior, errors,
  panics, invariants); canonical reference links; `TODO:` with what to do;
  `// SAFETY:` on every `unsafe` block (required).
- **Remove:** narration of what the next line does; restated names or signatures;
  history (what it used to be, what changed); settled decisions and alternatives
  considered (they belong in an ADR or work item); references to work-item IDs,
  phases, PRs or sessions; commented-out code.
- **Flag, don't change:** bare `TODO`, `FIXME`, `HACK`, `XXX`.
- When unsure whether a comment is "why" or "what", keep it and flag it.

## Complexity and abstraction

- **Weigh changes by parts and depth** (types, traits, modules, crates, indirection
  hops), not lines. LOC is a tie-breaker.
- **Extract a helper at the third reuse,** and only if it saves more than it costs.
  Don't extract when the raw line is clearer than any name.
- **Abstractions are faithfully named** with no hidden clauses; docs match behavior.
- **Exception:** in `main`/engine init, fold multi-line wiring into a named helper even
  at one call site (`init_renderer(&cfg)?`), kept beside the setup code.

## Workflow

- In interactive sessions, don't commit unprompted. A skill or work item that includes
  a commit or PR step is the authorization for that step.
- Never merge PRs or enable auto-merge; a human merges.
- Consider blast radius before destructive or hard-to-reverse actions; confirm first.
- Out-of-scope findings become a tracked work item, not scope creep.
- Never resolve a reviewer's thread; reply with what changed and leave status to them.
- Shared artifacts (skills, templates, docs) state standards impersonally.
