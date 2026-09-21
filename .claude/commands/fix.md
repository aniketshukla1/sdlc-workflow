---
description: Fast-track a small Bug/Task fix — test-first, no approval pauses
---

Invoke the `jira-autopilot` skill in fast-lane mode. For a small fix (Bug/Task/Sub-task, ≤2 files, no migration/auth/public-API change): confirm Jira key + type + branch `PROJ-123-summary` + worktree, write the failing test FIRST (repro), then the minimum fix, then green — one commit `PROJ-123 [Type] fix: ...`. Full local suite + lint + typecheck green with red evidence shown; browser pass only if UI is touched. Then `./scripts/publish.sh` (first push) → GitLab MR `[KEY][Type]` + Jira label + test evidence → Jira `#in-review`. No spec doc, no plan doc, no approval pauses. STOP and switch to the full lane if the fix grows past 2 files or hits migration/auth/API scope.
