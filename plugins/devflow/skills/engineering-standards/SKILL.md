---
name: engineering-standards
description: "Language-neutral engineering standards: layering, domain modeling, error handling, async, observability, testing (TDD, mutation), comment hygiene, complexity, abstraction and changeability rules. Load before writing, refactoring or reviewing code in any language; language skills add their own deltas."
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

## Document numbering (ISO 2145)

Applies to sections, sub-sections and milestones in every document and project.

- **Format:** Arabic numerals, one dot between levels, no trailing dot: `4`, `4.1`,
  `4.11`. Never `4.`, `IV` or `A`.
- **Start at 1.** Each level counts 1, 2, 3 within its parent.
- **Headings:** `## 4 Systems`, `### 4.1 Items and loadout`. Number to the depth the
  document needs, typically three levels, never beyond four.
- **Cross-references:** `§4.11` or "section 4.11".
- **Insertion:** a new item between two existing ones takes a sub-number (`1.1` between
  `1` and `2`) so nothing else is renumbered. Otherwise append at the end.
- **Milestones:** `<LINE>-M<n>`, e.g. `FPS-M2`, with `M<n>` equal to the roadmap phase it
  delivers where there is one. The line prefix keeps the series distinct from other
  milestone series (an engine's bare `M0`, `M1`); it parallels `<LINE>-F<n>` for features.
- **Out of scope:** feature and card IDs (`<LINE>-F<n>`, `<LINE>-F<n>-<NN>`) and ADR
  numbers (`NNNN`) keep their own schemes.
- **Why:** one hierarchical scheme gives every item a stable, sortable address, and
  inserting a bridge item never forces a renumber of references elsewhere.

## Complexity and abstraction

- **Weigh changes by parts and depth** (types, interfaces, modules, library/package
  boundaries, indirection hops), not lines. LOC is a tie-breaker.
- **Extract a helper at the third reuse,** and only if it saves more than it costs.
  Don't extract when the raw line is clearer than any name.
- **Exception:** in application entry/initialization code, fold multi-line wiring into a
  named helper even at one call site, kept beside the setup code.
- **Abstractions are faithfully named** with no hidden clauses; docs match behavior.

## Changeability

A change must not raise the cost of the next known change, and must not buy flexibility
nobody has asked for. Reversibility sets the severity: what is costly to undo after
merge blocks; what is cheap to undo becomes a follow-up.

| Check | Finding | Evidence required | Severity |
|---|---|---|---|
| C1 Boundary | A dependency points the wrong way, or an infrastructure type leaks into a domain surface | The written rule (ADR, project architecture, layering above) and the import or signature | Blocker |
| C2 One-way door | Something hard to reverse that the tech spec or an ADR does not name: a persisted format, a public API across a package boundary, a published event shape, a new dependency | The lines, and the spec's silence | Blocker; a person signs off |
| C3 Named-future collision | A decision fixed in place that a named upcoming item must change, so that item would rewrite this code instead of extending it | A link to the item (roadmap row, open issue, ADR, sibling card), the lines, and what the item would undo | Blocker when the item is in the same feature or the next milestone; follow-up otherwise |
| C4 Speculative generality | A trait, generic parameter, config switch or extension point with one use and no named consumer | The single use, and no item that names a second | Blocker on a public surface; follow-up when private |

- **The evidence rule cuts both ways.** No named future item: no finding for
  under-design ("this might need to change someday" is dropped). No named consumer: the
  abstraction goes ("this might be useful someday" is C4).
- **Short horizon.** Only the same feature and the next milestone can block; further out
  is too uncertain.
- **Name one-way doors up front.** A tech spec lists the one-way doors it opens, so a
  reviewer can tell a planned door from an accidental one.
