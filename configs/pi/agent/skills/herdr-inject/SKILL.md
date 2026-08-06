---
name: herdr-inject
description: Use for HerdrAgentInject requests that apply one narrowly scoped edit to a saved target file. Read the saved file when needed, treat the supplied target text as authoritative, and return only the exact replacement text; cancel broader decisions, out-of-range edits, dependency work, or requests lacking sufficient context.
---

# HerdrAgentInject

## Contract

Handle one bounded text injection into a saved file. The target text supplied by the caller is authoritative; do not reinterpret it from surrounding context. The response is a machine-consumed payload, not an explanation.

## Required inputs

- A saved target file.
- Target text and the requested replacement.
- Enough context to determine that the replacement is local, unambiguous, and in range.

You may read the saved file for context and verification. Do not modify the file yourself.

## Procedure

1. Confirm the target file is saved and the target text/replacement are present.
2. Read only the file context needed to validate the local injection.
3. Check that the request is a single, bounded replacement and does not require architectural, product, dependency, or other broader decisions.
4. If valid, return the replacement text exactly—no Markdown fences, labels, explanation, or surrounding text.
5. If invalid or underspecified, return `HERDR_INJECT_CANCELLED` followed by one concise reason. Do not provide a proposed replacement.

## Cancellation conditions

Cancel when any of these apply:

- The file is unsaved, missing, inaccessible, or not identified.
- The target text is absent, ambiguous, or outside the requested range.
- The request requires broader design/implementation decisions, multiple unrelated edits, dependency changes, or tool execution.
- Required context is insufficient to make the exact replacement safely.
- The caller asks to override the authoritative target text.

## Verification checklist

Before responding with a replacement, verify:

- [ ] Target file is saved and readable.
- [ ] Target text is authoritative and matches the requested range.
- [ ] Replacement is exact and limited to the bounded injection.
- [ ] No extra prose or formatting will be emitted.

Before cancelling, verify:

- [ ] A specific cancellation condition applies.
- [ ] The reason is concise and does not include a replacement.

## Final response format

Success: exact replacement text only.

Cancellation: `HERDR_INJECT_CANCELLED` followed by a concise reason.
