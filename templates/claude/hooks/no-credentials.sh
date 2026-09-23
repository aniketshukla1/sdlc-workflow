#!/usr/bin/env bash
# Keep credentials out of the diff. Advisory skills say "don't commit secrets";
# this hook makes violations close to impossible.
set -euo pipefail
INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .tool_input.command // empty' || true)"
if echo "$FILE" | grep -qiE '\.env(\.|$)|secrets/|id_rsa|aws/credentials'; then
  echo "BLOCKED: secrets path must not be read or edited ($FILE)." >&2; exit 2
fi
if echo "$INPUT" | grep -qiE 'password\s*=|api[_-]?key\s*=|AKIA[0-9A-Z]{16}|ghp_[A-Za-z0-9]{20,}'; then
  echo "BLOCKED: possible credential in tool input — use .env.example + synthetic fixtures." >&2; exit 2
fi
exit 0
