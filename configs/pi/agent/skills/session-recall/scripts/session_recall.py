#!/usr/bin/env python3
"""Fast, streaming search over pi JSONL session files."""

from __future__ import annotations

import argparse
import heapq
import json
import os
import re
import signal
import sys
from pathlib import Path
from typing import Any, Iterable

DEFAULT_ROOT = Path(os.environ.get("PI_CODING_AGENT_DIR", Path.home() / ".pi" / "agent")) / "sessions"
STOP_WORDS = {
    "and", "the", "how", "what", "when", "where", "why", "who", "that",
    "this", "with", "from", "into", "about", "works", "work", "does", "did",
    "you", "your", "was", "were", "for", "are", "can", "not", "have", "has",
    "had", "earlier", "today", "yesterday", "maybe",
}
FILENAME_TIMESTAMP = re.compile(r"^(\d{4}-\d{2}-\d{2})T(\d{2}-\d{2}-\d{2})")


def query_terms(query: str) -> list[str]:
    terms: list[str] = []
    seen: set[str] = set()
    for term in re.findall(r"[A-Za-z0-9]+", query.lower()):
        if len(term) >= 3 and term not in STOP_WORDS and term not in seen:
            terms.append(term)
            seen.add(term)
            if len(terms) == 12:
                break
    return terms


def message_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return " ".join(
            item.get("text", "")
            for item in content
            if isinstance(item, dict)
            and item.get("type") == "text"
            and isinstance(item.get("text"), str)
        )
    return ""


def rows(path: Path) -> Iterable[dict[str, Any]]:
    try:
        with path.open(encoding="utf-8", errors="replace") as stream:
            for line in stream:
                try:
                    row = json.loads(line)
                except (json.JSONDecodeError, ValueError):
                    continue
                if isinstance(row, dict):
                    yield row
    except OSError:
        return


def session_files(root: Path, end: str = "") -> Iterable[Path]:
    for path in root.rglob("*.jsonl"):
        # A session cannot contain a message before the timestamp in its filename.
        # This safely avoids opening future sessions for bounded searches.
        if end:
            match = FILENAME_TIMESTAMP.match(path.name)
            if match:
                session_start = f"{match.group(1)}T{match.group(2).replace('-', ':')}Z"
                if session_start > end:
                    continue
        yield path


def in_time(timestamp: str, start: str, end: str) -> bool:
    return (not start or timestamp >= start) and (not end or timestamp <= end)


def required_score(term_count: int) -> int:
    if term_count == 0:
        return 0
    return 2 if term_count >= 2 else 1


def scan_session(path: Path, terms: list[str], start: str, end: str) -> dict[str, Any] | None:
    iterator = iter(rows(path))
    header = next(iterator, {})
    if header.get("type") != "session":
        return None

    found: set[str] = set()
    started_at = ""
    ended_at = ""
    first_user = ""
    last_user = ""
    user_count = 0
    assistant_count = 0
    message_count = 0

    for row in iterator:
        if row.get("type") != "message":
            continue
        message = row.get("message")
        if not isinstance(message, dict):
            continue
        role = message.get("role")
        if role not in ("user", "assistant"):
            continue
        text = message_text(message.get("content"))
        timestamp = row.get("timestamp")
        if not text or not isinstance(timestamp, str) or not in_time(timestamp, start, end):
            continue

        if not started_at:
            started_at = timestamp
        ended_at = timestamp
        message_count += 1
        if role == "user":
            user_count += 1
            if not first_user:
                first_user = text
            last_user = text
        else:
            assistant_count += 1

        if len(found) < len(terms):
            lowered = text.lower()
            found.update(term for term in terms if term not in found and term in lowered)

    score = len(found)
    if not message_count or score < required_score(len(terms)):
        return None
    return {
        "session_path": str(path),
        "session_id": header.get("id"),
        "cwd": header.get("cwd", ""),
        "started_at": started_at,
        "ended_at": ended_at,
        "user_count": user_count,
        "assistant_count": assistant_count,
        "message_count": message_count,
        "first_user": first_user,
        "last_user": last_user,
        "match_score": score,
    }


def print_json(value: dict[str, Any]) -> None:
    print(json.dumps(value, ensure_ascii=False, separators=(",", ":")))


