---
name: design-brief
description: Create or update a lean `design-system.yaml` that defines visual direction, color/typography system, form factors, themes, spacing, and accessibility constraints. Use when starting a design project, redefining style direction, or making reference-informed art-direction changes.
---

# Design Brief

Create and maintain a single source-of-truth file: `design-system.yaml`.

## What this skill should do
- Gather minimal required context (goal, audience, desired style).
- Ask only essential follow-up questions when key fields are missing.
- Explore 3 distinct art directions, select one, then commit.
- Create or update `design-system.yaml` using the exact structure below.
- Keep the file lean and practical (no framework/tooling decisions here).
- Preserve existing valid values when updating.

## Non-goals (do not do in this skill)
- Do not build UI code (`index.html`, React components, CSS).
- Do not choose implementation framework/tooling (Next.js, Vue, etc.).
- Do not run screenshot QA or visual polish passes.
- Do not define motion implementation details beyond brief-level direction fields.

## Required output file
- Path: `./design-system.yaml`
- Format: YAML
- Keep keys stable and concise.

## Single-prompt mode (default)
When the user gives only a short prompt (e.g. "make me a stunning fintech landing page"):
- Do not block on many questions.
- Infer sensible defaults for missing fields.
- Ask at most 1-2 clarifying questions only if critical.
- Quickly draft 3 distinct art directions, pick one, then produce `design-system.yaml`.

## Direction exploration (required)
Before finalizing `design-system.yaml`, draft 3 short direction candidates (A/B/C), then choose one.
Each candidate must differ in at least 3 axes:
- style family,
- palette temperature/hue family,
- typography personality,
- composition bias,
- motif/material treatment.

For reference-driven requests (e.g. “closer to Claude-style quality”), make candidates intentionally varied:
- one reference-leaning editorial direction,
- one adjacent-but-distinct direction,
- one clearly orthogonal direction.

Then commit fully to one selected direction in the final YAML.

## Aesthetic quality bar (Claude-inspired)
Always push for distinctive, intentional design direction:
- Commit to a clear visual point-of-view (not generic SaaS defaults).
- Pick one memorable signature trait (e.g. cinematic contrast, editorial typography, geometric motif).
- Use strong color hierarchy: dominant base + purposeful accent.
- Pick typography with character and clear role separation (display/body/mono).
- Ensure readability and contrast remain strong at body-text sizes.
- Keep spacing rhythm consistent so layouts feel deliberate.
- Encode anti-goals to avoid cliché aesthetics.
- Prefer fewer, stronger choices over many timid choices.

Use reference transfer, not cloning:
- Borrow principles (typographic voice, tonal restraint, pacing, whitespace discipline, accent restraint), not literal layouts.
- Preserve at least 2 differentiators in the final direction (e.g. different palette family + different motif system).

## Standout defaults (when user gives little detail)
If details are missing, bias toward polished, modern, high-impact choices:
- `direction.page_archetype`: infer from prompt (`marketing`, `dashboard`, `settings-form`, `app-screen`, `docs-content`, `poster`, `slides`, `social`).
- `direction.style_family`: pick one strong family and commit.
- `direction.tone`: choose 1-2 from `editorial`, `bold`, `luxury`, `minimal` based on context.
- `direction.concept_statement`: one short sentence that locks the creative intent.
- `direction.visual_thesis`: one concise sentence describing visual execution.
- `direction.signature_motif`: one reusable motif to create identity continuity.
- `direction.signature_device`: optional focal visual object/pattern.
- `direction.composition_bias`: one layout bias (`editorial-asymmetry`, `calm-symmetry`, `modular-grid`, `floating-islands`).
- `direction.contrast_style`: one contrast mode (`soft-low-contrast`, `balanced-mid-contrast`, `crisp-high-contrast`).
- `direction.material_treatment`: one consistent surface language (`flat`, `paper`, `glass`, `matte`, `soft-shadow`).
- `direction.keywords`: include 5-9 concrete style cues, including one typographic signature cue and one section-pacing cue.
- `direction.anti_goals`: include at least 5 anti-patterns (include at least 1 anti-cliche and 1 anti-repeat item).
- Themes: keep a strong contrast ratio between `bg`/`surface`/`text`, with one assertive `primary` and one deliberate `accent`.
- Typography: avoid overused default stacks; choose pairings with personality and high readability.

Underconstrained fallback rotation:
- Rotate `direction.style_family` instead of repeating the same family across unrelated briefs.
- Avoid repeatedly defaulting to `neutral_tint: sage` unless the prompt/reference implies it.
- Prefer `accent_strategy: single-pop` by default; use `dual-accent` only when energy/expressiveness is explicit.

