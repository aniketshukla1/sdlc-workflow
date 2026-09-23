#!/usr/bin/env bash
# Run formatter/linter after file edits so drift never accumulates.
# Scoped to the changed file; full suite belongs at commit/PR.
set -euo pipefail
INPUT="$(cat)"
FILE="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // .file_path // .path // empty' || true)"
P="$FILE"; case "$P" in /*) ;; *) P="${OLDPWD:-.}/$P";; esac
case "$FILE" in
  *.py) command -v ruff >/dev/null 2>&1 && ruff check --fix "$P" >/dev/null 2>&1 || true ;;
  *.ts|*.tsx|*.js|*.jsx) [ -f frontend/package.json ] && (cd frontend && npx --no-install prettier --write "$P" >/dev/null 2>&1 || true) ;;
esac
exit 0
