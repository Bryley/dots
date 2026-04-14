#!/usr/bin/env bash
set -euo pipefail

ROOT="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/sessions"
QUERY=""
START=""
END=""
LIMIT=20

usage() {
  cat <<'EOF'
Usage: session_search.sh [options]
  --query <text>      Optional search query
  --start <iso8601>   Optional inclusive start timestamp (e.g. 2026-04-14T00:00:00Z)
  --end <iso8601>     Optional inclusive end timestamp
  --limit <n>         Max results (default: 20)
  --root <path>       Sessions root (default: ~/.pi/agent/sessions)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --query) QUERY="${2:-}"; shift 2 ;;
    --start) START="${2:-}"; shift 2 ;;
    --end) END="${2:-}"; shift 2 ;;
    --limit) LIMIT="${2:-20}"; shift 2 ;;
    --root) ROOT="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -d "$ROOT" ]]; then
  echo "Sessions directory not found: $ROOT" >&2
  exit 0
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

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

while IFS= read -r -d '' file; do
  jq -rc -s \
    --arg path "$file" \
    --arg start "$START" \
    --arg end "$END" \
    --argjson terms "$TERMS_JSON" '
      def text_from_message($m):
        if ($m | type) == "string" then $m
        elif ($m | type) == "array" then
          [ $m[]? | select(.type == "text") | .text ] | join(" ")
        else "" end;

      def in_time($ts):
        (($start == "" or $ts >= $start) and ($end == "" or $ts <= $end));

      . as $rows
      | ($rows[0] // {}) as $header
      | select($header.type == "session")
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
      | select(($filtered | length) > 0)
      | ($terms | map(select(length > 0))) as $terms2
      | ($filtered | map(.text | ascii_downcase) | join(" ")) as $blob
      | ($terms2 | length) as $termCount
      | (if $termCount == 0 then 0 else ($terms2 | map(select($blob | contains(.))) | length) end) as $score
      | select($termCount == 0 or $score >= (if $termCount >= 2 then 2 else 1 end))
      | {
          session_path: $path,
          session_id: ($header.id // null),
          cwd: ($header.cwd // ""),
          started_at: ($filtered[0].timestamp),
          ended_at: ($filtered[-1].timestamp),
          user_count: ([ $filtered[] | select(.role == "user") ] | length),
          assistant_count: ([ $filtered[] | select(.role == "assistant") ] | length),
          message_count: ($filtered | length),
          first_user: ([ $filtered[] | select(.role == "user") | .text ][0] // ""),
          last_user: ([ $filtered[] | select(.role == "user") | .text ][-1] // ""),
          match_score: $score
        }
    ' "$file" 2>/dev/null || true
done < <(find "$ROOT" -type f -name '*.jsonl' -print0) > "$TMP"

if [[ ! -s "$TMP" ]]; then
  exit 0
fi

jq -s --argjson limit "$LIMIT" '
  sort_by(.match_score, .ended_at)
  | reverse
  | .[:$limit]
  | .[]
' "$TMP"
