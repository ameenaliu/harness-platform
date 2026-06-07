---
name: frame-analysis-patterns
description: >
  The per-frame checklist the analyzer agent walks when reading sample
  video frames via Claude vision. Covers what to observe (composition,
  palette, motion, on-screen text, UI vs hero), how to batch frames for
  efficient context use, and how to synthesise per-frame notes into
  scene groupings.
disable-model-invocation: true
user-invocable: true
---

# Frame analysis patterns (analyzer Phase 1)

## The per-frame checklist

For each PNG frame the analyzer `Read`s (Claude vision), capture observations across these dimensions:

### 1. Composition

- **Subject placement**: central / rule-of-thirds-left / rule-of-thirds-right / full-bleed
- **Depth**: hero close-up / mid-shot / wide / overhead
- **Negative space**: heavy / balanced / minimal

### 2. Palette

- **Dominant colors** (top 2–3, approximated to nearest hex)
- **Saturation**: muted / balanced / vibrant
- **Brightness**: dark / mid / light
- **Brand-matching**: does the palette align with `brand.colors`?

### 3. Motion (inferred from blur / between-frame deltas)

- **Motion blur present**: yes / no
- **Camera movement**: static / pan / zoom / handheld
- **Subject movement**: still / motion / interaction (e.g., hand tap)

### 4. On-screen text

- **Text present**: yes / no
- **Text type if present**: title / subtitle / UI label / caption / watermark
- **Approximate text**: capture if short (≤ 8 words)

### 5. UI vs Hero

- **Frame type**: UI close-up (app screenshot) / hero shot (product / person in environment) / B-roll (atmospheric) / title card / end card

### 6. Transitions (compared to previous frame)

- **Continues prev scene**: yes / no
- **Transition type**: hard cut / dissolve / fade / wipe / morph (estimate from one frame; uncertain is OK)

## Batching protocol

To keep Claude's context manageable while reading dozens of frames:

- **Batch size**: 4–8 frames per `Read` sequence (4 if frames are large >500KB; 8 if smaller).
- **Per batch**: Read all N frames in succession (separate `Read` tool calls), then summarise the batch into the JSON output BEFORE moving to the next batch.
- **Don't re-read** a frame you've already analyzed — once is enough.

```text
Batch 1: Read frame-001.png, frame-002.png, frame-003.png, frame-004.png
         → emit summary of frames 1-4 to scratch
Batch 2: Read frame-005.png, frame-006.png, frame-007.png, frame-008.png
         → emit summary of frames 5-8 to scratch
...
Final: synthesise all batches into scenes (group adjacent similar frames)
```

## Synthesising frames into scenes

After all batches, group adjacent frames into scenes:

- **Same scene**: similar composition + similar palette + same subject + no hard cut between adjacent frames
- **New scene**: hard cut detected, OR major palette shift (>40% change in dominant color), OR new subject

Cap at 10 scenes per analysis — if you detect more, merge the most similar adjacent pair until ≤ 10.

For each scene, record:
- Scene index
- Start second (= first frame index × `1 / fps_extracted`)
- End second (= last frame index × `1 / fps_extracted`)
- Dominant composition + palette + UI/Hero/B-roll classification
- Notes (1–2 sentences summarising the scene's purpose)

## Inferring pacing

From the scene timings:

- **Fast pacing**: average scene duration < 3s
- **Medium pacing**: 3–6s
- **Slow pacing**: > 6s

Fast pacing suggests a high-energy template (e.g., `before-after`, `launch-announcement`); slow pacing suggests `feature-demo` or `testimonial-style`.

## Suggested template heuristic

| Detected shape | Suggested template |
|---|---|
| 1–2 scenes, all hero shots, slow pace | `launch-announcement` |
| 3–4 scenes, problem → solution → CTA arc | `problem-solution-cta` |
| 4 scenes, hard cut between scene 2 and 3 (visual contrast) | `before-after` |
| 4 scenes, one prominent face/portrait | `testimonial-style` |
| 5+ scenes, mostly UI close-ups | `app-walkthrough` |
| Single-feature focus, UI dwell shots | `feature-demo` |

When uncertain → default to `feature-demo`.

## Confidence levels

Report `suggested_template_confidence` in `analysis.json` as `low | medium | high`:

- `high` — clear shape match, ≥ 6 frames analyzed, no ambiguity
- `medium` — partial match or short sample (<6 frames)
- `low` — very short sample (≤ 3 frames) or contradictory signals — scriptwriter should probably ask the human

## No-sample case

If the analyzer is invoked with no `sample.mp4`:

- Skip frame extraction + vision reading
- Read `brief.md`
- Infer template from textual cues (see scriptwriter's "decision flow" in `script-templates/SKILL.md`)
- Set `confidence: low` and `source: null` in `analysis.json`
- Generate a placeholder 5-scene outline for the scriptwriter to populate
