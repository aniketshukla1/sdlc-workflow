# Teammate onboarding — set up and work in this SDLC (start here)

This guide takes you from zero to shipping your first Jira issue in this workflow. No prior knowledge of the agent skills is needed — follow the steps in order.

**What this workflow is, in one paragraph:** one Jira issue = one branch (`PROJ-123-summary`) = one MR. Agents (Cursor or OpenCode) do the coding driven by specs and tests; pipelines prove it; you approve the spec, approve the plan, test in the browser, and approve the MR. You never need to read code to validate work — but every gate is checkable when you want to.

---

## Part 1 — Prerequisites (once per machine)

- [ ] **Accounts/access:** Jira, GitLab (developer role or higher on the project), Cursor and/or OpenCode installed and signed in.
- [ ] **Toolchain:** Git, Node 20+, Python 3.12+, Docker + Docker Compose. Verify:
  ```bash
  git --version && node --version && python3 --version && docker compose version
  ```
- [ ] **Git identity + GitLab auth** (SSH key or HTTPS token) so you can push and open MRs.

## Part 2 — Project setup (once per repo checkout)

1. **Clone and enter the project:**
   ```bash
   git clone <gitlab-project-url> && cd <project>
   ```
2. **Install the agent skills** (both Cursor and OpenCode, one command — run from the project root):
   ```bash
   ./scripts/install-skills.sh --all
   # verify: ls .cursor/skills | wc -l && ls .opencode/skills | wc -l   # expect 25 each
   ```
   If skills seem ignored later, re-run this — a missing `references/` folder means a partial install (fixed by this script).
3. **Project config files** (should already be committed; if starting a fresh repo, copy from this template):
   - `AGENTS.md` at root (tells both agents how to behave — never delete it).
   - `CONSTRAINTS.md` (quality bars; copy from `CONSTRAINTS.md.example` once, tailor thresholds once).
   - `.cursor/rules/`, `.opencode/commands/` (routing + `/spec /plan /build /test /review /ship`).
4. **Local safety net:**
   ```bash
   cp templates/git-hooks/pre-commit.example .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
   ```
5. **Boot the app and confirm it runs:**
   ```bash
   docker compose up --build
   # backend: http://localhost:8000/docs   frontend: http://localhost:3000
   ```

## Part 3 — Project wiring (lead does once; everyone verifies)

- [ ] **GitLab MR template:** Settings → Merge Requests → paste `templates/gitlab/merge_request_template.md` as the default template.
- [ ] **Pipeline:** `templates/gitlab/.gitlab-ci.yml.example` → `.gitlab-ci.yml` (adjust images/vars). Expect jobs: conventions, lint, typecheck, test (+coverage), mutation, frontend, e2e, lighthouse, storybook, audit, deploy.
- [ ] **CODEOWNERS:** copy `templates/gitlab/CODEOWNERS.example` → `CODEOWNERS` at root, replace every `@…-lead` handle with real people. Enable Settings → Merge requests → "Require approval from code owners".
- [ ] **Auto-merge allowed:** Settings → Merge requests → "Allow merge when pipeline succeeds" + "Pipelines must succeed".
- [ ] **Renovate** (dependency bot): copy `templates/renovate/renovate.json.example` → `renovate.json`, replace reviewer, add schedule per `docs/renovate.md`.
- [ ] **Lighthouse + Storybook configs:** `templates/frontend/lighthouserc.cjs.example` → `frontend/lighthouserc.cjs`; run `npx storybook@latest init` in `frontend/` (see `docs/storybook.md`).
- [ ] **Jira ↔ GitLab linking:** connect via Smart Commits (see `docs/jira-gitlab-integration.md`), so `PROJ-123 #in-review` / `#close` move issues automatically.

## Part 4 — Conventions you must memorize (5 lines)

- **Branch:** `PROJ-123-short-summary` — Jira key first, no `feat/` prefix. One issue = one branch = one worktree = one MR.
- **Commits:** `PROJ-123 [Type] <feat|fix|…>: …` (e.g. `PROJ-123 [Story] feat: add login`). `[Type]` = Jira issue type.
- **MR title:** `[PROJ-123][Type] Summary` + label `Jira::Story|Bug|Task`.
- **Spec before code; tests before implementation.** Every spec criterion has an ID traced to a failing-first test.
- **Nothing reaches origin before your browser test passes.** First push is always `./scripts/publish.sh`.

## Part 5 — Your first issue, end to end (do this once, guided)

Pick a small Story or Bug from the Jira board (status Ready, clear acceptance criteria).

