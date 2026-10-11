---
name: azure-standards
description: "Thin, host-agnostic principles for .NET workloads deployed to Azure: managed identity, environment-driven config, idempotent restartable jobs, stateless services with health and graceful shutdown, OpenTelemetry observability, and container image hygiene. Load before writing or reviewing code or Dockerfiles for an Azure-hosted project."
user-invocable: false
---

# Azure standards

Apply `engineering-standards` first, and `dotnet-standards` for C# code. This skill
adds only principles for workloads that run on Azure, as services or as jobs, in a
container or not. It names no service as the required choice: every rule must hold
whether the host is App Service, Container Apps, Container Apps Jobs or another. A
project's own `CLAUDE.md` may narrow or override them; it wins.

Confirm any API, setting or behavior named below against current Microsoft
documentation before relying on it.

## Identity

- **Authenticate to Azure resources with a managed identity,** not a stored credential.
  Prefer the system-assigned or user-assigned identity of the host over any secret.
- **Use one credential entry point (Azure.Identity),** so the same code uses a
  developer sign-in locally and the managed identity when deployed.
  `DefaultAzureCredential` suits local development; when deployed, use a deterministic
  credential (for example `ManagedIdentityCredential`) or a narrowed chain, so a
  misconfigured identity fails clearly instead of falling through to other credentials.
- **No secrets in configuration files, images or repositories.** This includes
  connection strings with keys, passwords and tokens, in any environment.
- **Where a secret is unavoidable, resolve it from a secret store at runtime** (for
  example through Key Vault references or a Key Vault client), never bake it in.
  Grant the identity the least access that works.

## Configuration

- **Configuration comes from the environment** (environment variables or a
  configuration provider the host populates), bound to typed options.
- **Build one image and promote it unchanged across environments;** only configuration
  differs. Never rebuild per environment.
- **Validate configuration at startup** so a bad or missing value fails the boot, not
  the first request or run (see the options validation rule in `dotnet-standards`).

## Jobs

A job is a run-to-completion process started by a schedule, a message or a person.

- **Idempotent:** running the same work twice leaves the same result as running it once.
- **Safe on duplicate trigger:** assume the same trigger can fire twice or overlap;
  guard with an idempotency key, a lease or a conditional write rather than hoping.
- **Restartable from a checkpoint:** persist progress outside the process so a rerun
  resumes instead of starting over or repeating side effects.
- **Bounded retries** with backoff and a cap; after the cap, fail loudly rather than
  looping. Distinguish transient from permanent failures.
- **Explicit exit codes:** zero only for success, non-zero for failure, so the platform
  can tell. Do not swallow a failure to exit zero.
- **Honor SIGTERM:** on a termination signal stop taking new work, then finish the
  current unit or checkpoint within the host's grace period, and exit. Wire the
  cancellation token from host shutdown through every awaited call.

## Services

- **Stateless:** keep no required state in process memory or on local disk; any
  instance can serve any request and be replaced at any time. State lives in an
  external store.
- **Expose health and readiness endpoints** (ASP.NET Core health checks): liveness says
  the process should not be restarted, readiness says it can take traffic. Readiness
  checks dependencies; liveness does not, or a dependency outage restarts every instance.
- **Shut down gracefully:** respond to `IHostApplicationLifetime` (`ApplicationStopping`),
  stop accepting new work, drain in-flight work and flush telemetry before exit, within
  the host's termination grace period. Keep the .NET host's own shutdown timeout
  (`HostOptions.ShutdownTimeout`) below that period so the process exits on its own.

## Observability

- **Use OpenTelemetry for traces, metrics and logs,** exported to Azure Monitor (for
  example through the Azure Monitor OpenTelemetry distro or exporter), rather than a
  vendor-specific SDK scattered through code. The logging rules in `dotnet-standards`
  still apply.
- **Propagate correlation:** carry the W3C trace context across service and message
  boundaries and include a correlation id on log entries, so one request or job run can
  be followed end to end.
- **Never log secrets or personal data.**

## Docker

- **Multi-stage build:** build and test in an SDK stage, copy only published output
  into a runtime-only final stage.
- **Run as a non-root user** in the final stage.
- **Pin base image tags** to a specific version (a digest where the project requires
  reproducibility); never `latest`.
- **Keep a `.dockerignore`** that excludes build output, VCS data, local settings and
  anything secret from the build context.
- **One process per container;** scale and supervise at the platform level.
- **No secrets in layers:** not as `ENV`, `ARG`, copied files or build output. A layer
  is permanent once pushed, even if a later layer deletes the file.

## Tooling assumed

Docker and the .NET SDK are available in the agent runtime. The project contract's
environment setup command installs anything missing.

## Deferred to the project `CLAUDE.md`

This skill does not decide, and a project states, where it matters: which compute,
messaging and data services to use, naming conventions, networking, the infrastructure
as code choice, and corporate policy.
