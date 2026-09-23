#!/usr/bin/env bash
# Block edits to protected paths: generated, frozen legacy, secrets, build output.
# Fast + scoped: checks only the file in this action. Heavier checks belong at commit/PR.
set -euo pipefail
FILE="$(jq -r '.tool_input.file_path // .tool_input.path // empty' < /dev/stdin || true)"
case "$FILE" in
  *src/gen/*|*generated*|*storybook-static/*|*dist/*|*.next/*|*__pycache__/*|*.pyc)
    echo "BLOCKED: generated/build output is read-only ($FILE)." >&2; exit 2 ;;
  *backend/v1/*|*legacy/*)
    echo "BLOCKED: frozen legacy path ($FILE) — changes go in v2/ per CLAUDE.md." >&2; exit 2 ;;
  *.env|.env.*|*secrets/**|.aws/*|.ssh/*)
    echo "BLOCKED: secrets path ($FILE) must never enter agent context." >&2; exit 2 ;;
esac
exit 0
