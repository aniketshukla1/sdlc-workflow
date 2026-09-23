#!/usr/bin/env bash
# Triage a failed build non-interactively. Read-only judgment step — safe to run in CI.
# Usage: ./scripts/triage-failure.sh <build-log>  # appends triage.md for the MR thread
set -euo pipefail
LOG="${1:-out/build.log}"
claude -p "Read the build log at $LOG. Identify the most likely cause, say whether the failure looks flaky or real, and write a three-line summary for the PR thread." >> triage.md
cat triage.md
