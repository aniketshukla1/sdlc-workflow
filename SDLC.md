# SDLC — Phase Gates (Jira + GitLab + agent-skills)

Source of truth for "what happens when". Each phase lists: **goal, skills, command, Jira state, GitLab action, artifacts, exit gate**. Advance only when the gate is green.

> Orchestrator: `/autopilot` (`jira-autopilot` skill) drives Phases 0→5 end to end for one Jira issue — paste a key or a summary+description, it captures `intent.md`, clarifies, then calls `/spec` → `/plan` → `/build` → `/test` → `ui-verify.sh` → `publish.sh` → MR in gate order with human approvals at intent, spec, plan, and browser-UI pass. `scripts/` are its executors, never standalone shortcuts.
> Committed artifact chain (audit trail): `intent/INTENT-<KEY>.md` → `docs/specs/SPEC-<KEY>.md` → `tasks/<KEY>-plan.md` → diff + tests → MR + `REVIEW.md` findings → incident record. Each stage ends by committing its artifact; the next stage reads it. At first prompt by hand; end state is accepted-artifact-fires-next-gate.
>
> Two lanes (decided by the issue, Phase 0b — override always wins):
> - **Fast lane** — Bug/Task/Sub-task touching ≤2 files, no migration/auth/public-API change, acceptance fits in 2 Jira lines: `/fix` runs clarify → branch → failing-test-first fix → suite green → publish → MR with NO approval pauses (browser pass only if UI touched).
> - **Full lane** — everything else: the gated flow above. Small fixes must never pay the full toll.

Stack assumptions: FastAPI (`backend/`, `pytest`), React+Tailwind+shadcn (`frontend/`, `vitest`/`playwright`), `docker-compose.yml` for local. Adjust commands in `CONSTRAINTS.md` per repo.

---

## Phase 0 — Intake / Triage (intent.md)

| | |
|---|---|
| **Goal** | Turn vague ask into a versioned, machine-actionable `intent.md` + trackable Jira issue |
| **Skills** | `interview-me` (one question at a time, ~95% confidence), `idea-refine` (diverge → converge). Mandatory: `docs/clarification-protocol.md` — STOP and ask when unsure, never guess. |
| **Command** | `/intent` (or plain chat, or `/spec` if intent already accepted) |
| **Jira** | Create issue from `templates/jira/*.md`. Types: Story / Bug / Task. Status: `To Do` / `Refinement` |
| **GitLab** | Nothing yet — no branch until spec is approved |
| **Artifacts** | `intent/INTENT-<KEY>.md` from `templates/intent/intent.md.example` (Problem / Proposed outcome / Affected users and systems / Constraints / Open questions / Non-goals + Author, Status, Date, Jira link) + Jira issue with Problem / Users / Success criteria / Out-of-scope |

**Exit gate (product owner accepts intent):** `intent.md` committed to `intent/` with author + timestamp; Jira linked. If >30 min work or multi-file → go to Phase 1, else jump to Phase 3 with a 2-line spec in the Jira description.

---

## Phase 1 — Define (Spec + Constraints)

| | |
|---|---|
| **Goal** | Shared source of truth before any code — requirements + design in one session |
| **Skills** | `spec-driven-development` (6 areas: objective, commands, structure, style, testing, boundaries), `constraint-driven-development` (quality bar → `CONSTRAINTS.md`), `context-engineering` (stack commands in spec), `doubt-driven-development` (adversarial check on high-stakes decisions). Apply org skills (brand, security, compliance, UX) as constraints. Brownfield: query the Graphify code graph first (`docs/code-graph-and-test-stack.md`) and paste blast-radius nodes into Boundaries. |
| **Commands** | `/constraints` (once per project: writes `CONSTRAINTS.md`, `CLAUDE.md` from `templates/claude/`, `REVIEW.md` from `templates/review/`) → `/intent` (per idea) → `/spec` (per accepted intent) |
| **Jira** | Status `Refinement` → `Ready`. Link `intent/INTENT-<KEY>.md` + `SPEC-<KEY>.md` in issue. Record assumptions + open questions in Jira comments |
| **GitLab** | No code branch. Spec committed to `docs/specs/SPEC-<KEY>.md` on `main` or a `docs/<KEY>-spec` branch if spec itself needs review |
| **Artifacts** | `intent/INTENT-<KEY>.md` (accepted), `docs/specs/SPEC-<KEY>.md` (from `templates/spec/SPEC.md.example` + Flagged concerns + Provenance), `CONSTRAINTS.md`, `CLAUDE.md`, `REVIEW.md`, capability map if multi-module (`SPEC-<KEY>-map.md`) |

