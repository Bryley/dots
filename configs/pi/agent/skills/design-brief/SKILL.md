---
name: design-brief
description: Create or update a lean `design-system.yaml` that defines brand direction, form factors, themes, typography, spacing, and accessibility constraints. Use when starting a design project or redefining style direction.
---

# Design Brief

Create and maintain a single source-of-truth file: `design-system.yaml`.

## What this skill should do
- Gather minimal required context (goal, audience, desired style).
- Ask only essential follow-up questions when key fields are missing.
- Create or update `design-system.yaml` using the exact structure below.
- Keep the file lean and practical (no framework/tooling decisions here).
- Preserve existing valid values when updating.

## Required output file
- Path: `./design-system.yaml`
- Format: YAML
- Keep keys stable and concise.

## Single-prompt mode (default)
When the user gives only a short prompt (e.g. "make me a stunning fintech landing page"):
- Do not block on many questions.
- Infer sensible defaults for missing fields.
- Ask at most 1-2 clarifying questions only if critical.
- Produce `design-system.yaml` immediately, then iterate if user requests changes.

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

## Standout defaults (when user gives little detail)
If details are missing, bias toward polished, modern, high-impact choices:
- `direction.page_archetype`: infer from prompt (`marketing`, `dashboard`, `settings-form`, `app-screen`, `docs-content`, `poster`, `slides`, `social`).
- `direction.tone`: choose 1-2 from `editorial`, `bold`, `luxury`, `minimal` based on context.
- `direction.concept_statement`: one short sentence that locks the creative intent.
- `direction.visual_thesis`: one concise sentence describing visual execution.
- `direction.signature_motif`: one reusable motif to create identity continuity.
- `direction.signature_device`: optional focal visual object/pattern.
- `direction.composition_bias`: one layout bias (`editorial-asymmetry`, `calm-symmetry`, `modular-grid`, `floating-islands`).
- `direction.contrast_style`: one contrast mode (`soft-low-contrast`, `balanced-mid-contrast`, `crisp-high-contrast`).
- `direction.material_treatment`: one consistent surface language (`flat`, `paper`, `glass`, `matte`, `soft-shadow`).
- `direction.keywords`: include 4-8 concrete style cues.
- `direction.anti_goals`: include at least 3 anti-patterns.
- Themes: keep a strong contrast ratio between `bg`/`surface`/`text`, with one assertive `primary` and one deliberate `accent`.
- Typography: avoid overused default stacks; choose pairings with personality and high readability.

## Color/type/spacing selection heuristics
When choosing defaults or generating from sparse prompts:
- Colors: define clear role separation (`bg`, `surface`, `text`, `muted`, `primary`, `accent`, `border`) and avoid near-identical values.
- Colors: ensure role contrast (not just hue variation), especially `text` vs `surface` and `primary` vs `accent`.
- Typography: choose less-common but readable pairings; display and body should differ in personality while staying compatible.
- Typography scale: keep progression clear and compact (`sm < md < lg < xl`) and avoid dramatic jumps unless requested.
- Spacing: keep `unit` and `steps` simple; avoid overfitting many values.
- Spacing density should match intent (`airy`, `balanced`, `dense`) through step choices.
- Radius: align with tone (sharper for technical/brutalist, softer for calm/luxury/playful).

## Self-check before writing file
Before finalizing `design-system.yaml`, verify:
- Is the concept statement specific enough that two different models would produce similar visual character?
- Are colors differentiated by role (not just random hex values)?
- Do typography choices feel intentional for the target audience and medium?
- Are spacing/radius choices coherent with the chosen tone?
- Are anti-goals explicit enough to prevent generic output?

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
- `direction.tone` (1-3 preferred): `minimal`, `editorial`, `playful`, `luxury`, `bold`, `retro`, `futuristic`, `organic`, `brutalist`, `corporate-clean`
- `direction.composition_bias`: `editorial-asymmetry`, `calm-symmetry`, `modular-grid`, `floating-islands`, custom allowed
- `direction.contrast_style`: `soft-low-contrast`, `balanced-mid-contrast`, `crisp-high-contrast`, custom allowed
- `direction.material_treatment`: `flat`, `paper`, `glass`, `matte`, `soft-shadow`, custom allowed

## User-provided assets and references
The user may provide branding inputs (logos, screenshots, websites, PDFs, slide decks, social posts, style guides, product UI captures, etc.).
When present, quickly extract and reflect:
- Color cues: recurring brand hues, contrast tendencies, light/dark behavior.
- Typography cues: likely display/body style, tone, readability constraints.
- Composition cues: density, whitespace, corner style, visual rhythm.
- Brand personality cues: premium/playful/technical/editorial, and what to avoid.

Use provided assets as a strong prior, but still normalize into the canonical `design-system.yaml` structure and preserve readability/accessibility.

## Guardrails
- Do not add framework fields (React, Flutter, etc.) in this file.
- Do not add motion sections yet.
- Keep content compact to reduce token usage in downstream skills.
