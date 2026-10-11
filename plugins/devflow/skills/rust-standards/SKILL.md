---
name: rust-standards
description: "Rust-specific engineering standards layered on engineering-standards: crate layout, Result/panic rules, thiserror/anyhow, async cancellation, tracing, test conventions, rustdoc and unsafe comments. Load before writing, refactoring or reviewing Rust code."
user-invocable: false
---

# Rust engineering standards

Apply `engineering-standards` first; it holds the language-neutral rules. This skill
adds only the Rust deltas, for a Cargo workspace (binary crates plus engine/shared
library crates). A project's own `CLAUDE.md` may narrow or override them; it wins.

Stack assumptions: stable Rust, a Cargo workspace, an async runtime or job pool,
`tracing` for observability, `thiserror` for library errors (`anyhow` in binaries),
`cargo test`/nextest plus `proptest`/`criterion` where they earn their keep,
`clippy` and `rustfmt` enforced in CI.

## Architecture and layering

- **A binary crate is a deployable; library crates are reusable units.** Split crates
  at deployable, reuse or compile-time boundaries. Justify any other split.
- **In Rust:** a closed set is an enum or ECS composition; open polymorphism is
  `dyn Trait`.

## Resources and memory

- **Hot paths:** no per-frame allocation or needless dynamic dispatch in inner loops;
  reuse buffers. Measure before optimizing, but don't design allocation in.

## Validation and errors

- **Failure values are `Result`:** validate into a typed `Err`, not a panic;
  validating constructors are `new(..) -> Result` or `TryFrom`.
- **`panic!`/`unwrap`/`expect` only for broken invariants.** Prefer
  `expect("why this cannot fail")`.
- **Never silently drop:** no `let _ = fallible();`, no `.ok()`/`.unwrap_or_default()` swallowing a required value.

## Dependencies and conversions

- Conversions between layers use `From`/`TryFrom` or `to_domain()`.

## Async and cancellation

- **Cancellation is drop-based:** keep async code cancel-safe with RAII guards; signal
  with `select!` plus a `CancellationToken` or shutdown channel.
- Offload with `spawn_blocking` or `rayon`.

## Type system

- `Option` for absence.
- Enforce with `-D warnings` and clippy.
- `#[non_exhaustive]` where forward compatibility matters.

## Observability

- **Use `tracing`:** `info!(job_id = %id, "loaded asset")`.

## Error contracts at crate boundaries

- Define the public error as a `thiserror` enum.

## Events and decoupling

- An ECS event counts as an event channel under the decoupling rule.

## Testing

- **Naming:** `scenario_expected_result` in snake_case. Unit tests in
  `#[cfg(test)] mod tests`, nested modules for the behavior groups; integration tests
  in `tests/`.
- **Slow-test gate:** `#[ignore = "reason"]`, or a Cargo feature.

## Comments

- **Rustdoc** is the doc-comment form of the keep rule: contract statements stay.
  `// SAFETY:` on every `unsafe` block (required).
