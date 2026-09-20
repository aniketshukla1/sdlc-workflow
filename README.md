# Reusable SDLC Workflow — addyosmani/agent-skills + Cursor + OpenCode + Jira + GitLab

Production-grade, reusable SDLC template built on [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) (25 skills, 9 slash commands).

**Stack:** Python FastAPI (backend) · React + Tailwind + shadcn/ui (frontend) · docker-compose
**Tools:** Cursor + OpenCode (coding) · Jira (tracking) · GitLab (SCM + CI/CD, trunk-based)

> New teammate? Start here: [`docs/teammate-onboarding.md`](docs/teammate-onboarding.md) — setup, first-issue walkthrough, daily loop, troubleshooting.

## Lifecycle at a glance

```
DEFINE          PLAN           BUILD          VERIFY         REVIEW          SHIP
Idea     ───▶  Spec    ───▶   Code    ───▶   Test    ───▶   QA       ───▶   Go Live
/spec           /plan          /build        /test          /review        /ship
interview-me    planning-      incremental-  test-driven-   code-review-   git-workflow
idea-refine     breakdown      implementation debugging     code-simplify  ci-cd
spec-driven     context-       test-driven    browser-       security       docs/ADRs
constraints     engineering    api-design     testing        performance    observability
                               frontend-ui                              shipping-launch
Jira: To Do →   Jira: Ready →  Branch        Jira: In      MR open       Merge → Done
Refinement      Sub-tasks      PROJ-123-     Review/CI     5-axis review  rollout
                               summary
```

Full gate-by-gate definition: [`SDLC.md`](SDLC.md).
Branching + parallel-work policy: [`docs/branching-and-mr-policy.md`](docs/branching-and-mr-policy.md).
Jira↔GitLab wiring: [`docs/jira-gitlab-integration.md`](docs/jira-gitlab-integration.md).

## Repo layout (this template)

```
.
├── AGENTS.md                        # Shared router — read by every agent
├── CLAUDE.md / GEMINI.md            # Thin pointers for Claude Code / Gemini CLI
├── .windsurfrules                   # Thin router for Windsurf
├── SDLC.md                          # Phase gates, entry/exit, skill mapping
├── CONSTRAINTS.md.example           # Quality bar defaults (copy to CONSTRAINTS.md per project)
├── skills/                          # This pack's own skills (jira-autopilot, mr-review) — portable core
├── .cursor/
│   ├── rules/                       # Thin routing policies (never full skills)
│   └── skills/                      # Installed via script (gitignored, synced from upstream)
├── .opencode/
│   └── commands/                    # /autopilot /spec /plan /build /test /review /mr-review /ship wrappers
├── .claude/commands/                # Same wrappers for Claude Code ( marketplace: .claude-plugin/ )
├── .gemini/commands/                # Same wrappers as TOML for Gemini CLI
├── commands/                        # Same wrappers as TOML for Antigravity (manifest: plugin.json)
├── .codex-plugin/ + .agents/plugins/# Codex marketplace manifests (Codex reads ./skills/ in place)
├── .github/
│   ├── copilot-instructions.md      # Router for GitHub Copilot
│   └── skills/                      # Installed via script (gitignored)
├── .kiro/skills/                    # Installed via script (gitignored)
├── .agents/skills/                  # Generic discovery path (gitignored)
├── templates/
│   ├── adr/
│   │   └── ADR-template.md            # Architecture Decision Records (copy to docs/adr/NNNN-*.md)
│   ├── jira/                        # Story / Bug / Task / Sub-task / Flaky-test bodies
│   ├── gitlab/
│   │   ├── merge_request_template.md
│   │   └── .gitlab-ci.yml.example   # Stages mapped to skill gates (+ coverage/contract)
│   ├── git-hooks/
│   │   └── pre-commit.example       # Fast local gates (install to .git/hooks/)
│   ├── frontend/
│   │   ├── lighthouserc.cjs.example  # LHCI budgets (copy to frontend/lighthouserc.cjs)
│   │   └── Button.stories.tsx.example # Storybook story pattern (copy next to component)
│   ├── renovate/
│   │   └── renovate.json.example    # Dependency updates (copy to renovate.json at root)
│   └── spec/                        # SPEC.md + tasks/plan.md starters (AC-IDs + TDD-first)
├── scripts/
│   ├── install-skills.sh            # One-command skill install for every agent (upstream + this pack)
│   ├── new-issue.sh                 # PROJ-123-summary branch + worktree (LOCAL ONLY, no push)
│   ├── check-jira-conventions.sh    # Branch/commit/MR lint (also a CI job)
│   ├── ui-verify.sh                 # Compose up + health wait + URLs (the push gate)
│   └── publish.sh                   # FIRST push to origin, only after local UI pass
├── docs/
│   ├── teammate-onboarding.md       # START HERE: setup + first issue + daily loop
│   ├── clarification-protocol.md    # Ask-when-unsure rules (mandatory)
│   ├── automation-and-ui-verification.md  # Truly automated loop, UI-only human gate
│   ├── code-graph-and-test-stack.md # Graphify + pytest/vitest/playwright/axe guide
│   ├── spec-to-tdd-and-coverage.md  # Spec AC → failing test → green → coverage gates (core)
│   ├── ui-ux-testing.md             # 6-layer UI system: roles, tokens, axe, snapshots, e2e, LHCI
│   ├── storybook.md                 # Component catalog: setup, story rules, test-runner path
│   ├── flaky-test-triage.md         # Quarantine ritual: owner + expiry + weekly review
│   ├── migration-safety.md          # Expand/contract + reversible migrations (CI-proven)
│   ├── review-apps-plan.md          # PLAN: per-MR preview envs (not implemented yet)
│   └── renovate.md                  # Dependency-update bot setup (schedules, automerge, tokens)
└── references/                      # Symlinked/copied shared checklists (see script)
```

