# GEMINI.md — Gemini CLI pointer (this repo's reusable workflow)

This project runs the SDLC workflow defined in `AGENTS.md` — read it first.
It is the shared router for every supported agent; the notes below are
just Gemini-specific paths.

- Skills (this pack): `skills/<name>/SKILL.md` (`jira-autopilot`, `mr-review`).
  Run `./scripts/install-skills.sh --all` to sync upstream engineering skills
  plus this pack into `.gemini/skills/` and `.agents/skills/`, or
  `npx skills add addyosmani/agent-skills` for upstream only.
- Commands: `.gemini/commands/*.toml` (`autopilot`, `spec`, `planning`, `build`,
  `test`, `review`, `mr-review`, `ship`, plus `constraints`, `code-simplify`, `webperf`).
- Jira-linked work: prefer the `autopilot` flow — paste a Jira key or
  summary+description and it orchestrates clarify → branch → spec → plan →
  build → verify → publish → MR, pausing for spec approval, plan approval,
  and the human browser UI pass.
- Never push to origin before the human UI pass; first push is `scripts/publish.sh` only.
- Never paste secrets or `.env` contents into specs, Jira comments, or MR bodies.
