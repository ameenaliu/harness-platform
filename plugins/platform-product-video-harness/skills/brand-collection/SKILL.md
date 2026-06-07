---
name: brand-collection
description: >
  Canonical Q&A protocol for collecting brand kit inputs (name, colors,
  logo, tagline, fonts) and writing brand/brand.json + brand/logo.svg.
  Used by /init-video-workspace (Step 4.5, first-time setup) AND by
  /update-brand-kit (any-time update). Single source of truth so both
  paths use the same prompts, the same defaults, and the same random
  palette algorithm.
disable-model-invocation: true
user-invocable: true
---

# Brand collection protocol

Single source of truth for gathering brand-kit inputs from the user and writing them to `<ProductVideos>/brand/brand.json` + `<ProductVideos>/brand/logo.svg`.

This protocol is invoked by:
- `/init-video-workspace` Step 4.5 — first-time setup. No existing brand.json, so "current value" is "(none)".
- `/update-brand-kit` — any time after that. Reads existing brand.json, shows current values as defaults, only overwrites what the user changes.

## Inputs

- `<ProductVideos>` — absolute path to the ProductVideos repo root
- `<mode>` — `init` (called from init-video-workspace) or `update` (called from update-brand-kit)

## Output

- `<ProductVideos>/brand/brand.json` — written from scratch (init) or updated in place (update)
- `<ProductVideos>/brand/logo.svg` — replaced if the user provides a new one; left alone otherwise

## The protocol

### Step 0 — Load current state

- If `<ProductVideos>/brand/brand.json` exists, read it and remember every field as the "current value" (used as defaults in update mode).
- If it doesn't exist (init mode, fresh repo), seed defaults internally:
  - `name`: **derived from the workspace / repo folder name** — split on `-`/`_`/space, Title-Case each token (e.g. `kawee-kids` → `"Kawee Kids"`, `nafuu_app` → `"Nafuu App"`). Fall back to `"Your Brand"` only if the folder name is unusable.
  - `tagline`: `"Your tagline here."`
  - All other fields: see "Defaults" at the bottom of this file (neutral starter palette + generic personas).

### Step 1 — Brand name

Ask via `AskUserQuestion` (single, 2 options):

```
What's the brand name?
  - Keep current: <current name>          ← skip; reuse what's there
  - Other                                 ← user types a new name
```

(In init mode with no current name, replace the first option with `Use "<derived-from-folder-name>"`.)

### Step 2 — Tagline

Same shape:

```
What's the tagline? (One short sentence — appears on EndCard scenes.)
  - Keep current: "<current tagline>"
  - Other                                 ← user types
```

### Step 3 — Color palette

Ask via `AskUserQuestion` (single, 4 options):

```
How do you want to set brand colors?
  - Keep current palette (primary / accent / ink / paper)   ← only shown when current exists
  - Use neutral starter defaults (blue / amber / ink)        ← always shown in init mode
  - Generate a random pleasing palette
  - I'll provide my own hex codes
```

#### If "Provide my own"

Ask 4 separate `AskUserQuestion` calls (single, 2 options each: "Keep current: <hex>" + "Other"):

- `colors.primary` — main brand accent (default suggestion: `#2563EB`)
- `colors.accent` — call-to-action / highlight (default: `#F59E0B`)
- `colors.ink` — dark background / body text on light (default: `#0B1020`)
- `colors.paper` — light background / body text on dark (default: `#F8FAFC`)

Validate each: must match `^#[0-9A-Fa-f]{6}$` or `^#[0-9A-Fa-f]{3}$`. If invalid, re-prompt with the same question and a one-line "Hex format like #2563EB — try again." note.

