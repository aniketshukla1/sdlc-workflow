---
description: Five-axis review before merge
---

Invoke `code-review-and-quality` (+ `code-simplification`, `security-and-hardening`, `performance-optimization` as needed; `web-performance-auditor` via `/webperf` for UI). Runs AFTER `./scripts/publish.sh` (first push, post-UI-pass). Review the pushed branch diff against the spec + CONSTRAINTS + Definition of Done. Label findings Critical/Required vs Nit/Optional/FYI. Do not merge with unresolved Required.
