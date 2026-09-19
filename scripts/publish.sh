#!/usr/bin/env bash
# Publish AFTER local tests + browser UI pass: validates conventions, then pushes.
# Usage (inside the issue worktree): ./scripts/publish.sh [--mr-title "[PROJ-123][Story] ..."]
# Nothing reaches origin before this script. MR is opened after it, from GitLab UI or `glab mr create`.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
"$SCRIPT_DIR/check-jira-conventions.sh" "$@"

BRANCH="$(git branch --show-current)"
if git rev-parse --abbrev-ref --symbolic-full-name "@{u}" >/dev/null 2>&1; then
  git push
else
  git push -u origin "$BRANCH"
fi

echo ""
echo "✓ Pushed $BRANCH to origin (first push happens here, never before UI pass)."
echo "  Next: open MR titled per template, then /review + /ship."
echo "  UI re-check on pipeline artifacts is optional; behavior was already approved locally."
