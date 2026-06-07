---
name: remotion-conventions
description: >
  Remotion composition conventions for platform-product-video-harness — how
  to structure a per-video .tsx, when to use AbsoluteFill vs Sequence vs
  Series, useCurrentFrame patterns, staticFile() for assets, registering
  one Composition per aspect ratio in Root.tsx. Loaded by the compositor
  agent during Phase 3.
disable-model-invocation: true
user-invocable: true
---

# Remotion Conventions

How the compositor agent writes Remotion `.tsx` for product videos.

## Required reads

1. **`agents/shared/video-production-principles.md`** (in this plugin) — brand tokens, captions, audio levels, hook timing, CTA placement, composition decomposition, no-raw-HTML rule.
2. **`<ProductVideos>/brand/brand.json`** — single source of truth for colors, fonts, logo.
3. **Remotion docs** at https://www.remotion.dev/docs/ (only when you need a specific API; do not bulk-read).

## Composition structure

Per-video composition file: `<ProductVideos>/compositions/<slug>.tsx`. Keep ≤ 150 lines; extract anything reusable to `_components/`.

```tsx
import { AbsoluteFill, Sequence, useCurrentFrame, useVideoConfig } from 'remotion';
import { brand } from '../brand/brand.json';
import { SafeArea } from './_components/SafeArea';
import { BrandIntro } from './_components/BrandIntro';
import { FeatureCallout } from './_components/FeatureCallout';
import { CaptionStrip } from './_components/CaptionStrip';
import { EndCard } from './_components/EndCard';

export const InventoryLaunch: React.FC = () => {
  return (
    <AbsoluteFill style={{ backgroundColor: brand.colors.ink }}>
      <SafeArea>
        {/* Scene 1 — Hook (frames 0-90 = 0-3s at 30fps) */}
        <Sequence from={0} durationInFrames={90}>
          <BrandIntro headline="Inventory just got smarter." />
          <CaptionStrip text="Inventory just got smarter" />
        </Sequence>

        {/* Scene 2 — Problem ... */}
        {/* ... */}

        {/* Scene N — CTA */}
        <Sequence from={810} durationInFrames={90}>
          <EndCard cta={`Download ${brand.name} on iOS and Android today.`} />
          <CaptionStrip text={`Get ${brand.name} — link in bio`} />
        </Sequence>
      </SafeArea>
    </AbsoluteFill>
  );
};
```

## Primitives reference

| Primitive | When to use |
|---|---|
| `<AbsoluteFill>` | Root container of any composition; absolutely-positioned full-screen layer |
| `<Sequence from={n} durationInFrames={d}>` | Time-gate a portion of children (a scene); children render only during this frame range |
| `<Series>` + `<Series.Sequence>` | Sequential scenes that can't overlap (alternative to `<Sequence>` for strict chains) |
| `<Img src={staticFile('<slug>/asset.png')}>` | Static asset reference; **never** use raw `<img>` |
| `<Video src={staticFile('<slug>/clip.mp4')}>` | Embedded video clip |
| `<Audio src={staticFile('<slug>/audio.mp3')}>` | Audio track (rare — narrator mixes audio post-render) |
| `useCurrentFrame()` | Current frame for animation calculations |
| `useVideoConfig()` | `{ width, height, fps, durationInFrames }` for the active composition |
| `interpolate(frame, [in, out], [from, to], { extrapolateRight: 'clamp' })` | Frame-driven animation |
| `spring({ frame, fps, config })` | Physics-based animation |

## Aspect-ratio handling

The compositor registers **three** `<Composition>`s per video in `Root.tsx`, all pointing at the same React component, with different `width` + `height`:

```tsx
// compositions/Root.tsx
import { Composition } from 'remotion';
import { InventoryLaunch } from './inventory-launch';

export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="inventory-launch-9-16"
      component={InventoryLaunch}
      durationInFrames={900}    // total scene frames; here 30s @ 30fps
      fps={30}
      width={1080}
      height={1920}
    />
    <Composition
      id="inventory-launch-1-1"
      component={InventoryLaunch}
      durationInFrames={900}
      fps={30}
      width={1080}
      height={1080}
    />
    <Composition
      id="inventory-launch-16-9"
      component={InventoryLaunch}
      durationInFrames={900}
      fps={30}
      width={1920}
      height={1080}
    />
  </>
);
```

The shared `<SafeArea>` component reads `useVideoConfig()` to apply per-aspect-ratio safe-zone padding (see `agents/shared/video-production-principles.md → Aspect-ratio safe zones`).

## Asset loading

Source assets live in `<ProductVideos>/projects/<slug>/assets/`. Remotion's `staticFile()` reads from `<ProductVideos>/public/`, so the compositor **copies** assets:

```bash
mkdir -p "<repo>/public/<slug>"
cp "<repo>/projects/<slug>/assets/"* "<repo>/public/<slug>/"
```

Then in the composition:

```tsx
import { staticFile, Img } from 'remotion';

<Img src={staticFile('inventory-launch/empty-state.png')} />
```

`public/` is **gitignored** — it's a render-time artefact.

## Naming conventions

| Thing | Pattern |
|---|---|
| Per-video composition file | `compositions/<kebab-slug>.tsx` (matches the project folder slug) |
| Composition `id` | `<slug>-<aspect>` (e.g. `inventory-launch-9-16`) |
| Reusable component | `compositions/_components/<PascalCase>.tsx` (export named, not default) |
| Component prop interfaces | `<ComponentName>Props` (e.g. `BrandIntroProps`) |

## What to AVOID

- Hardcoded hex (`#06B6D4`) — use `brand.colors.primary`
- Hardcoded font names (`'Inter'`) — use `brand.fonts.heading`
- Raw `<div>` / `<img>` / `<button>` / `<span>` — use Remotion primitives or `_components/`
- Inline styles spanning >5 lines — extract into a shared `style.ts` or a component
- `position: absolute` outside `<AbsoluteFill>` context — let Remotion handle layering
- One giant composition file — extract to `_components/` at 150 lines

## See also

- `skills/remotion-component-library/SKILL.md` — usage examples for the shipped `_components/`
- `skills/aspect-ratio-rendering/SKILL.md` — multi-aspect rendering patterns
- `skills/brand-kit/SKILL.md` — brand.json structure
- `agents/shared/video-production-principles.md` — blocking rules
