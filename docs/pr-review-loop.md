# AI in the PR review loop — Claude gives and receives reviews

Engineers judge intent + risk; identical review passes cover the rest.

## Setup

1. Enable managed Code Review or run `claude-code-action` in your own CI
   (route via Bedrock/Vertex/Foundry where traffic must stay on your cloud agreement).
2. Tech lead owns `REVIEW.md` (from `templates/review/REVIEW.md.example`):
   Bugs / Security / Compliance-vs-(intent+spec+plan) passes, Important vs Nit,
   max 5 nits, do-not-report (generated, CI-enforced).
3. Findings never approve/block alone — branch protection requires a code owner.
   A machine-readable severity tally may gate merges (platform-owned).

## Fix loop

- Tag `@claude` on a review comment → Claude addresses it and pushes the fix (PR thread records both).
- For Claude-opened PRs, babysit to merge: sweep unresolved comments + failing checks,
  address, push, until green + waiting only on code-owner approval.
- Feed findings back into `CLAUDE.md`: a mistake flagged twice gets its correction there;
  review also flags when a change made `CLAUDE.md` stale. Tune monthly (rate findings, cap nits).

Metrics: time to first review → minutes; share resolved without a human touching the branch;
defects caught pre-merge vs escaped to prod.

## Cursor path

- **CI (recommended):** the `agent-review` job in `templates/gitlab/.gitlab-ci.yml.example`
  runs the same passes headlessly (`AGENT_BIN=agent` for Cursor) and attaches `review.md`
  (+ MR note when `GITLAB_TOKEN` is set). Address findings in Cursor; the PR thread records both.
- **Editor/cloud:** Cursor's own Agent Review and cloud agents as the interactive alternative —
  project hooks (`.cursor/hooks.json`) apply there too.
- Feed findings back into router memory (`AGENTS.md` / Cursor rules): a mistake flagged twice
  gets its correction there; review also flags when a change made the memory stale. Tune monthly.
