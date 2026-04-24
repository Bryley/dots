---
name: skill-builder
description: Creates, refactors, or audits reusable AI agent skills (SKILL.md) with activation-first metadata, a single clear workflow contract, explicit artifacts, verification loops, and trigger evals. Use when asked to build a new skill, improve an existing skill, or diagnose why a skill fails to trigger/perform.
---

# Skill Builder (Meta-Skill)

## Opening contract

Use this skill to produce **reliable, low-bloat, testable** skills.

A finished result must:
1. Trigger correctly from realistic user phrasing
2. Execute a single primary workflow clearly
3. Produce explicit, checkable outputs
4. Include verification and refinement hooks

---

## Defaults and inputs

If the user gives incomplete requirements, assume:
- Target: one workflow, one primary output contract
- Style: concise, operational, non-tutorial
- Safety: least privilege and explicit approval points for side effects

Before drafting, extract or ask for:
- Intended job of the skill (what it owns)
- Expected inputs and expected outputs
- Non-goals (what this skill should not do)
- Risk level (read-only vs side-effectful)

If key inputs are missing, stop and list exactly what is needed.

---

## Required artifacts

When using this meta-skill, always produce:
1. `SKILL.md` draft (spec-aligned frontmatter + body)
2. Trigger eval set (minimum: 2 positive, 1 negative)
3. Verification checklist (commands/artifacts)
4. Short changelog explaining high-impact edits

---

## Global constraints (hard rules)

- **Description is routing logic**: include what it does + when to use + trigger language.
- **One skill = one workflow contract**: split multi-mode behavior when triggers/outputs differ.
- **Prefer simple skill names**: default to short, literal names (e.g., `coding`, `debug`, `deploy`); only use longer names when required to avoid ambiguity/collision.
- Keep `SKILL.md` lean: operational core only; move depth to `references/` and mechanics to `scripts/`.
- Use explicit contracts: named files, headings, checks, stop conditions.
- No vague directives like “be careful” without measurable checks.
- Prefer deterministic/non-interactive scripts for mechanical tasks.

---

## Human checkpoints

Require confirmation before:
- Introducing destructive or irreversible steps
- Expanding scope from single workflow to multi-workflow
- Adding broad tool permissions or implicit network assumptions

---

## Workflow phases

### Phase 1 — Scope and boundaries
- Define primary job, input/output contract, and non-goals in one short block.
- Detect overlap with existing skills and propose split/merge strategy if needed.

### Phase 2 — Activation design
- Draft `name` and `description` for discoverability and disambiguation.
- Choose the shortest clear `name` first; let `description` carry nuance and routing detail.
- Add “use when” semantics and boundary cues.
- Optimize for natural user phrasing, not marketing language.

### Phase 3 — Execution contract
Draft body in this order:
1. Purpose/contract
2. Defaults/assumptions
3. Required artifacts
4. Ordered steps/phases
5. Verification loop
6. Stop/escalation conditions
7. Final handoff format

### Phase 4 — Context optimization
- Remove non-behavioral prose and repeated rationale.
- Move heavy examples/docs to `references/`.
- Move deterministic transforms/checks to `scripts/`.

### Phase 5 — Verification and evals
- Define done criteria in checkable terms.
- Add at least 3 trigger eval prompts (2 positive, 1 negative).
- Add execution checks (tests/lints/screenshots/file outputs as relevant).

### Phase 6 — Refinement loop
- Run evals, note misses, tighten metadata/instructions.
- If failures repeat, update skill contract (not ad-hoc chat steering).

---

## Guardrails and anti-patterns

Avoid:
- Vague descriptions (“helps with X”)
- Kitchen-sink skills with unrelated branches
- Critical constraints buried late
- Interactive scripts in autonomous workflows
- Over-automation before manual workflow reliability is proven

If tradeoffs are required, prefer:
- Clarity over cleverness
- Explicitness over brevity where safety is affected
- Smaller composable skills over one large polymorphic skill

---

## Final handoff format

Return results using this structure:

### A) Drafted/updated `SKILL.md`
(complete content)

### B) Trigger evals
- Positive 1:
- Positive 2:
- Negative 1:

### C) Verification checklist
- [ ] …
- [ ] …

### D) Changelog
- What changed
- Why it improves reliability/activation/execution
