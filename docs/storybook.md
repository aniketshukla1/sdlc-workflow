# Storybook — your component catalog (free, local, no account)

No Figma means the code is the design system. Storybook exhibits it: every component in every state, browsable in one page, without clicking through the app.

## Setup (once per project, 10 min)

```bash
cd frontend
npx storybook@latest init   # scaffolds .storybook/, example stories, scripts
npm run storybook           # local catalog at http://localhost:6006
```

Keep the scaffolded addons; make sure the accessibility addon is enabled. If your Storybook version offers the Vitest addon or test-runner, enable it in step 2 below — not day one.

## Story rules (per UI slice — part of Definition of Done for frontend work)

1. **New/changed component ships with stories for its states**: default, loading, empty, error, disabled, long-text. States are the spec AC-2 pattern made visible.
2. **One play function for the key interaction** (e.g. click submits, Esc closes dialog, toggle switches theme). If it can't be driven in a story, it won't be drivable in a test.
3. **Stories use the same tokens as the app** (shadcn/theme only — the token-lint rule from `docs/ui-ux-testing.md` applies here too). A story with ad-hoc hex is a bug, not a demo.
4. **Adapt `templates/frontend/Button.stories.tsx.example`** (copy next to your component, change props to match).

## Step 2 — stories as tests (wired: `storybook-tests` CI job)

Stories prove behavior headlessly — smoke, play functions, and axe per story (axe needs the a11y addon from setup):

```bash
cd frontend
npm i -D @storybook/test-runner   # one time; pins the runner to your Storybook version
npm run build-storybook
npx http-server storybook-static -p 6006 --silent &
npx wait-on http://127.0.0.1:6006
npx test-storybook --url http://127.0.0.1:6006 --maxWorkers=2
```

CI (`storybook-tests` job, frontend-changing MRs) runs exactly this on the playwright image. A failing play function or axe check fails the MR like any other test.

## What NOT to storybook

- One-off page shells with no reuse and no states (cover with e2e instead).
- Backend-driven copy variations (that's content, not components — cover with integration tests).
- Pixel-tweaking existing stories without a Jira reason (visual churn without acceptance criteria).

## When it pays vs when to delete

Keep it if: the same variant gets built twice, "which dialog do we use?" debates disappear, or dark-mode breaks get caught in stories first. Delete (or never start) if nobody opens `:6006` for two weeks — the Playwright snapshot flow in `docs/ui-ux-testing.md` still carries the safety net.
