# Template: app-walkthrough

| Field | Value |
|---|---|
| Target duration | 30–60s (default 45s) |
| Scene count | 6 |
| Tone (default) | energetic, friendly (Rachel) |
| Best for | Multi-screen tour, several features briefly each |

## Scenes

### Scene 1 — HOOK (0.0s → 3.0s, 3.0s)

- **Visual**: `<BrandIntro headline="{{hook_line}}">`. Logo briefly visible top-left.
- **Voiceover** (≤ 30 chars):
  > "{{hook_line}}"
  >
  > _Example: "Your business, finally simple."_
- **Caption**: `"{{hook_line}}"`

### Scene 2 — FEATURE 1 (3.0s → 11.0s, 8.0s)

- **Visual**: `{{asset_feature_1}}` — UI screenshot of feature 1. `<FeatureCallout label="{{feature_1_name}}" />`.
- **Voiceover** (≤ 80 chars):
  > "{{feature_1_pitch}}"
  >
  > _Example: "Track every transaction in seconds — inventory updates as you sell."_
- **Caption**: `"{{feature_1_name}}: {{feature_1_caption}}"`

### Scene 3 — FEATURE 2 (11.0s → 19.0s, 8.0s)

- **Visual**: `{{asset_feature_2}}`. Same callout pattern.
- **Voiceover** (≤ 80 chars):
  > "{{feature_2_pitch}}"
- **Caption**: `"{{feature_2_name}}: {{feature_2_caption}}"`

### Scene 4 — FEATURE 3 (19.0s → 27.0s, 8.0s)

- **Visual**: `{{asset_feature_3}}`. Same callout pattern.
- **Voiceover** (≤ 80 chars):
  > "{{feature_3_pitch}}"
- **Caption**: `"{{feature_3_name}}: {{feature_3_caption}}"`

### Scene 5 — VALUE SUMMARY (27.0s → 38.0s, 11.0s)

- **Visual**: `{{asset_summary}}` — a single hero shot summarising the value. Logo present.
- **Voiceover** (≤ 110 chars):
  > "{{value_summary}}"
  >
  > _Example: "{{product_name}} brings every part of your work into one place."_
- **Caption**: `"{{value_summary_short}}"`

### Scene 6 — CTA (38.0s → 45.0s, 7.0s)

- **Visual**: `<EndCard>` — {{product_name}} logo prominent + tagline + app store badges.
- **Voiceover** (≤ 50 chars, action verb):
  > "{{cta_line}}"
  >
  > _Default: "Get {{product_name}} on iOS and Android today."_
- **Caption**: `"{{cta_line_short}}"`

## Mandatory rules

- Hook in first 3s ✓.
- CTA verb in Scene 6.
- Each feature scene = exactly 8s — no exceptions (keeps total within 45s target).
- Feature scenes use `<FeatureCallout>` to anchor; no abstract talking shots.
- Maximum 3 features for a 45s walkthrough — more and the video sprawls (recommend `feature-demo` instead).

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `hook_line` | ✅ | brief.md (one-line value prop) |
| `feature_1_name`, `feature_1_pitch`, `feature_1_caption` | ✅ | brief.md (feature 1) |
| `feature_2_name`, `feature_2_pitch`, `feature_2_caption` | ✅ | brief.md (feature 2) |
| `feature_3_name`, `feature_3_pitch`, `feature_3_caption` | ✅ | brief.md (feature 3) |
| `value_summary`, `value_summary_short` | ✅ | brief.md (overarching value) |
| `cta_line`, `cta_line_short` | ✅ | brief.md / default |
| `asset_feature_1`, `_2`, `_3` | ✅ | assets/ |
| `asset_summary` | ✅ | assets/ |