Derive these from the four answers (don't ask separately):
- `colors.primaryAlt` — primary shifted ~40% lighter (algorithm: convert primary to HSL, set L to min(95, current_L + 30), back to hex).
- `colors.muted` — mid gray with ink's hue tint (algorithm: ink hue, saturation 10%, lightness 50%).

#### If "Generate random pleasing palette"

Algorithm (deterministic so re-runs without input change are stable — seed from brand name hash):

1. Pick a primary hue H in [0, 360) from the brand-name hash modulo 360.
2. `colors.primary` = HSL(H, 70%, 45%) → hex
3. `colors.primaryAlt` = HSL(H, 80%, 70%) → hex
4. `colors.accent` = HSL((H + 120) mod 360, 70%, 55%) → hex (analogous-triadic)
5. `colors.ink` = HSL(H, 30%, 12%) → hex (near-black with hue tint)
6. `colors.paper` = HSL(H, 30%, 96%) → hex (near-white with hue tint)
7. `colors.muted` = HSL(H, 15%, 50%) → hex (mid-gray with hue tint)

Tell the user the palette before writing it: *"Generated palette: primary #..., accent #..., ink #... — want to regenerate (different hue) or accept?"* via `AskUserQuestion`: `Accept` / `Regenerate` (loops back to step 1 with a new hue offset) / `Switch to provide my own` / `Use neutral starter defaults instead`.

### Step 4 — Logo

Ask via `AskUserQuestion` (single, 4 options):

```
Where's your logo SVG?
  - Keep current: brand/logo.svg                          ← only in update mode when file exists
  - I have a local file path                              ← user types absolute or repo-relative path
  - I have a URL — download it                            ← user types https:// URL
  - Generate a text placeholder using the brand name      ← inline SVG with brand name on ink bg
```

For "local path":
- Verify file exists and ends in `.svg` (warn if `.png`/`.jpg`/`.webp` — those work but SVG is preferred for sharpness at any size).
- Copy via `Bash cp` to `<ProductVideos>/brand/logo.svg` (preserving extension if non-svg).

For "URL":
- `curl -sfLo <ProductVideos>/brand/logo.svg "<url>"` — verify exit 0 and file is non-empty.
- If `Content-Type` headers indicated non-svg, rename appropriately.

For "Generate text placeholder":
- Write `<ProductVideos>/brand/logo.svg` using this template (substitute `{{NAME}}` and `{{INK}}` / `{{PRIMARY}}` from the collected brand):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 240 60" width="240" height="60" role="img" aria-label="{{NAME}}">
  <rect width="240" height="60" rx="8" fill="{{INK}}"/>
  <text x="50%" y="50%" dominant-baseline="middle" text-anchor="middle"
        font-family="Inter, sans-serif" font-weight="800" font-size="28" fill="{{PRIMARY}}">
    {{NAME}}
  </text>
</svg>
```

### Step 5 — Fonts (advanced — usually skipped)

Ask via `AskUserQuestion` (single, 2 options):

```
Use the default font stack (Inter for heading + body, JetBrainsMono for code)?
  - Yes (Recommended)
  - No — I'll customise                ← user types heading/body/mono names
```

If "No":
- Ask `fonts.heading` (single Q, "Keep Inter" + "Other")
- Ask `fonts.body` (single Q, "Keep Inter" + "Other")
- Ask `fonts.mono` (single Q, "Keep JetBrainsMono" + "Other")

Tell the user: *"Note — fonts must be available system-wide OR self-hosted via brand/fonts/. Inter and JetBrainsMono are the safest defaults."*

### Step 6 — Personas + tone

Offer in both modes (the prompt copy differs slightly):

```
Update personas and tone-of-voice rules?
  - Keep current / use neutral starter personas                        ← skip
  - Edit personas (add / remove / change labels)                       ← prose flow
  - Edit tone (banned words, banned phrases, preferred verbs)          ← prose flow
  - Both
```

If "Edit personas" or "Both": show the current (or neutral starter) personas, ask which to change, accept new key/label/voice via prose. Write back to brand.json.

If "Edit tone" or "Both": show current banned_words / banned_phrases / preferred_verbs, ask which lists to modify, accept comma-separated additions/removals via prose.

In **init mode**, the "Keep current" option reads as **"Use neutral starter personas"** — the generic `end_user` / `prospect` / `partner` set from the Defaults below. This keeps first-init fast while still surfacing the choice (no brand-specific personas are ever applied silently). The user can refine them anytime via `/update-brand-kit`.

### Step 7 — Confirm + write

Render the fully-resolved brand.json in the conversation. Show before/after when in update mode (use the **old** values from Step 0 vs the **new** values from Steps 1-6).

Ask via `AskUserQuestion`:

```
Write this brand kit?
  - Yes, write brand/brand.json (and logo if changed)
  - Let me edit one more field            ← loops back to the relevant step
  - Cancel — discard all changes
```

On "Yes":
1. Write `<ProductVideos>/brand/brand.json` (UTF-8, no BOM, 2-space indent, sorted keys).
2. If the user picked a new logo in Step 4, the file is already in place (no extra write).
3. If `compositions/<slug>.tsx` files exist that reference brand tokens, no changes needed — they import from `brand.json` so the next render picks up the new values.

On "Let me edit one more field": ask which step to re-run, jump back, continue.

On "Cancel": abort. brand.json + logo.svg unchanged.

### Step 8 — Report

Print:

```
✓ Brand kit updated.
  Name: <name>
  Tagline: "<tagline>"
  Primary: #...     (was: #... [or "(new)"])
  Accent:  #...     (was: ...)
  Ink:     #...     (was: ...)
  Paper:   #...     (was: ...)
  Logo:    brand/logo.svg     (source: <path|URL|generated|kept>)

Next render will use the new tokens. Re-render any in-flight previews to see them applied.
```

## Defaults (neutral starter baseline)

Used when init mode picks "Use neutral starter defaults" or when fields are missing from the existing brand.json in update mode. `name` is **derived from the workspace folder name** (see Step 0) — the value below is only the fallback.

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
  "fonts": { "heading": "Inter", "body": "Inter", "mono": "JetBrainsMono" },
  "logo": { "path": "brand/logo.svg", "minSizePx": 56, "safeAreaPx": 32 },
  "lowerThird": { "barHeightPx": 96, "barOpacity": 0.85, "barColor": "ink", "textColor": "paper" },
  "captionStrip": {
    "fontSizePx": 48, "lineHeightPx": 60, "bgColor": "ink", "bgOpacity": 0.8,
    "textColor": "paper", "paddingPx": 16, "maxWordsPerLine": 7, "maxLines": 2
  },
  "personas": [
    { "key": "end_user", "label": "primary end user of the product", "voice": "warm, plainspoken" },
    { "key": "prospect", "label": "prospective customer evaluating the product", "voice": "curious, value-driven" },
    { "key": "partner", "label": "partner / stakeholder integrated with the product", "voice": "professional, trust-building" }
  ],
  "tone": {
    "default": "warm and credible — confident without hype",
    "banned_words": ["revolutionary", "game-changing", "disrupt", "synergy", "leverage", "10x"],
    "banned_phrases": ["AI-powered", "next-generation", "world-class"],
    "preferred_verbs": ["track", "see", "manage", "grow", "save", "send", "get"]
  }
}
```

## Rules

- **Never overwrite without confirmation in update mode** — Step 7 is the gate. On Cancel, write nothing.
- **In init mode**, the user hasn't seen the file yet, so "current values" are the neutral starter defaults — frame prompts accordingly ("Use neutral starter default" instead of "Keep current").
- **Random palette is deterministic for a given brand name** — hashing the name as seed means re-running with no other input yields the same palette. The user can "Regenerate" to advance the seed.
- **Validate hex codes** — reject anything that doesn't match `^#[0-9A-Fa-f]{3,8}$`. Loop, don't fail.
- **Preserve unmentioned fields** — in update mode, fields the user didn't touch keep their existing values. Don't reset to defaults unless the user picks "Use neutral starter defaults" for the whole palette.
- **The default font stack matters** — `<BrandIntro>` and `<EndCard>` reference `brand.fonts.heading` / `brand.fonts.body`. If the user picks an exotic font that isn't system-installed or bundled in `brand/fonts/`, the render falls back to sans-serif silently — warn them explicitly.