**Exit gate (human approves spec):**
- [ ] All 6 spec areas filled; boundaries use Always / Ask-first / Never tiers
- [ ] Success criteria are measurable (e.g. `POST /login p95 < 300ms`, `LCP < 2.5s`)
- [ ] Tech decisions cite official docs (`source-driven-development`)
- [ ] Threat-model section filled (or N/A justified) for auth / personal-data / payment / public-API work
- [ ] Flagged concerns routed to policy owners and resolved; Provenance (intent SHA + skill versions + prompt) recorded
- [ ] Spec file committed; Jira + intent linked

Anti-pattern: "prototype, spec later" — prototypes become products; 15-min spec now beats 15-hour rework.

---

## Phase 2 — Plan (plan mode default)

| | |
|---|---|
| **Goal** | Small, verifiable, dependency-ordered tasks — plan reviewed before any code |
| **Skills** | `planning-and-task-breakdown` (vertical slices, ≤5 files/task, acceptance + verify per task), `api-and-interface-design` (contract-first at new/legacy seams). Every slice is test-first: each task names its failing tests BEFORE any implementation task. |
| **Command** | `/plan` (starts in plan mode: read-only until plan accepted) |
| **Jira** | Break into sub-tasks (one per slice). Each sub-task: acceptance criteria + verify step + file list. Order by dependency |
| **GitLab** | No branches yet. Plan committed as `tasks/<KEY>-plan.md` + `tasks/<KEY>-todo.md` |
| **Artifacts** | `tasks/<KEY>-plan.md` (from `templates/spec/plan.md.example`: files that change, order, risks, proof), `tasks/<KEY>-todo.md` (or Jira as tracker — pick one source of truth, mirror the other) |

**Exit gate (human approves plan):**
- [ ] Each task completable in one session, ≤~100 lines change
- [ ] Parallelizable vs sequential marked; risks + mitigations noted
- [ ] API contracts sketched before implementation tasks
- [ ] Every spec AC-ID traced to ≥1 test-first task (Acceptance → Test map fully mapped); each task lists Tests-first + Red-evidence fields
- [ ] Plan names files that change + proof; committed `plan.md` — review checks diff-vs-plan; departures update `plan.md` in the same commit

`/build auto` note: approve plan once, then all tasks run autonomously — but every task still TDD + individual commit, and it pauses on failure/risky steps.

---

## Phase 3 — Build (one Jira issue = one branch/worktree)

| | |
|---|---|
| **Goal** | Thin vertical slice → tested → committed, trunk-based |
| **Skills** | `incremental-implementation` + `test-driven-development` (red-green-refactor, 80/15/5 pyramid), `api-and-interface-design`, `frontend-ui-engineering` (a11y WCAG 2.1 AA), `source-driven-development`, `context-engineering` (load only needed spec sections). Subagents: `verifier` / `simplifier` / `researcher` (`templates/agents/`, `docs/parallel-sessions-and-subagents.md`). Deterministic guardrails: hooks (`docs/hooks-and-guardrails.md`) — skill is advisory, hook enforces. |
| **Command** | `/build` (or `/build auto` after approved plan). Start 2–3 parallel sessions max (one worktree per task, different files); sequential when sharing files. |
| **Jira** | `In Progress`. Assignee = you/agent. One issue in progress per worktree |
| **GitLab** | Create branch from `main`: `PROJ-123-short-summary` (Jira key first, no feat/ prefix, e.g. `PROJ-123-user-login`). For parallel work use worktrees: `git worktree add ../<repo>-123 PROJ-123-short-summary` |
| **Hooks** | PreToolUse: `protect-paths.sh` + `no-credentials.sh` + `no-test-edit-during-fix.sh` (`FIX_MODE=1` on `/fix`); PostToolUse: `lint-after-edit.sh`. No human approval prompts in Build. |

```
main ──●──●──●──●──  (always deployable)
        ╲    ╱
         ●──●  PROJ-123-summary (1–3 days max, then merge or flag)
```

Commits: `PROJ-123 [Type] <conventional-type>: ...` (e.g. `PROJ-123 [Story] feat: add login`, `PROJ-123 [Bug] fix: null token`) — [Type] is the Jira issue type. Atomic, test-first save-point pattern (failing test → implement → verify → commit; red output shown before green).

