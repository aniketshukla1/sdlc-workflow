#!/usr/bin/env bash
# Publish an mr-review verdict to GitLab: summary note + inline threads + approve state.
# Usage: ./scripts/mr-publish.sh --mr <IID> --verdict approve|request-changes|comment --body-file <md> [--inline <findings.tsv>] [--project <id|path>] [--host <url>]
# Env: GITLAB_TOKEN (api scope, REVIEWER identity — never the MR author's token for approve).
# Findings TSV (tab-separated): <path><TAB><line><TAB><severity><TAB><comment> (Critical/Required only).
# Inline threads target NEW lines of the MR diff and stay UNRESOLVED (merge-blocking when
# "all threads must be resolved" is enabled — that IS request-changes on GitLab).
set -euo pipefail

usage() {
  echo "Usage: $0 --mr <IID> --verdict approve|request-changes|comment --body-file <md> [--inline <tsv>] [--project <id|path>] [--host <url>]"
  exit 1
}

MR=""; VERDICT=""; BODY=""; INLINE=""; PROJECT=""; HOST="${GITLAB_HOST:-https://gitlab.com}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mr) MR="$2"; shift 2 ;;
    --verdict) VERDICT="$2"; shift 2 ;;
    --body-file) BODY="$2"; shift 2 ;;
    --inline) INLINE="$2"; shift 2 ;;
    --project) PROJECT="$2"; shift 2 ;;
    --host) HOST="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [[ -z "${GITLAB_TOKEN:-}" ]]; then echo "ERROR: set GITLAB_TOKEN (api scope)"; exit 1; fi
if [[ -z "$MR" || -z "$VERDICT" || -z "$BODY" ]]; then usage; fi
if [[ ! -f "$BODY" ]]; then echo "ERROR: body file missing: $BODY"; exit 1; fi
if [[ -n "$INLINE" && ! -f "$INLINE" ]]; then echo "ERROR: inline file missing: $INLINE"; exit 1; fi
case "$VERDICT" in approve|request-changes|comment) ;; *) usage ;; esac
command -v curl >/dev/null || { echo "ERROR: curl required"; exit 1; }
command -v python3 >/dev/null || { echo "ERROR: python3 required (JSON handling)"; exit 1; }

# Resolve project: numeric ID passes through, path gets URL-encoded, else parse origin remote.
if [[ -z "$PROJECT" ]]; then
  origin="$(git remote get-url origin 2>/dev/null || true)"
  PROJECT="$(echo "$origin" | sed -E 's#^(git@[^:]+:|https?://[^/]+/)##; s#\.git$##')"
  if [[ -z "$PROJECT" ]]; then echo "ERROR: cannot parse origin remote; pass --project <id|path>"; exit 1; fi
fi
if [[ "$PROJECT" =~ ^[0-9]+$ ]]; then
  PID="$PROJECT"
else
  PID="$(python3 -c 'import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1], safe=""))' "$PROJECT")"
fi
API="$HOST/api/v4/projects/$PID/merge_requests/$MR"

# 0. Fetch MR (validates IID; gives author + diff SHAs + web URL for posted links).
mr_json="$(curl -sS --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$API")"
web_url="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("web_url",""))' <<<"$mr_json")"
author_id="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("author",{}).get("id",""))' <<<"$mr_json")"
base_sha="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("diff_refs",{}).get("base_sha",""))' <<<"$mr_json")"
head_sha="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("diff_refs",{}).get("head_sha",""))' <<<"$mr_json")"
start_sha="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("diff_refs",{}).get("start_sha",""))' <<<"$mr_json")"
if [[ -z "$author_id" || -z "$head_sha" ]]; then echo "ERROR: unexpected MR response: $mr_json"; exit 1; fi

# 1. Reviewer identity — refuse self-approval (GitLab blocks it anyway; fail loudly here).
me_id="$(curl -sS --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$HOST/api/v4/user" | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])')"
if [[ "$VERDICT" == "approve" && "$me_id" == "$author_id" ]]; then
  echo "REFUSED: token belongs to the MR author — self-approval is blocked. Have another reviewer approve."
  exit 1
fi

# 2. Summary note (always posted).
note_json="$(python3 -c 'import json,sys; print(json.dumps({"body": open(sys.argv[1]).read()}))' "$BODY")"
note_resp="$(curl -sS -X POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header 'Content-Type: application/json' --data "$note_json" "$API/notes")"
note_id="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("id",""))' <<<"$note_resp")"
if [[ -z "$note_id" ]]; then echo "ERROR: note rejected: $note_resp"; exit 1; fi
echo "✓ note: $web_url#note_$note_id"

# 3. Inline threads for Critical/Required findings.
if [[ -n "$INLINE" ]]; then
  count=0
  while IFS=$'\t' read -r path line sev comment; do
    if [[ -z "${path// }" || "$path" == \#* ]]; then continue; fi
    if [[ ! "$line" =~ ^[0-9]+$ ]]; then echo "WARN: skipping bad row (want <path><TAB><line><TAB><sev><TAB><comment>): $path"; continue; fi
    payload="$(MR_PATH="$path" MR_LINE="$line" MR_SEV="$sev" MR_COMMENT="$comment" BASE="$base_sha" HEAD="$head_sha" START="$start_sha" python3 -c '
import json, os
print(json.dumps({"body": "[%s] %s" % (os.environ["MR_SEV"], os.environ["MR_COMMENT"]),
  "position": {"base_sha": os.environ["BASE"], "head_sha": os.environ["HEAD"], "start_sha": os.environ["START"],
    "position_type": "text", "new_path": os.environ["MR_PATH"], "new_line": int(os.environ["MR_LINE"])}}))')"
    curl -sS -X POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" --header 'Content-Type: application/json' --data "$payload" "$API/discussions" >/dev/null
    count=$((count + 1))
  done < "$INLINE"
  echo "✓ inline threads: $count"
fi

# 4. Review state.
if [[ "$VERDICT" == "approve" ]]; then
  resp="$(curl -sS -X POST --header "PRIVATE-TOKEN: $GITLAB_TOKEN" "$API/approve")"
  ok="$(python3 -c 'import json,sys; d=json.load(sys.stdin); print("yes" if d.get("approved", False) else "no: "+json.dumps(d))' <<<"$resp")"
  if [[ "$ok" == "yes" ]]; then
    echo "✓ approved: $web_url"
  else
    echo "ERROR: approve rejected: $ok"; exit 1
  fi
elif [[ "$VERDICT" == "request-changes" ]]; then
  if [[ -z "$INLINE" ]]; then echo "WARN: no --inline file: merge-blocking relies on unresolved threads; summary alone does not block."; fi
  echo "✓ request-changes recorded: summary posted + threads left UNRESOLVED. No approval given."
else
  echo "✓ comment posted (no state change)."
fi
