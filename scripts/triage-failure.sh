#!/usr/bin/env bash
# Triage a failed build non-interactively (read-only judgment step — safe in CI).
# Agent-agnostic: AGENT_BIN=claude (default, needs ANTHROPIC_API_TOKEN/KEY) or
# AGENT_BIN=agent for Cursor headless (install via https://cursor.com/install,
# authenticate per Cursor headless docs). Output appends triage.md for the MR thread.
# Usage: ./scripts/triage-failure.sh <build-log-or-test-report>
set -euo pipefail
LOG="${1:-out/build.log}"
BIN="${AGENT_BIN:-claude}"
"$BIN" -p "Read $LOG (build log or test-failure report). Identify the most likely cause, say whether the failure looks flaky or real, and write a three-line summary for the PR thread." --output-format text >> triage.md
cat triage.md
