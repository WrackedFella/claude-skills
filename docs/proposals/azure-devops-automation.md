# Proposal: devflow agent automation on Azure DevOps

Status: proposal, not implemented. Scope: how the `agent-ready` flow that runs on GitHub
today could run from Azure DevOps (ADO) boards, repos and pipelines. It adds no new
tooling to devflow; it lists the existing ADO mechanisms, what they replace, and what in
devflow would have to change.

Evidence labels: **Documented** (a Microsoft or Anthropic page states it, linked),
**Unverified** (plausible, but no page was read that states it; test before relying on it).

## 1. What runs today on GitHub

| Step | Mechanism |
|---|---|
| Trigger | Label `agent-ready` on an issue starts a workflow ([runtimes](../../wiki/runtimes.md#unattended-runs)) |
| Routing | Issue type: `feature` → `/devflow:refine <issue>`; anything else → `/devflow:orchestrate <issue>` |
| Runner | `claude-code-action` on a hosted runner, devflow installed from the marketplace, tool allow-list, turn and time limits |
| Output | Branch, PR into the base branch, issue comments; cards filed as sub-issues of the feature |
| Status | A separate workflow moves board Status on label, PR and close events |
| Concurrency | One run per issue (workflow concurrency group) |

The skills reach GitHub through `gh` (issues, PRs, sub-issues, labels) and
`plugins/devflow/scripts/board` (Projects v2 GraphQL). Nothing else is host-specific.

## 2. Concept mapping

| GitHub | Azure DevOps | Note |
|---|---|---|
| Issue | Work item | Tracked in Azure Boards |
| `feature` label / issue type | Work item type (for example Feature) | Type filter on the hook is API-only, see 3.2 |
| Sub-issue | Child link (`System.LinkTypes.Hierarchy-Reverse` on the child) | [REST update](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/update?view=azure-devops-rest-7.1) |
| Label | Tag (`System.Tags`, semicolon separated) | [Tags](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/tags?view=azure-devops-rest-7.1) |
| Projects v2 Status | `System.State` / board column | Column-to-state mapping not verified here |
| Gate class, Agent-eligible | Custom fields on the process | Unverified: field creation depends on the process model (inherited vs XML) |
| PR into `dev` | Azure Repos pull request | `Closes #N` becomes a work-item link |
| Workflow concurrency group | Tag-based claim (3.4) | ADO has no direct equivalent that was verified |

## 3. Triggers

### 3.1 Options

| Option | How it starts a run | Fit |
|---|---|---|
| Service hook, `workitem.updated`, filtered by **tag** | HTTP POST to a URL | Closest to a label trigger. Filters: area path, changed fields, work item type, links changed, tag ([events](https://learn.microsoft.com/en-us/azure/devops/service-hooks/events?view=azure-devops)) |
| Incoming WebHook service connection + `resources.webhooks` | A POST to an Azure DevOps endpoint starts the pipeline; payload filters by JSON path; optional secret verified by SHA-1 checksum of the body ([schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/resources-webhooks-webhook?view=azure-pipelines)) | Receiver for any hook-shaped sender |
| Run Pipeline REST call | `POST .../pipelines/{id}/runs` with `templateParameters` ([API](https://learn.microsoft.com/en-us/rest/api/azure/devops/pipelines/runs/run-pipeline?view=azure-devops-rest-7.1)); `az pipelines run --parameters` is the CLI form ([CLI](https://learn.microsoft.com/en-us/cli/azure/pipelines/runs?view=azure-cli-latest)) | Glue between a hook and a pipeline |
| Scheduled pipeline polling Azure Boards | YAML `schedules` with `always: true` ([schedules](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/scheduled-triggers?view=azure-devops)); the job queries work items by tag with WIQL ([syntax](https://learn.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax?view=azure-devops)) | No extra infrastructure; tolerates lost events |
| Azure DevOps connector (Logic Apps / Power Automate) | "When a work item is updated" trigger ([connector](https://learn.microsoft.com/en-us/connectors/visualstudioteamservices/)) | Needs a Logic Apps or Power Automate resource; the connector page notes the trigger is skipped when links change |

### 3.2 Caveats

- **Service hooks cannot start a pipeline directly.** The documented consumers are
  Web Hooks, Azure Service Bus, Azure Storage and several third-party tools; no "run
  pipeline" consumer was found ([consumers](https://learn.microsoft.com/en-us/azure/devops/service-hooks/consumers?view=azure-devops)).
  The Web Hooks consumer posts to a URL, so a receiver is needed.
- **Hook to Incoming WebHook endpoint is Unverified.** Whether the Web Hooks consumer can
  authenticate to the Incoming WebHook endpoint (custom headers, body checksum) was not
  confirmed. If not, put an Azure Function or Logic App between them that calls Run
  Pipeline.
- **Event delivery is not guaranteed for every change.** A Microsoft Q&A answer (community,
  not official) reports missing `workitem.updated` events and advises polling as a backstop
  ([thread](https://learn.microsoft.com/en-us/answers/questions/5838934/service-hook-for-work-item-updates-trigger-not-sen)).
- **Tag filter semantics are undocumented** for add vs remove. Test a subscription:
  adding `agent-ready` must fire, and removing it must not.
- **Work item type filter** set through the REST API works, but the UI shows "Any"
  (community report, [thread](https://learn.microsoft.com/en-us/answers/questions/5666112/how-i-can-set-the-workitemtype-of-one-webhook)).
  Create subscriptions by API ([guide](https://learn.microsoft.com/en-us/azure/devops/service-hooks/create-subscription?view=azure-devops))
  and keep them in source control as scripts.
- **No built-in rules engine** triggers on work item changes; hooks or the connector are
  the routes.

### 3.3 Recommended path

1. **Start with polling.** A scheduled pipeline (`always: true`) runs a WIQL query for work
   items tagged `agent-ready` and not `agent-running`, then queues one run per item
   (`az pipelines run --parameters workItem=<id> kind=<type>`). It needs only
   documented parts and survives missed events. Latency equals the schedule interval.
2. **Add the service hook** (tag filter → receiver → Run Pipeline) once latency matters.
   Keep the poll as the backstop.

### 3.4 Claiming and loop control

Each run's first step swaps `agent-ready` for `agent-running` with a JSON Patch that
includes a `test` operation on `/rev` ([update](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/update?view=azure-devops-rest-7.1)),
so a second run on the same item fails the claim. The tag swap is also what stops the hook
re-firing: the subscription filters on `agent-ready` only. Finishing removes
`agent-running`. A stale `agent-running` tag after a crashed run needs a human or a timed
sweep; that policy is open.

### 3.5 Routing

The receiver (or polling job) passes the work item type. Type `Feature` → `refine`;
anything else → `orchestrate`, as on GitHub. The pipeline YAML holds two jobs behind
`${{ if eq(parameters.kind, 'Feature') }}` template conditions
([parameters](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/template-parameters?view=azure-devops)).
Template parameters resolve at parse time, so they must be declared in the YAML.

## 4. Running Claude Code headless in Azure Pipelines

- **Command shape.** `claude -p "<prompt>"` runs non-interactively; `--allowedTools` uses
  permission-rule syntax such as `Bash(git diff *)`; `--max-turns` bounds iterations
  ([headless](https://code.claude.com/docs/en/headless), [GitLab CI example](https://code.claude.com/docs/en/gitlab-ci-cd),
  which is the closest documented non-GitHub CI pattern). Anthropic documents GitHub
  Actions and GitLab CI/CD; **no Azure Pipelines page was found**, so the pipeline
  below follows the GitLab pattern and is Unverified end to end.
- **Install.** Install the CLI with Node on the agent (a step in the pipeline). Microsoft-hosted
  images' preinstalled software was not confirmed here, so pin an explicit Node version
  with the `NodeTool@0` task or equivalent.
- **Plugin delivery.** The prompt is `/devflow:orchestrate <id>`, so devflow must be
  installed in the run. Adding a marketplace and installing a plugin from the CLI before
  `claude -p` is Unverified; `claude-code-action` does this through `plugin_marketplaces`
  and `plugins` inputs. Pin a tag, not `main`.
- **Foreground subagents.** Keep `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` and the
  system-prompt line that forces foreground subagents, as in the GitHub workflow.
- **Agent pool.** Microsoft-hosted jobs: 60 minutes free-tier, up to 360 with paid
  parallel jobs; the hosted maximum caps `timeoutInMinutes`
  ([parallel jobs](https://learn.microsoft.com/en-us/azure/devops/pipelines/licensing/concurrent-jobs?view=azure-devops)).
  The GitHub orchestrate job uses 60. Self-hosted agents (for example on Azure Container
  Apps jobs, [tutorial](https://learn.microsoft.com/en-us/azure/container-apps/tutorial-ci-cd-runners-jobs?pivots=container-apps-jobs-self-hosted-ci-cd-azure-pipelines&tabs=bash))
  lift the cap and allow a pre-baked toolchain.
- **Network.** Outbound access to the model endpoint, the plugin source and package
  registries is required. Microsoft-hosted agents are not covered by service tags; IP
  allow-listing uses a weekly file
  ([allow list](https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops)).
  Self-hosted agents give a stable egress.
- **Output.** Pipeline logs replace the Actions step summary. Publishing the run report
  as a pipeline artifact or a work item comment is a design choice, not required.

Sketch (illustrative, not tested):

```yaml
trigger: none
pr: none
parameters:
  - name: workItem
    type: string
  - name: kind
    type: string
pool: { vmImage: ubuntu-latest }
steps:
  - checkout: self
    persistCredentials: true
  - task: NodeTool@0
    inputs: { versionSpec: '22.x' }
  - script: bash scripts/claim-work-item.sh ${{ parameters.workItem }}   # tag swap, 3.4
    env: { AZURE_DEVOPS_EXT_PAT: $(System.AccessToken) }
  - script: |
      npm install -g @anthropic-ai/claude-code
      claude -p "/devflow:orchestrate ${{ parameters.workItem }}" \
        --max-turns 200 --allowedTools "Bash(git:*),Bash(az boards:*),Bash(az repos:*),Edit,Write,Task,Skill"
    timeoutInMinutes: 60
    env:
      CLAUDE_CODE_DISABLE_BACKGROUND_TASKS: "1"
      ANTHROPIC_API_KEY: $(ANTHROPIC_API_KEY)   # secrets are mapped explicitly
      AZURE_DEVOPS_EXT_PAT: $(System.AccessToken)
```

## 5. Replacements for `gh` steps

Azure DevOps CLI is the `azure-devops` extension of `az`; commands need
`--org`/`--project` or `az devops configure`. The CLI is not supported for Azure DevOps
Server (per the `az repos pr` pages); on-premises needs REST.

| devflow use | GitHub | ADO replacement | Evidence |
|---|---|---|---|
| Read item (title, body, labels, state) | `gh issue view --json` | `az boards work-item show --id` or REST Get Work Item | [CLI](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest), [REST](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/get-work-item?view=azure-devops-rest-7.1) |
| Edit body | `gh issue edit --body-file` | `az boards work-item update --description` or REST patch of `System.Description` | CLI/REST. Body is HTML in ADO, not Markdown: Unverified how Markdown fields behave per process |
| Create card | `gh issue create` | `az boards work-item create --type` | [CLI](https://learn.microsoft.com/en-us/cli/azure/boards/work-item?view=azure-cli-latest) |
| Link card to feature | sub-issues API | `az boards work-item relation add --relation-type Parent` | [CLI](https://learn.microsoft.com/en-us/cli/azure/boards/work-item/relation?view=azure-cli-latest) |
| List a feature's cards | `.../sub_issues` | WIQL tree query, or `relations` on the item | [WIQL](https://learn.microsoft.com/en-us/azure/devops/boards/queries/wiql-syntax?view=azure-devops) |
| Label add/remove | `gh issue edit --add-label` | REST patch of `/fields/System.Tags` (replace the whole list; semicolons) | [REST](https://learn.microsoft.com/en-us/rest/api/azure/devops/wit/work-items/update?view=azure-devops-rest-7.1) |
| Board fields (`board set/get/next`) | Projects v2 GraphQL | State and custom fields on the item; queue = WIQL query | CLI `--state`, `--fields`; queue Unverified until fields exist |
| Create PR | `gh pr create` | `az repos pr create --work-items ...` | [CLI](https://learn.microsoft.com/en-us/cli/azure/repos/pr/work-item?view=azure-cli-latest) (listing shows `--work-items`, `--transition-work-items`) |
| Link PR to item | `Closes #N` | `--work-items`, or `az repos pr work-item add` | same |
| PR review threads and replies | `gh api .../pulls/<n>/comments`, GraphQL | REST Pull Request Threads / Thread Comments, scope `vso.threads_full` | [REST](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-request-threads?view=azure-devops-rest-7.1) |
| Run CI on a branch (`gh workflow run`) | `gh workflow run CI` | `az pipelines run --name --branch` | [CLI](https://learn.microsoft.com/en-us/cli/azure/pipelines/runs?view=azure-cli-latest) |
| PR checks status | `gh pr checks` | Unverified: PR status / policy evaluation REST, not read here | |

Skills never resolve review threads (ground rule), so only thread read and reply are needed.

## 6. Authentication and secrets

| Need | Option | Evidence |
|---|---|---|
| Boards, repos, pipelines API from the job | Job access token (`System.AccessToken`), identity = project or collection Build Service; permissions come from that identity and must be granted (work item edit, repo Contribute, create PR, comment) | [access tokens](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/access-tokens?view=azure-devops). The exact permission set for PR creation was not verified |
| Cross-project or cross-org access | Service connection with Microsoft Entra workload identity federation instead of PATs | Same page |
| Model access | `ANTHROPIC_API_KEY` secret, or Microsoft Foundry with `CLAUDE_CODE_USE_FOUNDRY=1`, `ANTHROPIC_FOUNDRY_RESOURCE`, and either an API key or Entra ID | [Foundry](https://code.claude.com/docs/en/microsoft-foundry) |
| Secret storage | Variable group linked to Azure Key Vault (names mapped, values fetched at runtime; vault RBAC role "Key Vault Secrets User" for the service connection); mark values secret and map them into steps explicitly | [Key Vault groups](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/link-variable-groups-to-key-vaults?view=azure-devops), [secrets](https://learn.microsoft.com/en-us/azure/devops/pipelines/security/secrets?view=azure-devops) |
| Hook-to-pipeline authenticity | Incoming WebHook secret with body checksum header | [schema](https://learn.microsoft.com/en-us/azure/devops/pipelines/yaml-schema/resources-webhooks-webhook?view=azure-pipelines) |

Notes:

- Use the narrowest identity: a project-scoped Build Service ("Limit job authorization
  scope to current project"), granted only the repositories the agent edits.
- The agent must not be able to merge. Branch policies on the base branch (required
  reviewers, build validation) are the gate; the identity gets no bypass permission.
  Branch policy behavior for a pipeline-created PR was not verified.
- Secrets reach only the Claude step's environment, not every step.
- With Foundry plus Entra ID, no model API key is stored at all, at the cost of a service
  connection with the right role.

## 7. Gaps in devflow

Everything below is a change to devflow (skills, scripts, contract), listed as work to
size, not as a design.

1. **Hard-coded `gh`** appears in orchestrate, refine, tech-lead, ship, respond, sitrep and
   the reviewer and test-critic agents, plus `scripts/card`. Replace direct calls with a
   host adapter selected by a new project-contract setting (for example `Forge: github |
   azure-devops`), keeping the skills host-neutral.
2. **`scripts/board`** is Projects v2 GraphQL. An ADO counterpart must expose the same
   verbs (`set`, `get`, `next`, `probe`) over work item State and fields, with the same
   exit codes (5 = unreachable).
3. **`scripts/card`** needs an ADO counterpart: create item, set parent, tag.
4. **Terminology.** "Issue", `#N`, `Closes #N`, `[ID] title` need host-neutral wording;
   in ADO the item number is a work item ID and linking happens at PR creation.
5. **Body format.** Card bodies are Markdown (Gherkin, tables). ADO descriptions are HTML;
   whether a field renders Markdown is Unverified and depends on the process and field.
   A fallback is the card in a repo file with the work item linking to it, which conflicts
   with "the issue is the record".
6. **Process fields.** Gate class and Agent-eligible need custom fields, and Status values
   must map to the process's states. Needs an ADO process owner.
7. **Status automation.** The Board sync workflow has no counterpart. Options: ADO's own
   PR-to-work-item transitions (`--transition-work-items`, Unverified for the desired
   states), a service-hook-driven function, or the same pipeline moving State at the start
   and end of a run.
8. **Runtime doc.** `wiki/runtimes.md` needs a fifth row: Azure Pipelines run, with devflow
   delivered by the pipeline, board reachable via the job token.
9. **Marketplace install in headless CLI runs** (4) must be confirmed, since it is the
   only delivery route there.
10. **Concurrency and stale claims** (3.4) need a policy.
11. **Rust specifics** in `rust-standards` and the gate command are project contract items
    and are unaffected; the .NET flavour is planned elsewhere.

## 8. Order of work

1. Spike: one pipeline, one work item, `claude -p` with a trivial prompt, devflow
   installed from a pinned tag. Confirms sections 4 and the marketplace install.
2. Spike: service hook with tag filter → request bin; record add/remove behavior and
   payload shape (3.2). Then hook → Incoming WebHook endpoint.
3. Host adapter in devflow (gap 1-3) behind a contract setting; GitHub behavior unchanged.
4. Polling trigger and claim step (3.3, 3.4); then the hook.
5. Process fields and state mapping (gap 6, 7) with the ADO process owner.
6. Wiki: runtimes, board and contract pages.

## 9. Open questions

- Which ADO process model (inherited or XML) hosts the custom fields?
- Is the hook-to-pipeline route acceptable with an extra hop (Function or Logic App), or is
  polling enough?
- Hosted or self-hosted agents, given the 60-minute cap and egress rules?
- Model provider: Anthropic API key or Foundry with Entra ID?
- Where run output should live: pipeline logs, work item comment, or both.
