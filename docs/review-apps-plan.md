# Review apps per MR — PLAN (not implemented yet)

**Goal:** every UI-changing MR gets a live, seeded preview URL so testers approve the deployed artifact instead of local compose. Kills "works on my machine" and makes MR evidence links live.

**Non-goals (v1):** production data copies, perf/load testing on review apps, multi-service orchestration beyond app + postgres.

## Proposed design

- `review` job in `.gitlab-ci.yml` (runs on frontend/backend-changing MRs): build images, deploy to `review/$CI_COMMIT_REF_SLUG`, `on_stop: stop_review` for auto-cleanup.
- One seeded demo DB per review app (migrations + fixture seed on deploy, torn down with the app).
- Auto-stop after 3 days idle; manual stop button always available.
- MR template gains a `Review app: <url>` line; the UI checklist runs there instead of localhost.

## Open questions

- Hosting: GitLab Agent for Kubernetes vs a compose host? (k8s agent is the standard path)
- Secrets per review app (scoped deploy tokens, seeded demo users — never prod credentials).
- Cost guard: concurrent-app cap + auto-stop policy; who pays for idle apps.

## Done criteria (to implement later)

- [ ] MR with UI changes gets a working review URL within ~10 min of push
- [ ] Teardown automatic on merge + idle timeout; zero orphaned apps after a week
- [ ] UI checklist in `docs/automation-and-ui-verification.md` updated to run on the review URL
