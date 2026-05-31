---
name: bounded-development
description: Bounded Development (BD) — skeleton-first, AI-assisted coding workflow. Implements one stub function at a time with strict scope bounds, human-owned architecture, and test-first development. Use when implementing a specific stub or function, designing a project skeleton or module structure, or writing tests for a stub. Do not use for broad multi-file features, open-ended refactoring, or design prototypes.
---

# Bounded Development (BD)

## Philosophy

BD keeps AI inside pre-drawn boxes. The human owns architecture and interfaces. The AI fills single function bodies — one at a time — with explicit scope limits and human review at every step.

## Hard rules (apply to all modes)

1. **Never silently change an interface** — function signatures, return types, struct fields, and public APIs are frozen; surface conflicts before acting
2. **Never touch code outside declared scope**
3. **Surface design concerns before coding, not after**
4. **If uncertain whether something is in scope, ask — do not assume and expand**

## Mode routing

Identify the current task and load the matching reference file before proceeding:

| Task | Mode | Load |
|---|---|---|
| Designing files, types, structs, interfaces, stubs | **Architecture** | [references/bd-architecture.md](references/bd-architecture.md) |
| Writing or planning tests for a stub | **Test Design** | [references/bd-test.md](references/bd-test.md) |
| Implementing a stub function | **Implementation** | [references/bd-implement.md](references/bd-implement.md) |

Read the reference file for the active mode before doing any work.

## Stub state conventions

Stubs must be marked so they are discoverable. Use the language-appropriate marker:

| Language | Marker |
|---|---|
| Rust | `todo!()` |
| Python | `raise NotImplementedError` |
| Go | `panic("not implemented")` |
| TypeScript / JS | `throw new Error("not implemented")` |
| Other | `// TODO: STUB` + empty body |

To find remaining stubs: grep the project for the relevant marker.

## Implementation order

Implement **deepest stubs first** — leaf functions whose dependencies are already implemented or external. This ensures each function is fully testable before its callers need it, and no mocks are required for already-completed code.

To determine order: trace the call graph from the target feature down to functions with no unimplemented dependencies. Start there.
