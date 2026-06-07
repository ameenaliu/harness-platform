---
name: 9jalingo-voices
description: >
  9jaLingo TTS API — the secondary voice provider, used by
  /platform-product-video-harness:translate for Yoruba (yo), Hausa (ha),
  Igbo (ig), and Nigerian Pidgin (pcm). Covers all four launch-set
  languages with a single OpenAI-compatible endpoint. Credentials live
  in <ProductVideos>/.env as NAIJALINGO_API_KEY. ElevenLabs handles
  English + 28 other languages; 9jaLingo handles the four Nigerian
  languages; anything else falls back to captions-only.
disable-model-invocation: true
user-invocable: true
---

# 9jaLingo TTS — Nigerian-language voice for `/translate`

9jaLingo is the secondary TTS provider wired into the product-video harness. It handles the four Nigerian languages that ElevenLabs's `eleven_multilingual_v2` doesn't natively support: Yoruba, Hausa, Igbo, and Nigerian Pidgin.

Official docs: https://www.9jalingo.org/api-documentation

## When the harness uses 9jaLingo

Inside `/platform-product-video-harness:translate`, Phase T2 routes per language:

| Language code | Provider | This skill |
|---|---|---|
| `yo` Yoruba | 9jaLingo | ← here |
| `ha` Hausa | 9jaLingo | ← here |
| `ig` Igbo | 9jaLingo | ← here |
| `pcm` Nigerian Pidgin | 9jaLingo | ← here |
| `en` + the 32 ElevenLabs-supported languages | ElevenLabs | `skills/elevenlabs-voices/SKILL.md` |
| Anything else | captions-only fallback | (user dubs externally) |

The narrator agent (Phase 4 of `/generate`) uses ElevenLabs exclusively because the English baseline is always generated first. 9jaLingo only enters at `/translate` time for the four Nigerian languages above.

## Credential

`NAIJALINGO_API_KEY=nl-...` in `<ProductVideos>/.env`. Get a key at https://www.9jalingo.org/dashboard.

Setup follows the standard harness `.env` rules — see `skills/env-credential-recipes/SKILL.md`. The harness never writes `.env` directly; the user maintains it in their text editor. Both `secrets-guard.sh` (blocks `nl-` pattern in any source-file content) and `pii-pattern-guard.sh` (blocks the same in prompt input) protect the key.

## API call shape

```bash
set -a; . "<ProductVideos>/.env"; set +a    # sources NAIJALINGO_API_KEY into the subshell

curl -s -X POST "https://api.9jalingo.org/v1/audio/speech" \
  -H "Authorization: Bearer $NAIJALINGO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Bawo ni, e ku aaro o!",
    "voice": "yo",
    "speaker": "adaeze_ig",
    "response_format": "mp3",
    "temperature": 0.95,
    "top_p": 0.95,
    "repetition_penalty": 1.1
  }' \
  --output scene-01-voice.mp3
```

### Fields

| Field | Required | Description |
|---|---|---|
| `text` | ✅ | The translated voiceover line for this scene |
| `voice` | ✅ | Language code — exactly one of `yo`, `ha`, `ig`, `pcm` |
| `speaker` | optional | Speaker ID (e.g. `adaeze_ig`). Omit to use the default speaker for the language. |
| `response_format` | optional | `wav` (default), `mp3`, `flac`, `aac`, `alac`, `ogg`, `pcm`. The harness always uses `mp3` for consistency with ElevenLabs outputs. |
| `temperature` | optional | 0.0–1.5, default 0.95. Pin to 0.95 for brand-consistent voice across scenes within a single video. |
| `top_p` | optional | 0.0–1.0, default 0.95. Same — pin to 0.95. |
| `repetition_penalty` | optional | 1.0–1.5, default 1.1. Pin to 1.1. |
| `model_name` | optional | Model ID. As of 2026-05, the active model is `9jalingo-tts-1` — omit to use the API default, or pin to `9jalingo-tts-1` for explicit reproducibility. |

