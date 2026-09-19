<!--- GitLab MR template — save as .gitlab/merge_request_templates/Default.md in your project. Title: [PROJ-123][Story] Short summary. Labels: Jira::Story|Bug|Task -->

## Jira
Closes: [PROJ-123](<JIRA-URL>) · Type: Story|Bug|Task|Sub-task|Epic <!-- smart commits: PROJ-123 #in-review on open, #close on merge -->
Branch: `PROJ-123-short-summary` (Jira key first, no feat/ prefix)

## Spec
Implements: `docs/specs/SPEC-PROJ-123.md#<section>` · Plan: `tasks/PROJ-123-plan.md`

## What / Why
- What: ...
- Why: ... (link ADR if architectural: `docs/adr/NNNN-*.md`)

## How to test
```bash
docker compose up --build
# backend
pytest -q && ruff check . && mypy backend/
# frontend
cd frontend && npm run lint && npm run test && npx tsc --noEmit
```
- [ ] New tests fail without change, pass with it
- [ ] Full pipeline green (link)

## Changes
- Touched: ...
- Deliberately untouched (out of scope): ...

## Checklist (Definition of Done)
- [ ] Acceptance criteria met; edge/error paths handled
- [ ] Lint + typecheck + tests green; no regressions
- [ ] No secrets in diff; audit clean (`pip-audit` / `npm audit` — no critical/high)
- [ ] API errors shaped `{error:{code,message}}`; inputs validated at boundary
- [ ] UI: keyboard nav + contrast + focus verified; visual snapshots reviewed (1280px + 390px, light + dark); Figma parity for new screens (or N/A)
- [ ] Docs/ADR/changelog updated as needed
- [ ] Observability on new critical path (logs/metrics) or N/A

## Rollout / Rollback
- Flag: ... (owner + expiry) | Migration: ... | Rollback: flag off / revert `<sha>` (<5 min)

## Concerns / Follow-ups
- ...
- Follow-up Jira: ...
