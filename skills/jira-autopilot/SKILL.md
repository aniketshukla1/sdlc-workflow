---
name: jira-autopilot
description: End-to-end Jira-to-GitLab autopilot for one issue, fast lane or full lane. Use when the user pastes a Jira key, or a Jira summary plus description, and wants the flow handled. Use for quick Bug/Task fixes (fast lane, no approval pauses) as well as full spec-to-MR runs.
---

# Jira Autopilot (skill, not script)

## Overview

You are the orchestrator for one Jira issue, end to end. Scripts in
`scripts/` are **executors** you call — they never replace this skill.
The user pastes either (A) an existing Jira key or (B) a summary plus
description, and you drive everything to an open GitLab MR. Phase 0b
picks the lane by the issue: small Bug/Task fixes take the **fast lane**
(clarify → branch → test-first fix → suite green → MR, no approval
pauses); everything else takes the **full lane** (spec ⏸ → plan ⏸ →
build → UI pass ⏸ → MR). Automation removes copy-paste, never judgment.

Input contract (accept any of these, nothing else is required to start):

```text
PROJ-123
PROJ-123 [Story] short-summary
Summary: <text> / Description: <text> [/ Type: Story|Bug|Task|Sub-task|Epic]
PROJ-123 + pasted Jira description body
```

## Phase 0 — Parse and detect (no network, no code)

1. Detect mode:
   - **Mode A (existing):** input contains `^[A-Z][A-Z0-9]+-[0-9]+$`.
     Extract key, and optional type/slug hint.
   - **Mode B (create):** input has summary + description but no key.
     Require: summary (one line), description (problem + at least one
     testable criterion or explicit "criteria to follow"), type
     (default: ask, never silently default on ambiguous asks).
2. Validate: key regex, type enum
   (`Story|Bug|Task|Sub-task|Epic`), slug kebab-case when present.
   Invalid → STOP with the exact expected shape, no guessing.
3. State back in one block: `Mode: A|B / Key / Type / Slug-or-derived /
   Source: pasted|fetched`. Proceed only on explicit or clearly implied
   confirmation for Mode B creation (creating a Jira issue is
   externally visible).

## Phase 0b — Lane decision (fast vs full, decided by the issue)

Simple issues must not pay the full toll. Decide the lane here, state it
with a one-line reason — the user can override, and override always wins.

**Fast lane** if ALL hold:
- Type is `Bug`, `Task`, or `Sub-task` (never `Story`/`Epic`).
- Expected touch is ≤2 files, no migration, no auth change, no public-API
  change, no payment/personal-data surface.
- Acceptance fits in ≤2 Jira description lines (a failing test name counts).

**Full lane** otherwise — spec doc, plan doc, both approval gates.

Lane behavior:
- Fast: skip Phase 5 (spec doc) and Phase 6 (plan doc) entirely — the
  2-line Jira acceptance IS the spec. No approval pauses anywhere; run
  clarify → branch → test-first fix → suite green → publish → MR straight
  through. Only STOP on ambiguity you genuinely cannot resolve or a
  lane violation discovered mid-fix (then say so and switch to full lane).
- Full: unchanged — `/spec` ⏸ approval → `/plan` ⏸ approval → build →
  UI pass ⏸ → publish → MR.

## Phase 1 — Connect (MCP first, tokens as fallback)

Access order — always try in this order, stop at the first that works:

1. **MCP** — if Jira/GitLab MCP tools are configured, use them for
   fetch, create, comment, branch-push verification, and MR open.
2. **REST fallback** — `curl` + env tokens when MCP is absent:
   - Jira: `JIRA_HOST`, `JIRA_EMAIL`, `JIRA_API_TOKEN`
     (Cloud) or `JIRA_TOKEN` (Server/DCPAT).
   - GitLab: `GITLAB_HOST` (default `https://gitlab.com`),
     `GITLAB_TOKEN` (`api` scope).
3. **Missing creds → STOP.** Print the exact export block needed,
   do not proceed blind, do not invent issue content:

