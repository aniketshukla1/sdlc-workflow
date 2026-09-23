#!/usr/bin/env bash
# Run formatter/linter after file edits so drift never accumulates.
# Scoped to the changed file; full suite belongs at commit/PR.
set -euo pipefail
FILE="$(jq -r '.tool_input.file_path // .tool_input.path // empty' < /dev/stdin || true)"
case "$FILE" in
  *.py) command -v ruff >/dev/null 2>&1 && ruff check --fix "$FILE" >/dev/null 2>&1 || true ;;
  *.ts|*.tsx|*.js|*.jsx) [ -f frontend/package.json ] && (cd frontend && npx --no-install prettier --write "$OLDPWD/$FILE" >/dev/null 2>&1 || true) ;;
esac
exit 0
