# Parallel sessions and subagents

One engineer drives several streams. A **parallel session** is another full agent instance
in its own worktree on its own task. A **subagent** runs inside one session as a scoped
helper with its own context + tool limits for jobs that recur (verify, simplify, research).

## Parallel sessions

1. Split work by `tasks/<KEY>-plan.md` — tasks touching different files can run parallel;
   tasks sharing files run sequential in one session.
2. One worktree per task: `git worktree add ../<repo>-123 PROJ-123-slug`
   (see `docs/branching-and-mr-policy.md`; never share a checkout; suffix compose ports/DB per key).
3. Start with 2–3 sessions. Ceiling = how many streams one person can review properly.
   Tune permissions so safe commands (`git`, `pytest`, `ruff`, `npm run`) don't wait on approvals.
4. Controls come from repo config: hooks + permissions apply to all sessions; actions are
   logged + attributed to the engineer who ran them.

## Subagents

Copy `templates/agents/*.example` → `.claude/agents/` (checked into Git, shared by the team).
Each file: name, when-to-use description, allowed tools.

| Subagent | Job |
|---|---|
| `verifier` | Runs the app, exercises changed + 2 neighboring flows, reports vs `plan.md` Proof. Reports only, never fixes. |
| `simplifier` | Strips complexity before commit (Chesterton's Fence, Rule of 500). No behavior change. |
| `researcher` | Blast-radius mapping (owners, callers, schemas, coverage) without flooding main context. Read-only. |

The feedback loop (`docs/automation-and-ui-verification.md`) runs through the whole task;
the verifier subagent is the final fresh-context check once the session believes work is done.

Metrics: concurrent sessions per engineer while review holds (OTel); steering-vs-waiting share;
merged changes per engineer per week alongside rework rate.
