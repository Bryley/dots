---
name: documentation-lookup
description: Verify exact command, tool, API, or config behavior using local help first and official documentation second
---

# Documentation Lookup

Use this skill when exact behaviour matters and guessing would be risky.

## Purpose
Find the current, relevant documentation for a command, tool, library, API, or config format and tie it back to the user’s actual problem.

## Lookup Order
1. Check local help first when available, drilling into subcommand help pages if
   necessary:
   - `<command> --help`
   - `<command> help`
   - `<command> --version` if version differences may matter
   - `man <command>`
2. Check local project docs or config examples if they exist.
3. If local information is missing, incomplete, or possibly outdated, check current official web docs.
4. Use high-quality secondary sources only if official docs do not answer the question.

## Rules
- Prefer official documentation over blog posts or SEO tutorials.
- Do not rely on memory when syntax, flags, APIs, or behaviour may have changed.
- Do not assume behaviour is identical across versions, operating systems, or package variants.
- Quote or summarize only the part that is relevant to the current task.
- Tie documentation findings back to the user’s exact symptom or question.

## Output
When using this skill, aim to provide:
- what source was checked
- what exact behaviour was confirmed
- how it applies to the current issue
- any version or platform caveats
