# Template: testimonial-style

| Field | Value |
|---|---|
| Target duration | 15–30s (default 22s) |
| Scene count | 4 |
| Tone (default) | warm, authentic (Bella or Rachel) |
| Best for | Quote-led; attribution overlay; social proof |

## Scenes

### Scene 1 — HOOK / SUBJECT INTRO (0.0s → 3.0s, 3.0s)

- **Visual**: `{{asset_subject_portrait}}` — photo or B-roll of the testimonial subject (the {{persona_label}}). Subtle vignette + slight zoom (Ken-Burns).
- **Voiceover** (≤ 35 chars):
  > "{{subject_short_intro}}"
  >
  > _Example: "Meet Bola." (or "Sade, small business owner.")_
- **Caption**: `"{{subject_name}}, {{subject_role}}"`

### Scene 2 — QUOTE PART 1 (3.0s → 11.0s, 8.0s)

- **Visual**: `{{asset_subject_context}}` — B-roll of the subject's business / work. `<LowerThird name="{{subject_name}}" role="{{subject_role}}" />` overlay.
- **Voiceover** (≤ 90 chars; the subject's actual quote, condensed):
  > "{{quote_part_1}}"
  >
  > _Example: "I used to spend hours every Sunday reconciling my sales."_
- **Caption**: `"{{quote_part_1}}"` (rendered as quote marks)

### Scene 3 — QUOTE PART 2 (11.0s → 18.0s, 7.0s)

- **Visual**: cut to `{{asset_outcome}}` — the result the subject is talking about (the product UI / outcome screen).
- **Voiceover** (≤ 80 chars; the subject's "after" line):
  > "{{quote_part_2}}"
  >
  > _Example: "Now I see my numbers in seconds. I trust them. That changes everything."_
- **Caption**: `"{{quote_part_2}}"` (continuation of quote)

### Scene 4 — CTA (18.0s → 22.0s, 4.0s)

- **Visual**: `<EndCard>` with {{product_name}} logo + tagline (`brand.tagline`) + small `{{subject_name}}` attribution.
- **Voiceover** (≤ 50 chars, action verb):
  > "{{cta_line}}"
  >
  > _Default: "Join thousands more — get {{product_name}} today."_
- **Caption**: `"{{cta_line_short}}"`

## Mandatory rules

- Hook in first 3s ✓.
- CTA verb in Scene 4.
- The subject MUST be a real person whose attribution is OK to publish — scriptwriter flags via `[PO]` open question if `subject_name` isn't in the brief.
- Quote MUST sound like spoken language (contractions OK, no marketing-speak).
- No banned words.

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `subject_name` | ✅ | brief.md (the testifier) |
| `subject_short_intro` | ✅ | scriptwriter drafts; ≤ 35 chars |
| `subject_role` | ✅ | brief.md (business owner / partner / etc.) |
| `persona_label` | ✅ | brand.personas matching subject_role |
| `quote_part_1`, `quote_part_2` | ✅ | brief.md (the actual quote, split into 2 parts) |
| `cta_line`, `cta_line_short` | ✅ | brief.md / default |
| `asset_subject_portrait` | ✅ | assets/ (subject photo / B-roll) |
| `asset_subject_context` | ✅ | assets/ (subject's environment) |
| `asset_outcome` | ✅ | assets/ (the product UI showing the outcome) |
