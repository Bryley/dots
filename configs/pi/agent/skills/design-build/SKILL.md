---
name: design-build
description: Build and iteratively refine interactive frontend prototypes from `design-system.yaml` using a buildless workflow (React CDN + Tailwind CDN), visual screenshot checks, and accessibility-first polish.
---

# Design Build

Build fast, polished prototypes and refine them with tight visual feedback loops.

## Core objective
- Produce a standout, usable prototype quickly.
- Keep implementation buildless and easy to run in-browser.
- Preserve fidelity to `design-system.yaml`.
- Lock a single concept early and keep all sections consistent with it.

## Inputs
- `./design-system.yaml` (required style source of truth)
- User prompt + optional asset files/references

If `design-system.yaml` is missing:
- Ask the user to run `/skill:design-brief` first, or confirm generating a temporary default.
- Do not silently invent a full style system without user awareness.

## Output contract
- Primary output: `./prototype/index.html`
- Asset directory (when needed): `./prototype/assets/`
  - `./prototype/assets/images/`
  - `./prototype/assets/icons/`
  - `./prototype/assets/video/`
  - `./prototype/assets/audio/`

## Implementation rules
- Use a single `index.html` with:
  - React CDN
  - Tailwind CDN
  - inline `tailwind.config`
- Pin CDN versions where practical for reproducibility.
- Do **not** create `*.js` or `*.css` files unless the user explicitly asks.
- Tailwind-first: prefer utility classes; allow minimal inline `<style>` only for high-impact polish that Tailwind cannot express cleanly.
- Keep all key styling decisions mapped from `design-system.yaml`.
- Keep external dependencies minimal and clearly visible in the HTML.

## Design quality bar
- Choose a clear visual thesis and execute it intentionally.
- Avoid generic UI defaults and bland component patterns.
- Include one reusable signature motif (shape, stroke language, texture, lighting style, etc.) across key UI areas.
- When the archetype benefits from a focal visual, include one bespoke focal artifact (not just a standard card).
- Prioritize strong visual hierarchy, readable typography, and deliberate spacing.
- Vary rhythm/density intentionally (avoid same card/grid pattern everywhere).
- Define a consistent surface language (flat, paper, glass, matte, soft-shadow, etc.).
- Use subtle atmospheric background treatment when appropriate to support mood/depth.
- Keep contrast and legibility strong at normal reading sizes.
- Favor fewer, stronger design decisions over noisy or timid styling.

## Archetype-aware design
Adapt composition and interaction style to page type instead of forcing landing-page patterns:
- Dashboards: scanability, data hierarchy, quick actions.
- Forms/settings: completion flow, clarity, low cognitive load.
- Marketing/landing: narrative pacing, emotional emphasis.
- Docs/content: reading comfort, navigation clarity.
- Utility/product screens: speed, state clarity, operational confidence.

## Section distinctiveness
- Give each major section a role (focal, explanatory, proof, conversion, utility).
- Keep motif/material consistent, but vary composition so sections are not visually interchangeable.

## Interaction and refinement loop
- Ask minimal clarifying questions only when blocked.
- Ship a first usable draft quickly, then iterate.
- Apply targeted updates for feedback (layout, readability, spacing, hierarchy, polish).
- Prefer small, precise edits over full rewrites.
- Run a generic-section detector: if a section could fit any generic template, redesign it to reflect the project motif/thesis.

## Accessibility baseline
- Verify text/background contrast is acceptable.
- Ensure visible focus states for interactive elements.
- Ensure keyboard reachability for controls and nav.
- Keep default body text comfortably readable (typically ~16px unless intentionally different).
- Watch for clipping/overflow that harms readability.

## Icons and assets policy
- Default icon set: Lucide.
- If custom icons are required, create SVGs and store in `./prototype/assets/icons/`.
- Store reusable or large media in `./prototype/assets/` (images/video/audio).
- Do not scatter assets outside the prototype folder.

## Selector and targeting policy
- Add stable hooks for major sections/components:
  - `id` for human readability
  - `data-ai-id` for precise AI targeting
- Use consistent naming (e.g. `hero`, `feature-grid`, `pricing-card-pro`).

## Screenshot validation (required)
After major generation/update passes, run visual checks with the skill screenshot tool:
- `scripts/screenshot.js` (path is relative to this skill directory)

Behavior expectations:
- With no `--selector`: page screenshot (full page height by default, viewport-width mode by default).
- With `--selector`: component screenshot.
- No `--out`: script writes to temp file and prints path to stdout.

Useful options:
- `--width` / `--height` to match target form factor viewport.
- `--full-page true|false` to switch full-page vs viewport capture.
- `--capture-width viewport|page` for full-page width behavior.
- `--scroll-through` to trigger lazy-loaded content before capture.
- `--scroll-position top|bottom` for top/bottom-focused captures.
- `--debug-dimensions` to print viewport/page dimensions to stderr.

Recommended usage pattern:
- First pass: full-page screenshot with form-factor viewport.
- Then: targeted screenshots for key `data-ai-id` sections.
- Use `--scroll-through` when sections/images appear only after scroll.

Use screenshots to catch:
- overlapping elements
- clipping/overflow
- weak contrast/readability
- visual regressions after edits

## Form-factor validation
- Validate the primary form factor from `design-system.yaml` using matching viewport dimensions.
- When possible, also validate one additional supported form factor.

## Micro-detail polish pass (before completion)
Do one final polish pass on:
- typography rhythm (heading/body spacing, line lengths)
- icon optical alignment and control spacing
- border/shadow subtlety and consistency
- corner radius consistency by component role
- empty/loading/error states for key components

## Completion criteria
A pass is complete when:
- `./prototype/index.html` is runnable and visually polished.
- Output reflects `design-system.yaml`.
- Accessibility baseline checks are addressed.
- Screenshot review has been performed and obvious issues fixed.
- Critical console/runtime errors are not left unresolved.