FastAPI slice example: failing pytest (route 404/schema rejected) → Pydantic schema → route + validation → service → green pytest (unit+integration) → commit.
React slice example: failing vitest/playwright (element/behavior missing) → shadcn component → hook/store → API call → green vitest + a11y check + Storybook story for new/changed states → commit.

**Exit gate (per task):** Correctness + Quality sections of Definition of Done; red shown before green; `docker compose up --build` + `pytest` / `npm test` green with coverage bars met (no new uncovered lines on touched code); change summary written (touched / deliberately-untouched / concerns). Automated loop: `/build auto` runs the approved plan locally to a browser-testable state; human validates via `ui-verify.sh` + UI checklist, and ONLY then `publish.sh` pushes (`docs/automation-and-ui-verification.md`).

---

## Phase 4 — Verify

| | |
|---|---|
| **Goal** | Prove it works — locally, before anything reaches origin |
| **Skills** | `test-driven-development`, `debugging-and-error-recovery` (reproduce → localize → reduce → fix → guard), `browser-testing-with-devtools` (DOM/console/network/perf for UI), `performance-optimization` (measure-first). Feedback loop: single `pytest -q` / `npm test` target + `CLAUDE.md` healthy outputs + quantifiable target per task; bug fixes write failing test first + commit it, `FIX_MODE=1` blocks test edits; UI iterates implement → screenshot → compare 2–3 rounds. Evals: `docs/continuous-evals.md` — suite runs on `CLAUDE.md`/skills/hooks changes + schedule; incident → permanent eval. |
| **Command** | `/test`, then `./scripts/ui-verify.sh` (local compose + browser test on the SAME branch — nothing pushed yet). Verification is part of done: paste tool output, never "manually verified" without steps. |
| **Jira** | Stay `In Progress`. Bug sub-tasks get repro steps + regression test link |
| **GitLab** | Nothing pushed. Local gates only: unit/integration + lint + typecheck + `check-jira-conventions.sh`. Pipeline runs AFTER publish. |

**Exit gate (local, pre-push):**
- [ ] New behavior has failing-without/passing-with tests (red shown before green); local suite + lint + typecheck green
- [ ] Coverage bars met: backend ≥80% on touched + zero new uncovered lines; frontend vitest thresholds on touched; UI flows have e2e + axe clean; mutmut zero survived on high-risk backend modules
- [ ] Bug fixes include regression guard; flaky tests quarantined, not deleted
- [ ] UI changes verified with runtime data (DevTools trace/screenshot), visual snapshot diffs reviewed, not eyeballing
- [ ] Human browser test on the same branch PASSES (`docs/automation-and-ui-verification.md` checklist) — this is the push gate. Fail → back to Phase 3, no push.

---

## Phase 5 — Review (before merge)

