---
name: pipeline
description: Plan, approve, and execute multi-step pipelines using isolated agents with progress tracked in .scratchpad/PIPELINE.md. Use for complex tasks with dependencies, concurrent subtasks, or large intermediate outputs.
---

# Pipeline

## Purpose and contract

Own one workflow: convert a complex user request into an executable pipeline, get user approval, execute via isolated agents, and return a clear final handoff.

Inputs:
- User goal
- Optional pipeline template selection (templated mode) or no template (dynamic mode)

Outputs:
1. `.scratchpad/PIPELINE.md` with checklist progress
2. Step/substep outputs saved to files when output is non-trivial
3. Final summary: completed work, file artifacts, blockers/resolutions, remaining risks

Non-goals:
- Single-step trivial Q&A
- Large monolithic agent runs without decomposition
- Executing unapproved pipeline drafts

---

## Defaults and assumptions

- Pipelines run in two planning modes:
  - **Templated**: based on a selected template
  - **Dynamic**: generated from the user’s goal
- Top-level steps are ordered and depend on prior top-level steps.
- Substeps under a top-level step are unordered sibling tasks and can run concurrently.
- Each step/substep runs in its own isolated agent context.
- Prefer writing non-trivial outputs to files and passing file paths between steps.
- Use `.scratchpad/` for pipeline artifacts.

## Known agent tiers (default runtime profile)

Assume these agent types are available unless execution proves otherwise:

- `fast` — quick, low-cost tasks; default model `openai-codex/gpt-5.4-mini`
- `standard` — balanced tasks; default model `openai-codex/gpt-5.3-codex`
- `deep` — complex/high-impact tasks; default model `openai-codex/gpt-5.4`

Routing guidance:
- Use `fast` for lightweight extraction/lookup/formatting tasks.
- Use `standard` for ordinary planning/implementation/review tasks.
- Use `deep` for difficult reasoning, ambiguity resolution, and high-risk changes.
- Do not spend turns reading agent files only to enumerate available tiers.
- Only inspect agent files if a `subagent` call fails (e.g. unknown/disabled agent) or if user asks to verify live configuration.

---

## Required artifacts

### 1) `.scratchpad/PIPELINE.md`
Use this structure:

```md
# Pipeline
Goal: <user goal>
Mode: <templated|dynamic>
Approved: <true|false>
Status: <draft|running|blocked|done>

1) [ ] Step 1 [agent: standard]
    - [ ] Concurrent step 1.1 [agent: fast]
    - [ ] Concurrent step 1.2 [agent: fast]
    - [ ] Concurrent step 1.3 [agent: standard]
2) [ ] Step 2 [agent: standard]
3) [ ] Step 3 [agent: deep]
    - [ ] Concurrent substep 3.1 [agent: fast]
    - [ ] Concurrent substep 3.2 [agent: standard]
```

Rules:
- Every top-level step and substep must include one agent tag: `[agent: fast|standard|deep]`
- Agent tags are chosen during planning (before execution), so users can review routing decisions in advance

### 2) Artifact directory
Store run artifacts under:
- `.scratchpad/pipeline/<run-id>/...`

### 3) Final handoff summary
Include:
- What completed
- What files were created/updated
- What was blocked and how it was resolved
- What remains (if anything)

---

## Workflow

### Phase 1 — Plan selection and draft
1. Determine whether to use **templated** or **dynamic** planning.
2. Build small, concrete, low-ambiguity steps.
3. Choose an agent tier (`fast|standard|deep`) for every step and substep; include it inline in `PIPELINE.md`.
4. Prefer steps that produce clear artifacts (files) over long inline outputs.
5. Write initial draft to `.scratchpad/PIPELINE.md` with all checkboxes unchecked.
6. Set status to `draft`.

### Phase 2 — Approval gate
1. Present the draft to the user.
2. Ask for changes and revise until accepted.
3. Do not execute until user clearly approves.
4. On approval, perform a single edit that sets `Approved: true` and `Status: running` together.

### Phase 3 — Execution
For each top-level step in order:
1. If the step has 2+ unchecked substeps, execute sibling substeps concurrently using one `subagent` call in parallel mode (`tasks` array).
2. Map each substep to its declared tier via the `[agent: ...]` tag (use that value as the `agent` field in each parallel task).
3. If the step has exactly one substep, run one `subagent` single execution for that substep.
4. If no substeps exist, run one `subagent` single execution for the top-level step using its step-level agent tag.
5. Agent tasks must be small and explicit (e.g. "fetch transcript to file", "summarize file to bullets").
6. Write non-trivial outputs to files; pass file paths forward.
7. Mark each completed substep `[x]` in `.scratchpad/PIPELINE.md`.
8. Mark top-level step `[x]` only when all its substeps are complete.

### Phase 4 — Blockage handling
If an agent run is blocked:
1. Capture blocker in `.scratchpad/PIPELINE.md` (briefly).
2. Orchestrator attempts resolution by providing missing context/artifacts and retrying.
3. If a user decision is required, pause and ask focused questions.
4. Resume once blocker is resolved.

### Phase 5 — Finalization
1. Ensure all completed items are ticked.
2. Set status to `done` (or `blocked` if unresolved).
3. Return final handoff summary with artifact paths.

---

## Verification loop

Before declaring completion:
- Confirm all intended completed items are `[x]` in `.scratchpad/PIPELINE.md`
- Confirm every step/substep has an explicit `[agent: ...]` tag
- Confirm sibling substeps were executed concurrently (`subagent` parallel mode) when 2+ were available
- Confirm expected artifact files exist
- Confirm unresolved blockers are explicitly listed
- Confirm final summary references concrete file paths

---

## Stop/escalation conditions

Stop and ask user before continuing when:
- `Approved: true` is not set
- Required input is missing and cannot be inferred safely
- A blocker requires product/business preference
- A requested action is destructive or irreversible

---

## Final handoff format

Return:
1. Pipeline status (`done` or `blocked`)
2. Completed steps summary
3. Artifact file list
4. Blockers and resolutions
5. Next actions (if any)
