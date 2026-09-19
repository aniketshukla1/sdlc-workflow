# Jira Flaky-test template — labels: flaky

h2. Test
- Suite / file / case: ... (e.g. frontend e2e/checkout.spec.ts › applies coupon)
- First flaked: ... | Quarantined: ... | Expires: ... (+14 days default)

h2. Failure evidence
- Pipeline / MR link: ...
- Failure output (excerpt): ...
- Flake rate: ... (e.g. 3/10 runs)

h2. Owner
- Assignee (fix owner): ...

h2. Exit criteria (close ONLY when one is true)
- [ ] Fixed + green 7 consecutive days → unquarantine, link proof
- [ ] Deleted deliberately → reason recorded + spec/plan updated (no silent deletes)
- [ ] Expired with no fix → escalate: new expiry + reason, or delete per above

Branch: N/A (quarantine is a test annotation referencing this key, not product code)
Skill on start: debugging-and-error-recovery
