# Code graphs + test stack (recommended, FastAPI + React)

Use graphs to UNDERSTAND (where will this change ripple?) and tests to PROVE (does it work?). One of each is mandatory; the rest are defaults.

## 1. Code graph — Graphify (primary, already a skill here)

Graphify (`/graphify`) turns the repo into a persistent, queryable knowledge graph (`graphify-out/graph.json` + `graph.html` + `GRAPH_REPORT.md`) with god-node / community / path analysis and an honest EXTRACTED/INFERRED/AMBIGUOUS audit trail.

When to use it in this SDLC:
- Brownfield intake + Plan: `/graphify .` once (or `--update` after big merges), then `graphify query "<area>"` / `path "<A>" "<B>"` / `explain "<node>"` to map blast radius BEFORE writing the spec/plan. Paste the 3–5 relevant nodes + one surprising connection into the spec's Boundaries section.
- Build on unfamiliar code: query before touching (`doubt-driven-development` + graph evidence beats confident guessing).
- After merge: `graphify --update` so the next issue starts from a fresh map. `graphify-out/` stays gitignored (local cache, like `node_modules/`).

Why it fits: persistent across sessions (spec/plan files + graph carry handoffs), catches cross-module coupling (Hyrum's Law at the seams), and answers "what calls X?" without reading 50 files.

Complements (lightweight, no new infra):
- `ast-grep` / `rg` for structural search ("all Pydantic models with field X", "all shadcn Dialog usages").
- LSP (pyright/tsserver via Cursor/OpenCode) for precise go-to-refs during slices.
- GitLab code navigation as fallback in MRs.
- Heavy graph DBs (Neo4j/FalkorDB export via `graphify --neo4j`) ONLY for large monorepos — not the default.

## 2. Test stack (this is what lets you verify in UI only)

Backend — FastAPI (`backend/`):
- `pytest` + `pytest-asyncio` + `pytest-cov` (≥80% on touched modules, `--cov-fail-under=80` in CI).
- `httpx` / FastAPI `TestClient` for route integration; `respx` to mock outbound HTTP; `factory-boy` or `polyfactory` for fixtures.
- Migration check: `migration-check` CI job (`upgrade head → downgrade base → upgrade head` on a scratch DB) — see `docs/migration-safety.md`.
- Contract: snapshot `openapi.json` diff on API changes; optional `schemathesis` fuzz for property-based API testing.
- Static: `ruff`, `mypy` (strict on touched), `pip-audit` (zero critical/high).
- Mutation: `mutmut` on high-risk modules (auth/validation), zero survived — see `docs/spec-to-tdd-and-coverage.md`.

Frontend — React + Tailwind + shadcn (`frontend/`):
- `vitest` + `@testing-library/react` + `user-event` (behavior, not snapshots) + `msw` (API mocks) for unit/integration. Prefer `*ByRole` queries — they assert accessible markup by construction.
- `playwright` (REQUIRED for UI-only verification): happy + error paths, auth setup project, trace/video/screenshots on failure, artifacts uploaded from CI. Changed flows add `toHaveScreenshot()` baselines (1280px + 390px, light + dark) — full system in `docs/ui-ux-testing.md`.
- `@axe-core/playwright` (REQUIRED): zero serious/critical violations on every touched route (happy + empty + error states); keyboard-nav test per flow.
- Storybook catalog for components + states (`docs/storybook.md`); `npm run build-storybook` gated in CI.
- `eslint` (+ `eslint-plugin-tailwindcss`: class order, token discipline) + `tsc --noEmit`; Lighthouse CI budgets enforced in pipeline (`lighthouse` job: LCP <2.5s, CLS <0.1 on public routes).

E2E data rule: seed via API fixtures per run (never depend on shared staging data); quarantine flaky tests, never silently delete.

## 3. Minimal install deltas (per project)

```bash
# backend
pip install -U pytest pytest-asyncio pytest-cov httpx respx factory-boy pip-audit mutmut
# frontend
cd frontend && npm i -D vitest @testing-library/react @testing-library/user-event msw \
  @playwright/test @axe-core/playwright @lhci/cli eslint-plugin-tailwindcss
npx playwright install --with-deps
# code graph (local dev only)
pip install graphifyy  # or: uv tool install graphifyy
```

## 4. Mapping to skills/commands

- Understand: `context-engineering` + Graphify queries → `/spec`, `/plan`.
- Prove: `test-driven-development` (pyramid 80/15/5) + `browser-testing-with-devtools` + `debugging-and-error-recovery` → `/test`, `/build`.
- Gate: `code-review-and-quality`, `security-and-hardening`, `performance-optimization` + CI artifacts → `/review`, `/webperf`, MR.
