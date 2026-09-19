# Renovate — automated dependency updates (GitLab)

`pip-audit` / `npm audit` failing the build is an alarm. Renovate is the firefighter: it opens update MRs (grouped, scheduled, auto-merging patches) so the alarm doesn't sit red for weeks.

## Setup (one time per project)

1. Copy the config and make it yours:
   ```bash
   cp templates/renovate/renovate.json.example renovate.json
   # replace "your-devops-lead" with a real reviewer
   ```
2. Pick a runner (Renovate is GitHub-native; on GitLab you host the runner):
   - **Option A — Mend hosted app** (easiest): install the Renovate GitLab app on your group, add `renovate.json` at root, done.
   - **Option B — scheduled pipeline job**: add a bot token as a masked CI variable `RENOVATE_GITLAB_TOKEN` (`api` scope), create a weekly Pipeline schedule, and add this job to `.gitlab-ci.yml`:
   ```yaml
   renovate:
     image: { name: renovate/renovate:latest, entrypoint: [""] }
     variables:
       RENOVATE_CONFIG_FILE: renovate.json
       RENOVATE_PLATFORM: gitlab
       RENOVATE_ENDPOINT: $CI_API_V4_URL
       RENOVATE_TOKEN: $RENOVATE_GITLAB_TOKEN
     script: [renovate "$CI_PROJECT_PATH"]
     rules: [{ if: $CI_PIPELINE_SOURCE == "schedule" }]
   ```
3. Allow auto-merge in GitLab: Settings → Merge requests → check "Allow merge when pipeline succeeds" and "Pipelines must succeed". CODEOWNERS stays authoritative: manifest paths (`package.json`, `requirements*.txt`) list `@devops-lead`, so even patch MRs wait for that approval before automerging.

## How it fits this workflow (read this, it's deliberate)

- **Bot branches are exempt from Jira naming** (`renovate/*` passes `check-jira-conventions.sh` automatically) — they carry no Jira key by design. Everything else still applies: full pipeline (audit/tests/e2e), CODEOWNERS approval, squash-merge.
- **Security updates never automerged**: `vulnerabilityAlerts` MRs get the `security` label and always wait for a human, even for patches.
- **Majors are grouped but human-gated**: one MR per ecosystem (`npm non-major`, `python non-major`), never automerged on majors — a major can break the OpenAPI contract, which is a spec-level decision, not a bot decision.

## Validate the config locally

```bash
npx --yes -p renovate renovate-config-validator renovate.json
```
