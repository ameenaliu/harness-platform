# ProductVideos

This product's Remotion project for generating social-media product videos. Scaffolded by `platform-product-video-harness` `/init-video-workspace`.

## Generate a video

```bash
mkdir projects/$(date +%Y-%m-%d)_my-video
# Drop: brief.md + assets/*.png (and optional sample.mp4) into that folder
```

Then in Claude Code (or Codex), with `platform-product-video-harness` installed:

```
/platform-product-video-harness:generate projects/$(date +%Y-%m-%d)_my-video
```

The harness walks 5 phases (Analyze → Script → Build → Narrate → Review) with 3 human gates. Final output: 3 MP4s in `projects/<slug>/out/` (9:16, 1:1, 16:9).

## Manual / standalone Remotion commands

```bash
# Open Remotion Studio (local preview UI):
npx remotion studio

# Render a single composition manually:
npx remotion render compositions/Root.tsx <composition-id> out/manual.mp4 --codec=h264 --crf=18

# Lint compositions:
npx remotion lint
```

## Credentials

ElevenLabs API key goes in `.env` (gitignored, NEVER auto-written):

```bash
# Copy the template
cp .env.example .env

# Edit .env in your text editor and replace the placeholder value
# ELEVENLABS_API_KEY=sk_your_real_key_here
```

Get a key at https://elevenlabs.io/app/settings/api-keys. Starter tier ($5/mo) required for commercial use — posting to social media counts.

## Layout

- `brand/` — single source of truth for colors, fonts, logo
- `compositions/` — Remotion `.tsx` (committed); `_components/` reusable library
- `projects/<YYYY-MM-DD>_<slug>/` — one folder per video
  - Committed: `brief.md`, `assets/`, `script.md` (after Phase 2)
  - Gitignored: `_cache/`, `_preview/`, `audio/`, `out/`
- `ai/video-runs/` — gitignored runtime trackers per video

## See also

- Plugin README: `platform-product-video-harness/README.md` (in the `harness-platform` marketplace: `ameenaliu/harness-platform`)
- `AGENTS.md` (this repo) — cross-tool rules
- Brand kit canonical: `brand/brand.json`
