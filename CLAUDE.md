# CLAUDE.md — Claude Code pointer (this repo's reusable workflow)

This project runs the SDLC workflow defined in `AGENTS.md` — read it first.
It is the shared router for every supported agent; the rules below are
just Claude-specific paths.

- Skills (this pack): `skills/<name>/SKILL.md` (`jira-autopilot`, `mr-review`).
  Upstream engineering skills install via `npx skills add addyosmani/agent-skills`
  or `./scripts/install-skills.sh --all` (also syncs to `.claude/skills/`).
- Slash commands: `.claude/commands/` (`/autopilot`, `/intent`, `/spec`, `/plan`, `/build`,
  `/test`, `/review`, `/mr-review`, `/ship`, plus `/constraints`, `/code-simplify`, `/webperf`).
- Jira-linked work: prefer `/autopilot` — paste a Jira key or summary+description
  and it orchestrates intent → clarify → branch → spec → plan → build → verify → publish → MR,
  pausing for intent accept, spec approval, plan approval, and the human browser UI pass.
  Chain: `intent/INTENT-<KEY>.md` → `docs/specs/SPEC-<KEY>.md` → `tasks/<KEY>-plan.md` (plan mode, diff-vs-plan).
  Review policy: `REVIEW.md` (`templates/review/`). Project context: `CLAUDE.md` at project root (`templates/claude/`).
- Never push to origin before the human UI pass; first push is `scripts/publish.sh` only.
- Never paste secrets or `.env` contents into specs, Jira comments, or MR bodies.
