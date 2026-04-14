#!/usr/bin/env bash
set -euo pipefail

ROOT="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions"
SESSION=""
QUERY=""
START=""
END=""
CONTEXT=1
LIMIT=20

usage() {
  cat <<'EOF'
Usage: message_search.sh --session <id|path> --query <text> [options]
  --session <id|path>  Session UUID or .jsonl path
  --query <text>       Search query (required)
  --start <iso8601>    Optional inclusive start timestamp
  --end <iso8601>      Optional inclusive end timestamp
  --context <n>        Messages of context before/after (default: 1)
  --limit <n>          Max matches (default: 20)
  --root <path>        Sessions root (default: ~/.pi/agent/sessions)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:-}"; shift 2 ;;
    --query) QUERY="${2:-}"; shift 2 ;;
    --start) START="${2:-}"; shift 2 ;;
    --end) END="${2:-}"; shift 2 ;;
    --context) CONTEXT="${2:-1}"; shift 2 ;;
    --limit) LIMIT="${2:-20}"; shift 2 ;;
    --root) ROOT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$SESSION" || -z "$QUERY" ]]; then
  usage >&2
  exit 1
fi

SESSION_FILE=""
if [[ -f "$SESSION" ]]; then
  SESSION_FILE="$SESSION"
else
  while IFS= read -r -d '' f; do
    sid="$(head -n 1 "$f" | jq -r '.id // empty' 2>/dev/null || true)"
    if [[ "$sid" == "$SESSION" ]]; then
      SESSION_FILE="$f"
      break
    fi
  done < <(find "$ROOT" -type f -name '*.jsonl' -print0)
fi

if [[ -z "$SESSION_FILE" ]]; then
  echo "Session not found: $SESSION" >&2
  exit 1
fi

TERMS_JSON="$({
  printf '%s\n' "$QUERY" \
    | tr '[:upper:]' '[:lower:]' \
    | tr -cs '[:alnum:]' '\n' \
    | awk 'length >= 3' \
    | awk '!/^(and|the|how|what|when|where|why|who|that|this|with|from|into|about|works|work|does|did|you|your|was|were|for|are|can|not|have|has|had|earlier|today|yesterday|maybe)$/ { print }' \
    | awk '!seen[$0]++' \
    | head -n 12 \
    | jq -R .
} | jq -s .)"

jq -rc -s \
  --arg path "$SESSION_FILE" \
  --arg start "$START" \
  --arg end "$END" \
  --argjson terms "$TERMS_JSON" \
  --argjson ctx "$CONTEXT" \
  --argjson limit "$LIMIT" '
    def text_from_message($m):
      if ($m | type) == "string" then $m
      elif ($m | type) == "array" then
        [ $m[]? | select(.type == "text") | .text ] | join(" ")
      else "" end;

    def in_time($ts):
      (($start == "" or $ts >= $start) and ($end == "" or $ts <= $end));

    . as $rows
    | ($rows[0] // {}) as $header
    | [ $rows[]
        | select(.type == "message")
        | {
            id: .id,
            parentId: .parentId,
            timestamp: .timestamp,
            role: .message.role,
            text: text_from_message(.message.content)
          }
        | select((.role == "user" or .role == "assistant") and (.text | length > 0))
      ] as $messages
    | (if ($start == "" and $end == "") then $messages else [ $messages[] | select(in_time(.timestamp)) ] end) as $filtered
    | [ range(0; ($filtered | length)) as $i | $filtered[$i] + {pos: $i} ] as $mpos
    | ($terms | map(select(length > 0))) as $terms2
    | ($terms2 | length) as $termCount
    | [ $mpos[] as $m
        | ($m.text | ascii_downcase) as $t
        | (if $termCount == 0 then 0 else ($terms2 | map(select($t | contains(.))) | length) end) as $score
        | select($termCount == 0 or $score >= (if $termCount >= 2 then 2 else 1 end))
        | $m + {score: $score}
      ] as $hits
    | ($mpos | length) as $n
    | $hits
    | sort_by(.score, .timestamp)
    | reverse
    | .[:$limit]
    | .[] as $h
    | {
        session_path: $path,
        session_id: ($header.id // null),
        id: $h.id,
        parentId: $h.parentId,
        timestamp: $h.timestamp,
        role: $h.role,
        text: $h.text,
        score: $h.score,
        before: [
          range((if $h.pos - $ctx < 0 then 0 else $h.pos - $ctx end); $h.pos)
          | $mpos[.]
          | { timestamp, role, text }
        ],
        after: [
          range($h.pos + 1; (if $h.pos + $ctx + 1 > $n then $n else $h.pos + $ctx + 1 end))
          | $mpos[.]
          | { timestamp, role, text }
        ]
      }
  ' "$SESSION_FILE"
