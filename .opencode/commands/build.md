---
description: Build one slice at a time, test-driven
---

Invoke `incremental-implementation` + `test-driven-development` (+ `api-and-interface-design` for APIs, `frontend-ui-engineering` for UI, `source-driven-development` for framework calls). Confirm Jira key + type + branch `PROJ-123-summary` + worktree before coding. Work from `tasks/<KEY>-todo.md` one task at a time: red → green → refactor → commit `PROJ-123 [Type] <conventional-type>: ...`. Stay LOCAL — never push to origin; pushing happens only via `scripts/publish.sh` after the human browser UI pass. `/build auto` variant: run the whole approved plan autonomously, pausing on failures/risky steps.
