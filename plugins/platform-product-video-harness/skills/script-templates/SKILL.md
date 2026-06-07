---
name: script-templates
description: >
  6 markdown script templates the scriptwriter agent picks from in Phase 2.
  Each template has a scene structure, per-scene target durations, voiceover
  guidelines, and {{variables}} the scriptwriter fills in from the brief +
  analyzer output. Load this skill when picking a template.
disable-model-invocation: true
user-invocable: true
---

# Script Templates (6 ship in v0.1.0)

The scriptwriter agent picks the closest template based on:
1. The analyzer's `suggested_template` field (from `_cache/analysis.json`)
2. Strong signals in `brief.md` (e.g. "testimonial from a farmer" → `testimonial-style`)

If the two disagree, the brief wins.

## Templates

| File | Target duration | Best for |
|---|---|---|
| `problem-solution-cta.md` | 12–25s | Pain → resolution → action. The default for unknown content. |
| `feature-demo.md` | 20–45s | Single feature deep-dive with on-screen UI |
| `before-after.md` | 15–30s | Two-state comparison with clear "wow" transition |
| `testimonial-style.md` | 15–30s | Quote-led, attribution overlay, social proof |
| `app-walkthrough.md` | 30–60s | Multi-screen tour, several features briefly each |
| `launch-announcement.md` | 10–20s | Date + headline + single big visual + CTA. New feature / version announcement. |

## How templates are structured

Each template is a markdown file with:

1. **Front-matter metadata** (target duration, scene count, suggested tone)
2. **Scene-by-scene structure** with `{{variables}}` to fill in
3. **Voiceover guidelines** per scene (word count budget, tone, banned phrases per `brand.tone.banned_words`)
4. **Asset binding hints** (which `assets/` files plug into which scenes)
5. **Mandatory rules** the scriptwriter must enforce (hook ≤ 3s, CTA verb in last scene)

The scriptwriter fills `{{variables}}` from `brief.md` + `analysis.json` + the brand's personas / tone of voice (from brand.json), then writes the result to `<project-folder>/script.md`.

## Variable conventions

| Variable | Source |
|---|---|
| `{{product_name}}` | From `brand.json` (`brand.name`) |
| `{{persona}}` | From `brief.md` or analyzer hint; must match `brand.personas[].key` |
| `{{problem_one_liner}}` | From `brief.md` |
| `{{solution_pitch}}` | From `brief.md` |
| `{{cta_line}}` | From `brief.md` ("CTA" or "call to action" section) — fallback: "Download {{product_name}} on iOS and Android today." |
| `{{feature_name}}` | From `brief.md` |
| `{{asset_<name>}}` | From `<project-folder>/assets/` — scriptwriter matches by filename or asks at GATE #1 if ambiguous |

## Picking a template (decision flow)

```
1. Read analysis.json.summary.suggested_template
2. Read brief.md
3. Does brief explicitly request a specific style? → use that template (override)
4. Does brief contain "testimonial" / "quote" / "customer says"? → testimonial-style
5. Does brief contain "before/after" / "X vs Y" / "transformation"? → before-after
6. Does brief contain "launch" / "announcing" / "new release"? → launch-announcement
7. Does brief mention multiple features in a tour-like list? → app-walkthrough
8. Does brief focus on one feature deep-dive? → feature-demo
9. Else → problem-solution-cta (default)
```

## How to extend (post-v0.1.0)

Add a new `.md` file in this folder. Conform to the existing structure (front-matter + scene blocks + variable list + rules). The scriptwriter auto-discovers templates by `Glob("skills/script-templates/*.md")` excluding `SKILL.md`.
