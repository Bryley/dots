
# Global `AGENTS.md`

This file is the main entry point for AI assistants working in this environment.

It defines how to use the local Markdown-based agent and skill system.

## Purpose

- Use this file first to decide which local agent or skill is most relevant to the task.
- Keep this file small.
- Put detailed workflows in agent files and skill files, not here.

## Structure

- Agent files define role-specific workflows.
- Skill files define narrow reusable procedures.
- Prefer using the smallest relevant context for the task.
- Do not load everything by default.

## Routing Discipline

- Treat the agent and skill files listed below as operational instructions, not as optional references.
- If a user request clearly matches an agent or skill, load that file before answering.
- Do not answer from generic default behaviour when a listed agent or skill is a clear match.
- Prefer the closest relevant file over broad assistant-style responses.
- If a task involves writing on the user's behalf, load the matching writing-related skill before drafting.
- If a task involves debugging or investigation, load the matching debugging-related agent before proceeding.
- When in doubt between a generic response and a matching local file, prefer the matching local file.

## Agents

| Name | Location | Default to this when |
|---|---|---|
| `debugger` | `./agents/debugger.md` | Debugging runtime, config, environment, networking, programming, and command issues |
| `meta-agent` | `./agents/meta-agent.md` | Creating, updating, auditing, and repairing agent or skill definitions |
| `concept-director` | `./agents/concept-director.md` | Coordinating idea evaluation across specialist agents and producing a final recommendation with blunt plain-language scoring |
| `research-analyst` | `./agents/research-analyst.md` | Analyzing competitors, user pain points, substitutes, and market gaps for a proposed idea |
| `product-architect` | `./agents/product-architect.md` | Estimating technical feasibility, architecture options, delivery complexity, and infrastructure costs |
| `mvp-strategist` | `./agents/mvp-strategist.md` | Designing lean MVP and validation experiments with clear success and kill criteria |


## Skills


| Name | Location | Load this when |
|---|---|---|
| `documentation-lookup` | `./skills/documentation-lookup/SKILL.md` | Verifying any kind of documentation with high correctness |
| `dependency-installer` | `./skills/dependency-installer/SKILL.md` | Installing missing dependencies safely using mise for CLI tools and system package flow for low-level packages |
| `write-like-me` | `./skills/write-like-me/SKILL.md` | Writing that is meant to be perceived as if the user wrote it, git commit messages, emails, text messages, documentation, etc. |


## General rules

- Prefer correctness over guessing.
- Distinguish between facts, hypotheses, and fixes.
- Prefer minimal relevant context over large always-on context.
