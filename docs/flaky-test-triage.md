# Flaky-test triage — quarantine with an expiry, not a graveyard

Quarantine keeps the suite green without deleting signal. This ritual keeps quarantine honest: every quarantined test is a tracked issue with an owner and an expiry, reviewed weekly.

## Rules

1. **No issue → no quarantine.** The SAME MR that quarantines a test files a Jira issue from `templates/jira/flaky-test.md` (label `flaky`). The quarantine annotation references the key (e.g. `test.skip("PROJ-456 flaky: coupon race")`, `pytest.mark.skip(reason="PROJ-456")`).
2. **Every quarantine has owner + expiry** (+14 days default). Expired issues escalate — they are never auto-closed.
3. **Close only via:** fixed + 7 consecutive green days (link proof), or deliberate deletion (reason recorded, spec/plan updated).

## Weekly ritual (15 min, part of planning)

- Open the saved filter: `labels = flaky AND status != Done ORDER BY duedate ASC` (save as board "Flaky triage").
- Expired? → owner decides: fix-this-week (new date + reason) or delete-deliberately.
- Expiring soon? → confirm the owner is still right.
- Watch the metric: open count + median age. A growing count is suite rot — file it as a tech-debt Story, not background noise.

## Mechanics (find flakes, don't hide them)

- Playwright: `retries: 2` on CI + HTML reporter. A test that passes only on retry IS flaky — quarantine + file, don't celebrate the green.
- pytest: `pytest --lf` to reproduce last failures locally; rerun plugins (e.g. `pytest-rerunfailures`) only with the Jira link in a comment.
- Retries without triage (`retries: 5`, reruns with no issue) are a violation on sight — same as deleting the test.

## Anti-patterns

- Quarantine without issue/owner/expiry. Deleting a flaky test to get green. Letting expired issues sit.
