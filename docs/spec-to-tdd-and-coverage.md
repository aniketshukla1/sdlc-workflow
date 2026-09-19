# Spec → TDD → Coverage (the code-quality core of this workflow)

Specs without tests rot; tests without specs guess. Here they are one chain: **spec AC → failing test → green → coverage gate**. No step is optional.

## The chain

```
SPEC (AC-1, AC-2, ... + Acceptance → Test map)
  → PLAN (each AC becomes ≥1 test-first task: Tests-first + Red-evidence fields)
    → BUILD (per task: write failing test → show RED → implement → GREEN → refactor → commit)
      → VERIFY (coverage bars + e2e/axe + local UI pass → publish → pipeline re-proves it)
```

## Rules

1. **Unmapped AC blocks planning.** If a success criterion has no row in the Acceptance → Test map, the spec is not ready — `/plan` must refuse and send it back.
2. **Red evidence is required, not folklore.** Every task records its failing output before the fix (e.g. `FAILED test_login_rejects_bad_email - assert 200 == 422`). "Tests pass" with no prior red is not TDD and fails `/review`.
3. **Cover the levels, not just lines:** unit (logic/edge cases) → integration (route + DB, component + API mock) → e2e (critical user flows in Playwright). Pyramid ~80/15/5.
4. **Legacy first:** untested code gets characterization tests (pin current behavior, right or wrong) BEFORE any refactor. No characterization → no refactor, no exceptions.
5. **Flaky ≠ deletable.** Quarantine + file a `flaky`-labelled Jira issue (owner + expiry) per `docs/flaky-test-triage.md`; never silent-skip to get green.

## Coverage gates (where each bar is enforced)

| Bar | Local (pre-push) | CI (post-push) |
|---|---|---|
| Backend ≥80% touched, zero new uncovered lines | `pytest -q --cov=backend --cov-fail-under=80` | `backend-test` job (junit + cobertura artifacts) |
| Frontend vitest thresholds on touched | `npm run test -- --coverage` | `frontend-test` job (coverage artifact) |
| UI flows: e2e + axe | `npm run test:e2e` (changed flows) | `e2e` job (report + screenshots/video) |
| Stories: smoke + play + axe | `npx test-storybook` (served catalog) | `storybook-tests` job |
| API contract drift visible | — | `openapi-snapshot` artifact on MRs |
| Mutation: zero survived (high-risk backend) | `mutmut run` + `mutmut export-cicd-stats` | `mutation` job (fails on `survived > 0`) |
| Perf budgets LCP/CLS (public routes) | `npm run build` + `npx @lhci/cli autorun` | `lighthouse` job (fails on budget breach) |
| Secrets/audit clean | pre-commit hook + `gitleaks`/grep | `audit` job (zero critical/high) |

## Mutation testing (`mutmut`) — proves your tests can actually catch bugs

Coverage tells you lines RAN. Mutation tells you tests CHECK: mutmut deliberately breaks your code (flips `==` to `!=`, drops `return`s) and fails you if any mutant SURVIVES — i.e. your suite didn't notice. A surviving mutant = a test to write, same workflow as a failing AC.

Scope (keep it fast): high-risk backend modules ONLY — auth, validation, billing/pricing, permission checks. List them once in `pyproject.toml`:

```toml
[tool.mutmut]
source_paths = ["backend/"]
only_mutate = ["backend/auth/*", "backend/services/validation/*"]
do_not_mutate = ["*__init__.py"]
pytest_add_cli_args_test_selection = ["backend/tests/"]
```

Local loop (before publish):

```bash
mutmut run                  # scoped by only_mutate; incremental — reruns only what changed
mutmut export-cicd-stats    # writes mutants/mutmut-cicd-stats.json
mutmut browse               # TUI: inspect each survivor, write the killing test, re-run
```

Kill workflow per survivor = mini-TDD: `mutmut apply <id>` → write the failing test → revert the mutant → test passes → rerun. Gate: `survived == 0` to publish; CI's `mutation` job enforces the same numbers.

## When it fails

- Red won't reproduce → stop, clarify (is the AC wrong?), don't "fix" the test to match broken code.
- Coverage drops on touched lines → add the missing test in the SAME task/commit, not a follow-up.
- E2E flakes → quarantine + file Jira from `templates/jira/flaky-test.md`, keep the suite green without deleting the signal. Weekly review: `docs/flaky-test-triage.md`.

## Command cheat sheet

```bash
pytest -q --cov=backend --cov-fail-under=80 backend/tests/test_<area>.py
cd frontend && npm run test -- --coverage && npx tsc --noEmit && npm run lint
cd frontend && npx playwright test e2e/<flow>.spec.ts && npx axe --help  # via @axe-core/playwright
mutmut run && mutmut export-cicd-stats  # scoped by [tool.mutmut] only_mutate; zero survived to publish
./scripts/ui-verify.sh   # same-branch browser pass = the push gate
```
