#!/usr/bin/env bash
# Block edits/reads to protected paths: generated, frozen legacy, secrets, build output.
# Dual-schema: Claude (.tool_input.file_path) + Cursor (.file_path, .attachments[].file_path).
# Exit 2 blocks in both hosts (Cursor: deny). Unrecognized input fails open (exit 0).
# Tailor the pattern list to your repo; approve changes to this file like code.
set -euo pipefail
INPUT="$(cat)"
FILES="$(echo "$INPUT" | jq -r '[.tool_input.file_path, .tool_input.path, .file_path, .path] | map(select(. != null)) | join("\n")' 2>/dev/null || true)"
ATT="$(echo "$INPUT" | jq -r '[(.attachments // [])[].file_path] | map(select(. != null)) | join("\n")' 2>/dev/null || true)"
HIT="$(printf '%s\n%s' "$FILES" "$ATT" | grep -E 'src/gen/|generated|storybook-static|/dist/|\.next/|__pycache__|\.pyc$|/(v1|legacy)/|\.env(\.|$)|\.env$|secrets/|\.ssh|\.aws/credentials' | head -n 1 || true)"
if [ -n "$HIT" ]; then
  echo "BLOCKED: protected path ($HIT) — generated/build output is read-only; legacy v1/ is frozen (use v2/); secrets never enter agent context." >&2
  exit 2
fi
exit 0
