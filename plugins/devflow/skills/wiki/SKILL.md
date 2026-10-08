---
name: wiki
description: Keep the project wiki current with the current diff - update or add onboarding docs where the change adds or alters a structure, pattern or convention a new developer needs. Decides "none needed" when nothing qualifies. Run after implementation and before review or a PR.
argument-hint: "[base-ref]"
arguments: [base]
context: fork
model: sonnet
background: false
---

Bring the project's wiki in line with this diff. Never change code.

1. **Find the wiki and its rules.** The project's `CLAUDE.md` names its docs directory.
   Without one, stop and report "no wiki configured". Read the wiki's index page and
   follow its sections and conventions; they override the defaults below.
2. **Find the base:** `$base` if given, else the project's base branch from its
   `CLAUDE.md`, else `origin/main`. Diff with `git diff "$(git merge-base <base> HEAD)"`
   so uncommitted work is included.
3. **Decide whether the wiki needs a change.** The audience is a developer joining the
   project. A change qualifies when it adds or alters something they must know to work
   here:
   - a structure: a crate, module boundary, data flow or lifecycle;
   - a pattern: an extension point, or the way a kind of thing is added;
   - a convention: naming, layout, error handling or a workflow rule;
   - a format or contract other code or people depend on (file formats, GPU layouts,
     commands).

   Bug fixes, internal refactors, tests and tuning usually don't qualify. Then check
   drift: does any existing page describe code this diff changed? A page that no
   longer matches the code is a bug, whether or not the change qualifies.
4. **Write.** Prefer updating an existing page over adding one. Default page types:
   explanation (how and why a part works), how-to (steps for one task), reference
   (look-up facts: formats, layouts, lists). One page, one type. Rules:
   - describe how the system is now, never how it got there; no changelogs, IDs, PRs
     or session references;
   - name types and modules and link the source path; don't paste code except what the
     source can't show (layouts, formats, invariants), and don't cite line numbers;
   - link ADRs for rationale rather than re-arguing it, and don't repeat what rustdoc
     or a crate README already says;
   - terse and impersonal; a diagram only where it explains faster than prose, in a
     text format that diffs.

   A new page also gets an entry in the wiki index. Fix any links the change breaks.

Report one of:

- `Docs: updated` with each page changed and one line on what changed; new pages
  listed separately as `new: <path> — purpose`, since the PR review approves them.
- `Docs: none needed` with a one-line reason.
