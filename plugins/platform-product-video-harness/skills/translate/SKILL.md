---
name: translate
description: >
  Translate a generated product video into one or more languages — both
  captions (re-rendered as burned-in text via Remotion) and voiceover
  (re-synthesised via ElevenLabs eleven_multilingual_v2). Run after
  /platform-product-video-harness:generate has produced the English
  baseline at projects/<slug>/out/. Outputs land in
  projects/<slug>/translations/<iso-code>/out/{9-16,1-1,16-9}.mp4 — one
  set per language. Target languages declared as a comma-separated list
  of ISO 639 codes (e.g. "yo,ha,ig,pcm" for Yoruba, Hausa, Igbo, Nigerian
  Pidgin). Falls back gracefully for languages ElevenLabs doesn't support
  natively — translates captions, skips voice with a clear warning, and
  produces silent-with-captions output the user can dub externally.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
argument-hint: "<project-folder> <iso-codes>"
user-invocable: true
---

# /platform-product-video-harness:translate

Localise an already-generated product video — captions + voiceover — to one or more languages, in one command.

## Usage

```
/platform-product-video-harness:translate <project-folder> <iso-codes>
```

- `<project-folder>` — path under `<ProductVideos>/projects/`, must contain `script.md` (committed) + `out/{9-16,1-1,16-9}.mp4` from a previous `/generate` run.
- `<iso-codes>` — comma-separated ISO 639 codes for the target languages. Examples:
  - `"yo,ha,ig,pcm"` — Yoruba, Hausa, Igbo, Nigerian Pidgin (a common Nigerian-language set)
  - `"fr,es,pt"` — French, Spanish, Portuguese
  - `"ar"` — single language

Output: `projects/<slug>/translations/<iso>/out/{9-16,1-1,16-9}.mp4` per language.

## Pre-flight

1. Verify `<ProductVideos>/.claude/context/platform-video-context.md` exists. If missing → halt with `"Run /platform-product-video-harness:init-video-workspace first."`
2. Verify `<project-folder>/script.md` exists and `<project-folder>/out/{9-16,1-1,16-9}.mp4` all exist. If any missing → halt with `"Run /platform-product-video-harness:generate <project-folder> first to produce the English baseline."`
3. Verify the source composition exists at `<repo-path>/compositions/<slug>.tsx`. If missing → halt with `"The composition for this project is missing — re-run /generate (Phase 3) to regenerate it."`
4. Verify `<ProductVideos>/.env` contains `ELEVENLABS_API_KEY=…`. If missing → halt with the standardised remediation block from `skills/env-credential-recipes/SKILL.md` (verbatim).
5. Parse `<iso-codes>`. Validate each is a known ISO 639-1 (2-letter), 639-2/3 (3-letter), or BCP-47 code. Reject silently-invalid codes (e.g. `"xx"`) with a one-line message + suggestion. Continue with the valid subset on user confirmation.
6. For each target language, **route to a TTS provider**:
   - `yo` / `ha` / `ig` / `pcm` → 9jaLingo (`skills/9jalingo-voices/SKILL.md`). Verify `NAIJALINGO_API_KEY` is in `<ProductVideos>/.env`. If missing AND one of these four languages is requested, halt with the 9jaLingo remediation block (see Phase T2 below); other languages still proceed.
   - Languages in the ElevenLabs supported set (en + 31 others — see `skills/elevenlabs-voices/SKILL.md` § Multilingual support) → ElevenLabs.
   - Anything else (e.g. `sw` Swahili, `am` Amharic) → `captions-only` fallback (translated captions burned-in; user dubs voice externally).
   Surface the per-language routing up-front so the user knows which provider each language will use.

## The 5-phase per-language pipeline

For each language in `<iso-codes>`, run this sequence. Languages run **sequentially** (Remotion render is CPU-heavy; running 4 languages in parallel fights for resources and ElevenLabs has rate limits).

### Phase T1 — Translate text

Read `<project-folder>/script.md`. Extract per scene:
- `voiceover` line(s)
- `caption` line(s)
- Any on-screen text references (asset filenames or hardcoded strings in the composition)

For each language, prompt Claude (via the main session — no separate agent needed):

