---
name: brand-kit
description: >
  Pointer to the per-project brand kit canonical source at
  <ProductVideos>/brand/brand.json. Used by the scriptwriter (personas,
  banned phrases, tone of voice), compositor (colors, fonts, logo
  placement), and reviewer (verifies brand tokens are used, not
  hardcoded). The harness encodes process rules + a neutral starter
  brand.json template here; the brand itself lives in the ProductVideos
  repo and evolves with the brand.
disable-model-invocation: true
user-invocable: true
---

# Brand Kit — Pointer

**This skill is a thin pointer.** The canonical brand kit for your product lives in `<ProductVideos>/brand/brand.json` (and `brand/logo.svg`, `brand/fonts/`) — collected per-workspace at init time. Read it directly when you need brand decisions.

## Required reads

1. `<ProductVideos>/brand/brand.json` — colors, fonts, logo, safe-area, lower-third style. Single source of truth.
2. `<ProductVideos>/brand/logo.svg` — the brand logo (SVG, preferred over PNG for sharpness at any size).
3. Optional: `<ProductVideos>/brand/fonts/` — font files if not loaded via system / web.

## brand.json structure (neutral starter template)

This is the starter template `/init-video-workspace` ships; `/update-brand-kit` (and the init brand-collection flow) replace these values with your brand's. `name` is derived from the workspace folder name at init.

```json
{
  "name": "Your Brand",
  "tagline": "Your tagline here.",
  "colors": {
    "primary": "#2563EB",
    "primaryAlt": "#60A5FA",
    "accent": "#F59E0B",
    "ink": "#0B1020",
    "paper": "#F8FAFC",
    "muted": "#64748B"
  },
  "fonts": {
    "heading": "Inter",
    "body": "Inter",
    "mono": "JetBrainsMono"
  },
  "logo": {
    "path": "brand/logo.svg",
    "minSizePx": 56,
    "safeAreaPx": 32
  },
  "lowerThird": {
    "barHeightPx": 96,
    "barOpacity": 0.85,
    "barColor": "ink",
    "textColor": "paper"
  },
  "captionStrip": {
    "fontSizePx": 48,
    "lineHeightPx": 60,
    "bgColor": "ink",
    "bgOpacity": 0.8,
    "textColor": "paper",
    "paddingPx": 16,
    "maxWordsPerLine": 7,
    "maxLines": 2
  },
  "personas": [
    {
      "key": "end_user",
      "label": "primary end user of the product",
      "voice": "warm, plainspoken"
    },
    {
      "key": "prospect",
      "label": "prospective customer evaluating the product",
      "voice": "curious, value-driven"
    },
    {
      "key": "partner",
      "label": "partner / stakeholder integrated with the product",
      "voice": "professional, trust-building"
    }
  ],
  "tone": {
    "default": "warm and credible — confident without hype",
    "banned_words": ["revolutionary", "game-changing", "disrupt", "synergy", "leverage", "10x"],
    "banned_phrases": ["AI-powered", "next-generation", "world-class"],
    "preferred_verbs": ["track", "see", "manage", "grow", "save", "send", "get"]
  }
}
```

## Process rules (encoded here — they cross-cut the workflow)

### Colors

- Always referenced via `brand.colors.<key>` in compositions. Never inline a hex literal like `#2563EB`.
- Primary is for hero accents; never for body text on light backgrounds (contrast issues).
- Ink is the default video background (works well with most app dark modes).
- Accent used sparingly — CTAs, success states, hero callouts. Never as page background.

### Fonts

- Headings: `brand.fonts.heading` (Inter, weight 600-800).
- Body / captions: `brand.fonts.body` (Inter, weight 400-500).
- Mono only for code snippets / data tables.
- Never load a font not in `brand/fonts/` or system-available.

### Logo

- Minimum on-screen size: `brand.logo.minSizePx` (currently 56px).
- Always with `brand.logo.safeAreaPx` clear space (32px in v0.1.0) — no other elements within that margin.
- Lockup orientations: horizontal preferred for 16:9, stacked for 1:1 and 9:16.

### Personas

- Scripts MUST use one of `brand.personas[].key` — never generic "user", "customer", "people".
- Persona drives voice — the scriptwriter's `tone` field maps to `brand.personas[].voice`.

### Tone of voice

- Banned words / phrases (`brand.tone.banned_*`) are non-negotiable — scriptwriter rejects any voiceover containing them.
- Preferred verbs guide CTA construction.

## Keeping brand tokens in sync across repos (for reference)

If your product also ships a web/app surface with its own design tokens (e.g. via the SDLC harness's web conventions), keep them aligned with this brand kit: `brand.colors.primary` / `brand.colors.ink` / `brand.colors.accent` are the canonical source. Update `<ProductVideos>/brand/brand.json` first when the brand evolves, then propagate to the product repo's architecture docs (e.g. via the SDLC harness's architecture-reconciliation phase).
