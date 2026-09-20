---
description: Prove it works — reproduce, fix, guard
---

Invoke `test-driven-development` + `debugging-and-error-recovery` (+ `browser-testing-with-devtools` for UI). Reproduce first, localize, reduce, fix, add regression guard — all LOCAL, no push. Then boot `./scripts/ui-verify.sh` and hand the browser URLs + UI steps to the human; the human UI pass is the push gate. Report failing/passing commands (`pytest`, `vitest`, `playwright`, `ruff`, `mypy`, `eslint`, `tsc --noEmit`) with output, not claims.
