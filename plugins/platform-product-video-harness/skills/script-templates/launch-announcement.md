# Template: launch-announcement

| Field | Value |
|---|---|
| Target duration | 10–20s (default 15s) |
| Scene count | 3 |
| Tone (default) | confident, celebratory (Antoni or Rachel) |
| Best for | New feature / version launch; date + headline + single big visual + CTA |

## Scenes

### Scene 1 — HEADLINE / HERO (0.0s → 4.0s, 4.0s)

- **Visual**: `{{asset_hero}}` full-bleed (the new feature's hero shot, or a stylised launch graphic). `<LogoStinger duration={30} />` (1s logo flash at start). Background uses `brand.colors.ink` with a subtle `brand.colors.accent` light flare.
- **Voiceover** (≤ 45 chars):
  > "{{headline}}"
  >
  > _Example: "Introducing {{product_name}} {{feature_name}} v2."_
- **Caption** (large, hero typography — not the standard CaptionStrip; use `<BrandIntro headline>`):
  > "{{headline_short}}"

### Scene 2 — VALUE (4.0s → 11.0s, 7.0s)

- **Visual**: `{{asset_value}}` — UI close-up or demo loop showing the launch's main value. `<FeatureCallout label="{{key_change}}" />`.
- **Voiceover** (≤ 80 chars):
  > "{{value_line}}"
  >
  > _Example: "Live sync across every device, with offline support and audit trail."_
- **Caption**: `"{{value_line_short}}"`

### Scene 3 — DATE + CTA (11.0s → 15.0s, 4.0s)

- **Visual**: `<EndCard>` — {{product_name}} logo + the launch date overlaid prominently + app store badges (if app feature) or "Available now in {{product_name}}" pill.
- **Voiceover** (≤ 50 chars, action verb):
  > "{{cta_line}} {{launch_date_natural}}"
  >
  > _Example: "Get it today on iOS and Android." / "Available now — open {{product_name}} to try it."_
- **Caption**: `"{{launch_date_natural}} — {{cta_line_short}}"`

## Mandatory rules

- Hook in first 3s ✓ (Scene 1 starts immediately with the headline + visual).
- CTA verb in Scene 3.
- `headline_short` ≤ 5 words (otherwise it won't fit the hero typography at this duration).
- `launch_date_natural` is human-readable ("today" / "this week" / "May 30") — never a raw ISO date.
- If `launch_date_natural` is in the future, scriptwriter flags as `[PO]` open question: "Confirm this video will be cut + posted before {{launch_date_natural}}."

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `headline` | ✅ | brief.md (the announcement) |
| `headline_short` | ✅ | scriptwriter shortens; ≤ 5 words |
| `key_change` | ✅ | brief.md (what's new in this launch) |
| `value_line`, `value_line_short` | ✅ | brief.md (value of the launch) |
| `launch_date_natural` | ✅ | brief.md (human-readable date) |
| `cta_line`, `cta_line_short` | ✅ | brief.md / default |
| `asset_hero` | ✅ | assets/ (launch hero visual) |
| `asset_value` | ✅ | assets/ (UI / demo close-up) |
