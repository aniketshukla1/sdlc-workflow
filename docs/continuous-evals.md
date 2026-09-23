# Continuous evals in CI — stage-gate QA that keeps up with agents

Evals = prompt + checks (tests pass, lint clean, behavior unchanged, policy followed).
Collect 20–50 real tasks with expected outcomes; each prod incident adds a permanent eval.

## Wiring

- Copy `templates/evals/eval.json.example` → `evals/<name>.json` (one per task),
  `templates/evals/check.sh.example` → `evals/check.sh` (`chmod +x`).
- Include `templates/evals/agent-evals.gitlab-ci.yml.example` in `.gitlab-ci.yml`
  (runs on `CLAUDE.md`/skills/hooks changes + nightly schedule).
- Gate config changes on pass rate: a skill change that drops the rate gets reviewed before merge.

Metrics: eval pass rate over time; incident → permanent-eval time; regressions caught in CI vs prod.
