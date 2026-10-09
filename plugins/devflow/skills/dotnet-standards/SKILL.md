---
name: dotnet-standards
description: C#/.NET-specific engineering standards layered on engineering-standards: solution layout, compiler and analyzers as gate, records and value objects, exceptions vs result types, CancellationToken, DI and options, ILogger, xUnit and Stryker.NET, XML docs. Load before writing, refactoring or reviewing C#/.NET code.
user-invocable: false
---

# .NET engineering standards

Apply `engineering-standards` first; it holds the language-neutral rules. This skill
adds only the C#/.NET deltas, for a solution of deployable projects plus class
libraries. A project's own `CLAUDE.md` may narrow or override them; it wins.

Stack assumptions: a current supported .NET SDK, MSBuild solutions, the built-in
`Microsoft.Extensions.*` abstractions (dependency injection, options, logging),
xUnit, and Stryker.NET for mutation testing. Confirm any tool or option named below
against its official documentation before relying on it.

## Solution layout

- **A deployable is an executable project (web host, worker, CLI); everything else is
  a class library.** `ProjectReference`s make the layering visible as a graph, but
  MSBuild only rejects cycles, so enforce direction with an architecture test (for
  example NetArchTest or ArchUnitNET) or an analyzer. Split projects at deployable, reuse or
  layering boundaries only.
- **Share build settings in `Directory.Build.props`** and package versions in
  `Directory.Packages.props` (central package management), so one edit changes every
  project and versions cannot drift.

## Compiler as gate

- **Enable `<Nullable>enable</Nullable>`** so absence is visible in the type system and
  a missing null check is a warning, not a runtime fault.
- **Set `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`** in the shared props,
  with a curated analyzer set and severities in `.editorconfig`. Suppress with `#pragma warning disable` plus a
  reason comment, or `[SuppressMessage(..., Justification = "...")]`, never in a
  solution-wide `.editorconfig` severity to get green.
- **Formatting is checked, not just applied:** `dotnet format --verify-no-changes`
  fails on drift, so style never reaches review.

## Domain modeling

- **Use `record` (or `record struct`) for immutable data** and `sealed` for every
  class not designed for inheritance: value equality and non-destructive `with` come
  free, and sealing keeps the type closed to accidental subclassing.
- **Value objects wrap rule-bearing primitives behind a validating factory** (a static
  `Create`/`TryCreate` returning a failure value, with the constructor private), so an
  invalid instance cannot be built.
- **No behavior-less inheritance hierarchies used to share code.** Model alternatives
  as a base record with sealed derived records, matched with `switch` expressions. The
  compiler cannot prove exhaustiveness over a class hierarchy, so the fallback arm
  throws on an unknown type and a test covers each subtype. For enums, only `switch`
  expressions are checked (CS8524, a warning); `switch` statements get no check. A
  discard arm hides new members, so omit it. CS8524 also fires for out-of-range
  values; downgrade it in `.editorconfig` only if the team accepts that, otherwise
  cover with a test.

## Errors

- **Exceptions for broken invariants and boundary faults** (I/O, cancellation);
  **a result type for expected domain failures** that callers must handle. Exceptions
  thrown by parsers are caught at the boundary and turned into a failure value.
  Exceptions are costly and invisible in signatures; results make the failure part of the contract.
- **Never `catch {}` or catch-and-ignore.** Catch the narrowest type you can handle,
  rethrow with `throw;` (not `throw ex;`, which resets the stack trace), and wrap with
  an inner exception when crossing a layer.
- **At API edges, map failures to `ProblemDetails`** (RFC 9457, which obsoletes
  RFC 7807) in one place, `AddProblemDetails` with an `IExceptionHandler` (which also needs
  `AddExceptionHandler<T>()` and `UseExceptionHandler()`), so clients
  get a uniform error shape and internals do not leak.

## Async and cancellation

