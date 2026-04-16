---
name: session-recall
description: "Search prior pi sessions in two phases: session discovery and message drill-down. Use when the user asks about previous conversations or asks for a summary of recent work."
---

# Session Recall (v3)

This skill uses two scripts:

1. `session_search.sh` = broad discovery (like web search)
2. `message_search.sh` = drill-down in one chosen session (like page fetch)

Use JSON output from scripts as evidence. Do not claim memory without evidence.

## Script 1: Session search

Searches session files and returns matching sessions with metadata.

```bash
~/.pi/agent/skills/session-recall/scripts/session_search.sh \
  --query "web fetching in pi" \
  --start "2026-04-14T00:00:00Z" \
  --end "2026-04-14T23:59:59Z" \
  --limit 20
```

Returns JSON lines with:
- `session_path`, `session_id`, `cwd`
- `started_at`, `ended_at`
- `user_count`, `assistant_count`, `message_count`
- `first_user`, `last_user`
- `match_score`

## Script 2: Message search

Searches inside one session and returns matching messages with surrounding context.

```bash
~/.pi/agent/skills/session-recall/scripts/message_search.sh \
  --session "<session_id_or_path>" \
  --query "web fetching" \
  --start "2026-04-14T00:00:00Z" \
  --end "2026-04-14T23:59:59Z" \
  --context 1 \
  --limit 20
```

Returns JSON lines with:
- `session_path`, `session_id`
- `id`, `parentId`, `timestamp`, `role`, `text`, `score`
- `before[]` and `after[]` context messages

## Suggested workflow

1. Infer ISO `start`/`end` from user wording when helpful (`earlier today`, `yesterday`, etc.).
2. Run `session_search.sh` first.
3. Pick top 1-3 sessions by `match_score` and recency.
4. Run `message_search.sh` on those sessions.
5. Respond with concise findings + confidence.

## Notes

- If the user asks broad questions like "what did I work on today", run `session_search.sh` with only time range and no query.
- Keep outputs concise; avoid dumping full logs.
