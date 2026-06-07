---
name: elevenlabs-voices
description: >
  ElevenLabs voice IDs by tone (energetic / calm / authoritative / warm),
  voice_settings presets, Sound Effects API prompt patterns for ambient
  BGM beds, and the TTS / SFX API call shapes. Loaded by the narrator
  agent (Phase 4) and referenced by init-video-workspace during voice selection.
disable-model-invocation: true
user-invocable: true
---

# ElevenLabs voices + Sound Effects (defaults)

## Voice library

These are standard ElevenLabs voices (available on Starter $5/mo+). The narrator pins one voice ID per video for consistency; init-video-workspace captures the default in `<ProductVideos>/.claude/context/platform-video-context.md`.

| Voice name | Voice ID | Tone | Best for | Sample brief style |
|---|---|---|---|---|
| Rachel | `21m00Tcm4TlvDq8ikWAM` | warm, friendly | Default voice; product demos, walkthroughs | "Energetic but approachable" |
| Antoni | `ErXwobaYiN019PkySvjV` | calm, authoritative | Launch announcements, before-after, anything serious | "Confident, broadcast-quality" |
| Bella | `EXAVITQu4vr4xnSDxMAC` | warm, casual | Testimonials, personal stories | "Like a friend explaining" |
| Adam | `pNInz6obpgDQGcFmaJgB` | deep, narrative | Documentary feel, longer-form (60s+) | "Movie-trailer energy" |
| Domi | `AZnzlk1XvdvUeBnXmlld` | bright, energetic | High-energy product launches, app walkthroughs | "Caffeinated demo" |
| Elli | `MF3mGyEYCl7XYWbV9V6O` | youthful, friendly | Targeting younger personas | "Casual conversation" |

**To find more voices**: https://elevenlabs.io/app/voice-library — copy the `voice_id` from the URL.

## voice_settings (pinned for every TTS call)

```json
{
  "stability": 0.5,
  "similarity_boost": 0.75,
  "style": 0.0,
  "use_speaker_boost": true
}
```

- `stability` 0.5 — balanced; lower = more expressive but inconsistent; higher = monotone
- `similarity_boost` 0.75 — strong adherence to the source voice timbre
- `style` 0.0 — disables style exaggeration (more natural)
- `use_speaker_boost` true — improves similarity at slight latency cost

Don't deviate per scene — consistency across a single video matters more than per-line nuance.

## TTS API call shape

```bash
curl -s -X POST \
  "https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: audio/mpeg" \
  -d '{
    "text": "Your voiceover line here.",
    "model_id": "eleven_multilingual_v2",
    "voice_settings": {
      "stability": 0.5,
      "similarity_boost": 0.75,
      "style": 0.0,
      "use_speaker_boost": true
    }
  }' \
  --output scene-01-voice.mp3
```

### Models

- `eleven_multilingual_v2` — default; supports English + 28 other languages; ~70% char usage; **recommended**. Also the model used by `/platform-product-video-harness:translate` for non-English localisation.
- `eleven_turbo_v2_5` — lower latency, slightly lower quality; ~50% char usage; good for high-volume drafts.
- `eleven_monolingual_v1` — legacy; English-only; avoid.

### Multilingual support (used by /translate)

`eleven_multilingual_v2` officially supports these languages — pass the matching ISO 639-1 code to `/platform-product-video-harness:translate`. Languages NOT in the list automatically downgrade to `captions-only` mode (text is translated and re-rendered into the composition; voice is skipped so the user can dub externally).

**Supported** (✅ — full voice-and-captions):
`en` English · `es` Spanish · `fr` French · `de` German · `it` Italian · `pt` Portuguese · `pl` Polish · `tr` Turkish · `ru` Russian · `nl` Dutch · `cs` Czech · `ar` Arabic (RTL — review V8 frames for caption width drift) · `zh` Chinese (Mandarin) · `ja` Japanese · `hu` Hungarian · `ko` Korean · `hi` Hindi · `sv` Swedish · `no` Norwegian · `fi` Finnish · `da` Danish · `uk` Ukrainian · `el` Greek · `id` Indonesian · `ms` Malay · `ro` Romanian · `sk` Slovak · `bg` Bulgarian · `hr` Croatian · `ta` Tamil · `fil` Filipino · `vi` Vietnamese

