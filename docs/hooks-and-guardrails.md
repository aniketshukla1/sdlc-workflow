# Hooks and guardrails — advisory skills + deterministic hooks

Rule of thumb: **skill** for institutional knowledge that must be applied consistently;
`CLAUDE.md` for repo working knowledge; **prompt** for one-off intent. A skill is advisory —
it makes Claude likely to comply. A hook makes violations close to impossible.

## Build-phase hooks (fast, scoped, no humans)

Copy `templates/claude/settings.json.example` → `.claude/settings.json`,
`templates/claude/hooks/*.sh` → `.claude/hooks/` (`chmod +x`):

| Hook | What it enforces |
|---|---|
| `protect-paths.sh` (PreToolUse Edit/Write) | Block generated/build output, frozen `v1/`/legacy, secrets paths |
| `no-credentials.sh` (PreToolUse) | Block credential patterns in tool input; secrets stay out of diff |
| `no-test-edit-during-fix.sh` (PreToolUse) | `FIX_MODE=1` blocks test edits during `/fix` — fix code, not test |
| `lint-after-edit.sh` (PostToolUse) | Formatter/linter on the changed file only |
| `production-gate.sh` (PreToolUse Bash) | Block `*deploy*prod*` without `RELEASE_APPROVAL` |

Build hooks must be fast and scoped to the changed file. Heavier checks (full suite)
belong at commit/PR. A hook that asks a human belongs in Deploy (`SDLC.md` Phase 5),
because an approval prompt in Build puts a person on the critical path of all parallel sessions.

## Approval gates (Deploy)

Engineering + change/compliance list gates that must survive (change sign-off, release
authorization, protected-path edits). Each gate is a hook script that can allow/ask/block.
Team hooks live in `.claude/settings.json`; non-negotiable hooks live in managed settings
(`templates/claude/managed-settings.json.example`) where engineers cannot switch them off.
A block must explain itself + the route to approval.

## Skills vs hooks

- Write a skill for one policy with a named owner + written source of truth
  (security standard, API convention, brand rule). Folder `SKILL.md` with frontmatter
  trigger + body. Ship in repo `.claude/skills/<name>/` or org-wide via plugin.
  Test that it triggers (ask the task in different ways). Policy change → skill change
  with owner sign-off; engineers pick it up next session.
- Back any must-hold policy with a hook or review pass. Skill makes violations rare;
  hook makes them near-impossible. Log invocations (session traces/OTel); review skill
  changes like code.

Metrics: policy-change → skill-merge time (skill PR); PR findings citing the policy → 0;
hook wait per gate (OTel allow/block timestamps); violations reaching prod before/after.
