# True automation — human tests in UI, never reads code (unless they want to)

Goal: after you approve the plan once, agents + pipeline do everything else. You validate a running app in the browser. Code review is done by pipeline + review agents; your job is behavior.

## The automated loop (per Jira issue)

```
You: approve SPEC + plan (2 human gates — everything else is automated)
  → ./scripts/new-issue.sh PROJ-123 Story short-summary   # branch PROJ-123-summary + worktree (LOCAL ONLY, no push)
  → /build auto                                            # all slices: TDD + atomic commits PROJ-123 [Type] ... (local)
  → /test + ./scripts/ui-verify.sh                        # local suite + compose boot, same branch
You: test in browser on that SAME branch (nothing on origin yet) → pass or send back to /build
  → ./scripts/publish.sh                                   # FIRST push: conventions check + push to origin
  → pipeline (conventions→lint→typecheck→test→build→e2e→audit) green or auto-pauses with a question
  → /review + /webperf (agents) → MR [PROJ-123][Type] auto-filled (Jira+type, spec, tests, rollback, UI steps)
You: approve MR in GitLab (behavior already proven locally; pipeline is the second net)
  → squash-merge → staged rollout → monitors → Jira #close (auto-suggested, human confirms)
```

Human gates are ONLY: (1) spec approval, (2) plan approval, (3) local UI behavior approval — REQUIRED before first push, (4) MR approve button. No code reading required. Origin never sees the branch before gate (3).

## What "done" delivers to you (every MR)

- Preview URL (GitLab review app, or local `docker compose up --build` URL printed by `scripts/ui-verify.sh`).
- UI test steps: numbered click path (e.g. 1. open /login 2. enter invalid email 3. see error X).
- Automated evidence (no claims without output): pytest/vitest/playwright summaries, axe a11y result, screenshots/video artifacts from CI, pipeline link.
- Scope note: touched / deliberately-untouched / concerns + follow-up Jira links.

If any evidence is missing or red, the agent must STOP and ask — never fake green.

## Automation pieces in this template

| Piece | What it does |
|---|---|
| `scripts/new-issue.sh PROJ-123 Story slug` | Creates `PROJ-123-slug` branch + `../<repo>-123` worktree from `main`. LOCAL ONLY — never pushes. Fails if key/type/slug malformed. |
| `scripts/check-jira-conventions.sh` | Validates branch (`PROJ-123-slug`), staged/current commits (`PROJ-123 [Type] type: ...`), MR title (`[PROJ-123][Type] ...`). Runs in `publish.sh` pre-push and in CI (`conventions` job). |
| `scripts/ui-verify.sh` | Boots `docker compose up --build` on the SAME local branch, waits for `/healthz` + frontend, prints URLs + UI checklist stub. This is the push gate — fail loops to `/build`, pass unlocks `publish.sh`. |
| `scripts/publish.sh` | FIRST push to origin (conventions check + push). Run only after local UI pass. MR is opened after it. |
| `.gitlab-ci.yml.example` | Full gates + artifacts: junit/xml, coverage, `playwright-report/`, screenshots, axe output. MR shows evidence without opening code. |
| `docs/clarification-protocol.md` | Agent auto-pauses with questions instead of guessing — the other half of "truly automated". |
| `docs/code-graph-and-test-stack.md` | Graphify for impact mapping + recommended test libs so automation actually proves behavior. |

## UI-only checklist (paste into MR / use per preview)

- [ ] Happy path works per spec success criteria (steps in MR "How to test — UI").
- [ ] Error/empty states show correct messages (try one invalid input).
- [ ] No console errors; no broken layout at 1280px + 390px widths.
- [ ] Keyboard-only pass: tab through the changed flow, focus visible, no traps.
- [ ] Visual snapshots match (or intentional diff reviewed); new screens match Figma.
- [ ] Evidence attached: e2e video/screenshots + axe clean (or N/A with reason).

## Rules that keep it honest

- `/build auto` never bypasses per-task TDD + individual commits + pauses on failure/risk (`SDLC.md` Phase 2–3).
- Coverage/audit/perf bars from `CONSTRAINTS.md` are enforced in CI, not negotiable in chat.
- Rollback path is written in the MR before merge; canary thresholds (`shipping-and-launch`) decide rollout, not optimism.