## Color/type/spacing selection heuristics
When choosing defaults or generating from sparse prompts:
- Colors: define clear role separation (`bg`, `surface`, `text`, `muted`, `primary`, `accent`, `border`) and avoid near-identical values.
- Colors: ensure role contrast (not just hue variation), especially `text` vs `surface` and `primary` vs `accent`.
- Colors: use tinted neutrals (subtle hue bias) instead of flat grayscale when tone calls for refinement.
- Colors: keep accent usage intentional and sparse; avoid spreading accent color across too many elements.
- Typography: choose less-common but readable pairings; display and body should differ in personality while staying compatible.
- Typography: rotate away from recurring defaults (e.g. repeated Fraunces/Manrope reuse) unless explicitly requested.
- Typography scale: keep progression clear and compact (`sm < md < lg < xl`) and avoid dramatic jumps unless requested.
- Spacing: keep `unit` and `steps` simple; avoid overfitting many values.
- Spacing density should match intent (`airy`, `balanced`, `dense`) through step choices.
- Radius: align with tone (sharper for technical/brutalist, softer for calm/luxury/playful).

## Designer font selection (required)
Select type from a curated, high-quality pool and justify pairing fit to `direction.style_family`.
- Editorial/luxury candidates: `Canela`, `Noe Display`, `Cormorant Garamond`, `Bodoni Moda`, `Ivar Display`, `Playfair Display`
- Modern/tech candidates: `Sora`, `Space Grotesk`, `General Sans`, `Manrope`, `Inter Tight`, `IBM Plex Sans`
- Humanist/content candidates: `Source Sans 3`, `Instrument Sans`, `Public Sans`, `Work Sans`
- Mono accents: `IBM Plex Mono`, `JetBrains Mono`, `Geist Mono`

Pairing rules:
- Prefer one expressive display + one highly readable body.
- Avoid repeating the exact same display/body pair when prompt is underconstrained.
- If a premium/editorial brief is requested, default to serif-led display instead of all-sans.

## Color art direction
Add a compact color strategy that drives stronger palette decisions:
- `color_art_direction.palette_intent`: overall palette mood (e.g. `quiet-luxury`, `editorial-contrast`, `calm-tech`, `playful-pop`)
- `color_art_direction.temperature`: `warm` | `cool` | `mixed`
- `color_art_direction.neutral_tint`: subtle neutral hue bias (e.g. `sage`, `stone`, `slate`, `sand`, `rose-gray`)
- `color_art_direction.accent_strategy`: `single-pop` | `dual-accent` | `monochrome-plus`
- `color_art_direction.color_ratio`: intended base/surface/accent usage (e.g. `75/20/5`)

## Self-check before writing file
Before finalizing `design-system.yaml`, verify (pass/fail):
- [ ] Concept statement is specific enough that two different models would produce similar visual character.
- [ ] Colors are differentiated by role (not random hex picks).
- [ ] Typography choices are intentional for audience and medium.
- [ ] Spacing/radius choices are coherent with tone and material treatment.
- [ ] Anti-goals are explicit enough to block generic output.
- [ ] `direction.anti_goals` has 5+ items, including at least one anti-cliche, one anti-repeat clause, and one anti-card-grid clause.
- [ ] Brief includes one typographic signature cue and one section-pacing cue.
- [ ] If reference-inspired, brief includes at least 2 borrowed principles and at least 2 clear differentiators.
- [ ] Chosen direction differs from rejected candidates on at least 3 axes (`style_family`, palette family/temperature, typography personality, composition bias, motif/material).

Safe-profile rejection:
- If the direction converges to a common default cluster (e.g. `minimal+organic`, `calm-symmetry`, `matte/paper`, `sage-like neutral tint`, `balanced-mid-contrast`) without explicit user request, regenerate once with a bolder style-family choice.

Freshness safeguards:
- Do not reuse the same motif family (`arcs/rings/halos`) by default; rotate to a different motif class (rules/lines, cut-paper planes, typographic blocks, geometric frames, etc.).
- Anti-goals must explicitly block the most likely fallback cliché for the chosen style family.
- Include an anti-goal that blocks repeated card-stack layout chrome (e.g. repetitive rounded card grids).
- Chosen direction must include one "unmistakable decision" that is visible in at least two sections downstream (e.g. type treatment, motif system, or sectional rhythm).
- Chosen direction should define one pacing shift (tonal/material contrast between sections) to avoid visual flatness across the page.

## Canonical structure

