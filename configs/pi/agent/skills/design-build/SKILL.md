---
name: design-build
description: Build and iteratively refine interactive frontend prototypes from `design-system.yaml` using a buildless workflow (React CDN + Tailwind CDN), screenshot-driven review, and high-quality art direction.
---

# Design Build

Create a polished, distinctive prototype with one clear visual thesis.

## Priority ladder (use when rules conflict)
1. Distinctive concept and memorability
2. Restraint and composition quality
3. Readability and accessibility
4. Interaction polish
5. Process/tooling compliance

## 1) Mission
- Deliver a usable first draft quickly, then refine.
- Prioritize artistic clarity over checklist bloat.
- Preserve fidelity to `design-system.yaml`.

## 2) Hard constraints (non-negotiable)
- Required input: `./design-system.yaml`.
- Primary output: `./prototype/index.html`.
- Buildless stack in one file: React CDN + Tailwind CDN + inline `tailwind.config`.
- Pin CDN versions where practical for reproducible results.
- Do not create `*.js` or `*.css` files unless user explicitly asks.
- Keep assets in `./prototype/assets/` (`images`, `icons`, `video`, `audio`).
- Default icons: Lucide; custom icons only when needed in `./prototype/assets/icons/`.

If `design-system.yaml` is missing:
- Ask user to run `/skill:design-brief` first, or confirm temporary defaults.

## 3) Creative direction (highest priority)
Before building, lock:
- a visual thesis (1 sentence),
- a signature motif,
- one memorable focal moment,
- one **unforgettable design decision** used in at least 2 major areas.

Commit to a strong tone/style family from `design-system.yaml` and execute it consistently.
Do not reinterpret toward safe defaults; amplify the chosen family in typography, composition, and surfaces.
Use a distinctive, readable type pairing; avoid overused default font choices unless explicitly requested.

Never ship generic AI aesthetics:
- over-repeated card grids,
- bland SaaS defaults,
- weak hierarchy,
- decorative noise without purpose,
- trendy-but-contextless styles.

## 4) Composition and archetype fit
- Prefer fewer, stronger sections over many repetitive sections.
- For marketing/narrative first drafts, target roughly 4-6 major sections unless user asks for more.
- Card-chrome budget: use at most 2 repeated card-cluster sections unless explicitly requested.
- Keep negative space intentional; do not fill every region.
- Vary section treatment only when it strengthens the concept.
- Include at least one deliberate section pacing shift (tonal/material contrast) so the page does not feel visually flat.
- Carry one typographic signature move into at least 2 sections (e.g. italic phrase treatment, display/sans contrast pattern, or pull-quote style).
- If a section feels generic or low-value, remove/merge it.

Adapt to page type:
- Marketing/narrative: focal storytelling and paced reveal.
- Dashboard/utility: scanability, hierarchy, fast actions.
- Forms/settings: completion clarity, minimal distraction.
- Docs/content: reading comfort and navigation clarity.

## 5) Motion and theme behavior
- Add tasteful hover/focus micro-interactions by default.
- Add subtle scroll-reveal/stagger only for narrative pages.
- Keep motion minimal/functional for dashboards/forms/settings.
- Respect `prefers-reduced-motion`.
- Add light/dark mode toggle by default unless user opts out.
- For isolated components/panels (not full pages), theme toggle is optional.
- Ensure both themes feel designed (not simple inversion), and persist preference when practical.

## 6) QA workflow and completion
- Add stable hooks on key regions: `id` + `data-ai-id`.
- Run screenshot checks with `scripts/screenshot.js` (skill-relative path):
  - full-page at primary viewport,
  - targeted shots for key `data-ai-id` regions,
  - use `--scroll-through` during QA to catch lazy/reveal-state issues.
- Tooling efficiency:
  - Do not read the full screenshot script by default (token waste).
  - Validate usage with `node scripts/screenshot.js --help` (or equivalent skill-relative path) and run commands directly.
  - Read script source only when debugging failures or changing the script itself.

Run 3 short passes after first draft:
1. Concept pass (reinforce thesis/motif, remove off-theme elements)
2. Polish pass (typography rhythm, spacing, surfaces, CTA emphasis)
3. Accessibility pass (contrast, focus states, keyboard reachability, reduced-motion)

Pass accountability (required):
- For each pass, record:
  - issues found,
  - concrete edits made (file + targeted area),
  - or explicit reason if no edit is needed.
- If issues are found, apply at least one targeted edit before the next pass.

Motion/visibility safeguards:
- Do not let scroll animations gate core content visibility.
- Content must remain readable when motion is reduced/disabled.
- Verify no major section is unintentionally low-opacity, blurred, or hidden before completion.

Pass stop condition:
- Continue passes until no high-severity issues remain, or
- two consecutive passes produce no meaningful improvements (with explicit reason).

Final de-bloat check:
- remove 15-25% non-essential content if page feels crowded.

A pass is complete when:
- page is polished and runnable,
- design-system fidelity is maintained,
- obvious visual/runtime issues are fixed,
- motion/theme behavior is intentional and usable,
- layout is not overcrowded and the focal hierarchy is clear,
- all major sections are clearly visible in QA screenshots,
- repeated card clusters are within budget,
- at least one tonal/material pacing shift is present,
- typographic signature move is clearly visible in at least 2 sections.
