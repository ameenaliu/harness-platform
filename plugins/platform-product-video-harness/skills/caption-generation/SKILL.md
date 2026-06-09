---
name: caption-generation
description: >
  How the scriptwriter derives burned-in captions from voiceover lines,
  syncs them to scene frame ranges, and respects per-platform caption
  constraints. Captions are mandatory for every voiceover line — Reels
  / Feed / LinkedIn / Shorts all default to muted playback.
disable-model-invocation: true
user-invocable: true
---

# Caption generation (Phase 2 — scriptwriter, Phase 3 — compositor)

## Why captions are mandatory

- All major short-form platforms (Instagram Reels + Feed, TikTok, YouTube Shorts, LinkedIn, Twitter/X) default to **muted playback**.
- Auto-captions exist on some platforms but are not reliable for brand-critical text and not guaranteed on all.
- Accessibility (WCAG 1.2.2): pre-recorded video with audio MUST have synchronised captions.

The reviewer (Phase 5 / V4) rejects any output where a voiceover line lacks a matching `<CaptionStrip>` in the composition.

## Caption derivation rules (scriptwriter does this in Phase 2)

For each voiceover line in `script.md`:

1. **Strip filler words**: "you know", "basically", "actually", "just" — they read fine in voiceover but pad caption length.
2. **Drop articles when natural**: "the", "a", "an" if removing keeps meaning ("Tap the button" → "Tap button" is fine in a caption context).
3. **Shorten** to fit `brand.captionStrip.maxWordsPerLine` (7 words per line) × `brand.captionStrip.maxLines` (2 lines) = **14 words max** per caption.
4. **Preserve key brand terms** unchanged: the brand name (`brand.name`), product/feature names, persona labels.

Example transformations:

| Voiceover (longer) | Caption (shorter) |
|---|---|
| "<Brand> tracks every transaction, syncs across devices, and gives you live insights." | "Track, sync, see insights — live." |
| "I used to spend hours every Sunday reconciling my sales." | "Sundays used to mean hours of reconciling." |
| "Download <Brand> on iOS and Android today." | "Get <Brand> on iOS + Android" |

If the original voiceover already fits in ≤ 14 words, use it verbatim.

## Caption sync (frame-level)

In the composition, the `<CaptionStrip>` lives inside the same `<Sequence>` as its scene. It automatically appears for the full scene's duration. No per-word timing — captions are scene-level, not karaoke-style.

```tsx
<Sequence from={90} durationInFrames={240}>   {/* Scene 2: 3.0s → 11.0s */}
  <FeatureCallout label="Tap to log" />
  <CaptionStrip text="Tap to log a transaction" />
</Sequence>
```

The caption appears at frame 90 and disappears at frame 330 (3.0s → 11.0s) — synced to the voiceover by construction.

## Multi-line captions

When a caption needs 2 lines (12–14 words), the scriptwriter splits at natural break points:

| Single string | Split into 2 lines |
|---|---|
| "Track every transaction in seconds — inventory updates as you sell" | "Track every transaction in seconds —" / "inventory updates as you sell" |

The `<CaptionStrip>` component handles line-wrapping automatically; the scriptwriter just provides the raw string. But for cleaner line breaks, the scriptwriter can hint with `\n`:

```markdown
- **On-screen caption**:
  > "Track every transaction in seconds —\ninventory updates as you sell"
```

## Caption positioning per aspect ratio

The `<CaptionStrip>` component reads `useVideoConfig()` and positions itself per-aspect-ratio:

| Aspect | Position from bottom |
|---|---|
| 9:16 | 380px from bottom (above platform UI overlays) |
| 1:1 | 180px from bottom |
| 16:9 | 130px from bottom |

These are tuned to avoid Reels/TikTok/LinkedIn UI overlay zones. No need to override per video.

## Caption styling

Inherited from `brand.captionStrip`:

- Font: `brand.fonts.body` (Inter, weight 600 for legibility on busy backgrounds)
- Font size: 48px (scales proportionally for 16:9 — bumps to 56px)
- Background: `brand.colors.ink` at 80% opacity (subtle box for contrast)
- Text color: `brand.colors.paper`
- Padding: 16px around text

## Reviewer enforcement (Phase 5 / V4)

The reviewer:

1. Parses `script.md` for voiceover lines (counts them per scene).
2. Parses `compositions/<slug>.tsx` for `<CaptionStrip` occurrences (counts them per `<Sequence>`).
3. For each `<Sequence>` containing a voiceover line, verify a matching `<CaptionStrip>` exists in the same `<Sequence>`.
4. Missing → `[V4-CRITICAL] Scene N has voiceover "..." but no <CaptionStrip>`.

## Edge cases

- **Voiceover-less scene** (e.g. a logo stinger or pure visual beat) — no caption needed. Scriptwriter notes "voiceover: (none)" in `script.md`; compositor omits the `<CaptionStrip>`.
- **Multiple short voiceover lines in one scene** — combine into one caption that summarises both, OR use two `<CaptionStrip>` with `<Sequence>` sub-children offset by the line gap (rare; only when lines are >2s apart).
- **Non-English voiceover** — captions in the same language as the voiceover. v0.1.0 is English-only.
