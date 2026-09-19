# Jira ↔ GitLab integration (Smart commits + linking)

Goal: every branch/MR/commit moves the right Jira issue with zero manual copy-paste.

## 1. Connect (one time, admin)

- GitLab → Settings → Integrations → Jira: enter Jira URL + user/API token, enable triggers (commit/MR/pipeline/deploy).
- Jira → Apps → GitLab: confirm commits/MRs appear in issue Development panel.
- Verify: push `PROJ-123 [Task] test: link check` on a scratch branch → commit shows under that Jira issue.

## 2. Smart-commit syntax (use in commits/MR bodies)

```
PROJ-123 #comment Fixed null token on refresh
PROJ-123 #in-review      # MR opened → Jira In Review (or use #in-progress on branch push)
PROJ-123 #close          # merge → Jira Done/Resolved (only after deploy verified per SDLC Phase 6)
<JIRA-URL>/browse/PROJ-123   # always paste full link in MR "Jira" section too
```

- Jira key + [Type] must lead the commit message (`PROJ-123 [Story] feat: ...`) for auto-linking. Branch must be `PROJ-123-summary` (key first) so GitLab ↔ Jira Development panel links automatically.
- Don't `#close` from the MR until staging/canary monitors are green — closing on merge alone hides rollout failures.

## 3. Per-issue routine (agent + human)

1. Jira `Ready` → agent confirms key + type (e.g. `PROJ-123` + Story) before creating `PROJ-123-summary` branch/worktree.
2. Commits carry `KEY [Type]`; Jira auto-logs them.
3. MR body references `Closes: PROJ-123` + Jira type + spec path; title `[PROJ-123][Story] ...`; open transitions issue `#in-review`.
4. Merge + verified deploy → `#close` with release/tag note.

## 4. If integration is unavailable (manual fallback)

- Paste branch name, MR URL, pipeline URL, and test output into Jira comments at each gate (Ready/In Progress/In Review/Done).
- Add Jira issue URL into MR description "Jira" section by hand.
