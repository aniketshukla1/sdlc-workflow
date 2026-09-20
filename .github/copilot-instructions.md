# Copilot instructions — SDLC workflow (Jira + GitLab, trunk-based)

This repo's workflow is defined in `AGENTS.md` — follow it as the router.
Skills live in `skills/<name>/SKILL.md` (`jira-autopilot`, `mr-review`;
synced to `.github/skills/` by `./scripts/install-skills.sh --all`).
Upstream engineering skills (spec, plan, TDD, review, ship) install via
`npx skills add addyosmani/agent-skills`.

## Rules

- Jira-linked work: prefer the `jira-autopilot` skill — paste a Jira key
  (`PROJ-123`) or summary+description and orchestrate clarify → branch
  (`PROJ-123-slug`, key first, no `feat/` prefix) → spec (`docs/specs/SPEC-<KEY>.md`,
  stop for approval) → plan (`tasks/<KEY>-plan.md`, stop for approval) →
  build (TDD, commits `KEY [Type] <feat|fix|...>: ...`, LOCAL only) →
  test + `./scripts/ui-verify.sh` (human browser pass = push gate) →
  `./scripts/publish.sh` (first push) → MR `[KEY][Type]` + `Jira::` label.
- Colleague MRs: `mr-review` skill — Jira-AC traceability table first, then
  five-axis gates, then exactly one verdict (Approve / Request changes / Comment).
- Clarify before code when confidence is below ~95% (max 3 questions per round,
  assumptions listed). Spec before code for multi-file work; tests before
  implementation always (red evidence required).
- Never push before the human UI pass. Never auto-merge or `#close` on merge alone.
- Never emit secrets, tokens, or `.env` contents into specs, Jira, or MR text.
