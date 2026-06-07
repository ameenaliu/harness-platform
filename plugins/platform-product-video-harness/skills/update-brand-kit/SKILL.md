---
name: update-brand-kit
description: >
  Update the brand kit (colors, logo, tagline, fonts, personas, tone) of
  the ProductVideos repo any time after init. Reads the current brand/brand.json,
  walks the user through what they want to change, writes the result back.
  Compositions and the next render automatically pick up the new tokens
  because they import from brand.json. Use whenever the brand evolves —
  new logo, refreshed palette, refined tone of voice, persona changes.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
argument-hint: "(no arguments — interactive)"
user-invocable: true
---

# /platform-product-video-harness:update-brand-kit

Update the brand kit for the ProductVideos repo. Interactive — no arguments.

## Usage

```
/platform-product-video-harness:update-brand-kit
```

You'll be walked through 6 question batches:

1. **Brand name** — keep current or change
2. **Tagline** — keep current or change
3. **Color palette** — keep current / neutral starter defaults / generate random / provide your own hex codes
4. **Logo** — keep current / local path / URL / generate text placeholder
5. **Fonts** — keep current / customise heading + body + mono
6. **Personas + tone** — keep current / edit personas / edit tone of voice / both

After Step 6 you see the rendered before/after of `brand.json` and confirm before anything is written.

Cancel anytime — the existing `brand/brand.json` + `brand/logo.svg` are not touched until you confirm at the final gate.

## Pre-flight

1. Verify `<ProductVideos>/.claude/context/platform-video-context.md` exists. If missing → halt with `"Run /platform-product-video-harness:init-video-workspace first."`
2. Verify `<ProductVideos>/brand/brand.json` exists. If missing (somehow), suggest re-running `init-video-workspace`.

## What this skill does

Delegates the entire collection + write flow to the `brand-collection` skill in **update mode**. See `skills/brand-collection/SKILL.md` for the canonical 8-step protocol — same one used by `init-video-workspace` Step 4.5.

The only practical differences in update mode vs init mode:

- All prompts show the **current** value as the first option (`Keep current: ...`).
- Step 6 (personas + tone) is **offered** instead of skipped — this is the main reason `/update-brand-kit` exists separately, since first-time init avoids the friction of persona editing.
- Step 7's confirmation shows a **before/after diff** of the brand.json, so you can see exactly what's changing before approving.
- On Cancel, the existing files are left untouched (init mode's Cancel aborts the whole workspace setup).

## Output

- `<ProductVideos>/brand/brand.json` — updated in place
- `<ProductVideos>/brand/logo.svg` — replaced only if you picked a new logo

## When the new brand is visible

Compositions import from `brand.json` (`import { brand } from '../brand/brand.json'`), so the **next render** picks up the new tokens. In-flight previews from a `/generate` invocation are not retroactively re-rendered — re-run `/generate` for any project you want updated to use the new brand.

For per-video composition files (`compositions/<slug>.tsx`) that hardcoded a brand token at write time (rare — the compositor enforces the import pattern), grep `compositions/*.tsx` for old hex values and either regenerate via `/generate` or hand-edit.

## Output (after Step 7 confirm)

```
✓ Brand kit updated.
  Name: <name>
  Tagline: "<tagline>"
  Primary: #...     (was: #...)
  Accent:  #...     (was: #...)
  Ink:     #...     (was: #...)
  Paper:   #...     (was: #...)
  Logo:    brand/logo.svg     (source: <path|URL|generated|kept>)

Next render will use the new tokens.
```

## Rules

- **No silent changes** — every field the user changes must be re-shown in the Step 7 before/after diff. The user controls when the file is written.
- **No partial writes** — Step 7's confirm writes everything at once. Cancel aborts cleanly without touching the disk.
- **Random palette is deterministic per brand name** — regenerating with the same name yields the same palette unless the user picks "Regenerate" to advance the seed.
- **Fonts are user responsibility** — if you pick a font that isn't system-installed or bundled in `brand/fonts/`, the render falls back silently. The protocol warns you but doesn't block.
