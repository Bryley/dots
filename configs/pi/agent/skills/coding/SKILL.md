---
name: coding
description: Executes production code changes with minimal, verifiable diffs. Use when implementing features, fixing bugs, refactoring behavior, or modifying shipped application/service code. Do not use for throwaway prototypes, design exploration, or docs-only work.
---

# Production Coding Guardrails

## Purpose and contract
Own one workflow: safely produce production-ready code changes with explicit assumptions, minimal scope, and verification evidence.

Inputs:
- User request to change production code
- Existing repository code and test/tooling context

Outputs:
1. A minimal code diff tied directly to the request
2. Verification evidence (tests/lint/build or explicit gap)
3. Final handoff summary with changed files, assumptions, and residual risks

Non-goals:
- UI mockups/prototypes
- Broad architecture redesign unless explicitly requested
- Unrelated cleanup/refactors

## Defaults and assumptions
- Prefer simplest implementation that satisfies requirements
- Ask clarifying questions when requirements are ambiguous or conflicting
- Match existing project patterns and style
- Avoid speculative abstractions and unrequested features
- If verification cannot run, report why and provide exact next command

## Required artifacts in every execution
Use these headings in the response:
1. `## Assumptions`
2. `## Plan`
3. `## Changes Made`
4. `## Verification`
5. `## Handoff`

`## Verification` must include concrete commands and outcomes.

## Workflow
1. **Think before coding**
   - Restate request in one sentence.
   - List assumptions; if high-impact ambiguity exists, stop and ask.
   - If two viable approaches exist, choose the simpler one and state why.

2. **Simplicity first**
   - Implement the minimum code that satisfies the request.
   - Do not add speculative abstractions, configurability, or future-proofing.

3. **Goal-driven execution**
   - Convert request into checkable outcomes (tests, behavior, compile/lint constraints).
   - For bug fixes, prefer reproduce-first (test or deterministic check).

4. **Make surgical changes**
   - Touch only files required for requested behavior.
   - Do not perform unrelated refactors/formatting churn.
   - Remove only dead code created by your own changes.

5. **Verify and handoff**
   - Run the smallest meaningful command set first, then broader checks as needed.
   - Preferred order: targeted test -> related test suite -> lint/typecheck/build (as applicable).
   - Record pass/fail status and any skipped checks with reason.
   - Summarize changed files and why each changed.
   - List remaining risks, assumptions, or follow-ups.

## Stop and escalation conditions
Stop and ask before continuing when:
- Requirements are ambiguous and could change API/data behavior
- Requested change implies destructive migration or irreversible data changes
- Required permissions/network/dependencies are unavailable
- Existing tests/tooling are broken in ways unrelated to the task

## Quality bar (done criteria)
A task is done only if all are true:
- Every changed line maps to requested behavior
- No speculative abstractions or unrequested functionality
- Verification evidence is provided (or explicit, actionable verification gap)
- Final handoff includes changed files + risks/assumptions
