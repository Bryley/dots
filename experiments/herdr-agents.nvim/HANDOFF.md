# Handoff

## Overarching goal

Make AI delegation fast and user-controlled from Neovim without locking into a single model provider or harness. Herdr is the initial transport/session manager; coding harnesses such as Pi or Claude Code should remain swappable.

## Current v1 decision

- Build a small Neovim plugin that can send prompts to Herdr-managed agent panes.
- Support selecting an existing agent and later spawning temporary workers.
- Start with the harnesses' normal direct file editing behavior to validate usefulness.
- Use Herdr's existing terminal UI for agent interaction and questions.
- Keep Nvim UI small: task status, notifications, and jump/focus actions.

## Ideas discussed for later

- Bounded-development task recipe: task at cursor/function, strict scope, ask before interface/scope changes.
- Generic scoped delegation: prose, code, Markdown, reviews, transformations.
- Virtual text/signs for queued, working, blocked, ready, stale, and failed tasks.
- Review/apply workflow where agents edit isolated copies or Git worktrees and return patches.
- Three-way merge proposals with `current`, original `base`, and agent `candidate` so parallel workers can safely propose edits to the same file.
- Hunk/range annotations as generic user feedback sent to agents; likely integrate with an existing review-comment plugin rather than own persistence initially.

## Herdr facts used

- Herdr can start, list, read, send to, focus, attach to, and wait on agents.
- Herdr reports statuses such as `idle`, `working`, `blocked`, and `done`.
- Herdr notifications can signal an agent needing input or finishing.
- Existing Neovim/Herdr plugins currently focus on seamless pane navigation, not agent task dispatch.

## Scope guardrails

- Do not build a generic chat UI, patch editor, task database, or annotation system in the first iteration.
- Avoid sending prompts into a working user-owned agent without explicit confirmation.
- Treat plugin-created workers as managed; existing agents as external targets.
- Do not auto-close a worker merely because it is idle; close after its result is consumed, rejected, or cancelled.