> *"Translate the following voiceover and caption lines to <language name> (ISO: <code>). Preserve brand terms verbatim (the brand name, product/feature names, iOS, Android, etc.). Match the brand tone: <tone from script.md header — warm/energetic/calm/authoritative>. Keep captions to ≤ 7 words per line × ≤ 2 lines (per `skills/caption-generation/SKILL.md`). Output as JSON keyed by scene index."*

For Yoruba (yo) / Hausa (ha) / Igbo (ig) / Nigerian Pidgin (pcm):
- These are languages Claude handles directly — no third-party translation API needed.
- For Pidgin: spell out brand words as they're pronounced locally (e.g. the brand name stays as-is; common loan words like "marketplace" stay as-is since the loan word is common). Keep code-switching where natural to spoken Pidgin.
- Surface translated content in conversation so user can spot-check before any disk writes.

Save translations to `<project-folder>/translations/<iso>/translations.json`:

```json
{
  "scene_1": {
    "voiceover": "<translated>",
    "captions": ["<translated line 1>", "<translated line 2>"]
  },
  "scene_2": {
    "voiceover": "<translated>",
    "captions": ["<translated line 1>"]
  }
}
```

Present to user: *"Translations for <language> ready. Spot-check above, then approve to continue with TTS + render."* Via `AskUserQuestion`: `APPROVED` / `EDIT — I'll dictate changes` / `SKIP this language`.

### Phase T2 — Regenerate voiceover (per language, provider-routed)

The harness routes each language to the right TTS provider automatically. **You don't pick the provider** — the workflow picks based on the ISO code.

| Language code | Provider | Reference |
|---|---|---|
| `yo` / `ha` / `ig` / `pcm` | 9jaLingo | `skills/9jalingo-voices/SKILL.md` |
| `en` / `es` / `fr` / `de` / `it` / `pt` / `pl` / `tr` / `ru` / `nl` / `cs` / `ar` / `zh` / `ja` / `hu` / `ko` / `hi` / `sv` / `no` / `fi` / `da` / `uk` / `el` / `id` / `ms` / `ro` / `sk` / `bg` / `hr` / `ta` / `fil` / `vi` | ElevenLabs | `skills/elevenlabs-voices/SKILL.md` |
| Anything else | captions-only fallback | (no provider; user dubs externally) |

#### Provider A — 9jaLingo (for yo / ha / ig / pcm)

1. **Pre-flight**: verify `NAIJALINGO_API_KEY=...` is in `<ProductVideos>/.env` (non-empty). If missing:
   ```text
   ⚠ 9jaLingo API key not found.

   1. Get your API key at https://www.9jalingo.org/dashboard
   2. Add this line to <ProductVideos>/.env:
        NAIJALINGO_API_KEY=nl-your_real_key_here
   3. Re-run /platform-product-video-harness:translate <project> <iso-codes>

   .env is gitignored AND the secrets-guard hook will refuse any attempt
   to commit it. The harness never auto-writes .env — you stay in control.
   ```
   Halt the affected languages (`yo`/`ha`/`ig`/`pcm`) with `Outcome: BLOCKED — missing NAIJALINGO_API_KEY`. **Other languages (ElevenLabs / captions-only) still proceed** — only the Nigerian-language subset is blocked.

2. **Source `.env`** into the subshell:
   ```bash
   set -a; . "<repo-path>/.env"; set +a    # exports NAIJALINGO_API_KEY
   ```

3. **Read the pinned 9jaLingo speaker** from `<repo-path>/.claude/context/platform-video-context.md`. If absent, omit `speaker` from the request (9jaLingo uses its default speaker for the language).

4. **Per scene**, call 9jaLingo TTS via the canonical pattern in `skills/9jalingo-voices/SKILL.md` § API call shape:
   ```bash
   curl -s -X POST "https://api.9jalingo.org/v1/audio/speech" \
     -H "Authorization: Bearer $NAIJALINGO_API_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "text": "<translated voiceover line>",
       "voice": "<iso: yo|ha|ig|pcm>",
       "speaker": "<pinned-speaker-or-omit>",
       "response_format": "mp3",
       "temperature": 0.95,
       "top_p": 0.95,
       "repetition_penalty": 1.1
     }' \
     --output "<project-folder>/translations/<iso>/audio/scene-NN-voice.mp3"
   ```

