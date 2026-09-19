#!/usr/bin/env bash
# Enforce Jira conventions locally + in CI.
# Checks: branch PROJ-123-slug (no prefix) · commits "PROJ-123 [Type] type: ..." · optional MR title.
# Bot (renovate/*) branches carry no Jira key and pass through (pipeline + CODEOWNERS still gate them).
# Usage: ./scripts/check-jira-conventions.sh [--mr-title "[PROJ-123][Story] ..."] [--base origin/main]
set -euo pipefail

MR_TITLE=""; BASE="origin/main"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mr-title) MR_TITLE="$2"; shift 2 ;;
    --base) BASE="$2"; shift 2 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

BRANCH="${CI_MERGE_REQUEST_SOURCE_BRANCH_NAME:-$(git branch --show-current)}"
FAIL=0

# Bot branches (Renovate) carry no Jira key — exempt from naming/commit gates.
# Their MRs are still gated by pipeline (audit/tests) + CODEOWNERS approval.
if [[ "$BRANCH" == renovate/* ]]; then
  echo "SKIP Jira conventions (bot branch $BRANCH)"
  exit 0
fi

if [[ ! "$BRANCH" =~ ^[A-Z][A-Z0-9]+-[0-9]+-[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "FAIL branch '$BRANCH' — want PROJ-123-short-summary (Jira key first, no feat/ prefix)"
  FAIL=1
else
  echo "OK branch $BRANCH"
fi
KEY="$(echo "$BRANCH" | grep -oE '^[A-Z][A-Z0-9]+-[0-9]+' || true)"

git fetch origin main -q 2>/dev/null || true
RANGE="$BASE..HEAD"
if git rev-parse --verify "$BASE" >/dev/null 2>&1; then
  while IFS= read -r msg; do
    [[ -z "$msg" ]] && continue
    if [[ ! "$msg" =~ ^[A-Z][A-Z0-9]+-[0-9]+\ \[(Story|Bug|Task|Sub-task|Epic)\]\ (feat|fix|refactor|test|docs|chore):\ .+ ]]; then
      echo "FAIL commit '$msg' — want 'PROJ-123 [Type] <feat|fix|refactor|test|docs|chore>: ...'"
      FAIL=1
    fi
    if [[ -n "$KEY" && ! "$msg" =~ ^$KEY\  ]]; then
      echo "FAIL commit '$msg' — key must match branch ($KEY)"
      FAIL=1
    fi
  done < <(git log --format=%s "$RANGE" 2>/dev/null || true)
  echo "OK commits checked ($RANGE)"
else
  echo "SKIP commit check (no $BASE yet)"
fi

if [[ -n "$MR_TITLE" ]]; then
  if [[ ! "$MR_TITLE" =~ ^\[[A-Z][A-Z0-9]+-[0-9]+\]\[(Story|Bug|Task|Sub-task|Epic)\]\ .+ ]]; then
    echo "FAIL MR title '$MR_TITLE' — want '[PROJ-123][Type] Summary'"
    FAIL=1
  else
    echo "OK MR title"
  fi
fi

[[ $FAIL -eq 0 ]] && echo "✓ Jira conventions pass" || { echo "✗ Jira conventions failed"; exit 1; }
