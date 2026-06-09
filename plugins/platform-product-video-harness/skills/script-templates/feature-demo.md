# Template: feature-demo

| Field | Value |
|---|---|
| Target duration | 20–45s (default 30s) |
| Scene count | 5 |
| Tone (default) | confident, instructional (Antoni or Rachel) |
| Best for | Single feature deep-dive with on-screen UI close-ups |

## Scenes

### Scene 1 — HOOK (0.0s → 3.0s, 3.0s)

- **Purpose**: hook
- **Visual**: `{{asset_feature_hero}}` — the feature's most striking screen, full-bleed. Optional gentle Ken-Burns zoom via `interpolate`.
- **Voiceover** (≤ 35 chars):
  > "Meet {{feature_name}}."
  >
  > _Example: "Meet your product."_
- **Caption**:
  > "Meet {{feature_name}}"

### Scene 2 — CONTEXT (3.0s → 8.0s, 5.0s)

- **Purpose**: problem (light)
- **Visual**: a single context-setting shot — `{{asset_context}}` — showing where the feature fits. Lower-third overlay with the persona name: `<LowerThird name="{{persona_label}}" />`.
- **Voiceover** (≤ 60 chars):
  > "For every {{persona_label}}, {{context_pain}}."
  >
  > _Example: "For every small business owner, tracking what's in your business is a daily headache."_
- **Caption**: `"{{persona_label}}: {{context_pain_short}}"`

### Scene 3 — DEMO BEAT 1 (8.0s → 16.0s, 8.0s)

- **Purpose**: feature
- **Visual**: `{{asset_demo_1}}` — the first user-action close-up. Annotate with `<FeatureCallout label="{{demo_1_action}}">` arrow pointing at the relevant UI element.
- **Voiceover** (≤ 95 chars):
  > "{{demo_1_voiceover}}"
  >
  > _Example: "Tap any item to log a new entry — quantity, date, notes — done in seconds."_
- **Caption**: `"{{demo_1_caption}}"`

### Scene 4 — DEMO BEAT 2 (16.0s → 24.0s, 8.0s)

- **Purpose**: feature
- **Visual**: `{{asset_demo_2}}` — the second user-action close-up (the "wow" moment). `<FeatureCallout>` highlight.
- **Voiceover** (≤ 95 chars):
  > "{{demo_2_voiceover}}"
  >
  > _Example: "Live totals update across every device in your business — no manual sync needed."_
- **Caption**: `"{{demo_2_caption}}"`

### Scene 5 — CTA (24.0s → 30.0s, 6.0s)

- **Purpose**: cta
- **Visual**: `<EndCard>` with {{product_name}} logo + feature name reinforced + app store badges.
- **Voiceover** (≤ 50 chars, MUST contain action verb):
  > "{{cta_line}}"
  >
  > _Default: "Try {{feature_name}} on {{product_name}} — get it now."_
- **Caption**: `"{{cta_line_short}}"`

## Mandatory rules

- Hook in first 3s ✓ (Scene 1 ends at 3.0s exactly).
- CTA verb in Scene 5.
- Demo beats (Scenes 3 + 4) use `<FeatureCallout>` to anchor the eye — no abstract talking-head shots.
- No banned words.

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `feature_name` | ✅ | brief.md (which feature this demos) |
| `persona_label` | ✅ | brand.personas[].label matching the persona key |
| `context_pain` | ✅ | brief.md (one-sentence pain context) |
| `context_pain_short` | ✅ | scriptwriter shortens |
| `demo_1_action`, `demo_1_voiceover`, `demo_1_caption` | ✅ | brief.md (first key interaction) |
| `demo_2_action`, `demo_2_voiceover`, `demo_2_caption` | ✅ | brief.md (second key interaction) |
| `cta_line`, `cta_line_short` | ✅ | brief.md / default |
| `asset_feature_hero` | ✅ | assets/ |
| `asset_context` | ✅ | assets/ |
| `asset_demo_1`, `asset_demo_2` | ✅ | assets/ |
