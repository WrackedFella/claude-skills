# Operations

Skills and agents name an operation, never a command. Each runs as the command in the
column of the project's `Tracker` setting in `CLAUDE.md` (unset means `github`; a tracker with no column stops the run).
`scripts/board` and `scripts/card` stay GitHub-only.

| Operation | GitHub | Azure DevOps (Unverified) |
|---|---|---|
| Read work item (title, body, labels, state) | `gh issue view <n> --json title,body,labels,state` | `az boards work-item show --id <n> --output json` (`System.Title`, `System.Description`, `System.Tags`, `System.State`) |
| Edit work item body | `gh issue edit <n> --body-file <file>` | `az boards work-item update --id <n> --description <html>` |
| Create child work item | `${CLAUDE_PLUGIN_ROOT}/scripts/card publish <parent> "[<ID>] <title>" <body-file> --label <name>` (files the issue and links it as a sub-issue) | `az boards work-item create --type <type> --title "[<ID>] <title>" --description <html> --fields System.Tags=<tags>` (tags on create derived, not from the proposal), then `az boards work-item relation add --id <child> --relation-type parent --target-id <parent>` |
| List children | `gh api repos/{owner}/{repo}/issues/<n>/sub_issues` | `az boards work-item show --id <n> --expand relations`, keeping `System.LinkTypes.Hierarchy-Forward`; or `az boards query --wiql <query>` |
| Set state | `${CLAUDE_PLUGIN_ROOT}/scripts/board set <owner> <number> <issue-url> Status=<option>`; without a board, the card status | `az boards work-item update --id <n> --state <state>`; Gate class and Agent-eligible are custom fields set with `--fields` |
| Open PR | `gh pr create` | `az repos pr create --source-branch <branch> --target-branch <base> --title <t> --description <d> --work-items <id>` |
| Read PR | `gh pr view --json number,url,headRefName,baseRefName`; related PRs `gh pr list --search`; checks `gh pr checks` | `az repos pr show --id <n>`; related PRs `az repos pr list` filtered by `--source-branch`, `--target-branch`, `--status` or `--creator` (no text search; otherwise manual); checks: manual (PR status and policy evaluation REST not yet identified) |
| Read review threads | `gh api graphql` (`isResolved`), or `gh api repos/{owner}/{repo}/pulls/<n>/comments` plus `gh pr view --comments` | `az devops invoke --area git --resource pullRequestThreads --route-parameters project=<p> repositoryId=<r> pullRequestId=<n>` (scope `vso.threads_full`; `--api-version 7.1`); a thread's `status` (`active`, `fixed`, `closed`, …) is the resolved signal, so skip non-`active` threads |
| Reply to thread | inline review comment: `gh api repos/{owner}/{repo}/pulls/<n>/comments/<id>/replies -f body=<text>` (`<id>` is the numeric REST id, the GraphQL `databaseId`); PR-level comment: `gh pr comment <n> --body <text>` | inline thread: `az devops invoke --area git --resource pullRequestThreadComments --api-version 7.1 --http-method POST --route-parameters project=<p> repositoryId=<r> pullRequestId=<n> threadId=<id> --in-file <comment.json>`; PR-level comment: the same call on `pullRequestThreads` to open a new thread |

- The GitHub column keeps the `--json` fields skills read; changing one is a breaking
  change to every skill.
- Linking a PR to its work item is part of *Open PR*: `Closes #N` in the PR body on GitHub.
- A project that declares no board skips every board step as if the board were
  unreachable: no reads, no writes, and the PR body says which Status changes were skipped.

## Azure DevOps

Source: the [ADO automation proposal](https://github.com/WrackedFella/claude-skills/pull/24)
(`docs/proposals/azure-devops-automation.md`, sections 2 and 5), taken as written. **Every
Azure DevOps command is Unverified** until DNET-F2-03 runs it against a real organization;
a command that fails there becomes "manual" with the reason.

- Commands use the `azure-devops` extension of `az` (set `az devops configure` defaults or
  pass `--org` and `--project`); `az devops invoke` or REST covers what the CLI has no verb
  for. The CLI does not support Azure DevOps Server; on-premises needs REST. Pin the
  extension in the consuming project (`az extension add --name azure-devops --version <pinned>`) and
  record the version it was verified with next to the Tracker setting; the table was written
  without a version (no command here has been run).
- Cards use `System.Description`, which is HTML: write cards as HTML, since Markdown may
  not render (proposal gap 5; unverified per process).
- `scripts/board` and `scripts/card` stay GitHub-only, so a project on this tracker
  declares no board and *Set state* is the State field.

| GitHub | Azure DevOps |
|---|---|
| Issue | Work item |
| `feature` label | Work item type (for example Feature) |
| Sub-issue | Child link (`System.LinkTypes.Hierarchy-Reverse` on the child) |
| Label | Tag (`System.Tags`, semicolon separated; writes replace the whole list) |
| Board Status | `System.State` (board column mapping not verified) |
| Gate class, Agent-eligible | Custom fields on the process (creation depends on the process model) |
| `Closes #N` | `--work-items` on the PR |
