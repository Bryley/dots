# BD Implementation Mode

## Purpose

Implement one stub function. Nothing more.

---

## Pre-flight (complete before writing any code)

### 1. Locate the stub
- Find the function in its file
- Read the full function: signature, parameters, return type, body comments, documentation comments
- Identify the stub marker to be replaced

### 2. Gather context
- Find the associated test file/cases and read it (if it exists)
- For each function this stub calls: collect the **signature and any documentation comments** — do not read bodies
- Note imports already in scope

### 3. Size and clarity check

Estimate the implementation before writing anything. The goal is not just line count but **legibility** — a developer unfamiliar with this codebase should be able to read the function and understand what it does at a glance, without needing to trace through logic.

- Can this be done in **~50 lines or fewer** AND remain immediately readable?
- If **no on either count**: STOP. Do not write any code. Present the concern clearly and propose ways to break the function into smaller pieces. Wait for the user's decision before proceeding.
- If **yes**: continue

Even within the line budget: if a distinct section of the implementation would be meaningfully clearer as a named helper — one with an obvious purpose and a name that explains what it does — raise it as a suggestion before implementing. Do not suggest this for trivial operations (a single lookup, a one-line transform). Only raise it when the benefit to readability is substantial.

### 4. Signature check

Before implementing, consider whether the current signature is appropriate:
- Does the function have everything it needs as parameters?
- Is the return type right — should it return a `Result`, `Option`, error value, or similar given the ways it can fail?
- Is the function name clear and accurate for what it actually does?

If any of these seem wrong or limiting: STOP. Do not implement against a signature you believe is incorrect. Present your concern, suggest 2–3 concrete alternatives, and wait for the user to decide. Treat this the same as the size check — raise it before writing any code, not after.

### 5. State assumptions
- List any non-obvious decisions you will make during implementation
- If any assumption could affect the function's signature, callers, or shared types: stop and confirm before writing code

---

## Implementation rules

**In scope:**
- The target function body
- Imports, if a new one is genuinely required (list it explicitly)

**Out of scope — do not touch:**
- Function signatures (yours or anyone else's)
- Other functions, even obviously related ones
- Types, structs, enums, interfaces
- Tests (unless there is a clear bug in the test itself)
- Any file not containing the target function

**Dependencies:**
- Before adding anything new, check whether the project already has a suitable dependency for the task
- If a suitable one already exists in the project: use it, no need to ask
- If nothing suitable exists: STOP before implementing. Explain what is needed, present 2–3 options with brief tradeoffs (popularity, performance, maintenance, fit for purpose), give a clear recommendation, and ask the user to decide
- Never add a new dependency silently

**Style:**
- Prefer explicit over clever
- Prefer readable over terse
- Match the existing code style and patterns in the project
- Do not add logging or instrumentation unless the spec or user explicitly requests it
- Do not add error handling beyond what the spec (body comments) requires
- Do not extract helpers without explicit user approval — if extraction seems necessary, raise it as a concern instead

---

## After implementing

1. Run the function's tests
2. If tests fail: fix within scope (function body only); do not modify tests unless there is a clear bug in the test itself
3. If you had to deviate from the spec comments to make it work: note it in the handoff

---

## Handoff format

Always end with this block:

```
### BD Implementation Summary
**Function:** `<name>` in `<file>`
**Lines added:** <n>
**Imports added:** <list, or "none">
**Tests:** <passed / failed — include command run>
**Deviations from spec:** <none, or description>
**Concerns for review:** <none, or description>
```

---

## Stop conditions

Stop and surface to the user before continuing if:
- The body comments (spec) are ambiguous, missing, or contradictory
- Implementing cleanly requires modifying a second function
- A dependency the function needs has the wrong signature or doesn't exist
- Tests need to change to pass and it isn't clearly a test bug
- The implementation would exceed ~50 lines and no prior size discussion happened
