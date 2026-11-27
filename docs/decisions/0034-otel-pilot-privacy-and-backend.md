# D0034 The OpenTelemetry pilot exports metrics and API events only, to Grafana Cloud Free

- **Status:** Proposed, 2026-11-27.
- **Decision:**
  - **Signals:** metrics and `api_request`, `api_error`, `tool_result` events. Traces (beta) are off.
  - **Content gates stay at their defaults (off):** `OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_ASSISTANT_RESPONSES`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT`, `OTEL_LOG_RAW_API_BODIES`. A gate on a public repository's run is a standing prohibition, not a per-run choice.
  - **Identity and cardinality:** `OTEL_METRICS_INCLUDE_SESSION_ID=false`, `OTEL_METRICS_INCLUDE_ACCOUNT_UUID=false`; the run is identified by resource attributes the workflow sets (`gh.repo`, `gh.run_id`, `issue`, `gate_class`, `lane`), not by the session.
  - **Backend:** Grafana Cloud Free (10,000 active series, 50 GB logs, 14-day retention). Honeycomb Free (20 M events and 100 M metric data points a month, 60-day events) is the fallback if the series limit binds or ad-hoc event queries matter more than standing dashboards.
  - **Credentials:** an Actions secret holding a write-only OTLP token; no secret reaches a fork PR run; the endpoint and token for cloud threads are environment variables of the cloud environment, not repository files.
- **Why:**
  - **Privacy.** With OAuth, `user.email` is a telemetry attribute and goes to the configured endpoint (S33); a third-party backend must not receive it, so the account attributes are off and the workflow's own attributes are the identity. Prompts, tool input and responses are off by default and stay off because the repository is public and a log line can quote a file.
  - **Series budget.** Metric labels multiply: `model` x `type` x `query_source` x `agent.name` x run. `session.id` defaults on and would add a label value per run; per-run attributes are bounded by active series at one time, which short runs keep far under 10,000 (S35). Honeycomb counts events, and the volume is a few hundred API requests a run (S36).
  - **Cost.** Both free tiers cover the pilot with room to spare; neither needs a card (S35, S36).
  - **Why Grafana first.** The deliverable is a standing dashboard of tokens per model and kind, per issue and per step; PromQL over metrics does that directly, and the free tier's 14-day retention is enough for a ten-run pilot. Per-issue totals older than 14 days stay in the run records.
- **Evidence:** limits as published on the vendors' pages, read through search summaries (S35, S36); not yet exercised from an Actions runner or the cloud environment's network allow-list, which must permit the OTLP host (S33 lists the endpoint variables).
- **Sources:** S33, S35, S36.
- **Reopen when:** the pilot hits a free-tier limit, the OTLP host cannot be allowed from the cloud environment, or Justin prefers the token to live elsewhere.
