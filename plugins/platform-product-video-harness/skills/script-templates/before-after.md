# Template: before-after

| Field | Value |
|---|---|
| Target duration | 15–30s (default 22s) |
| Scene count | 4 |
| Tone (default) | dramatic but credible (Antoni) |
| Best for | Two-state comparison with a clear "wow" transition |

## Scenes

### Scene 1 — HOOK / "BEFORE" SETUP (0.0s → 3.0s, 3.0s)

- **Visual**: `{{asset_before}}` full-bleed. Slight desaturation filter to communicate "old way".
- **Voiceover** (≤ 35 chars):
  > "Before {{product_name}}:"
- **Caption**: `"Before {{product_name}}"`

### Scene 2 — "BEFORE" DETAIL (3.0s → 9.0s, 6.0s)

- **Visual**: 2–3 quick cuts of the friction (`{{asset_before_friction_1}}`, `_2`, optional `_3`). Hold each ~2s.
- **Voiceover** (≤ 75 chars):
  > "{{before_pain}}"
  >
  > _Example: "Hours lost to manual ledgers, missing receipts, guesswork on profits."_
- **Caption**: `"{{before_pain_short}}"`

### Scene 3 — "AFTER" REVEAL (9.0s → 17.0s, 8.0s)

- **Visual**: hard-cut from Scene 2 to `{{asset_after}}` (full-bleed, full color, slight accent border using `brand.colors.accent`). The transition is the emotional payoff.
- **Voiceover** (≤ 90 chars):
  > "After {{product_name}}: {{after_outcome}}"
  >
  > _Example: "After {{product_name}}: every transaction logged in seconds, profits visible at a glance."_
- **Caption**: `"After {{product_name}}"` (first 2s) then `"{{after_outcome_short}}"` (last 6s)

### Scene 4 — CTA (17.0s → 22.0s, 5.0s)

- **Visual**: `<EndCard>` with {{product_name}} logo + tagline + app store badges.
- **Voiceover** (≤ 50 chars, action verb):
  > "{{cta_line}}"
  >
  > _Default: "Get {{product_name}} on iOS and Android today."_
- **Caption**: `"{{cta_line_short}}"`

## Mandatory rules

- Hook in first 3s ✓ (Scene 1 = 3.0s).
- CTA verb in Scene 4.
- The "BEFORE → AFTER" hard cut is the key beat — no slow dissolves; instant transition for impact.
- "AFTER" reveal MUST show the actual product UI / outcome, not an abstract metaphor.

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `before_pain` | ✅ | brief.md (the "before" state) |
| `before_pain_short` | ✅ | scriptwriter shortens |
| `after_outcome` | ✅ | brief.md (the "after" state) |
| `after_outcome_short` | ✅ | scriptwriter shortens |
| `cta_line`, `cta_line_short` | ✅ | brief.md / default |
| `asset_before`, `asset_before_friction_1`, `_2` | ✅ | assets/ |
| `asset_after` | ✅ | assets/ |
