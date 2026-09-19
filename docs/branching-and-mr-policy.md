# Branching + MR policy (trunk-based, Jira-linked, parallel-safe)

## Naming (enforced by `.cursor/rules/jira-gitlab-trunk.mdc` + `AGENTS.md` + `scripts/check-jira-conventions.sh`)

- Branch: `PROJ-123-short-summary` — e.g. `PROJ-123-user-login`, `PROJ-124-null-token`, `PROJ-125-bump-deps`. Jira key first, no feat/ prefix. Kebab-case, ≤60 chars total.
- Commit: `PROJ-123 [Type] <conventional-type>: imperative summary` (+ body explaining why). [Type] = Jira issue type ([Story|Bug|Task|Sub-task|Epic]). Conventional types: feat/fix/refactor/test/docs/chore.
  - `PROJ-123 [Story] feat: add login form validation`
  - `PROJ-123 [Bug] fix: null token on refresh`
  - `PROJ-123 [Task] chore: bump deps`
- MR title: `[PROJ-123][Type] Short summary` + GitLab label `Jira::Story|Bug|Task`. Squash-merge; keep `PROJ-123 [Type]` in squash message for Jira linking.
- Worktree dir: `../<repo>-123` (one per issue, parallel agents never share a checkout).

### Jira type → commit/MR mapping

| Jira type | [Type] tag | Allowed conventional types | MR label |
|---|---|---|---|
| Story | `[Story]` | feat, test, docs | `Jira::Story` |
| Bug | `[Bug]` | fix, test | `Jira::Bug` |
| Task | `[Task]` | chore, refactor, docs, test | `Jira::Task` |
| Sub-task | `[Sub-task]` | same as parent | `Jira::Task` |
| Epic | `[Epic]` | feat (slice MRs reference Epic in body) | `Jira::Epic` |

## Lifecycle

```bash
git checkout main && git pull --ff-only
git checkout -b PROJ-123-user-login
git worktree add ../myapp-123 PROJ-123-user-login   # parallel-safe checkout
# ... implement → test → commit (PROJ-123 [Story] feat: ...) per slice ...
git push -u origin PROJ-123-user-login
# Open MR from branch → title [PROJ-123][Story] ... → template auto-fills (save template as .gitlab/merge_request_templates/Default.md)
# After squash-merge:
git worktree remove ../myapp-123 && git branch -D PROJ-123-user-login
```

- Lifetime ≤1–3 days. Stale >3 days → split scope or hide behind feature flag (`shipping-and-launch` flag lifecycle).
- `main` always deployable. Release stabilization uses short release branches, never freezes `main`.
- No force-push to shared branches. No long-lived `develop`. No formatting+behavior mixes. ~100 lines per commit/MR; >1000 must split (`code-review-and-quality` splitting strategies).

## MR quality bar (highest-standard default)

- Green pipeline (lint → typecheck → test → build → e2e → audit), 1+ approval, no unresolved Required threads.
- Description = MR template fully filled: Jira link, spec section, test evidence (commands + output), Definition of Done checklist, rollout/rollback.
- Security: no secrets, audit clean, inputs validated, authZ checked. Perf: no N+1, budgets met. UI: a11y verified with runtime data.

## Parallel-work rules (multiple Jira issues at once)

- One issue per worktree; never `git checkout` inside a worktree another agent uses.
- Each worktree runs its own `docker compose` ports / DB (suffix by key, e.g. `DB_NAME=app_123`) to avoid collisions.
- Before merge in each worktree: `git fetch origin && git rebase origin/main`, re-run touched tests.