## Quick start (per project)

```bash
# 1. Copy this template into your repo root (or clone it as starter)
cp -r /path/to/sdlc-workflow/.cursor /path/to/sdlc-workflow/AGENTS.md /path/to/my-project/
cp -r /path/to/sdlc-workflow/.opencode /path/to/my-project/
cp -r /path/to/sdlc-workflow/.claude /path/to/my-project/          # Claude Code commands
cp -r /path/to/sdlc-workflow/.gemini /path/to/sdlc-workflow/commands /path/to/my-project/  # Gemini / Antigravity
cp -r /path/to/sdlc-workflow/.codex-plugin /path/to/sdlc-workflow/.agents /path/to/my-project/  # Codex
cp /path/to/sdlc-workflow/AGENTS.md /path/to/my-project/CLAUDE.md  # or copy thin CLAUDE.md/GEMINI.md
cp /path/to/sdlc-workflow/CONSTRAINTS.md.example /path/to/my-project/CONSTRAINTS.md

# 2. Install all 25 skills for EVERY agent (plus this pack's jira-autopilot + mr-review)
./scripts/install-skills.sh --all
# Or subset: ./scripts/install-skills.sh --skills spec-driven-development,test-driven-development,code-review-and-quality

# 3. Wire GitLab templates + local hooks (one time per project)
# GitLab → Settings → Merge Requests → Default MR template, paste templates/gitlab/merge_request_template.md
# Copy templates/gitlab/.gitlab-ci.yml.example → .gitlab-ci.yml and adjust image/vars
# Install pre-commit: cp templates/git-hooks/pre-commit.example .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit

# 4. Run the lifecycle (identical in every agent — same gates, native command shape)
# Fast path (recommended): paste a Jira key OR summary+description → /autopilot drives
# new-issue → /spec → /plan → /build → /test → ui-verify → publish → GitLab MR in gate order
/autopilot     # gated: still pauses for spec approval, plan approval, and your browser UI pass
# Manual path (same gates, you invoke each step):
/constraints   # once per project → writes CONSTRAINTS.md
./scripts/new-issue.sh PROJ-123 Story short-summary  # branch PROJ-123-summary + worktree (LOCAL ONLY)
/spec          # per Jira Epic/Story → writes SPEC-<KEY>.md, link in Jira (asks questions first)
/plan          # per spec → writes tasks/plan.md + Jira sub-tasks
/build         # per sub-task on the PROJ-123-summary worktree (or /build auto) — commits stay LOCAL
/test          # reproduce → fix → guard (local)
./scripts/ui-verify.sh  # boot + URLs → you test in browser on SAME branch, NOTHING on origin yet
# UI fails → back to /build (still local). UI passes ↓
./scripts/publish.sh     # FIRST push to origin (conventions check + push)
/review        # 5-axis + security + perf → MR [PROJ-123][Type] auto-filled → approve in GitLab → /ship
# Reviewing a colleague's MR? /mr-review — Jira-AC traceability + hard gates + verdict, posted to the MR
```

