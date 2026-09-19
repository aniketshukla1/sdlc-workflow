# SDLC — Phase Gates (Jira + GitLab + agent-skills)

Source of truth for "what happens when". Each phase lists: **goal, skills, command, Jira state, GitLab action, artifacts, exit gate**. Advance only when the gate is green.

> Orchestrator: `/autopilot` (`jira-autopilot` skill) drives Phases 0→5 end to end for one Jira issue — paste a key or a summary+description, it clarifies, then calls `/spec` → `/plan` → `/build` → `/test` → `ui-verify.sh` → `publish.sh` → MR in gate order with human approvals at spec, plan, and browser-UI pass. `scripts/` are its executors, never standalone shortcuts.

Stack assumptions: FastAPI (`backend/`, `pytest`), React+Tailwind+shadcn (`frontend/`, `vitest`/`playwright`), `docker-compose.yml` for local. Adjust commands in `CONSTRAINTS.md` per repo.

---

## Phase 0 — Intake / Triage

| | |
|---|---|
| **Goal** | Turn vague ask into a trackable, unambiguous Jira issue |
| **Skills** | `interview-me` (one question at a time, ~95% confidence), `idea-refine` (diverge → converge). Mandatory: `docs/clarification-protocol.md` — STOP and ask when unsure, never guess. |
| **Command** | None — plain chat, or `/spec` if already clear |
| **Jira** | Create issue from `templates/jira/*.md`. Types: Story / Bug / Task. Status: `To Do` / `Refinement` |
| **GitLab** | Nothing yet — no branch until spec is approved |
| **Artifacts** | Jira issue with Problem / Users / Success criteria / Out-of-scope |

**Exit gate:** Jira issue has testable success criteria and explicit non-goals. If >30 min work or multi-file → go to Phase 1, else jump to Phase 3 with a 2-line spec in the Jira description.

---

## Phase 1 — Define (Spec + Constraints)

| | |
|---|---|
| **Goal** | Shared source of truth before any code |
| **Skills** | `spec-driven-development` (6 areas: objective, commands, structure, style, testing, boundaries), `constraint-driven-development` (quality bar → `CONSTRAINTS.md`), `context-engineering` (stack commands in spec), `doubt-driven-development` (adversarial check on high-stakes decisions). Brownfield: query the Graphify code graph first (`docs/code-graph-and-test-stack.md`) and paste blast-radius nodes into Boundaries. |
| **Commands** | `/constraints` (once per project) → `/spec` (per Epic/Story) |
| **Jira** | Status `Refinement` → `Ready`. Link `SPEC-<KEY>.md` in issue. Record assumptions + open questions in Jira comments |
| **GitLab** | No code branch. Spec committed to `docs/specs/SPEC-<KEY>.md` on `main` or a `docs/<KEY>-spec` branch if spec itself needs review |
| **Artifacts** | `docs/specs/SPEC-<KEY>.md`, `CONSTRAINTS.md`, capability map if multi-module (`SPEC-<KEY>-map.md`) |

**Exit gate (human approves spec):**
- [ ] All 6 spec areas filled; boundaries use Always / Ask-first / Never tiers
- [ ] Success criteria are measurable (e.g. `POST /login p95 < 300ms`, `LCP < 2.5s`)
- [ ] Tech decisions cite official docs (`source-driven-development`)
- [ ] Threat-model section filled (or N/A justified) for auth / personal-data / payment / public-API work
- [ ] Spec file committed; Jira linked

Anti-pattern: "prototype, spec later" — prototypes become products; 15-min spec now beats 15-hour rework.

---

## Phase 2 — Plan

| | |
|---|---|
| **Goal** | Small, verifiable, dependency-ordered tasks |
| **Skills** | `planning-and-task-breakdown` (vertical slices, ≤5 files/task, acceptance + verify per task), `api-and-interface-design` (contract-first at new/legacy seams). Every slice is test-first: each task names its failing tests BEFORE any implementation task. |
| **Command** | `/plan` |
| **Jira** | Break into sub-tasks (one per slice). Each sub-task: acceptance criteria + verify step + file list. Order by dependency |
| **GitLab** | No branches yet. Plan committed as `tasks/<KEY>-plan.md` + `tasks/<KEY>-todo.md` |
| **Artifacts** | `tasks/<KEY>-plan.md`, `tasks/<KEY>-todo.md` (or Jira as tracker — pick one source of truth, mirror the other) |

**Exit gate (human approves plan):**
- [ ] Each task completable in one session, ≤~100 lines change
- [ ] Parallelizable vs sequential marked; risks + mitigations noted
- [ ] API contracts sketched before implementation tasks
- [ ] Every spec AC-ID traced to ≥1 test-first task (Acceptance → Test map fully mapped); each task lists Tests-first + Red-evidence fields

`/build auto` note: approve plan once, then all tasks run autonomously — but every task still TDD + individual commit, and it pauses on failure/risky steps.

---

## Phase 3 — Build (one Jira issue = one branch/worktree)