### Pinned voice_settings (mirror ElevenLabs's per-scene-consistency rule)

For a given video render, use the SAME `voice`, `speaker`, `temperature`, `top_p`, and `repetition_penalty` across all scenes — same constraint the ElevenLabs narrator follows (stability 0.5 + similarity 0.75) so brand voice stays consistent.

## Speaker selection

The user picks a default speaker per language at `init-video-workspace` time and the choice is recorded in `<ProductVideos>/.claude/context/platform-video-context.md` alongside the ElevenLabs voice ID. `/translate` reads it from there.

If no default is set, the workflow falls back to omitting `speaker` (9jaLingo picks its default for the language) and surfaces a warning.

Browse available speakers at https://www.9jalingo.org/dashboard once you have an account. Speaker IDs follow the `<name>_<lang>` convention (e.g. `adaeze_ig` for an Igbo speaker named Adaeze).

## Error handling

9jaLingo returns 200 with an `audio/<format>` body on success. On error it returns 4xx/5xx with a JSON body. Detect via the same trick used for ElevenLabs:

```bash
# After curl --output saves the response, check if it's JSON (error) or binary (audio)
if head -c 2 scene-01-voice.mp3 | grep -q '{"'; then
  echo "9jaLingo API error:"
  cat scene-01-voice.mp3
  exit 1
fi
```

Common errors:
- `401` `unauthorized` → API key wrong, revoked, or `Authorization: Bearer nl-...` malformed
- `402` `subscription_blocked` → billing issue / out of credits
- `429` `too_many_requests` → rate-limited; back off
- `422` `voice_not_found` → bad `voice` value (must be exactly `yo` / `ha` / `ig` / `pcm`)
- `422` `speaker_not_found` → bad `speaker` ID

On `401` / `402` halt with `Outcome: BLOCKED` and the API's error message — never silently retry on auth/billing errors. On `429` back off + retry once. On other 4xx surface to the user; the translation can fall back to `captions-only` for that language if the user opts in.

## Pricing (sign in to see current rates)

9jaLingo doesn't publish per-character pricing on the public API docs page — visit https://www.9jalingo.org/dashboard after signing up to see your tier. Plan accordingly: for a 30-second video the per-language character cost is ~450 chars (matches the ElevenLabs estimate in `skills/elevenlabs-voices/SKILL.md`).

## When 9jaLingo isn't available

If `NAIJALINGO_API_KEY` is missing OR the API returns a hard error (`401`/`402`), the `/translate` workflow downgrades to `captions-only` mode for the affected Nigerian languages — same fallback ElevenLabs-unsupported languages get. The translated captions are still burned into the re-rendered composition; voice is skipped so the user dubs externally.

If you intentionally don't want 9jaLingo (e.g. you prefer to dub Nigerian languages in a studio), don't set `NAIJALINGO_API_KEY` and the workflow will go straight to `captions-only` for `yo`/`ha`/`ig`/`pcm` without trying the API. No error.

## Why 9jaLingo specifically

The user picked 9jaLingo as the sole Nigerian-language provider after reviewing the alternatives (NKENNEAi, Spitch, YarnGPT, Intron Sahara, Abena AI, Meta MMS). Reasons:

- **Single provider for all four launch-set languages** (`yo`, `ha`, `ig`, `pcm`) — no need to mix providers per language.
- **Documented REST API** with curl examples + OpenAI-compatible endpoint shape — minimal integration work.
- **Same `.env`-credential + bash-source pattern** the harness already uses for ElevenLabs — no new architectural concept.
- **Nigerian-built** for Nigerian-language quality.

Other providers may make sense later (e.g. open-source Meta MMS for cost reduction at scale, or NKENNEAi for cross-validation), but only 9jaLingo is wired into the harness in v0.4.0.
