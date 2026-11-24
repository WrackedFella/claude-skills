# D0026 A paused run restarts only on a comment starting with `Resume`

- **Status:** Accepted, 2026-11-24 (Justin).
- **Decision:**
  - A paused headless run restarts when a person posts a comment whose body starts with `Resume` (case-insensitive; a leading `**` bold marker is fine). Other comments do not start a run.
  - The Pause comment ends with a line saying so.
  - Answer collection is unchanged: every comment after the latest `Paused:` comment by a non-bot owner, member or collaborator counts as an answer, so earlier answers, addenda and the Resume comment are all read on resume.
  - Runners filter their comment trigger to match; a runner that starts on any issue comment defeats the rule.
- **Why:** Claude threads posting as the owner put an answer, an addendum and a spec revision in separate comments, and each started or queued a run.
- **Evidence:** moho issue #698, comments between 2026-11-24 19:49Z and 20:24Z; runs 45478276234 and 45478587619 were cancelled, one after 11 minutes.
- **Sources:** none.
- **Reopen when:** a person cannot post a `Resume` comment where the runner listens, or a run starts on a comment that does not begin with `Resume`.