```bash
# 1. Create the branch + isolated worktree (LOCAL ONLY — nothing pushed)
/scripts/new-issue.sh PROJ-123 Story short-summary
cd ../<repo>-123

# 2. Define: agent interviews you until the spec is unambiguous, then writes it
/spec            # → docs/specs/SPEC-PROJ-123.md — REVIEW it, approve explicitly

# 3. Plan: spec becomes small test-first tasks
/plan            # → tasks/PROJ-123-plan.md — REVIEW it, approve explicitly

# 4. Build: agent implements slice by slice (failing test → code → green → commit, all local)
/build           # or: /build auto — runs the whole approved plan, pauses on risk

# 5. Verify locally + test in YOUR browser (the push gate)
/test            # reproduce → fix → guard, with real command output
./scripts/ui-verify.sh   # prints the URLs — click through the UI checklist in docs/automation-and-ui-verification.md
# UI fails? Back to /build (still local, still unpushed). UI passes? Continue.

# 6. Publish: FIRST push to origin, then pipeline proves it again in CI
./scripts/publish.sh     # conventions check + push → GitLab pipeline runs everything

# 7. Review + merge
/review           # agent 5-axis review; address Required findings or file follow-up Jira
# Open the MR (template auto-fills: Jira+type, spec, tests, checklist, rollback) → approve → squash-merge
/ship             # rollout checklist, monitors, Jira #close when green
```

After merge: `git worktree remove ../<repo>-123` (cleanup), branch auto-deleted on squash-merge.

## Part 6 — Daily loop (after onboarding)

`new-issue` → `/intent` → `/spec` → `/plan` → `/build` → `/test` → browser → `publish` → `/review` → MR → `/ship`. Your human gates are always the same five: **intent accept, spec approval, plan approval, browser pass, MR approval.** Full gate reference: `SDLC.md`. Flowchart: `docs/sdlc-flow.mmd`.

## Part 7 — Testing rules that apply to everyone

- **Red before green, with evidence.** "Tests pass" without a prior failing run is not TDD and fails review.
- **Coverage bars:** backend ≥80% on touched code + zero new uncovered lines; frontend vitest thresholds; e2e + axe on UI flows; visual snapshots for changed flows (1280px + 390px, light + dark); mutmut zero-survived on high-risk backend modules; LHCI budgets on public routes. Details: `docs/spec-to-tdd-and-coverage.md`, `docs/ui-ux-testing.md`.
- **Flaky test?** Quarantine it AND file a `flaky`-labelled Jira issue (owner + expiry) from `templates/jira/flaky-test.md` in the same MR. Reviewed weekly — see `docs/flaky-test-triage.md`. Never delete to get green.
- **Legacy code with no tests?** Characterization tests first, then refactor. No exceptions.
- **Unsure about anything?** Ask before acting — the agent is required to do the same (`docs/clarification-protocol.md`).

## Part 8 — Troubleshooting

| Symptom | Fix |
|---|---|
| Agent ignores skills / freelances | Check `AGENTS.md` at repo root + `ls .cursor/skills` (or `.opencode/skills`); re-run `./scripts/install-skills.sh --all` |
| `publish.sh` fails on conventions | Branch must be `PROJ-123-slug`, commits `PROJ-123 [Type] type: …` — fix names/messages, never `--no-verify` your way past |
| Pipeline red after green locally | Read the failing job log, reproduce its exact command locally, fix on the same branch, push again |
| Snapshot diffs in e2e/storybook | Open the image diff: intentional change? regenerate (`--update-snapshots`) AND review the diff; unintentional? fix the CSS |
| mutmut survivors | `mutmut browse` → write the killing test per survivor → rerun; gate is zero survived on high-risk modules |
| Merge conflicts | In your worktree: `git fetch origin && git rebase origin/main`, resolve, re-run touched tests, push |
| Docker port/DB collision (parallel issues) | Suffix resources per issue (e.g. `DB_NAME=app_123`); one worktree per issue, never share checkouts |
| Renovate MR looks odd | Bot branches (`renovate/*`) skip Jira naming by design; pipeline + CODEOWNERS still gate them — approve manifest MRs, let patches auto-merge |
| Expired flaky issue assigned to you | Fix-this-week (new date) or delete-deliberately with reason — see `docs/flaky-test-triage.md` |

## Part 9 — FAQ

- **Do I have to read code to review?** No. Spec + plan approvals, browser test, evidence in the MR (test reports, screenshots, axe, LHCI), pipeline green, agent review with no unresolved Required items. Read code whenever you want — it's all there.
- **The spec/plan looks wrong?** Say so before code starts — that's the cheapest moment. After code starts, changes go back through spec update first.
- **Can I work two issues at once?** Yes — one worktree per issue (`new-issue.sh` does this). Never `git checkout` inside a worktree another task uses.
- **Where do decisions live?** Specs + ADRs + MR descriptions. If a "why" isn't written down, ask for it in review.
