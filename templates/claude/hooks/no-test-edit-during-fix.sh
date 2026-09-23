#!/usr/bin/env bash
# Protect the feedback loop: during a fix task the agent must not weaken the check.
# Set FIX_MODE=1 when running /fix or a bug-fix slice. Hook blocks test edits in that mode.
# Alternative: check the diff in review and reject any test change without a flaky-Jira link.
set -euo pipefail
FILE="$(jq -r '.tool_input.file_path // .tool_input.path // .tool_input.file // .file_path // .path // empty' < /dev/stdin || true)"
if [ "${FIX_MODE:-0}" = "1" ]; then
  case "$FILE" in
    *test_*.py|*tests/*|*.test.ts*|*.spec.ts|*e2e/*)
      echo "BLOCKED: FIX_MODE=1 — do not edit test files during a fix. Fix the code, not the test." >&2
      echo "If the test itself is wrong, stop and ask for human approval + follow-up Jira." >&2
      exit 2 ;;
  esac
fi
exit 0
