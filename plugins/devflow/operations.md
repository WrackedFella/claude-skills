# Operations

Skills and agents name an operation, never a command. Each runs as the command in the
column of the project's `Tracker` setting in `CLAUDE.md` (unset means `github`; a tracker with no column stops the run).
`scripts/board` and `scripts/card` stay GitHub-only.

| Operation | GitHub |
|---|---|
| Read work item (title, body, labels, state) | `gh issue view <n> --json title,body,labels,state` |
| Edit work item body | `gh issue edit <n> --body-file <file>` |
| Create child work item | `${CLAUDE_PLUGIN_ROOT}/scripts/card publish <parent> "[<ID>] <title>" <body-file> --label <name>` (files the issue and links it as a sub-issue) |
| List children | `gh api repos/{owner}/{repo}/issues/<n>/sub_issues` |
| Set state | `${CLAUDE_PLUGIN_ROOT}/scripts/board set <owner> <number> <issue-url> Status=<option>`; without a board, the card status |
| Open PR | `gh pr create` |
| Read PR | `gh pr view --json number,url,headRefName,baseRefName`; related PRs `gh pr list --search`; checks `gh pr checks` |
| Read review threads | `gh api graphql` (`isResolved`), or `gh api repos/{owner}/{repo}/pulls/<n>/comments` plus `gh pr view --comments` |
| Reply to thread | inline review comment: `gh api repos/{owner}/{repo}/pulls/<n>/comments/<id>/replies -f body=<text>` (`<id>` is the numeric REST id, the GraphQL `databaseId`); PR-level comment: `gh pr comment <n> --body <text>` |

- The GitHub column keeps the `--json` fields skills read; changing one is a breaking
  change to every skill.
- Linking a PR to its work item is part of *Open PR*: `Closes #N` in the PR body on GitHub.
- A project that declares no board skips every board step as if the board were
  unreachable: no reads, no writes, and the PR body says which Status changes were skipped.
