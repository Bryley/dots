# Global AGENTS.md

## Scratchpad Policy for AI-Generated Temporary Files

When working in any project, place AI-generated temporary artifacts inside a project-local `.scratchpad/` directory.

Examples include (not limited to):
- pipeline plans or run state
- transcript dumps
- large JSON outputs
- intermediate analysis files
- temporary logs/debug artifacts

### Required behavior

1. Always write temporary AI artifacts under `<project-root>/.scratchpad/...`.
2. Before writing into `.scratchpad/`, ensure `<project-root>/.gitignore` contains a line for `.scratchpad/`.
3. If `.gitignore` does not exist, create it and add `.scratchpad/`.
4. If `.gitignore` exists but is missing the entry, append `.scratchpad/` exactly once (do not duplicate entries).
5. If the repo appears to intentionally track `.scratchpad/` (for example explicit unignore rules), ask the user before changing ignore rules.
6. Do not place temporary AI artifacts in normal project directories unless the user explicitly requests it.
7. If a temporary artifact should become permanent, ask before moving it into tracked paths.

## General

- Keep changes minimal and scoped.
- Follow project conventions.
- Prefer clear, auditable file operations.
- When reporting information to me, be extreamly consise and sacrifice grammar for the sake of concision.

## Web, Code, and Docs Research

Use `ketch` CLI for external research — web pages, OSS code, and library docs.
- Web search: `ketch search "query"` — titles, URLs, snippets.
- Web search + full content: `ketch search "query" --scrape`.
- Scrape: `ketch scrape <url>` — fetches a URL and returns clean markdown.
- Batch scrape: `ketch scrape <url1> <url2> ...` — concurrent fetch.
- Crawl: `ketch crawl <url> --sitemap --background` — crawl a site, poll with `ketch crawl status`.
- Code search: `ketch code "query" --lang go` — real OSS code with line, repo, and stars.
- Library docs: `ketch docs "query" --library /org/repo` — version-aware curated snippets.
- JS-rendered pages are handled automatically — if a page returns a loading shell, ketch re-fetches it with a headless browser.
- All commands support `--json` for structured output.
- Discovery: `ketch config` — returns effective config and available backends as JSON.
- The operator has already configured the search/code/docs backends and browser. Do not override unless you have a specific reason.