| | |
|---|---|
| **Goal** | Merge only what a staff engineer would approve |
| **Skills** | `code-review-and-quality` (5 axes, ~100-line changes, Nit/Optional/FYI vs Required/Critical), `code-simplification` (Chesterton's Fence, Rule of 500), `security-and-hardening` (OWASP Top 10, secrets, deps), `performance-optimization`. Colleague-MR reviews use `mr-review` (Jira-AC traceability first, then gates, then verdict). Review policy: `REVIEW.md` (from `templates/review/REVIEW.md.example`: Bugs / Security / Compliance passes, Important vs Nit, max 5 nits, do-not-report). AI loop: `docs/pr-review-loop.md` — managed Code Review or `claude-code-action`, `@claude` fix loop + babysit-to-merge, findings → `CLAUDE.md`, monthly tune. Hooks as gates: `docs/hooks-and-guardrails.md` + `production-gate.sh` (`RELEASE_APPROVAL`); CI autonomy: `docs/cicd-integration.md` (`claude -p` triage → gated writes, sandboxed, MCP deploy, env tiers, rehearsed rollback). |
| **Commands** | `/review` (own branch pre-MR, checks diff vs `intent.md` + `SPEC-<KEY>.md` + `tasks/<KEY>-plan.md`), `/mr-review` (colleague MR — hard review before approval), `/code-simplify`, `/webperf` (web UI only) |
| **Jira** | `In Review`. Link MR. Smart commits (`PROJ-123 #comment`, `PROJ-123 #in-review`) if integration enabled |
| **GitLab** | AFTER local UI pass: `./scripts/publish.sh` (conventions check + first push) → pipeline must be green (see `.gitlab-ci.yml.example` stages: conventions → lint → typecheck → test → **assist** → build → e2e → audit; assist runs `agent-evals` on config changes/schedule, `agent-triage` on failure, `agent-review` on MRs — `AGENT_BIN=claude|agent`, see `docs/cicd-integration.md`) → open MR: title `[PROJ-123][Type] Summary` + label `Jira::Story|Bug|Task`, template `templates/gitlab/merge_request_template.md`. Require: green pipeline, 1 approval, no unresolved Required threads, no secrets |

Personas (optional, via `agents/`): `code-reviewer`, `test-engineer`, `security-auditor`, `web-performance-auditor` — personas don't invoke personas; run them in parallel, human reconciles.

**Exit gate:** All Required/Critical addressed or filed as follow-up Jira; MR description has Jira link + spec section + test evidence + rollback note. Colleague reviews are published to the MR (summary + inline threads + approve/withheld state) via `/mr-review` Phase 5 — a verdict that only lives in chat doesn't count.

---

## Phase 6 — Ship + Maintain (close the loop)

| | |
|---|---|
| **Goal** | Reversible, observable, incremental release; breaches write the next `intent.md` |
| **Skills** | `git-workflow-and-versioning` (squash-merge, delete branch, tag if versioned), `ci-cd-and-automation` (shift-left, flag-gated pipeline), `documentation-and-adrs` (why, not what), `observability-and-instrumentation` (logs/metrics/traces, RED), `shipping-and-launch` (checklist + staged rollout + rollback), `deprecation-and-migration` (when removing) |
| **Command** | `/ship` |
| **Jira** | `Done` only after deploy verified + monitors green. Smart commit `PROJ-123 #close` on merge |
| **GitLab** | Squash-merge → delete branch → remove worktree. Staging → flag-off prod → 5% canary (24–48h, error/latency thresholds) → 25/50/100% → cleanup flag ≤2 weeks |
| **Maintain** | Headless: `scripts/detect-breach.sh` (deterministic, no model) + `templates/maintain/bands.yaml.example` (1σ log → 2σ diagnose → 3σ propose PR/runbook) → agent writes `intent/INTENT-<KEY>.md` → normal gated flow. Triage queue: fix now / schedule / dismiss (dismissals tune bands). Fix ships → add eval. See `docs/closing-the-loop.md`. |

Rollback triggers: error rate >2× baseline, p95 latency +50%, data-integrity/security signal → flag off (<1 min) or revert (<5 min). Rollback is the most rehearsed path (single command, proven in staging).

**Exit gate:** Health 200, no new error types, critical flow smoke-tested, logs flowing, ADR + changelog + API docs updated, flag cleanup issue filed.

---

## Cross-cutting rules

1. **Brownfield first:** `context-engineering` (real conventions + landmines) + Graphify queries (blast radius, `researcher` subagent) before modifying legacy; characterization tests before refactor; small bisectable commits. Keep `CLAUDE.md` under one page (`templates/claude/CLAUDE.md.example`); when Claude repeats a mistake twice, the correction goes there.
2. **Two-speed:** legacy = protect + test; new work = full `/intent→/spec→/plan→/build→/review→/ship` → breach writes next intent (`docs/closing-the-loop.md`).
3. **Clarify before code:** confidence <~95% → STOP and ask per `docs/clarification-protocol.md`. No open high-risk question survives into Build.
4. **Automate to UI-only, push only after UI pass:** after plan approval the loop runs locally to a browser-testable state; NOTHING reaches origin before the human UI pass (`docs/automation-and-ui-verification.md`). First push = `scripts/publish.sh`, then pipeline + MR.
5. **Skills are advisory, hooks enforce:** every must-hold policy pairs a skill with a hook or review pass (`docs/hooks-and-guardrails.md`). Build hooks never wait on humans.
6. **Session handoff:** phases can be separate sessions; carry `intent/INTENT-*.md` + `SPEC-*.md` + `tasks/*` + `git status` + last verification state forward. Re-run checks if code moved.
7. **Source of truth per artifact:** declare repo vs Jira vs linkage. Minimum: artifact notes Jira key, Jira notes commit SHA. Prefer MCP read-at-start + write-back in the same session.
8. **Quality is monotonic:** each adopted gate stays on. If a month in nothing new is enforced, rollout stalled.