- **Accept a `CancellationToken` in every async API and pass it to every awaited
  call;** cancellation is cooperative and only propagates if each hop forwards it.
- **Never block on a task with `.Result`, `.Wait()` or `.GetAwaiter().GetResult()`:**
  it ties up a thread and risks deadlock. Async goes all the way up.
- **Return `IAsyncEnumerable<T>` to stream** unbounded or large results instead of
  buffering a list.
- **Don't wrap I/O in `Task.Run`:** async I/O already frees the thread; `Task.Run` only
  moves CPU-bound work off a caller that must stay responsive.

## Dependency injection and configuration

- **One composition root** (`Program.cs` or the host builder) registers services;
  everything else takes dependencies through its constructor. No `IServiceProvider`
  resolved inside domain code, no static state.
- **Bind configuration to typed options (`IOptions<T>`) and validate on start:**
  `.ValidateDataAnnotations().ValidateOnStart()` on the options builder, or
  `AddOptionsWithValidateOnStart<T>()` (.NET 8+), with `IValidateOptions<T>` for custom
  rules. Bad config then fails the boot instead of the first request.
- **Inject `TimeProvider` instead of reading `DateTime.UtcNow`,** so time is
  controllable in tests. It is built in from .NET 8 (`Microsoft.Bcl.TimeProvider` for
  older targets); `FakeTimeProvider` is in `Microsoft.Extensions.TimeProvider.Testing`.
- **Create `HttpClient` through `IHttpClientFactory` (typed clients)** to get handler
  lifetime management, and attach one resilience handler per client
  (`Microsoft.Extensions.Http.Resilience`: `AddStandardResilienceHandler`, or
  `AddResilienceHandler` for a custom pipeline) rather than hand-rolled loops.

## Logging

- **Use `ILogger<T>` message templates with named placeholders:**
  `logger.LogInformation("Loaded {AssetId}", id)`. Never string interpolation, which
  destroys the structured fields and allocates even when the level is off.
- **On hot paths use `LoggerMessage` source generation** (`[LoggerMessage]` partial
  methods) to avoid per-call boxing and template parsing; it also validates templates
  at compile time. Analyzer CA2254 flags a log template that is not static.
- **Open a scope (`BeginScope`) or an `Activity`** around meaningful units of work so
  correlated entries and traces share an id.

## Testing

- **xUnit.** Name tests `Method_Scenario_Expected`; group related tests in a test class
  per unit, nested classes per behavior where it helps.
- **API tests use `WebApplicationFactory<TEntryPoint>`** to run the real pipeline
  in-process; replace only the infrastructure edges.
- **Use Testcontainers for real infrastructure** (databases, brokers) instead of mocks
  of them; this assumes Docker is available where tests run, so tag such tests
  `[Trait("Category","Integration")]` and run the fast set with
  `dotnet test --filter "Category!=Integration"`.
- **Mutation testing with Stryker.NET** in diff mode
  (`dotnet stryker --since:<base-branch>`; without `--since` it mutates the whole
  project), with
  a break threshold (`thresholds.break` in `stryker-config.json`, or `--break-at`);
  a score below it exits non-zero.
- **Check an assertion library's license before adding one.** FluentAssertions 8+ is
  under the Xceed commercial license (v7 and earlier are Apache-2.0); AwesomeAssertions
  is the Apache-2.0 fork. Prefer plain xUnit `Assert`.

## Documentation comments

- **XML doc comments (`///`) state a public member's contract:** behavior, `<exception>`
  for what it throws, thread-safety and invariants. The keep/remove rules from
  `engineering-standards` apply; don't restate the signature in `<summary>`.
- **Enable doc generation for library projects** (`GenerateDocumentationFile`) so a
  missing doc on public API surfaces as a warning, and therefore an error under the gate.

## Example gate

A minimal gate for the project contract; each command must exit non-zero on failure:

```bash
dotnet build -warnaserror
dotnet format --verify-no-changes
dotnet test
```
