# Template: problem-solution-cta

| Field | Value |
|---|---|
| Target duration | 12–25s (default 18s) |
| Scene count | 4 |
| Tone (default) | warm, plainspoken (default brand voice — Rachel or similar) |
| Best for | Default for unknown content. Pain → resolution → action. |

## Scenes

### Scene 1 — HOOK (0.0s → 2.5s, 2.5s)

- **Purpose**: hook
- **Visual**: `{{asset_problem_state}}` (e.g., empty inventory, stack of receipts, confused face). Use full-bleed. Subtle vignette via `<BrandIntro overlay="dark">`.
- **Voiceover** (≤ 30 chars):
  > "{{problem_one_liner}}"
  >
  > _Examples: "Lost track of your inventory?" / "Tired of paper receipts?" / "Sales feel like guesswork?"_
- **On-screen caption** (CaptionStrip, max 7 words):
  > "{{problem_one_liner_short}}"

### Scene 2 — PROBLEM (2.5s → 7.0s, 4.5s)

- **Purpose**: problem
- **Visual**: 2–3 quick cuts of the friction. Use `<Sequence>` children with `from` offsets for the cuts. Assets: `{{asset_friction_1}}`, `{{asset_friction_2}}`, optional `{{asset_friction_3}}`.
- **Voiceover** (≤ 55 chars):
  > "{{problem_detail}}"
  >
  > _Example: "Manual tracking is slow, error-prone, and easy to forget."_
- **On-screen caption**:
  > "{{problem_detail_short}}"

### Scene 3 — SOLUTION (7.0s → 14.0s, 7.0s)

- **Purpose**: solution
- **Visual**: `{{asset_solution_screen}}` — the product feature in action. UI close-up via `<FeatureCallout>` with annotated highlights. Add a subtle accent border using `brand.colors.accent`.
- **Voiceover** (≤ 85 chars):
  > "{{solution_pitch}}"
  >
  > _Example: "{{product_name}} tracks every transaction, syncs across devices, and gives you live insights."_
- **On-screen caption**:
  > "{{solution_pitch_short}}"

### Scene 4 — CTA (14.0s → 18.0s, 4.0s)

- **Purpose**: cta
- **Visual**: `<EndCard>` — {{product_name}} logo + tagline + app store badges (`assets/badges/ios.svg`, `assets/badges/android.svg` from brand kit).
- **Voiceover** (≤ 50 chars, MUST contain action verb):
  > "{{cta_line}}"
  >
  > _Default: "Download {{product_name}} on iOS and Android today."_
- **On-screen caption**:
  > "{{cta_line_short}}"

## Mandatory rules (scriptwriter enforces)

- **Hook in first 3s**: Scene 1 must finish by 2.5s (within the 3s limit per `agents/shared/video-production-principles.md`).
- **CTA verb**: Scene 4 voiceover MUST contain one of: `download`, `try`, `get`, `visit`, `learn`, `sign up`, `start`. Default `cta_line` already satisfies.
- **No banned words**: scriptwriter rejects any voiceover containing `brand.tone.banned_words`.
- **Persona**: pick from `brand.personas[].key`; never generic "user" / "customer".
- **Caption length**: each `CaptionStrip` ≤ 7 words / line, ≤ 2 lines.

## Variables checklist

| Variable | Required | Source |
|---|---|---|
| `problem_one_liner` | ✅ | brief.md (problem statement) |
| `problem_one_liner_short` | ✅ | Scriptwriter shortens for caption (≤ 7 words) |
| `problem_detail` | ✅ | brief.md |
| `problem_detail_short` | ✅ | Scriptwriter shortens |
| `solution_pitch` | ✅ | brief.md (solution / value prop) |
| `solution_pitch_short` | ✅ | Scriptwriter shortens |
| `cta_line` | optional | brief.md (CTA section); default: "Download {{product_name}} on iOS and Android today." |
| `cta_line_short` | ✅ | Scriptwriter shortens |
| `asset_problem_state` | ✅ | assets/ folder; scriptwriter matches by filename or asks |
| `asset_friction_1`, `_2`, `_3` | ≥2 | assets/ folder |
| `asset_solution_screen` | ✅ | assets/ folder |