def search_sessions(args: argparse.Namespace) -> int:
    root = Path(args.root).expanduser()
    if not root.is_dir():
        print(f"Sessions directory not found: {root}", file=sys.stderr)
        return 0

    if args.limit == 0:
        return 0

    terms = query_terms(args.query)
    best: list[tuple[int, str, int, dict[str, Any]]] = []
    sequence = 0
    for path in session_files(root, args.end):
        result = scan_session(path, terms, args.start, args.end)
        if result is None:
            continue
        ranked = (result["match_score"], result["ended_at"], sequence, result)
        sequence += 1
        if len(best) < args.limit:
            heapq.heappush(best, ranked)
        elif ranked[:3] > best[0][:3]:
            heapq.heapreplace(best, ranked)

    for _, _, _, result in sorted(best, reverse=True):
        print_json(result)
    return 0


def resolve_session(root: Path, session: str) -> Path | None:
    direct = Path(session).expanduser()
    if direct.is_file():
        return direct

    matches = root.rglob(f"*_{session}.jsonl")
    match = next(matches, None)
    if match is not None:
        return match

    # Fallback supports IDs that do not appear in older/custom filenames.
    for path in root.rglob("*.jsonl"):
        first = next(iter(rows(path)), {})
        if first.get("id") == session:
            return path
    return None


def load_messages(path: Path, start: str, end: str) -> tuple[dict[str, Any], list[dict[str, Any]]]:
    iterator = iter(rows(path))
    header = next(iterator, {})
    messages: list[dict[str, Any]] = []
    for row in iterator:
        if row.get("type") != "message":
            continue
        message = row.get("message")
        if not isinstance(message, dict):
            continue
        role = message.get("role")
        text = message_text(message.get("content"))
        timestamp = row.get("timestamp")
        if (
            role in ("user", "assistant")
            and text
            and isinstance(timestamp, str)
            and in_time(timestamp, start, end)
        ):
            messages.append({
                "id": row.get("id"),
                "parentId": row.get("parentId"),
                "timestamp": timestamp,
                "role": role,
                "text": text,
            })
    return header, messages


def search_messages(args: argparse.Namespace) -> int:
    root = Path(args.root).expanduser()
    path = resolve_session(root, args.session)
    if path is None:
        print(f"Session not found: {args.session}", file=sys.stderr)
        return 1

    terms = query_terms(args.query)
    threshold = required_score(len(terms))
    header, messages = load_messages(path, args.start, args.end)
    hits: list[tuple[int, str, int]] = []
    for position, message in enumerate(messages):
        lowered = message["text"].lower()
        score = sum(term in lowered for term in terms)
        if score >= threshold:
            hits.append((score, message["timestamp"], position))
    hits.sort(reverse=True)

    for score, _, position in hits[: args.limit]:
        hit = messages[position]
        result = {
            "session_path": str(path),
            "session_id": header.get("id"),
            **hit,
            "score": score,
            "before": [
                {key: message[key] for key in ("timestamp", "role", "text")}
                for message in messages[max(0, position - args.context) : position]
            ],
            "after": [
                {key: message[key] for key in ("timestamp", "role", "text")}
                for message in messages[position + 1 : position + args.context + 1]
            ],
        }
        print_json(result)
    return 0


def nonnegative(value: str) -> int:
    parsed = int(value)
    if parsed < 0:
        raise argparse.ArgumentTypeError("must be non-negative")
    return parsed


def parser() -> argparse.ArgumentParser:
    main = argparse.ArgumentParser(add_help=False)
    commands = main.add_subparsers(dest="command", required=True)

    sessions = commands.add_parser("sessions")
    sessions.add_argument("--query", default="")
    sessions.add_argument("--start", default="")
    sessions.add_argument("--end", default="")
    sessions.add_argument("--limit", type=nonnegative, default=20)
    sessions.add_argument("--root", default=str(DEFAULT_ROOT))
    sessions.set_defaults(run=search_sessions)

    messages = commands.add_parser("messages")
    messages.add_argument("--session", required=True)
    messages.add_argument("--query", required=True)
    messages.add_argument("--start", default="")
    messages.add_argument("--end", default="")
    messages.add_argument("--context", type=nonnegative, default=1)
    messages.add_argument("--limit", type=nonnegative, default=20)
    messages.add_argument("--root", default=str(DEFAULT_ROOT))
    messages.set_defaults(run=search_messages)
    return main


def main() -> int:
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    args = parser().parse_args()
    return args.run(args)


if __name__ == "__main__":
    raise SystemExit(main())