| | |
|---|---|
| **Goal** | Thin vertical slice → tested → committed, trunk-based |
| **Skills** | `incremental-implementation` + `test-driven-development` (red-green-refactor, 80/15/5 pyramid), `api-and-interface-design`, `frontend-ui-engineering` (a11y WCAG 2.1 AA), `source-driven-development`, `context-engineering` (load only needed spec sections) |
| **Command** | `/build` (or `/build auto` after approved plan) |
| **Jira** | `In Progress`. Assignee = you/agent. One issue in progress per worktree |
| **GitLab** | Create branch from `main`: `PROJ-123-short-summary` (Jira key first, no feat/ prefix, e.g. `PROJ-123-user-login`). For parallel work use worktrees: `git worktree add ../<repo>-123 PROJ-123-short-summary` |

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
| **Skills** | `test-driven-development`, `debugging-and-error-recovery` (reproduce → localize → reduce → fix → guard), `browser-testing-with-devtools` (DOM/console/network/perf for UI), `performance-optimization` (measure-first) |
| **Command** | `/test`, then `./scripts/ui-verify.sh` (local compose + browser test on the SAME branch — nothing pushed yet) |
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
| **Skills** | `code-review-and-quality` (5 axes, ~100-line changes, Nit/Optional/FYI vs Required/Critical), `code-simplification` (Chesterton's Fence, Rule of 500), `security-and-hardening` (OWASP Top 10, secrets, deps), `performance-optimization`. Colleague-MR reviews use `mr-review` (Jira-AC traceability first, then gates, then verdict). |
| **Commands** | `/review` (own branch pre-MR), `/mr-review` (colleague MR — hard review before approval), `/code-simplify`, `/webperf` (web UI only) |
| **Jira** | `In Review`. Link MR. Smart commits (`PROJ-123 #comment`, `PROJ-123 #in-review`) if integration enabled |
| **GitLab** | AFTER local UI pass: `./scripts/publish.sh` (conventions check + first push) → pipeline must be green (see `.gitlab-ci.yml.example` stages: conventions → lint → typecheck → test → build → e2e → audit) → open MR: title `[PROJ-123][Type] Summary` + label `Jira::Story|Bug|Task`, template `templates/gitlab/merge_request_template.md`. Require: green pipeline, 1 approval, no unresolved Required threads, no secrets |

Personas (optional, via `agents/`): `code-reviewer`, `test-engineer`, `security-auditor`, `web-performance-auditor` — personas don't invoke personas; run them in parallel, human reconciles.

**Exit gate:** All Required/Critical addressed or filed as follow-up Jira; MR description has Jira link + spec section + test evidence + rollback note. Colleague reviews are published to the MR (summary + inline threads + approve/withheld state) via `/mr-review` Phase 5 — a verdict that only lives in chat doesn't count.

---

## Phase 6 — Ship

| | |
|---|---|
| **Goal** | Reversible, observable, incremental release |
| **Skills** | `git-workflow-and-versioning` (squash-merge, delete branch, tag if versioned), `ci-cd-and-automation` (shift-left, flag-gated pipeline), `documentation-and-adrs` (why, not what), `observability-and-instrumentation` (logs/metrics/traces, RED), `shipping-and-launch` (checklist + staged rollout + rollback), `deprecation-and-migration` (when removing) |
| **Command** | `/ship` |
| **Jira** | `Done` only after deploy verified + monitors green. Smart commit `PROJ-123 #close` on merge |
| **GitLab** | Squash-merge → delete branch → remove worktree. Staging → flag-off prod → 5% canary (24–48h, error/latency thresholds) → 25/50/100% → cleanup flag ≤2 weeks |

Rollback triggers: error rate >2× baseline, p95 latency +50%, data-integrity/security signal → flag off (<1 min) or revert (<5 min).

**Exit gate:** Health 200, no new error types, critical flow smoke-tested, logs flowing, ADR + changelog + API docs updated, flag cleanup issue filed.

---

## Cross-cutting rules

1. **Brownfield first:** `context-engineering` (real conventions + landmines) + Graphify queries (blast radius) before modifying legacy; characterization tests before refactor; small bisectable commits.
2. **Two-speed:** legacy = protect + test; new work = full `/spec→/plan→/build→/review→/ship`.
3. **Clarify before code:** confidence <~95% → STOP and ask per `docs/clarification-protocol.md`. No open high-risk question survives into Build.
4. **Automate to UI-only, push only after UI pass:** after plan approval the loop runs locally to a browser-testable state; NOTHING reaches origin before the human UI pass (`docs/automation-and-ui-verification.md`). First push = `scripts/publish.sh`, then pipeline + MR.
5. **Session handoff:** phases can be separate sessions; carry `SPEC-*.md` + `tasks/*` + `git status` + last verification state forward. Re-run checks if code moved.
6. **Quality is monotonic:** each adopted gate stays on. If a month in nothing new is enforced, rollout stalled.
