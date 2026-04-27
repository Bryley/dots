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
