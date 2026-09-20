# Installation — step by step

There are two things to install, and they live in different places:

| What | Lives where | Installed by |
|---|---|---|
| **Skills** (the brains: `jira-autopilot`, `mr-review`, upstream engineering skills) | Per-agent skills dirs (global `~/.agents/skills/`, or project `.cursor/skills/` etc.) | `npx skills`, `install-skills.sh`, or `install-workflow.sh` |
| **Executors** (the hands: `scripts/`, `templates/`, `AGENTS.md`, routers, commands) | Inside each project repo | `install-workflow.sh` or manual copy |

Skills without executors can advise but can't run the flow. Executors without skills are just files. You need both.

## Prerequisites

- `git` and `bash` (macOS/Linux; Windows via Git Bash or WSL).
- For the one-line installs: `node` + `npx` ([nodejs.org](https://nodejs.org/)).
- No Jira/GitLab tokens needed at install time — `/autopilot` asks for them on first run (see [`jira-gitlab-integration.md`](jira-gitlab-integration.md)).

## Path A — fastest: skills CLI (skills only, 1 minute)

Best when you just want the two skills (`jira-autopilot`, `mr-review`) in whatever agent you're using right now.

```bash
# List first (safe, installs nothing):
npx skills add aniketshukla1/sdlc-workflow --list

# Install into all detected agents in this project:
npx skills add aniketshukla1/sdlc-workflow

# Install globally (every project) and/or for specific agents/skills:
npx skills add aniketshukla1/sdlc-workflow -g
npx skills add aniketshukla1/sdlc-workflow -s jira-autopilot -a claude-code -y
```

Verify:

```bash
npx skills list        # project scope — you should see jira-autopilot, mr-review
npx skills list -g     # global scope
```

Then **restart your agent session** so it discovers the new skills. Limitation: this installs skills only — for the full flow (scripts, templates, Jira/MR automation) continue with Path B.

## Path B — full workflow installer (recommended for real projects)

`scripts/install-workflow.sh` (in this repo) installs skills **and** executors. Run it with no flags and it interviews you:

```bash
./scripts/install-workflow.sh
```

```text
Install the SDLC workflow:
  1) global          skills for every project (then give project paths for scripts/templates)
  2) current project full template into .
  3) project path    full template into a directory you name
Choice [1/2/3]: _
```

### Option 1 — global

1. Pick which agents get the skills (it shows detected ones; empty = all).
2. Skills install globally (`~/.agents/skills/`, `~/.cursor/skills/`, … — same dirs `npx skills -g` uses).
3. It then asks for **project paths**, one at a time, and copies the executors
   (`scripts/`, `templates/`, `AGENTS.md`, routers, commands, `CONSTRAINTS.md.example`)
   into each. Enter empty to finish.

Non-interactive equivalent:

```bash
./scripts/install-workflow.sh --scope global --project ~/my-app --project ~/other-app --yes
./scripts/install-workflow.sh --scope global --agents cursor,opencode,claude --yes  # specific agents
```

### Option 2 — current project

Run inside the project repo. Copies the full template (everything committed, minus `.git`)
into `.` and optionally syncs the 25 upstream skills into it:

```bash
./scripts/install-workflow.sh --scope project --yes
```

### Option 3 — a project path you name

```bash
./scripts/install-workflow.sh --scope project --project ~/my-app --yes
```

### Useful flags

| Flag | Effect |
|---|---|
| `--agents a,b,c` | Limit global install (known: `cursor,opencode,claude,codex,gemini,copilot,kiro,universal`) |
| `--skip-upstream` | Skip the 25 upstream skills (offline-friendly; rerun `install-skills.sh --all` later) |
| `--no-npx` | Copy skills manually instead of `npx skills add` (fully offline) |
| `--yes` | Non-interactive, accept defaults |
| `--help` | Full usage |

### Verify a project install

```bash
ls AGENTS.md scripts/install-skills.sh skills/jira-autopilot/SKILL.md templates/jira/
./scripts/install-skills.sh --all   # if you used --skip-upstream earlier
```

## Path C — manual (no scripts)

1. **Skills:** copy `skills/jira-autopilot` and `skills/mr-review` into your agent's skills dir:
   - Universal (read by most agents): `.agents/skills/` (project) or `~/.agents/skills/` (global)
   - Cursor: `.cursor/skills/` or `~/.cursor/skills/`
   - OpenCode: `.opencode/skills/` (project; global lives where your upstream clone is)
   - Claude Code: `.claude/skills/` or `~/.claude/skills/`
   - Gemini CLI: `.gemini/skills/` or `~/.gemini/skills/`
   - GitHub Copilot: `.github/skills/`
   - Kiro: `.kiro/skills/` or `~/.kiro/skills/`
   - Codex / Command Code / skills CLI: read `./skills/` in place — nothing to copy
2. **Executors:** copy `AGENTS.md`, `scripts/`, `templates/`, `CONSTRAINTS.md.example`,
   plus the adapter dirs for your host(s) (`.opencode/commands/`, `.claude/commands/`,
   `.cursor/rules/`, `.github/copilot-instructions.md`, … — see README layout).
3. **Upstream skills:** `npx skills add addyosmani/agent-skills` or `./scripts/install-skills.sh --all`.
4. Restart the agent session.

## After installing (all paths)

1. **Per-agent native setup (optional, one time):** register the marketplaces so
   commands appear natively — `/plugin marketplace add aniketshukla1/sdlc-workflow`
   (Claude), `codex plugin marketplace add aniketshukla1/sdlc-workflow` (Codex),
   `agy plugin install https://github.com/aniketshukla1/sdlc-workflow.git` (Antigravity).
2. **Jira/GitLab access:** export the tokens (or configure MCP servers) from
   [`jira-gitlab-integration.md`](jira-gitlab-integration.md#0-autopilot-access-mcp-first-tokens-as-fallback).
   The skill prints the exact export block if anything is missing.
3. **First run:** paste a Jira key — `/autopilot PROJ-123` — and follow the gates.
   New teammate? [`teammate-onboarding.md`](teammate-onboarding.md) walks the first issue.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `npx skills` hangs / offline | Use `--no-npx --skip-upstream` flags, rerun the network steps later |
| Agent doesn't see the skill | Restart the session (skills load at startup); confirm with `npx skills list` |
| `install-workflow.sh: permission denied` | `chmod +x scripts/*.sh` |
| Skill found but flow errors on missing `scripts/` | You installed skills-only (Path A) — run Path B/C to add executors |
| `install-skills.sh` fails to clone upstream | Network or GitHub SSH issue — uses HTTPS; check `git ls-remote https://github.com/addyosmani/agent-skills.git` |
