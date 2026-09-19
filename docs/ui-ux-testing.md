# UI/UX testing — efficient layers that compound to near-perfect

One technique never catches everything. Six cheap layers do. Each is scoped so the suite stays fast: changed flows get everything, the whole app gets lint + sweeps.

## The layers (cheapest first)

0. **Component catalog (Storybook).** Every component in every state, browsable without running app flows — your design system made visible. New/changed components ship with stories (see `docs/storybook.md`); `build-storybook` fails CI on broken ones.

1. **Role-query unit tests (free, always on).** Write Testing Library tests with `getByRole`/`findByRole` — if the test can find it by role+name, a screen reader can too. Accessible markup becomes a side effect of testing, not a separate chore.
2. **Token discipline (lint, not eyeballs).** `eslint-plugin-tailwindcss` (class order, no duplicates) + rule: shadcn/theme tokens only — no ad-hoc hex, no arbitrary values except layout (justify each). Violations fail lint, not review.
3. **axe sweep per touched route (seconds).** `@axe-core/playwright` zero serious/critical on every route the MR touches — happy, empty, AND error states.
4. **Visual snapshots per changed flow (the big one).** Playwright `toHaveScreenshot()` at 1280px + 390px, light + dark. Baselines committed (`*.spec.ts-snapshots/`); snapshot diffs are reviewed like code. Catches the moved-4px regressions humans miss and unit tests can't see.
5. **e2e behavior flows (already in).** Happy + one error path with trace/video, plus a keyboard-only run of the critical flow (tab order, dialog focus trap, Esc closes).
6. **Lab budgets + human design QA.** LHCI LCP/CLS on public routes; human compares new screens against the Figma link in Jira (spacing/type/hierarchy) — the only step taste can do.

## Viewport × theme matrix (changed flows only)

| | 390px | 768px | 1280px |
|---|---|---|---|
| light | snapshot | smoke | snapshot |
| dark | smoke | — | snapshot |

Smoke = loads, no horizontal scroll, no console errors. Full matrix only on design-system changes.

## States every new UI must cover (the AC-2 pattern)

loading (skeleton, never blank) → data → empty → error → disabled, plus `prefers-reduced-motion` respected for non-essential animation. Each state gets at least a unit or snapshot assertion; e2e covers happy + error.

## Commands

```bash
cd frontend
npx playwright test e2e/<flow>.spec.ts --update-snapshots  # ONLY after an INTENTIONAL visual change — then review the image diff
npx playwright test e2e/<flow>.spec.ts                     # CI mode: snapshots must match committed baselines
```