**Not supported by ElevenLabs** (routed to 9jaLingo instead — see `skills/9jalingo-voices/SKILL.md`):
`yo` Yoruba · `ha` Hausa · `ig` Igbo · `pcm` Nigerian Pidgin (ISO 639-3) — all four covered by 9jaLingo.

**Not supported by either** (falls back to `captions-only` — translated captions burned-in, no voice; user dubs externally):
`sw` Swahili · most other African and minority languages.

### Secondary TTS provider for Nigerian languages

ElevenLabs's `eleven_multilingual_v2` doesn't cover `yo` / `ha` / `ig` / `pcm`. For those four, the `/translate` workflow routes to **[9jaLingo](https://www.9jalingo.org/api-documentation)** — a single Nigerian-language TTS API covering all four with an OpenAI-compatible endpoint shape. See `skills/9jalingo-voices/SKILL.md` for the full API call shape, credential setup (`NAIJALINGO_API_KEY` in `.env`), error handling, and speaker selection.

The provider routing happens automatically inside `/translate` Phase T2 — you don't pick the provider; the workflow picks based on the ISO code. If `NAIJALINGO_API_KEY` isn't set when you pass `yo`/`ha`/`ig`/`pcm` to `/translate`, the workflow halts with a remediation block pointing at https://www.9jalingo.org/dashboard.

### Error handling

ElevenLabs returns 200 with a `audio/mpeg` body on success. On error it returns 4xx/5xx with a JSON body. Detect:

```bash
# After curl --output saves the response, check whether it's JSON (error) or binary (audio)
if head -c 2 scene-01-voice.mp3 | grep -q '{"'; then
  echo "ElevenLabs API error:"
  cat scene-01-voice.mp3
  exit 1
fi
```

Common errors:
- `401` `quota_exceeded` → out of monthly characters; upgrade tier
- `401` `unauthorized` → API key wrong or revoked
- `402` `subscription_blocked` → billing issue
- `429` `too_many_requests` → rate-limited; backoff
- `422` `voice_not_found` → bad voice ID

## Sound Effects API (for BGM ambient beds)

```bash
curl -s -X POST \
  "https://api.elevenlabs.io/v1/sound-generation" \
  -H "xi-api-key: $ELEVENLABS_API_KEY" \
  -H "Content-Type: application/json" \
  -H "Accept: audio/mpeg" \
  -d '{
    "text": "Your sound prompt here",
    "duration_seconds": 22,
    "prompt_influence": 0.3
  }' \
  --output bgm-raw.mp3
```

- `duration_seconds` max 22 (Sound Effects API current cap). The narrator loops this to total video length via ffmpeg.
- `prompt_influence` 0.3 → loose adherence (more musical); 0.7 → tight adherence (more literal SFX).

### BGM prompt patterns by tone

| Tone | Prompt |
|---|---|
| energetic | `"upbeat warm electronic loop, subtle percussion, lo-fi vibe, no melody"` |
| calm | `"ambient pad, gentle warmth, subtle texture, no melody, no drums"` |
| authoritative | `"corporate atmospheric pad, low energy, slow build, no melody"` |
| warm / friendly | `"acoustic guitar fingerpicking loop, warm reverb, soft, no vocals"` |
| dramatic | `"cinematic pad with subtle rising tension, low strings, no percussion"` |
| celebratory | `"gentle uplifting chord progression, warm pad, light percussion, no melody"` |

**Always include `"no melody"` or `"no vocals"`** — the bed must sit under the voiceover without competing.

## Character usage estimate

Voiceover: ~75 words per 30s of video = ~450 chars (with spaces).

- 30s video → ~450 chars × ~1 (TTS overhead) = **~450 chars** per video
- Starter tier (30k chars/mo) → **~60 videos / month**
- Free tier (10k chars/mo) → **~20 videos / month**, but commercial-use prohibited

The narrator agent's status block reports the approx char usage so the user can track quota.

## When the user wants to clone a brand voice

Requires Creator tier ($22/mo). Out of scope for v0.1.0. To prep:

1. Upgrade to Creator at https://elevenlabs.io/app/subscription
2. Record 1+ minute of clean audio of the target person (CEO, marketing lead) — quiet room, single take, no music
3. Upload via Voice Lab → Add Voice → Instant Voice Cloning
4. Copy the generated `voice_id`
5. Update `<ProductVideos>/.claude/context/platform-video-context.md` `Default voice ID` field
6. All subsequent renders use the brand voice
