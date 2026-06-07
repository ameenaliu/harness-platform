---
name: social-platform-specs
description: >
  Per-platform video specs for social-media output — aspect
  ratio, dimensions, duration caps, file-size caps, captions requirement,
  codec/format. Used by the compositor (sets Composition width/height +
  duration), narrator (per-platform audio constraints), and reviewer
  (validates outputs against caps).
disable-model-invocation: true
user-invocable: true
---

# Social Platform Specs (v0.1.0)

The plugin renders 3 MP4s per video — one per aspect ratio. Each maps to multiple platforms:

| Output | Aspect | Dimensions | Platforms |
|---|---|---|---|
| `9-16.mp4` | 9:16 | 1080 × 1920 | Instagram Reels, TikTok, YouTube Shorts, Facebook Reels |
| `1-1.mp4` | 1:1 | 1080 × 1080 | Instagram Feed, Facebook Feed, LinkedIn (feed post) |
| `16-9.mp4` | 16:9 | 1920 × 1080 | YouTube (long-form), LinkedIn (native video), Twitter/X |

## Per-platform constraints (v0.1.0 target)

### Instagram Reels (9:16)

| Spec | Value |
|---|---|
| Aspect | 9:16 |
| Dimensions | 1080 × 1920 (recommended) |
| Duration | 15–90 seconds (default target: 30s) |
| File size cap | 100 MB |
| Codec | H.264 |
| Container | MP4 |
| Frame rate | 30 fps |
| Audio | AAC, stereo, 192 kbps |
| Captions | **Burned in** (no automatic captions guarantee on muted playback) |
| Safe area | Central 1080 × 1350 — top 220px (caption bar) + bottom 350px (UI overlay) often obscured |

### Instagram Feed (1:1)

| Spec | Value |
|---|---|
| Aspect | 1:1 |
| Dimensions | 1080 × 1080 |
| Duration | 3–60 seconds (default target: 30s) |
| File size cap | 100 MB |
| Codec | H.264, MP4 |
| Frame rate | 30 fps |
| Audio | AAC, stereo |
| Captions | Burned in (feed often plays muted) |
| Safe area | Full frame |

### TikTok (9:16)

| Spec | Value |
|---|---|
| Aspect | 9:16 |
| Dimensions | 1080 × 1920 |
| Duration | 15 seconds – 10 minutes (default target: 30s for product videos) |
| File size cap | 287 MB |
| Codec | H.264, MP4 |
| Frame rate | 30 or 60 fps (we use 30) |
| Audio | AAC |
| Captions | Burned in (TikTok auto-captions exist but can't be relied on for brand consistency) |
| Safe area | Central 1080 × 1500 — bottom 420px obscured by UI (username, description, sound, share/like buttons) |

### YouTube Shorts (9:16)

| Spec | Value |
|---|---|
| Aspect | 9:16 |
| Dimensions | 1080 × 1920 |
| Duration | ≤ 60 seconds (hard cap for Shorts) |
| File size cap | 256 MB |
| Codec | H.264, MP4 |
| Frame rate | 30 fps |
| Audio | AAC |
| Captions | Burned in (auto-captions only on rendered upload) |

### YouTube long-form (16:9)

| Spec | Value |
|---|---|
| Aspect | 16:9 |
| Dimensions | 1920 × 1080 (HD) |
| Duration | 60 seconds – ~12 hours (default target: 60–180s for product videos) |
| File size cap | 256 GB (effectively unlimited) |
| Codec | H.264, MP4 |
| Frame rate | 30 fps |
| Audio | AAC, stereo, 384 kbps recommended |
| Captions | Optional (YouTube auto-captions reliable for English) |

### LinkedIn (16:9 + 1:1)

| Spec | Value |
|---|---|
| Aspect | 16:9 (native video) or 1:1 (feed) |
| Dimensions | 1920 × 1080 or 1080 × 1080 |
| Duration | 3 seconds – 10 minutes (default target: 30–60s) |
| File size cap | 200 MB |
| Codec | H.264, MP4 |
| Frame rate | 30 fps |
| Audio | AAC |
| Captions | Burned in (feed plays muted by default) |

## Defaults the compositor uses

| Setting | Value | Why |
|---|---|---|
| Frame rate | 30 fps | Universal compatibility; reasonable file size |
| Video codec | H.264 (libx264) | Universal platform support |
| Video bitrate | CRF 18 (constant quality) | High quality without bloat; ~5–10MB per 30s @ 1080p |
| Audio codec | AAC | Universal platform support |
| Audio bitrate | 192 kbps | Plenty for speech + light BGM |
| Container | MP4 | Universal |
| Pixel format | yuv420p | Required by older platforms (X, some embeds) |
| `+faststart` | yes | Web playback starts immediately (vs after full download) |

## Caption rules

All 3 output aspect ratios get burned-in captions via the `<CaptionStrip>` component. This is mandatory because:

- All platforms (especially Instagram + LinkedIn + Twitter/X) play feed videos muted by default.
- Auto-captions are not reliable for brand-critical text and not guaranteed on all platforms.
- Accessibility (WCAG 1.2.2): pre-recorded video with audio MUST have synchronised captions.

Caption placement per aspect ratio (handled by `<CaptionStrip>` component, reading `useVideoConfig()`):

| Aspect | Caption position |
|---|---|
| 9:16 | Bottom 25% (above UI overlay) |
| 1:1 | Bottom 20% |
| 16:9 | Bottom 18% |

## What the reviewer enforces (Phase 5 / V7)

For each output MP4:

```bash
SIZE_BYTES=$(stat -c %s "<file>" 2>/dev/null || stat -f %z "<file>")
SIZE_MB=$((SIZE_BYTES / 1024 / 1024))
```

Caps used by reviewer (lowest of all platforms targeting that aspect ratio):

- `9-16.mp4`: 100 MB cap (Instagram Reels limit, the tightest of the 9:16 platforms)
- `1-1.mp4`: 100 MB cap (Instagram Feed)
- `16-9.mp4`: 200 MB cap (LinkedIn — tighter than YouTube's effective unlimited)

Over → `[V7-WARNING]` finding (not blocking — reviewer suggests re-encode at lower CRF if user wants to fit).
