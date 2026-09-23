# CI/CD integration — agents inside the pipeline, inside gates

Principle: the agent may act up to the production gate and cannot pass it.

1. Start read-only: `scripts/triage-failure.sh` (failed-build triage), flaky summary, changelog draft via `claude -p`.
2. Add write steps behind existing gates (fix lint, update generated docs, address `@claude`).
   Anything written arrives as a PR via branch protection — no direct push to `main`.
3. Sandbox execution: containers + network policy + short-lived scoped tokens; no standing prod credentials.
4. Expose deploy/status/rollback as MCP tools, scoped per environment (allowlist, not a shell script with credentials).
5. Tier autonomy: dev = free deploy; staging = middle; prod = agent prepares, release manager
   authorizes, `production-gate.sh` enforces (`RELEASE_APPROVAL`).
6. Rollback is the most rehearsed path: single command, exercised regularly in staging.
   The closing loop (`docs/closing-the-loop.md`) calls it on a 3σ breach, so prove it in advance.

Metrics: share of failures triaged without paging; DORA (CI + deploy tooling already emit).

## Assist jobs (GitLab example)

`templates/gitlab/.gitlab-ci.yml.example` has an `assist` stage (runs after `test`, skipped
when irrelevant so green pipelines don't wait):

| Job | When | What |
|---|---|---|
| `agent-evals` | Schedule + `CLAUDE.md`/skills/hooks changes | Runs `evals/*.json` via `$AGENT_BIN -p`; hard fail gates config changes |
| `agent-triage` | Pipeline failure (`when: on_failure`, `allow_failure`) | Greps junit failures → `scripts/triage-failure.sh` → `triage.md` artifact |
| `agent-review` | MRs (`allow_failure`) | Diff (capped 40k) + `REVIEW.md` passes → `review.md`; posts an MR note only if `GITLAB_TOKEN` is set |

## Picking the agent (`AGENT_BIN`)

- `AGENT_BIN=claude` (default): installs `@anthropic-ai/claude-code`, `claude -p "…" --output-format text`, auth via `ANTHROPIC_API_KEY`.
- `AGENT_BIN=agent` (Cursor): installs via `https://cursor.com/install`, `agent -p "…" --output-format text`
  (text/json/stream-json supported), authenticate per [Cursor headless docs](https://cursor.com/docs/cli/headless).
  Same modes as the editor; Plan mode available headless for spec/plan passes.
