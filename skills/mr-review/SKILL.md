---
name: mr-review
description: Hard pre-merge review of a colleague MR judged against its Jira issue. Use when reviewing another person's merge request, when asked to review an MR, or before approving any MR for merge. Use when you need Jira acceptance-criteria traceability plus five-axis gates before anything merges.
---

# MR Hard Review (colleague MRs)

## Overview

You are the last line of defense before `main`. A green pipeline is necessary but never sufficient: pipelines don't check Jira coverage, architecture stability, or missing scope. This skill judges the MR against its Jira description acceptance-criteria-by-acceptance-criteria, then runs hard quality gates, then delivers a verdict. Review the diff, never the author.

## Inputs (required — STOP and ask if any is missing)

1. **MR identifier** — URL or branch (`PROJ-123-summary`).
2. **Jira key + type** — must be linked in the MR (`[PROJ-123][Type]` + Jira link). No Jira link → verdict is Request changes immediately, no further review needed.
3. **Pipeline + artifact access** — status of every gate (conventions, lint, typecheck, coverage, mutation, e2e, axe, LHCI, storybook, audit).
4. **Publish credentials** — `GITLAB_TOKEN` with `api` scope (reviewer identity). Approving from the MR author's token is refused — arrange another reviewer.

## Phase 0 — Gather (read-only, no opinions yet)

- Full MR diff; is the MR template completely filled (Jira+type, spec section, test evidence, checklist, rollback)?
- Jira description: acceptance criteria list, test plan, rollout/risks, Figma/design reference if any.
- Linked spec section + plan tasks for this slice.
- Pipeline: green on every job? Artifacts actually attached (junit, coverage, mutants stats, playwright report, snapshots, LHCI)?
- CODEOWNERS: required owners assigned, approvals present where matched?

## Phase 1 — Jira vs MR traceability (the core — catches missing parts)

Build this table; every row needs evidence, never prose claims:

| Jira AC | Implemented? (file:line) | Tested? (test + level) | Evidence | Status |
|---|---|---|---|---|
| AC-1 | … | … | pipeline link / command output | covered / partial / missing |
| AC-2 | … | … | … | … |

- **Missing AC → Required (blocking).** The MR does not do what Jira asked.
- **Extra scope** (files outside the plan, unrelated refactors, touched-but-deliberately-untouched) → Required: split into its own MR or file a follow-up Jira. Scope discipline protects architecture stability.
- **Jira test plan vs MR tests:** every claimed check must map to a real test + output. "Manually verified" without steps is a gap, not evidence.

## Phase 2 — Five-axis hard review

- **Correctness:** logic, edge/error paths, concurrency/race conditions, data integrity, migration reversibility. Would you bet production on each hunk?
- **Design / architecture stability:** boundaries respected (spec Always/Ask/Never)? ADRs followed? New dependencies justified (no drive-by deps)? Public/API contracts unchanged — or changed with major + migration note? No layering violations (UI reaching past services, validation skipped at boundary)?
- **Readability:** naming reveals intent, no dead code/debug output, slices ~100 lines, no formatting+behavior mixes.
- **Tests:** pyramid respected? Red evidence present (fail-without/pass-with)? Snapshots reviewed, not rubber-stamped (`--update-snapshots` diff inspected)? Quarantines carry `flaky` Jira issues? Mutation survivors on touched high-risk code?
- **Security / performance:** OWASP Top 10 at every touched trust boundary (auth, input, queries, secrets, CORS/rate-limit), audit clean, no N+1, LHCI budgets held.

Severity labels — use exactly these:
- **Critical:** merge-never (data loss, breach, corrupt migration, broken contract). One Critical = Request changes alone.
- **Required:** must fix, or file a *blocking* follow-up Jira the author accepts before merge.
- **Nit / Optional / FYI:** non-blocking style, suggestions, learning notes.

## Phase 3 — Evidence + safety verification

- Coverage/mutation/snapshot/axe/LHCI artifacts green AND attached (a claim without an artifact is open).
- Migrations: reversible, rollback executable (not theoretical), data backup considered.
- Feature flags for incomplete work: owner + expiry present.
- No TODOs-that-matter, no debug output, no secrets; lockfiles committed if manifests changed.

## Phase 4 — Verdict (exactly one)

- **Approve:** zero Critical/Required open + all Jira AC covered + evidence attached + safety verified. State the risk rating (Low/Medium + why) even on approve.
- **Request changes:** blocking list grouped as Missing AC / Correctness / Safety — each item with file:line + why it blocks + suggested fix. Nothing vague.
- **Comment:** non-blocking Nits/FYIs + suggested follow-up Jira titles (author files them).
- Always close with: covered AC count, missing AC count, open Required/Critical count, risk rating.

## Phase 5 — Publish to the MR (comments + review state)

A verdict that only lives in chat doesn't count. Write findings first, then publish:

1. Save `reviews/PROJ-123-review.md` (verdict + traceability table + counts + risk) and `reviews/PROJ-123-findings.tsv` (`<path><TAB><line><TAB><severity><TAB><comment>`, Critical/Required only).
2. Run `./scripts/mr-publish.sh --mr <IID> --verdict approve|request-changes|comment --body-file <md> [--inline <tsv>]`.
   - Approve → posts summary note + approves via API. Rejected approvals (self-approval, missing rights) fail loudly — never bypass.
   - Request changes → posts summary + one UNRESOLVED inline discussion per finding. With "all threads must be resolved" enabled, unresolved threads ARE the merge block on GitLab.
   - Comment → summary only, no state change.
3. Verify + report the posted URLs (`.../merge_requests/<iid>#note_<id>`). Re-fetch if in doubt.

## Common rationalizations

| Rationalization | Reality |
|---|---|
| "Pipeline is green so it's fine" | Pipelines don't check AC coverage, scope creep, or architecture. That's this skill. |
| "It's a small MR" | Small MRs still break contracts and migrate data. Check the seam. |
| "The author is senior" | Review the diff, not the author. Seniors write the subtlest bugs. |
| "Approve now, fix later" | Later never comes. Required means Required — or a blocking follow-up Jira accepted pre-merge. |
| "Tests exist" | Do they fail without the change? No red evidence, no proof. |
| "Snapshots were updated" | Was the image diff inspected, or rubber-stamped? An updated snapshot can bless a regression. |

## Red flags

- No Jira link in the MR; ACs untestable ("works correctly", "fast enough").
- Approval requested with red/missing pipeline jobs ("CI is flaky" without a `flaky` issue).
- Unresolved Required threads from a previous round.
- Scope that grew since the plan with no spec update.
- Pressure to approve fast ("needed today") — speed up the review, never lower the bar.
- A verdict delivered only in chat, never posted to the MR.
- Approving your own MR (author token) — refused by the publish script; arrange another reviewer.

## Verification

Before delivering the verdict, confirm:

- [ ] Every Jira AC has a table row with a status (no AC skipped)
- [ ] Every Required/Critical cites file:line + reason + suggested fix
- [ ] Evidence artifacts checked, not assumed from prose
- [ ] Architecture/stability explicitly judged (boundaries, contracts, migrations, flags)
- [ ] Verdict is exactly one of Approve / Request changes / Comment, with counts + risk rating
- [ ] Verdict published to the MR (note URL + inline threads + approve/withheld state confirmed)