```bash
export JIRA_HOST="https://<your-domain>.atlassian.net"
export JIRA_EMAIL="you@example.com"
export JIRA_API_TOKEN="<jira-api-token>"   # Server/DC: JIRA_TOKEN instead
export GITLAB_HOST="https://gitlab.com"    # or self-hosted URL
export GITLAB_TOKEN="<gitlab-token api scope>"
```

Hygiene (non-negotiable): never print token values, never paste tokens
or `.env` contents into specs, Jira comments, MR bodies, or chat beyond
the export template above. Customer data stays out of prompts — use
`.env.example` + synthetic fixtures.

## Phase 2 — Fetch or create the Jira issue

- **Mode A:** fetch the issue (MCP, else
  `GET {JIRA_HOST}/rest/api/3/issue/{KEY}`). Extract: type, summary,
  description, acceptance criteria, test plan, risks/rollout notes.
  Missing AC → treat as a clarification item in Phase 3, not as
  permission to invent scope.
- **Mode B:** create the issue from `templates/jira/<type>.md`
  (story/bug/task; Sub-task/Epic reuse story skeleton + type label).
  Fill Problem/Who, testable Success criteria, In/Out scope, Test plan,
  Rollout/Risks. Create (MCP, else `POST .../rest/api/3/issue`),
  capture the returned key, then continue as Mode A.
- Record the canonical Jira URL (`{JIRA_HOST}/browse/{KEY}`) — it goes
  into the branch workflow and later the MR body.

## Phase 3 — Clarify before anything irreversible

Follow `docs/clarification-protocol.md` + `interview-me` style:

1. If confidence on intent/scope/acceptance/stack/key-type is below
   ~95%, STOP and ask — max 3 questions per round, highest risk first,
   each with a recommended default + trade-off.
2. Always surface an assumptions block before leaving this phase:

```text
ASSUMPTIONS I'M MAKING:
1. ...
2. ...
→ Correct me now or I'll proceed with these after your answers.
```

3. Record answers in `docs/specs/SPEC-<KEY>.md` (Open Questions, full
   lane) or the Jira comment (fast lane), and, when connected, as a Jira
   comment. No open high-risk question survives into Build. Vague ask →
   `interview-me` → `idea-refine` before any spec work. Fast lane: skip
   questions the fix itself answers (repro + failing test are the proof).

## Phase 4 — Branch and worktree (executor, local only)

Run the executor, do not hand-roll git commands:

```bash
./scripts/new-issue.sh <KEY> <Type> <short-summary-slug>
cd ../<repo>-<NUM>   # worktree printed by the script
```

Rules: branch `<KEY>-<slug>` off `main` (key first, no `feat/` prefix,
≤60 chars), one issue = one branch = one worktree = one MR.
Nothing is pushed here — first push happens only in Phase 8.

## Phase 5 — Spec gate (`/spec`, human approval) — FULL LANE ONLY

Skip entirely on the fast lane (the 2-line Jira acceptance IS the spec).

Invoke `spec-driven-development` (+ `constraint-driven-development` if
`CONSTRAINTS.md` is missing). Read the Jira issue + `CONSTRAINTS.md`,
write `docs/specs/SPEC-<KEY>.md` (6 areas + threat-model section for
auth/data/payment/public-API work, measurable criteria, every criterion
with an AC-ID in an Acceptance → Test map — unmapped AC blocks
planning). **STOP for human spec approval.** Link the spec file in a
Jira comment.

## Phase 6 — Plan gate (`/plan`, human approval) — FULL LANE ONLY

Skip entirely on the fast lane (one fix = one task, no plan doc).

Invoke `planning-and-task-breakdown` (contract-first via
`api-and-interface-design` at new/legacy seams). Refuse planning if any
AC lacks a test mapping. Produce vertical slices (≤5 files / ~100 lines
each, test-first: Tests-first + Red-evidence + acceptance + verify +
files) as `tasks/<KEY>-plan.md` + `tasks/<KEY>-todo.md`, propose Jira
sub-tasks. **STOP for human plan approval.** No product code yet.

## Phase 7 — Build (`/build` or `/fix`, local only)

