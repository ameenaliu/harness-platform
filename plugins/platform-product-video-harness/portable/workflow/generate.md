# platform-video-generate — single workflow, 5 phases (+ optional Phase 0), 3 gates

Drive a video project from `assets/` (+ optional `brief.md` and `sample.mp4`) to 3 final MP4s (9:16 + 1:1 + 16:9). Run as the **orchestrator** (see the orchestrator role for full coordination rules).

**Usage**: `<command> <project-folder>` where `<project-folder>` is a path under `<ProductVideos>/projects/`.

```
/platform-product-video-harness:generate projects/2026-05-25_inventory-launch
```

Always read the workspace config (`<ProductVideos>/.claude/context/platform-video-context.md`) and the runtime tracker (`<ProductVideos>/ai/video-runs/<slug>.md`) before acting; resume from recorded state.

## Phase 0 — Brief Drafting (conditional, orchestrator-hosted)

Runs **only** if `<project-folder>/brief.md` does not exist. Skipped otherwise.

The orchestrator (not a subagent) handles Phase 0 inline — it's gathering user input, not transforming pipeline state, so it doesn't need a spawned agent. Sequence:

1. Print a sample `brief.md` so the user knows the target shape.
2. Ask 3 multiple-choice questions in one batch: **Audience** (persona key with custom Other), **Tone** (warm / energetic / authoritative / Other), **CTA** (Download / Open / Sign-up / Other).
3. Ask one free-text question: **Goal — the one thing the viewer should walk away knowing / doing**.
4. Ask one optional question: any extra notes (banned topics, key assets, persona language).
5. Write `<project-folder>/brief.md` from the answers, with the auto-appended banned-phrases reminder on the Tone line.
6. Present the rendered brief + ask `LOOKS GOOD / EDIT IT / START OVER / CANCEL`. Loop on edits.

No GATE number — Step 6 IS the human checkpoint, but `brief.md` is user input, not approved pipeline output. On `CANCEL`, halt the workflow.

After `LOOKS GOOD`, proceed to Phase 1 with the freshly-written `brief.md`.

## Phase 1 — Analyze (silent)

Spawn the **analyzer** to extract frames via ffmpeg (1 fps), read each via Claude vision, infer scene count + pacing + dominant palette + suggested template. Writes `_cache/analysis.json`. No gate. Skip if cached AND `sample.mp4` hash matches.

If `sample.mp4` is absent, analyzer produces a minimal outline from `brief.md` alone.

## Phase 2 — Script — GATE #1

Spawn the **scriptwriter** to pick a template (default: analyzer's suggestion; override on strong brief signal), fill variables from `brief.md` + analysis, draft `script.md` with scene shot list + voiceover + on-screen captions + per-scene durations.

The scriptwriter presents the full draft via `AskUserQuestion`:
- `APPROVED` → proceed to Phase 3
- `NEEDS CHANGES — edits below` → re-draft affected scenes, loop
- `WRONG TEMPLATE — try <other>` → restart at template selection
- `CANCEL` → abort

**Enforces template-side**: hook in first 3s, CTA verb in last scene, duration within ±2s of template target.

## Phase 3 — Build — GATE #2

Spawn the **compositor** to generate `compositions/<slug>.tsx`, wire assets via `staticFile()`, register 3 `<Composition>`s in `Root.tsx` (one per aspect ratio), then run `npx remotion render` × 3 to produce silent preview MP4s in `_preview/`.

Compositor presents preview file paths via `AskUserQuestion`:
- `APPROVED` → proceed to Phase 4
- `NEEDS CHANGES — visual edits` → modify composition, re-render
- `NEEDS CHANGES — script edit` → orchestrator loops back to Phase 2
- `CANCEL` → abort

**Enforces**: brand tokens (no hardcoded hex/fonts), no raw HTML, captions present for every voiceover line, composition ≤ 150 lines.

## Phase 4 — Narrate (silent)

Spawn the **narrator** to:

1. Load `ELEVENLABS_API_KEY` from `<ProductVideos>/.env` via `set -a; . .env; set +a`. If missing → halt with the standardised remediation block from `env-credential-recipes` skill (do NOT auto-write `.env`).
2. Call ElevenLabs TTS per scene with pinned voice ID + `voice_settings` (stability 0.5, similarity 0.75). Save per-scene stems.
3. Normalise each stem to -16 LUFS via `ffmpeg loudnorm`.
4. Call ElevenLabs Sound Effects API once for an ambient bed (~22s); loop + duck to -28 LUFS via ffmpeg.
5. Mix voiceover stems + ducked BGM into one audio track.
6. Mux audio + each silent preview into `out/{9-16,1-1,16-9}.mp4`.

No gate — outputs feed Phase 5 immediately.

## Phase 5 — Review — GATE #3

Spawn the **reviewer** (read-only) to verify each output via `ffprobe` + `ffmpeg loudnorm` + static checks on the composition:

- V1 Aspect ratio (1080×1920 / 1080×1080 / 1920×1080)
- V2 Duration within ±2s of script target
- V3 Audio integrated loudness within -16 ± 2 LUFS
- V4 Captions present for every voiceover line
- V5 No hardcoded hex / fonts in composition
- V6 Hook ≤ 3s + CTA verb in final scene
- V7 File size within platform caps

Reports `INFORMATIONAL` (always); human decides at GATE #3:
- `APPROVED — ship` → workflow ends, outputs ready to post (manually)
- `NEEDS CHANGES — re-narrate` → loop to Phase 4
- `NEEDS CHANGES — re-build` → loop to Phase 3
- `NEEDS CHANGES — re-script` → loop to Phase 2
- `CANCEL` → abort, outputs remain on disk

## Invariants

- Three gates are mandatory; never auto-advance. Phase 0's confirm-loop is not numbered (`brief.md` is user input, not approved pipeline output).
- `.env` is the user's territory; the harness guides them — no agent ever writes it.
- **Phase 0 is the one place the orchestrator writes a file directly** (`brief.md`); every other artefact is the relevant phase agent's job. Phase 0 is skipped when `brief.md` already exists.
- Output is always 3 MP4s (9:16 + 1:1 + 16:9) — never one or two; the compositor must register all three `<Composition>`s.
- Tracker (`ai/video-runs/*.md`) is local runtime state — never committed.
- Final transition (posting to social media) is manual — the harness produces files, not posts.
- Cache discipline: Phase 1 is idempotent (cached against `sample.mp4` hash); other phases re-run on every invocation.
