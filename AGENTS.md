# AGENTS.md — Shared Agent Router (Cursor + OpenCode)

> Copy this file to your project root. It is the system prompt that forces skill-driven execution in both Cursor and OpenCode. Do NOT copy upstream `addyosmani/agent-skills` root AGENTS.md — that configures the skills repo itself.

This project uses skills synced from `addyosmani/agent-skills`:
- Upstream skills + this pack's `skills/` (jira-autopilot, mr-review) sync via `scripts/install-skills.sh` into every host dir: `.cursor/skills/`, `.opencode/skills/`, `.claude/skills/`, `.agents/skills/`, `.github/skills/`, `.kiro/skills/`, `.gemini/skills/` (all gitignored; Codex/Command Code/skills-CLI read `./skills/` in place).
- Commands (committed wrappers, same workflow per host): `.opencode/commands/`, `.claude/commands/`, `.gemini/commands/*.toml`, `commands/*.toml` (Antigravity). Routers: `.cursor/rules/`, `.github/copilot-instructions.md`, `.windsurfrules`, `CLAUDE.md`, `GEMINI.md`.
- Shared checklists: `references/` (copied by script — fixes upstream per-skill gap #361)

## Core rules

1. If a task matches a skill below, LOAD it first (`skill({name})` in OpenCode / read `.cursor/skills/<name>/SKILL.md` in Cursor) and follow it strictly. Do not partially apply.
2. Never skip required steps (spec, plan, test, review) when a skill demands them. State the verification evidence, not "seems right".
3. One Jira issue = one branch = one worktree = one MR. Branch `PROJ-123-short-summary` (Jira key first, no feat/ prefix). Commits `PROJ-123 [Type] <conventional-type>: ...` where [Type] is the Jira issue type ([Story|Bug|Task|Sub-task|Epic]). MR `[PROJ-123][Type] Summary` + GitLab label `Jira::Story|Bug|Task`.
4. Trunk-based: branch off `main`, merge back in 1–3 days, squash-merge, delete branch. `main` always deployable.
5. Spec before code for anything >30 min or multi-file; tests before implementation ALWAYS (spec AC → failing test → green → refactor, red evidence required). No characterization tests → no legacy refactor.
6. Clarify before code: if confidence is <~95% on intent/scope/acceptance/stack/Jira key-type, STOP and ask (interview-me, one question at a time, assumptions listed). See `docs/clarification-protocol.md`. Never guess on irreversible work.
7. Automate to UI-only verification: every change must end with a runnable preview + automated test evidence + UI checklist so the human validates in the browser, not in code. See `docs/automation-and-ui-verification.md`.
8. Load skills BY PHASE — never all 25 as always-on context.
9. Agent hygiene: never feed production secrets, customer data, or `.env` contents into agent context — use `.env.example` + synthetic fixtures. Secrets live in the manager/env, never in prompts, specs, or MR text.

## Intent → skill mapping

- Jira paste / Jira-to-MR end-to-end / new Jira issue from summary → `jira-autopilot` (`/autopilot`) — orchestrates intake→branch→spec→plan→build→verify→publish→MR; `scripts/` are executors it calls, never replacements. Small Bug/Task fix (≤2 files, no migration/auth/API change) → fast lane (`/fix`): test-first fix → suite green → MR, no approval pauses.
- Vague ask / "what should we build" → `interview-me`, then `idea-refine`
- New feature / Epic / significant change → `spec-driven-development` + `constraint-driven-development` (`/spec`, `/constraints`)
- Spec exists, need tasks → `planning-and-task-breakdown` (`/plan`)
- Implementing slice / API / UI → `incremental-implementation` + `test-driven-development` + (`api-and-interface-design` | `frontend-ui-engineering`) + `source-driven-development` (`/build`)
- Bug / failure / flaky / unexpected → `debugging-and-error-recovery` (`/test`)
- Browser UI build/debug → `browser-testing-with-devtools`
- Review / MR → `code-review-and-quality` + `code-simplification` + `security-and-hardening` + `performance-optimization` (`/review`, `/code-simplify`, `/webperf`)
- Reviewing a colleague's MR → `mr-review` (`/mr-review`) — Jira-AC traceability + hard gates + verdict before approval
- Git / branch / commit / MR / conflict / parallel worktrees → `git-workflow-and-versioning`
- Pipeline / CI / flags / deploy → `ci-cd-and-automation` + `shipping-and-launch` (`/ship`)
- Decision / API change / feature shipped → `documentation-and-adrs`
- Logs / metrics / alerts / prod debug → `observability-and-instrumentation`
- Removing code / migration / sunset → `deprecation-and-migration`
- High-stakes / unfamiliar code / irreversible → `doubt-driven-development` (adversarial re-check before commit)
- Session start / switch / quality drop → `context-engineering`
- Unsure which applies → `using-agent-skills` (meta-router; only when host has no native routing)

## Stack context (FastAPI + React + Tailwind + shadcn + compose)

- Backend: `backend/` FastAPI + Pydantic v2 + SQLAlchemy/Alembic; `pytest` (unit/integration), `ruff`, `mypy`. Run: `docker compose up --build`, `pytest -q`, `ruff check .`, `mypy backend/`.
- Frontend: `frontend/` React + Tailwind + shadcn/ui; `vitest`, `playwright`, `eslint`, `tsc --noEmit`. Run: `npm run dev/test/lint/build`.
- Never commit `.env`, `node_modules/`, `dist/`, `.next/`, `__pycache__/`. Validate inputs at boundary (Pydantic/Zod), never trust client.
- UI must pass keyboard nav + contrast (WCAG 2.1 AA) + focus management; check `references/accessibility-checklist.md`.

## Execution model (every request)

1. Detect intent → if unsure (<~95%), clarify FIRST per `docs/clarification-protocol.md`. Then load matching skill(s) BEFORE acting.
2. Follow the skill workflow exactly, including its Verification checklist.
3. For Jira-linked work: confirm Jira key + Jira type ([Story|Bug|Task|Sub-task|Epic]), branch `PROJ-123-summary`, and spec/plan files before coding. Prefer `/autopilot` — it detects pasted key vs summary+description, clarifies to ~95%, and calls `scripts/` executors in gate order.
4. After changes: structured summary (touched / deliberately-untouched / concerns) + test evidence + local preview URL + UI test steps + Jira status suggestion. Human verifies in UI on the SAME local branch, not code. Never push to origin before that UI pass — first push is `scripts/publish.sh` only (via autopilot Phase 9, or manually).