```yaml
version: 1

project:
  name: ""
  goal: ""
  audience: ""

form_factors:
  primary: "desktop-web"
  supported:
    - name: "desktop-web"
      viewport: { width: 1440, height: 1024 }
      orientation: "landscape"

# tones are style direction tags; choose 1-3
direction:
  page_archetype: "marketing"
  style_family: "editorial-contrast"
  tone: ["minimal"]
  concept_statement: ""
  visual_thesis: ""
  signature_motif: ""
  signature_device: ""
  composition_bias: "calm-symmetry"
  contrast_style: "balanced-mid-contrast"
  material_treatment: "matte"
  keywords: []
  anti_goals: []

accessibility:
  contrast_target: "AA"
  base_font_px: 16

color_art_direction:
  palette_intent: "quiet-luxury"
  temperature: "warm"
  neutral_tint: "sage"
  accent_strategy: "single-pop"
  color_ratio: "75/20/5"

themes:
  light:
    bg: "#ffffff"
    surface: "#f6f7f9"
    text: "#111111"
    muted: "#667085"
    primary: "#2563eb"
    accent: "#d97706"
    border: "#e5e7eb"
  dark:
    bg: "#0b1020"
    surface: "#121a2b"
    text: "#f3f4f6"
    muted: "#94a3b8"
    primary: "#60a5fa"
    accent: "#fbbf24"
    border: "#24324a"

typography:
  display: "Plus Jakarta Sans"
  body: "Source Sans 3"
  mono: "JetBrains Mono"
  scale:
    sm: 14
    md: 16
    lg: 20
    xl: 28

spacing:
  unit: 4
  steps: [1, 2, 3, 4, 6, 8, 12]
  radius:
    sm: 6
    md: 10
    lg: 14
```

## Allowed options
- `form_factors.primary` / `supported[].name`:
  - `desktop-web`, `mobile-phone`, `tablet`, `slides-16:9`, `slides-4:3`, `poster-a4`, `poster-a3`, `instagram-post`, `instagram-story`, `linkedin-post`
  - custom allowed if needed (prefer explicit viewport)
- `supported[].orientation`: `portrait` | `landscape` | `square`
- `accessibility.contrast_target`: `AA` | `AAA`
- `direction.page_archetype`: `marketing`, `dashboard`, `settings-form`, `app-screen`, `docs-content`, `poster`, `slides`, `social`, custom allowed
- `direction.style_family`: `editorial-contrast`, `clinical-precision`, `neo-brutalist`, `cinematic-dark`, `playful-kinetic`, `organic-luxury`, `retro-modern`, `data-minimal`, custom allowed
- `direction.tone` (1-3 preferred): `minimal`, `editorial`, `playful`, `luxury`, `bold`, `retro`, `futuristic`, `organic`, `brutalist`, `corporate-clean`
- `direction.composition_bias`: `editorial-asymmetry`, `calm-symmetry`, `modular-grid`, `floating-islands`, custom allowed
- `direction.contrast_style`: `soft-low-contrast`, `balanced-mid-contrast`, `crisp-high-contrast`, custom allowed
- `direction.material_treatment`: `flat`, `paper`, `glass`, `matte`, `soft-shadow`, custom allowed
- `color_art_direction.temperature`: `warm` | `cool` | `mixed`
- `color_art_direction.accent_strategy`: `single-pop` | `dual-accent` | `monochrome-plus`

## User-provided assets and references
The user may provide branding inputs (logos, screenshots, websites, PDFs, slide decks, social posts, style guides, product UI captures, etc.).
When present, quickly extract and reflect:
- Color cues: recurring brand hues, contrast tendencies, light/dark behavior.
- Typography cues: likely display/body style, tone, readability constraints.
- Composition cues: density, whitespace, corner style, visual rhythm.
- Brand personality cues: premium/playful/technical/editorial, and what to avoid.

For strong visual references, explicitly split:
- transfer principles to keep,
- literal traits to avoid copying,
- differentiators to enforce in this brief.

Use provided assets as a strong prior, but still normalize into the canonical `design-system.yaml` structure and preserve readability/accessibility.

## Required response format
Return in this order:
1. `Direction exploration summary`
   - Direction A (short)
   - Direction B (short)
   - Direction C (short)
2. `Chosen direction`
   - Why chosen
   - 2 borrowed reference principles (if reference-driven)
   - 2 enforced differentiators
3. `Output written`
   - `./design-system.yaml`
4. `Verification`
   - checklist pass/fail summary

## Trigger evals (activation checks)
- Positive 1: "Create a design-system for a fintech dashboard with a strong, premium visual direction."
- Positive 2: "Make this landing feel closer to Claude-level craft but not a clone; update the design brief."
- Negative 1: "Implement this in Next.js with Tailwind components and animations."

## Guardrails
- Do not add framework fields (React, Flutter, etc.) in this file.
- Do not add motion sections yet.
- Keep content compact to reduce token usage in downstream skills.