5. Verify each output is non-empty + non-error: `[ -s "<file>" ] || halt`. Detect JSON-error responses (head -c 2 → `{"`) and surface them.

6. **On 9jaLingo error** (HTTP 401 / 402): halt the affected language with `Outcome: BLOCKED` and the API's error message. Other languages still proceed.
   **On HTTP 429**: back off (5–10s) and retry once. On second failure, downgrade to `captions-only` for this language and warn the user.

7. **Normalise each stem to -16 LUFS** via `ffmpeg loudnorm` (same recipe as the English narrator — see `skills/ffmpeg-recipes/SKILL.md` § Audio normalisation).

#### Provider B — ElevenLabs (for en + the 32 supported languages)

1. Read `<repo-path>/.claude/context/platform-video-context.md` for the pinned `VOICE_ID` (the brand voice from init). For multilingual TTS, that voice ID is used as the *source voice* — ElevenLabs renders it speaking the target language.

2. For each scene with a voiceover line, call ElevenLabs TTS via `curl` per the canonical pattern in `skills/elevenlabs-voices/SKILL.md` § TTS API call shape, with:
   - `model_id`: `eleven_multilingual_v2`
   - `voice_settings`: same pinned settings (stability 0.5, similarity_boost 0.75, style 0.0, use_speaker_boost true)
   - `text`: the translated voiceover line for this scene + this language
   - `--output`: `<project-folder>/translations/<iso>/audio/scene-NN-voice.mp3`

3. Normalise each stem to -16 LUFS.

4. **On ElevenLabs HTTP 401/402**: halt this language with `Outcome: BLOCKED`. **On HTTP 422 `voice_not_found`**: shouldn't happen for languages in the supported list above, but if it does (e.g. ElevenLabs deprecated a language), surface the actual error and downgrade to `captions-only` for that language.

#### Provider fallback — captions-only

For languages **not** in the 9jaLingo or ElevenLabs columns above (e.g. `sw` Swahili, `am` Amharic), skip Phase T2 entirely. Phase T4 muxes the BGM bed only; the user dubs voiceover externally and re-muxes.

### Phase T3 — Re-render compositions with translated captions

For each language, generate a per-language clone of the composition:

1. Read the existing `<repo-path>/compositions/<slug>.tsx`.
2. Write `<repo-path>/compositions/<slug>__<iso>.tsx` — same file, but every `<CaptionStrip text="<English>" />` is replaced with the translated caption from `translations.json`. Use the scene index in the surrounding `<Sequence from={...}>` to map.
3. Update `<repo-path>/compositions/Root.tsx` to register three new compositions per language: `<slug>__<iso>-9-16`, `<slug>__<iso>-1-1`, `<slug>__<iso>-16-9`. Same `durationInFrames`/`fps` as the English baseline; same `width`/`height` per aspect ratio. Re-use the existing `import` if possible (the component name is just `<Slug><Iso>` PascalCased).
4. Render three silent previews per language:
   ```bash
   cd "<repo-path>"
   for ratio in 9-16 1-1 16-9; do
     npx remotion render compositions/Root.tsx <slug>__<iso>-${ratio} \
       "<project-folder>/translations/<iso>/_preview/${ratio}-preview.mp4" \
       --codec=h264 --crf=18 --no-audio --pixel-format=yuv420p
   done
   ```
5. On render failure, surface stderr, retry once with `--log=verbose`, halt the language on second failure with `Outcome: FAILED`. Other languages continue.

### Phase T4 — Mix audio + mux per language

For languages that produced voice in Phase T2 (9jaLingo or ElevenLabs):

1. **Mix voiceover stems + BGM** — re-use the English BGM bed at `<project-folder>/audio/bgm.mp3` (no need to regenerate the ambient sound effects per language). Use the same `voiceover-bgm-mix` recipe from `skills/ffmpeg-recipes/SKILL.md` § voiceover-bgm-mix — only the input voice stems change.
2. **Mux audio + video** per aspect ratio:
   ```bash
   for ratio in 9-16 1-1 16-9; do
     ffmpeg -y \
       -i "<project-folder>/translations/<iso>/_preview/${ratio}-preview.mp4" \
       -i "<project-folder>/translations/<iso>/audio/mixed.mp3" \
       -map 0:v -map 1:a \
       -c:v copy -c:a aac -b:a 192k \
       -shortest -movflags +faststart \
       "<project-folder>/translations/<iso>/out/${ratio}.mp4"
   done
   ```

