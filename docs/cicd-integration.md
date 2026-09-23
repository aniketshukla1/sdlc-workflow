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