Fast lane: write the failing test FIRST (repro of the bug), then the
minimum fix, then green. One commit
`KEY [Type] fix: ...`. No approval pauses — straight to Phase 8.

Full lane:

Invoke `incremental-implementation` + `test-driven-development`
(+ `api-and-interface-design` / `frontend-ui-engineering` /
`source-driven-development` as the slice demands). Confirm key + type +
branch + worktree before coding. One task at a time from
`tasks/<KEY>-todo.md`: failing test → implement → green → refactor →
commit `KEY [Type] <feat|fix|refactor|test|docs|chore>: ...`
(atomic, key matches branch, tests green before commit).
Stay LOCAL — never push to origin from this phase.

## Phase 8 — Verify (test + review gates, still local)

1. `test-driven-development` + `debugging-and-error-recovery`:
   reproduce → localize → reduce → fix → guard. Full local suite +
   lint + typecheck green (`./scripts/check-jira-conventions.sh`).
2. Full lane: `./scripts/ui-verify.sh` (compose up + health wait + URLs).
   Human browser-tests on the SAME branch per
   `docs/automation-and-ui-verification.md` checklist.
   **Pass → Phase 9. Fail → back to Phase 7, no push.**
   Fast lane: UI pass only if UI is touched; otherwise the green suite +
   red-evidence (fail-without/pass-with) IS the gate.

## Phase 9 — Publish + open the GitLab MR (first touch of origin)

1. Executor (conventions check + first push):

```bash
./scripts/publish.sh --mr-title "[<KEY>][<Type>] <summary>"
```

2. Open the MR (MCP preferred, else `glab mr create`, else GitLab REST
   `POST /projects/:id/merge_requests` with `GITLAB_TOKEN`):
   - Title: `[<KEY>][<Type>] <summary>`
   - Label: `Jira::Story|Bug|Task` (Sub-task→Task label, Epic→Task label
     + Epic link in body)
   - Body: `templates/gitlab/merge_request_template.md` filled with
     Jira URL + type, spec section, test evidence (commands + outputs,
     never "manually verified" without steps), checklist, rollback note.
   - Source branch `<KEY>-<slug>` → `main`. Assignee/reviewers per
     CODEOWNERS where matched.
3. Jira transition: comment with branch + MR URL + pipeline URL, smart
   commit `KEY #in-review` where the integration is enabled
   (`docs/jira-gitlab-integration.md`). Never `#close` here — Done
   happens only after merge + verified deploy (Phase 6 Ship rules).

Close with: MR URL + IID, Jira URL + suggested status (`In Review`),
test evidence summary (red output + green output), and the explicit next
human steps (review MR → merge → `/ship`). Full lane only: add spec/plan
file paths.

## Non-goals (the skill refuses these)

- Auto-merge, auto-close, or `#close` on merge alone.
- Pushing before the human UI pass (`publish.sh` is the first push).
- Creating Jira issues without an explicit or clearly implied go-ahead.
- Widening scope beyond the issue (extra files/refactors → split MR or
  follow-up Jira).
- Weakening quality bars to reach green (no skipped tests, no
  suppressed linters, no lowered thresholds).

## Verification

Before reporting the MR, confirm:

- [ ] Mode + key + type + **lane** stated back with one-line reason;
      Jira fetched or created with URL recorded
- [ ] Clarifications asked only for genuine ambiguity (≤3/round,
      assumptions listed), answers recorded in spec (full) or Jira (fast)
- [ ] Branch `<KEY>-<slug>` via `new-issue.sh`, commits match
      `KEY [Type] <type>:` and key matches branch
- [ ] Full lane: spec approved (AC-IDs fully test-mapped), plan approved
      (slices ≤100 lines, red-evidence per task). Fast lane: skipped by
      design, 2-line Jira acceptance on record
- [ ] Local suite + lint + typecheck green with red evidence shown;
      full lane: human browser pass recorded; fast lane: browser pass
      only if UI touched
- [ ] First push via `publish.sh` only, MR opened with
      `[KEY][Type]` title + Jira label + filled template + test
      evidence, Jira `#in-review` commented
- [ ] No tokens/secrets in chat, spec, Jira, or MR text
