# BD Test Design Mode

## Purpose

Design and implement tests for a specific stub function. Tests are written before implementation (TDD). The human approves the test plan before any test code is written.

---

## Principles

- Tests are the spec made executable — they document intended behaviour, not implementation details
- Each test covers exactly one behaviour
- If a test is hard to understand, it will be hard to trust
- Tests must be valid and runnable even though the function isn't implemented yet (they will fail — that's expected and correct)
- Do not depend on other unimplemented stubs; mock or skip those dependencies

---

## Workflow

### Step 1 — Generate test ideas

Read the target function: signature, parameters, return type, and body comments.

Produce a numbered test plan covering:
- **Happy path** — normal inputs producing expected outputs
- **Edge cases** — boundary values, empty inputs, zero, maximum, single-element collections
- **Error / failure cases** — invalid inputs, missing data, dependency failures
- **Contract cases** — anything explicitly promised in the body comments

Present the plan as a numbered list with a one-line description per case. Do not write any test code yet.

### Step 2 — Human review

Wait for the user to:
- Approve the list, or
- Add, remove, or modify cases

Do not proceed to Step 3 until the user explicitly approves the plan.

### Step 3 — Implement approved tests

- Write tests for approved cases only — do not add extras without asking
- One test per approved case
- Use the simplest assertion that proves the behaviour
- If a test depends on an unimplemented function: use a mock, a stub value, or mark the test with a language-appropriate skip/ignore and note why
- Tests should be valid and runnable without errors (failures on the unimplemented stub are expected)

### Step 4 — Verify test structure

Run the tests using the project's test command. Confirm:
- They are accepted by the test runner without syntax or setup errors
- They fail on the unimplemented stub (expected)
- No test fails for a reason unrelated to the stub being unimplemented

If a test fails unexpectedly: fix the test (not the function), within scope.

---

## Constraints

- Do not implement the function being tested
- Do not write tests for functions other than the target
- Do not write integration or end-to-end tests unless the user explicitly requests them
- Keep test helpers minimal — inline what you reasonably can

---

## Handoff format

End with:

```
### BD Test Summary
**Function:** `<name>`
**Test location:** <file, module, or inline block — follow language conventions>
**Cases written:** <n>
**Status:** runs and fails on stub as expected / <issue>
**Skipped cases:** <none, or case number + reason>
**Notes for implementer:** <none, or anything discovered about the spec while writing tests>
```

The "Notes for implementer" field is important — writing tests often surfaces spec ambiguities that should be resolved before implementation begins.

---

## Stop conditions

Stop and surface to the user before continuing if:
- The function spec (body comments) is ambiguous and affects what tests to write
- A test case would require calling multiple unimplemented functions with no clean mock strategy
- The function signature makes certain cases untestable without interface changes