For languages in `captions-only`:

1. Skip audio mixing. Mux the BGM bed (no voice) into the silent previews:
   ```bash
   for ratio in 9-16 1-1 16-9; do
     ffmpeg -y \
       -i "<project-folder>/translations/<iso>/_preview/${ratio}-preview.mp4" \
       -i "<project-folder>/audio/bgm.mp3" \
       -map 0:v -map 1:a -c:v copy -c:a aac -b:a 128k \
       -shortest -movflags +faststart \
       "<project-folder>/translations/<iso>/out/${ratio}.mp4"
   done
   ```
2. The user records voiceover externally (their own studio / phone) and re-muxes via `ffmpeg -i <captions-only.mp4> -i <user-voice.mp3> ...`.

### Phase T5 — Per-language review (optional but recommended)

Spawn the reviewer agent against the per-language output to run the standard V1-V9 verification. Critical for translations: V8 (animation pacing) is unchanged across languages (visuals are identical except for captions), but V9 (callout alignment) is worth re-running because the translated label text might be much longer or shorter than English and visually misalign with the callout box.

Reviewer call:
```text
Spawn @platform-video-reviewer with:
  - Project folder: <project-folder>
  - Repo path: <repo-path>
  - Script: <project-folder>/script.md (English source for AC + AC-count comparison)
  - Translation: <project-folder>/translations/<iso>/translations.json
  - Outputs: <project-folder>/translations/<iso>/out/{9-16,1-1,16-9}.mp4
  - Composition: <repo-path>/compositions/<slug>__<iso>.tsx
  - Language: <iso>
```

Reviewer treats translation mode as informational (it's already a derivative of an APPROVED English video). No gate. Findings post to conversation.

## Completion report

After all languages finish:

```
✅ Translation complete for project <slug>.

Languages produced:
  ✓ yo (Yoruba)            — 9jaLingo            projects/<slug>/translations/yo/out/{9-16,1-1,16-9}.mp4
  ✓ ha (Hausa)             — 9jaLingo            projects/<slug>/translations/ha/out/...
  ✓ ig (Igbo)              — 9jaLingo            projects/<slug>/translations/ig/out/...
  ✓ pcm (Nigerian Pidgin)  — 9jaLingo            projects/<slug>/translations/pcm/out/...
  ✓ fr (French)            — ElevenLabs          projects/<slug>/translations/fr/out/...
  ⚠ sw (Swahili)           — captions-only       (neither provider supports it; dub audio externally)

ElevenLabs character usage this run: ~<N> chars across <S> scenes × <L> languages.

Next steps:
  - Spot-check each language's output in your video player.
  - For captions-only outputs, dub voiceover externally then re-mux with ffmpeg.
  - Posting to social platforms is manual — open each platform's uploader per language.
```

## Rules

- **English baseline must exist.** The whole workflow assumes `out/{9-16,1-1,16-9}.mp4` already produced by a previous `/generate`. No re-running the 5 generation phases — that's a separate workflow.
- **Languages run sequentially.** Parallel renders fight for CPU; parallel ElevenLabs calls hit rate limits.
- **Voice stays consistent across languages.** Use the same pinned ElevenLabs `VOICE_ID` (from `platform-video-context.md`) for all languages — ElevenLabs's `eleven_multilingual_v2` model speaks the target language with the SAME source voice timbre, which is brand-consistency-correct.
- **Captions are burned-in, not subtitles.** Re-rendering the composition (Phase T3) is mandatory — there's no native subtitle track ride-along on social platforms reliable enough for our use case.
- **Translation is Claude-driven.** No third-party translation API. For Nigerian languages, Claude handles them directly (including Pidgin). If the user disputes a translation, they edit `translations.json` and the workflow can be re-run with `--skip-translate` (future flag).
- **Fail soft per language.** If language X fails Phase T2 (TTS), downgrade to `captions-only` for X and continue. If language X fails Phase T3 (render), halt X and continue with the others. Aggregate failures in the completion report.
- **Idempotent re-runs.** Re-invoking `/translate` against an already-translated language overwrites existing outputs in `translations/<iso>/out/`. Source `translations.json` is preserved if present (edit it manually to refine translations between runs).
