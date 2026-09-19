# Clarification protocol — ask when unsure (non-negotiable)

Great software comes from killing ambiguity before code. The agent MUST ask clarifying questions whenever it is not ~95% sure how/what to do. Guessing silently is a workflow violation.

## When to STOP and ask (before any spec/plan/code)

- Intent ambiguous: more than one valid interpretation of the ask.
- Scope unclear: success criteria, users, non-goals, or Jira type (Story/Bug/Task/Epic) missing.
- Missing context: no Jira key, no spec/plan file, unknown stack command, conflicting constraints.
- High-stakes / irreversible: DB migration, auth/security, public API change, prod deploy, deletion/migration, unfamiliar legacy code (`doubt-driven-development` territory).
- Confidence <95%: if you cannot restate the task + acceptance + boundaries back without hedging, you are not ready.

## How to ask (interview-me style)

1. One question at a time (max 3 per round, ordered by risk). Wait for answers — do not batch 10 questions and do not proceed on assumptions.
2. Lead with the highest-risk unknown first (scope > acceptance > technical choice > style).
3. Always surface assumptions explicitly before acting:

```
ASSUMPTIONS I'M MAKING:
1. ...
2. ...
→ Correct me now or I'll proceed with these after your answers.
```

4. Offer options with a recommended default + trade-off, never a bare open question when you can propose.
5. Record answers: update `docs/specs/SPEC-<KEY>.md` Open Questions + Jira comments. Re-state the refined task and get explicit approval (`yes, proceed`) before leaving Define/Plan.

## Phase-specific minima

- Intake/Define (`/spec`): no code until Jira success criteria + non-goals + Jira type confirmed. Vague ask → `interview-me` → `idea-refine` → spec.
- Plan (`/plan`): no tasks until dependency order + slice boundaries + API contracts confirmed.
- Build (`/build`): no implementation until Jira key + [Type] + branch `PROJ-123-summary` + target files confirmed for that slice.
- Verify/Review/Ship (`/test`, `/review`, `/ship`): if evidence is red/ambiguous (failing test, unclear error, perf regression), stop, report, ask — never weaken the bar to get green.

## Anti-patterns (violations)

- "I'll assume X and fix later" on scope/acceptance/security choices.
- Asking zero questions on a vague multi-file request.
- Burying 5 questions inside a code delivery instead of asking first.
- Treating silence as approval for irreversible actions.

Verification: every Define/Plan MR description links the answered questions; no open High-risk question survives into Build.
