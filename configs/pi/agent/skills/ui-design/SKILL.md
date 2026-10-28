---
name: ui-design
description: Make UI design decisions and review UX for simple, restrained, accessible applications. Use when planning screens or flows, simplifying a cluttered interface, reviewing usability, or choosing layout, whitespace, typography and colors. Produces a concise design recommendation and prioritized usability findings; not a frontend implementation or branding workflow.
---

# UI Design

## Contract
Help people complete their task with minimal confusion. Priorities: usability → accessibility → clarity → visual character. Produce a short design recommendation and evidence-backed review, not code or a new framework. Modify files only when explicitly authorized.

Reuse suitable components, brand rules and tokens; surface accessibility conflicts. Leave code, prototypes and formal design-system files to other workflows. Explain conflicting priorities rather than combining novelty-first defaults with this skill.

## 1. Establish the task
Read provided material. Identify audience, primary task, essential information, devices and costly mistakes. Ask at most two questions when missing context changes the recommendation; otherwise state assumptions.

Describe entry → action → feedback → recovery. Use user vocabulary, familiar patterns and recognition over recall. Fewer clicks do not necessarily mean less effort.

## 2. Make a restrained design recommendation
Give a compact layout/flow sketch and visual roles for new work; retain what works in existing UI. Apply:

- **Hierarchy:** make the page purpose and next action apparent. Give each task area a clear primary action; subordinate secondary actions and separate destructive ones. Use actual content, not generic marketing filler.
- **Whitespace and alignment:** use a small spacing scale, such as 4/8/12/16/24/32px. Space within a group less than between groups. Align edges consistently; adapt density to the task rather than making every screen airy.
- **Section separation:** use descriptive headings, proximity and consistent gaps first; add a divider or surface change only when it clarifies a boundary. Keep global navigation, local navigation and content visually distinct. Do not put everything in a card.
- **Typography:** default to one readable family, including system fonts; two only with a clear role. Use a compact type scale and 2–3 weights. Start body text around 16px, line-height around 1.5, reading lines around 45–75 characters; adjust to context. Avoid tiny, thin or low-contrast labels. Align prose to its reading direction; align comparable numbers consistently.
- **Color:** default to neutrals plus one accent, with additional semantic colors only as needed. Assign stable roles: background, surface, text, muted text, border, action and status. Reserve emphasis for important information. Pair status colors with text or shape; distinguish links beyond color alone.
- **Controls and copy:** use recognizable controls, consistent terms, visible labels, sentence case and specific actions (“Save changes”). Name icon-only controls accessibly; explain unfamiliar icons visibly. No hover-only or gesture-only essentials.
- **Forms and feedback:** persistent labels, upfront requirements, timely validation, field-associated errors and recovery instructions. Preserve values; explain saving, completion and why actions are disabled. Allow paste and useful autofill.
- **Visual restraint:** avoid gratuitous gradients, glass, glow, giant headings, floating shapes, pill badges, repeated card grids and scroll reveals. Use imagery or motion only for a task or content purpose; respect reduced motion. No automatic theme toggle, signature motif or unusual font requirement. Existing conventional styling is acceptable: specificity comes from real content and good decisions, not novelty.

Do not remove labels, feedback or discoverability to achieve minimalism. Every additional visual device should clarify meaning, grouping, state or action; otherwise remove it.

## 3. Walk through failure and edge cases
Walk one realistic task as a first-time and returning user. Check relevant risks:
- Is location, clickability, changed state and next action clear? Are Back, refresh and relevant deep links predictable?
- Are loading, empty, no-results, error, success and permission-limited states useful? Could hidden filters imply missing data?
- Do long/translated text, large datasets and missing values break layout or hide essential information?
- Could delays, repeat clicks, timeouts, navigation or session expiry duplicate actions or lose work? Check retry and unsaved-change recovery.
- Could adjacent controls, ambiguous scope or defaults cause costly mistakes? Prefer undo for reversible actions; explicit confirmation for irreversible ones.

Separate observed defects from plausible risks. Recommend task-based testing with real users when uncertainty matters.

## 4. Verify accessibility and layout
Use computed styles and available browser/accessibility tools, not visual guesses. Record the tool or method and results.

- **Contrast:** use a WCAG contrast checker on actual foreground/background pairs, accounting for transparency and image backgrounds. Record pair, state and ratio. Normal text: ≥4.5:1; large text (≥24 CSS px regular or ≥18.67 CSS px bold): ≥3:1. Required control/state indicators and meaningful graphics: ≥3:1 against adjacent colors. Check muted text, placeholders, buttons, errors and focus indicators in supported themes and relevant states. Do not round a failing ratio upward. Decorative and inactive elements have exceptions; do not apply text thresholds blindly to all borders.
- **Keyboard:** complete the primary flow without a pointer. Check logical focus order, visible unobscured focus, no traps, expected widget keys, and dialog focus entry/return. Native controls before custom widgets.
- **Semantics:** inspect headings, landmarks, names, labels, image alternatives and error associations. Verify important asynchronous feedback is announced appropriately; include a screen-reader spot check when available.
- **Targets and reflow:** prefer roughly 44×44 CSS px touch targets. WCAG 2.2 AA minimum is 24×24 CSS px, with documented spacing/other exceptions. Test narrow width (around 320 CSS px), 200% text enlargement and 400% zoom: no lost controls or clipped essential content; legitimate two-dimensional content may scroll locally. Do not disable zoom.

Use available automated scans plus manual checks; scans alone do not establish compliance. Screenshots show composition, not measured contrast, keyboard behavior or semantics. For screenshot/proposal-only work, give acceptance checks and mark verification pending. Never invent measurements or claim WCAG compliance.

## 5. Refine and hand off
Address blockers → recurring friction → polish. Recheck changed flows; stop at no known in-scope blockers or report constraints. No unrelated redesign.

Return concisely:
1. **Direction:** task, layout/flow, and restrained visual choices (omit redundant detail for a review).
2. **Findings:** severity → screen/component or file:line → user consequence → smallest useful fix. Use blocker / friction / polish; no invented locations.
3. **Verification:** checks performed, measured contrast pairs, unresolved risks and untested behavior.
