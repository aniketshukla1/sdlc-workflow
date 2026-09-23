#!/usr/bin/env bash
# Production deploy gate: allow up to the gate, never past it without approval.
# The agent prepares the release; a named release manager authorizes it via $RELEASE_APPROVAL.
# Approval prompts belong here (Deploy), never in Build — Build hooks must not wait on humans.
set -euo pipefail
CMD="$(jq -r '.tool_input.command // .command // empty' < /dev/stdin || true)"
if echo "$CMD" | grep -qiE 'deploy.*prod|prod.*deploy|kubectl.*prod|helm.*prod'; then
  if [ -z "${RELEASE_APPROVAL:-}" ]; then
    echo "BLOCKED: production deploys need a release authorization (RELEASE_APPROVAL)." >&2
    echo "Prepare the release, then ask the release manager to approve." >&2
    exit 2
  fi
fi
exit 0
