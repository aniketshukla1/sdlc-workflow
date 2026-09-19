#!/usr/bin/env bash
# Create Jira branch + worktree: ./scripts/new-issue.sh PROJ-123 Story short-summary
# Convention: branch PROJ-123-short-summary (Jira key first, NO feat/ prefix).
set -euo pipefail

usage() { echo "Usage: $0 <JIRA-KEY> <JiraType> <short-summary-slug>"; echo "  e.g. $0 PROJ-123 Story user-login"; echo "  JiraType: Story|Bug|Task|Sub-task|Epic"; exit 1; }
[[ $# -eq 3 ]] || usage

KEY="$1"; TYPE="$2"; SLUG="$3"

[[ "$KEY" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]] || { echo "ERROR: bad Jira key '$KEY' (want PROJ-123)"; exit 1; }
case "$TYPE" in Story|Bug|Task|Sub-task|Epic) ;; *) echo "ERROR: bad Jira type '$TYPE'"; usage ;; esac
[[ "$SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || { echo "ERROR: bad slug '$SLUG' (kebab-case, e.g. user-login)"; exit 1; }

BRANCH="${KEY}-${SLUG}"
NUM="${KEY##*-}"
REPO="$(basename "$(pwd)")"
WORKTREE="../${REPO}-${NUM}"

[[ ${#BRANCH} -le 60 ]] || { echo "ERROR: branch '$BRANCH' >60 chars, shorten slug"; exit 1; }
git rev-parse --verify "$BRANCH" >/dev/null 2>&1 && { echo "ERROR: branch $BRANCH exists"; exit 1; }
[[ -e "$WORKTREE" ]] && { echo "ERROR: worktree path $WORKTREE exists"; exit 1; }

git fetch origin main -q 2>/dev/null || true
git checkout main -q 2>/dev/null || git checkout -b main -q || true
git pull --ff-only -q 2>/dev/null || true
git checkout -b "$BRANCH" -q
git worktree add "$WORKTREE" "$BRANCH" -q
# Local-only: NOTHING is pushed to origin here. Push happens via
# scripts/publish.sh and only after local tests + browser UI pass.

echo "✓ Branch:    $BRANCH  [Jira type: $TYPE] (local only, not pushed)"
echo "✓ Worktree:  $WORKTREE"
echo "✓ Commits:   ${KEY} [${TYPE}] <feat|fix|...>: ..."
echo "✓ MR title:  [${KEY}][${TYPE}] <summary>"
echo "  Next: cd $WORKTREE && /plan or /build auto"
