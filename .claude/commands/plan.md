---
description: Break spec into small verifiable tasks
---

Invoke the `planning-and-task-breakdown` skill. Start in plan mode (read-only until plan accepted). Read `intent/INTENT-<JIRAKEY>.md` + `docs/specs/SPEC-<JIRAKEY>.md`; if any success criterion lacks a test mapping, REFUSE and send the spec back (unmapped AC blocks planning). Produce vertical slices (≤5 files / ~100 lines each) where every task is test-first: Tests-first + Red-evidence + acceptance + verify + files. Name files that change, order of work, risks, and proof (`templates/spec/plan.md.example`). Save `tasks/<JIRAKEY>-plan.md` and `tasks/<JIRAKEY>-todo.md`, propose Jira sub-tasks. Commit approved `plan.md` — diff-vs-plan is checked in review; update `plan.md` in the same commit when implementation departs. No product code — show plan for approval first.
