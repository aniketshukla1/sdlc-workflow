#!/usr/bin/env bash
# Install the SDLC workflow by choice: global skills, current project, or a given path.
#
#   ./scripts/install-workflow.sh                          # interactive: pick scope, agents, projects
#   ./scripts/install-workflow.sh --scope global --yes     # global skills, then prompted for project paths
#   ./scripts/install-workflow.sh --scope project --project ~/my-app --yes
#   ./scripts/install-workflow.sh --scope project --project ~/my-app --agents cursor,opencode --yes
#
# Flags:
#   --scope global|project     where the workflow goes (default: ask)
#   --project PATH             target project (default: current dir; repeatable)
#   --agents a,b,c             global skill targets (default: all detected)
#                              known: cursor,opencode,claude,codex,gemini,copilot,kiro,universal
#   --skip-upstream            skip ./scripts/install-skills.sh (no network for upstream skills)
#   --no-npx                   copy skills manually instead of `npx skills add` (offline)
#   --yes                      non-interactive, accept defaults
#   -h|--help                  this help
#
# What lands where:
#   global   → skills/jira-autopilot + skills/mr-review into each agent's user skills dir
#              (via npx, or manual copy with --no-npx). Then you give project
#              path(s) that receive the executors: scripts/, templates/,
#              AGENTS.md, routers, commands, CONSTRAINTS.md.example.
#   project  → full template copy (everything committed, minus .git) into the
#              target dir + optional upstream skill sync inside it.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCOPE=""
PROJECTS=()
AGENTS_ARG=""
SKIP_UPSTREAM=0
NO_NPX=0
YES=0

usage() { sed -n '2,/^set /p' "$0" | sed 's/^# \{0,1\}//'; exit 0; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --scope) SCOPE="$2"; shift 2 ;;
    --project) PROJECTS+=("$2"); shift 2 ;;
    --agents) AGENTS_ARG="$2"; shift 2 ;;
    --skip-upstream) SKIP_UPSTREAM=1; shift ;;
    --no-npx) NO_NPX=1; shift ;;
    --yes) YES=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1 (see --help)"; exit 1 ;;
  esac
done

[[ "$SCOPE" =~ ^(global|project)?$ ]] || { echo "ERROR: --scope must be global|project"; exit 1; }

ask() { # $1 = prompt, $2 = default → prints answer
  local prompt="$1" def="$2" ans
  if [[ $YES -eq 1 ]]; then echo "$def"; return; fi
  read -r -p "$prompt [$def]: " ans
  echo "${ans:-$def}"
}

# Map agent id → global user skills dir (mirrors `npx skills` agent table).
agent_dir() {
  case "$1" in
    cursor) echo "$HOME/.cursor/skills" ;;
    opencode) echo "$HOME/.config/opencode/skills" ;;
    claude) echo "$HOME/.claude/skills" ;;
    codex) echo "$HOME/.codex/skills" ;;
    gemini) echo "$HOME/.gemini/skills" ;;
    copilot) echo "$HOME/.copilot/skills" ;;
    kiro) echo "$HOME/.kiro/skills" ;;
    universal) echo "$HOME/.agents/skills" ;;
    *) echo "" ;;
  esac
}

detect_agents() {
  for a in cursor opencode claude codex gemini copilot kiro universal; do
    d="$(agent_dir "$a")"
    [[ -n "$d" && -d "$d" ]] && echo "$a"
  done
  return 0
}

install_skills_global() { # $1 = comma list or empty (all detected)
  local list="$1"
  if [[ $NO_NPX -eq 0 ]] && command -v npx >/dev/null; then
    if [[ -n "$list" ]]; then
      local args=()
      IFS=',' read -ra SEL <<< "$list"
      for a in "${SEL[@]}"; do args+=(-a "$a"); done
      # shellcheck disable=SC2068
      npx -y skills add "$REPO_ROOT" -g -y "${args[@]}"
    else
      npx -y skills add "$REPO_ROOT" -g -y
    fi
    return
  fi
  # Offline fallback: manual copy of this pack's skills.
  local targets=()
  if [[ -n "$list" ]]; then IFS=',' read -ra targets <<< "$list"; else targets=($(detect_agents)); fi
  [[ ${#targets[@]} -gt 0 ]] || targets=(universal)
  for a in "${targets[@]}"; do
    d="$(agent_dir "$a")"
    [[ -n "$d" ]] || { echo "WARN: unknown agent '$a', skipped"; continue; }
    mkdir -p "$d"
    for s in "$REPO_ROOT"/skills/*/; do
      [[ -f "$s/SKILL.md" ]] || continue
      skill="$(basename "$s")"
      mkdir -p "$d/$skill"
      cp -r "$s/." "$d/$skill/"
      echo "✓ global skill $skill → $d"
    done
  done
}

copy_template() { # $1 = target dir
  local target="$1"
  mkdir -p "$target"
  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$REPO_ROOT" archive HEAD | tar -x -C "$target"
  else
    (cd "$REPO_ROOT" && tar cf - --exclude=.git .) | (cd "$target" && tar xf -)
  fi
  echo "✓ template → $target"
  if [[ $SKIP_UPSTREAM -eq 0 ]]; then
    (cd "$target" && ./scripts/install-skills.sh --all) || echo "WARN: upstream skill sync failed (offline?) — rerun ./scripts/install-skills.sh --all later"
  else
    echo "(skipped upstream skill sync — rerun ./scripts/install-skills.sh --all with network)"
  fi
}

if [[ -z "$SCOPE" ]]; then
  echo "Install the SDLC workflow:"
  echo "  1) global          skills for every project (then give project paths for scripts/templates)"
  echo "  2) current project full template into ."
  echo "  3) project path    full template into a directory you name"
  SCOPE="$(ask "Choice [1/2/3]" "2")"
  case "$SCOPE" in
    1|global) SCOPE="global" ;;
    3|custom|"project path") SCOPE="custom" ;;
    *) SCOPE="project" ;;
  esac
fi

if [[ "$SCOPE" == "global" ]]; then
  AGENTS_LIST="$AGENTS_ARG"
  if [[ -z "$AGENTS_LIST" ]]; then
    detected="$(detect_agents | tr '\n' ',' | sed 's/,$//')"
    echo "Detected agents with skill dirs: ${detected:-none}"
    AGENTS_LIST="$(ask "Agents (comma list, empty = all detected)" "")"
  fi
  install_skills_global "$AGENTS_LIST"
  echo ""
  echo "Global skills installed. Skills are the brain — each project still needs"
  echo "the executors (scripts/, templates/, AGENTS.md, routers)."
  for p in "${PROJECTS[@]}"; do copy_template "$p"; done
  while true; do
    p="$(ask "Project path for executors (empty = done)" "")"
    [[ -z "$p" ]] && break
    copy_template "$p"
  done
  echo "✓ global install complete"
elif [[ "$SCOPE" == "project" ]]; then
  if [[ ${#PROJECTS[@]} -eq 0 ]]; then
    PROJECTS=("$(pwd)")
  fi
  for p in "${PROJECTS[@]}"; do copy_template "$p"; done
  echo "✓ project install complete"
elif [[ "$SCOPE" == "custom" ]]; then
  p="$(ask "Project path" "")"
  [[ -n "$p" ]] || { echo "ERROR: no path given"; exit 1; }
  copy_template "$p"
  echo "✓ project install complete"
fi
