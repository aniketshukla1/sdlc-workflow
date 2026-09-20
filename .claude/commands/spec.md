---
description: Define what to build — spec before code
---

Invoke the `spec-driven-development` skill. First run `interview-me` until ~95% confidence: ask clarifying questions one at a time when intent/scope/acceptance/Jira type is ambiguous, list ASSUMPTIONS I'M MAKING, and record answers. Then read the linked Jira issue + `CONSTRAINTS.md`, write `docs/specs/SPEC-<JIRAKEY>.md` covering the 6 areas (+ threat-model section for auth/data/payment/API work) with testable success criteria — every criterion gets an AC-ID mapped to ≥1 test in an Acceptance → Test map (unmapped AC = spec not ready). Also run `constraint-driven-development` if `CONSTRAINTS.md` is missing. Stop for human approval before planning. No product code in this step.
