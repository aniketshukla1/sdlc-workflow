# Closing the loop on metrics — headless Maintain

A deterministic script watches prod; on breach it invokes Claude stateless/non-interactive
(CI runner or Agent SDK, sandboxed). A confidence gate (deterministic check or adversarial
reviewer) decides continue vs escalate to human. People triage + review; nobody has to start it.

## Wiring

1. Pick one metric with a stable rolling baseline (CI failure rate, post-deploy 5xx, PR cycle time).
2. Detection stays deterministic (no model): `scripts/detect-breach.sh` + `templates/maintain/bands.yaml.example`
   (`1σ` log → `2σ` diagnose read-only → `3σ` propose PR or pre-approved runbook). Version + unit-test the script.
3. Trigger: scheduled GitLab/GitHub workflow, monitoring webhook, or in-network cron.
4. Agent writes diagnosis as `intent/INTENT-<KEY>.md` (anomaly + evidence, outcome, systems, questions) —
   then it flows through `/spec → /plan → /build → /review` like anything else.
5. Triage queue: fix now / schedule / dismiss. Dismissals tune the bands.
6. When a fix ships, add an eval (`docs/continuous-evals.md`) so the class stays covered.

Examples: CI failures 3σ → quarantine flaky or open revert PR; 5xx + deploy in window → rollback;
PR-cycle drift → report to eng leadership. Chat incidents (Slack/Teams via Claude Tag + MCP):
verify metric back at baseline in-thread, write post-mortem to a versioned lessons file.

Metrics: breach → `intent.md` time (vs old incident → post-mortem-action time);
share becoming merged fixes; repeat incidents of the same class → down.
