#!/usr/bin/env bash
# Install/sync addyosmani/agent-skills for Cursor + OpenCode (dual-target).
# Fixes upstream per-skill gap #361 by always copying repo-level references/ alongside.
set -euo pipefail

UPSTREAM_URL="https://github.com/addyosmani/agent-skills.git"
CACHE_DIR="${SKILLS_CACHE:-/tmp/agent-skills-upstream}"
SKILLS_ARG="${1:- --all}"
SELECTED=""

usage() {
  echo "Usage: $0 [--all] [--skills a,b,c] [--cache-dir DIR]"
  echo "  --all            install all 25 skills (default)"
  echo "  --skills a,b,c   install subset (e.g. spec-driven-development,test-driven-development)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all) SKILLS_ARG="all"; shift ;;
    --skills) SELECTED="$2"; SKILLS_ARG="subset"; shift 2 ;;
    --cache-dir) CACHE_DIR="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

echo "→ Fetching upstream skills into $CACHE_DIR"
if [[ -d "$CACHE_DIR/.git" ]]; then
  git -C "$CACHE_DIR" pull --ff-only -q
else
  rm -rf "$CACHE_DIR" && git clone -q --depth 1 "$UPSTREAM_URL" "$CACHE_DIR"
fi

install_targets() { # $1 = skill dir name
  local skill="$1"
  # Every host that consumes SKILL.md from a checkout directory.
  # (.codex-plugin + .agents/plugins read ./skills/ in place — no copy needed.
  # Command Code / skills-CLI discover ./skills/ directly — no copy needed.)
  for target in .cursor/skills .opencode/skills .claude/skills .agents/skills .github/skills .kiro/skills .gemini/skills; do
    mkdir -p "$target/$skill"
    cp -r "$CACHE_DIR/skills/$skill/." "$target/$skill/"
    mkdir -p "$target/$skill/references"
    cp -rn "$CACHE_DIR"/references/. "$target/$skill"/references/ 2>/dev/null || true
  done
  # Fix #361: ensure shared checklists travel with every install
  mkdir -p references
  cp -rn "$CACHE_DIR"/references/. ./references/ 2>/dev/null || true
}

if [[ "$SKILLS_ARG" == "subset" ]]; then
  IFS=',' read -ra LIST <<< "$SELECTED"
  for s in "${LIST[@]}"; do
    s="$(echo "$s" | xargs)"
    [[ -d "$CACHE_DIR/skills/$s" ]] || { echo "Unknown skill: $s"; ls "$CACHE_DIR/skills"; exit 1; }
    install_targets "$s"
  done
else
  for d in "$CACHE_DIR"/skills/*/; do
    install_targets "$(basename "$d")"
  done
fi

# Project-local skills (this template's own skills/, e.g. mr-review) → every agent.
if [[ -d "skills" ]]; then
  for d in skills/*/; do
    [[ -f "$d/SKILL.md" ]] || continue
    skill="$(basename "$d")"
    for target in .cursor/skills .opencode/skills .claude/skills .agents/skills .github/skills .kiro/skills .gemini/skills; do
      mkdir -p "$target/$skill"
      cp -r "$d/." "$target/$skill"/
    done
    echo "✓ local skill: $skill"
  done
fi

echo "✓ Installed to .cursor/skills/ + .opencode/skills/ + .claude/skills/ + .agents/skills/ + .github/skills/ + .kiro/skills/ + .gemini/skills/ (with references/)"
echo "  Verify: ls .cursor/skills | wc -l && ls .opencode/skills | wc -l"
echo "  Next: copy AGENTS.md + CONSTRAINTS.md.example→CONSTRAINTS.md into your project root."