Truly automated: after plan approval, agents work locally to a browser-testable state; NOTHING reaches origin before your local UI pass. Details: `docs/automation-and-ui-verification.md`. Unsure handling: `docs/clarification-protocol.md` (agent must ask, never guess). Graphs/tests: `docs/code-graph-and-test-stack.md` (Graphify + pytest/vitest/playwright/axe).

> Skills activate automatically too (API design → `api-and-interface-design`, UI → `frontend-ui-engineering`, etc.). Explicit `/commands` are the deterministic path — auto-routing is the fallback. Never load all 25 skills as always-on context; load by phase.

## Conventions (non-negotiable)

- **One Jira issue = one branch = one worktree = one MR.** Branch: `PROJ-123-short-summary` (Jira key first, no feat/ prefix, e.g. `PROJ-123-user-login`). See `docs/branching-and-mr-policy.md`.
- **Commits:** `PROJ-123 [Type] <conventional-type>: ...` (e.g. `PROJ-123 [Story] feat: ...`, `PROJ-123 [Bug] fix: ...`). `[Type]` = Jira issue type. Atomic, ~100 lines, tests pass before commit.
- **MR title:** `[PROJ-123][Type] Summary` + label `Jira::Story|Bug|Task`. Description = Jira link + type + spec section + tests + checklist (template enforced).
- **Spec before code; tests before implementation.** Every spec AC has an ID traced to ≥1 failing-first test (`docs/spec-to-tdd-and-coverage.md`). Coverage: backend ≥80% touched + zero new uncovered lines, frontend vitest thresholds, e2e + axe on UI MRs. Mutation: mutmut zero-survived on high-risk backend modules.
- **Definition of Done** = task acceptance criteria **plus** standing checklist (`references/definition-of-done.md`).
- **CODEOWNERS:** sensitive paths (auth, migrations, billing, CI) need named human approval — copy `templates/gitlab/CODEOWNERS.example` → `CODEOWNERS` at project root and replace the handles.

## Supported agents

Same workflow (`AGENTS.md` + `skills/`) in every host's native discovery path.
Upstream engineering skills come from `addyosmani/agent-skills`; this pack adds
`jira-autopilot` + `mr-review` plus Jira/GitLab lifecycle wrappers.

| Agent | Skills | Commands | Notes |
|---|---|---|---|
| Claude Code | `.claude/skills/` (via install script) | `.claude/commands/` + marketplace `.claude-plugin/` | `/plugin marketplace add <this-repo>` |
| Codex | `./skills/` in place (`.codex-plugin/`) | `@jira-autopilot`, `@mr-review` | `codex plugin marketplace add <this-repo>` (CLI v0.122+) |
| Cursor | `.cursor/skills/` | `.cursor/rules/` + auto-routing | Never paste full skills into rules |
| OpenCode | `.opencode/skills/` | `.opencode/commands/` | `skill({name})` routing via `AGENTS.md` |
| Gemini CLI | `.gemini/skills/`, `.agents/skills/` | `.gemini/commands/*.toml` | `gemini skills install <repo> --path skills` also works |
| GitHub Copilot | `.github/skills/`, `.agents/skills/` | `.github/copilot-instructions.md`, `.github/agents/` | `npx skills add` supported |
| Kiro | `.kiro/skills/` | auto-discovered | Follows `AGENTS.md` |
| Windsurf | via `.windsurfrules` | `commands/*.toml` reference | Keep global rules to 2–3 skills |
| Antigravity | `./skills/` + `plugin.json` | `commands/*.toml` | `agy plugin install <repo>` |
| Command Code / skills CLI / others | `./skills/` directly | `AGENTS.md` | `npx/cmd skills add <repo>` — plain Markdown |

`./scripts/install-skills.sh --all` syncs upstream skills + this pack into all
seven checkout skill dirs (all gitignored — wrappers and manifests are committed).
Codex, Command Code, and skills-CLI hosts read `./skills/` in place: no copy needed.

## Upstream

- Skills source: `https://github.com/addyosmani/agent-skills` (`skills/`, `references/`, `agents/`)
- Per-skill installs omit repo-level `references/` (upstream [#361](https://github.com/addyosmani/agent-skills/issues/361)) — `install-skills.sh` copies `references/` alongside to fix this.
- Do NOT copy upstream root `AGENTS.md`/`CLAUDE.md` — those configure the skills repo itself. This template's `AGENTS.md` is yours.
