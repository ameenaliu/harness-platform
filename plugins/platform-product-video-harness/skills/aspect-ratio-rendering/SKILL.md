---
name: aspect-ratio-rendering
description: >
  How to render the same Remotion composition into 9:16, 1:1, and 16:9
  in one render pass. The compositor registers 3 <Composition>s per
  video — same React component, different width/height — and a shared
  <SafeArea> + scene components adapt to the active aspect ratio at
  render time via useVideoConfig().
disable-model-invocation: true
user-invocable: true
---

# Aspect-ratio rendering (3 outputs from one composition)

## The architecture

```
                  ┌──────────────────────────────────────┐
                  │  Per-video composition .tsx          │
                  │  (one React component)               │
                  │   - reads useVideoConfig()           │
                  │   - same Sequences, Scenes, Captions │
                  └────────────────┬─────────────────────┘
                                   │
                  ┌────────────────┼─────────────────────┐
                  │                │                     │
                  ▼                ▼                     ▼
       <Composition                <Composition         <Composition
        id="...-9-16"               id="...-1-1"          id="...-16-9"
        width={1080}                width={1080}          width={1920}
        height={1920}               height={1080}         height={1080}>
       />                          />                    />
```

One component, three `<Composition>` registrations, three render calls. Each render reads its `width`/`height` via `useVideoConfig()` so shared components (`<SafeArea>`, `<CaptionStrip>`, `<LowerThird>`) can adapt per-aspect-ratio without per-video conditional logic.

## Registering in `Root.tsx`

```tsx
import { Composition } from 'remotion';
import { ProductLaunch } from './product-launch';

const DURATION_FRAMES = 900;   // 30s @ 30fps; from script.md
const FPS = 30;

export const RemotionRoot: React.FC = () => (
  <>
    {/* ... other compositions ... */}

    <Composition
      id="product-launch-9-16"
      component={ProductLaunch}
      durationInFrames={DURATION_FRAMES}
      fps={FPS}
      width={1080}
      height={1920}
    />
    <Composition
      id="product-launch-1-1"
      component={ProductLaunch}
      durationInFrames={DURATION_FRAMES}
      fps={FPS}
      width={1080}
      height={1080}
    />
    <Composition
      id="product-launch-16-9"
      component={ProductLaunch}
      durationInFrames={DURATION_FRAMES}
      fps={FPS}
      width={1920}
      height={1080}
    />
  </>
);
```

ID convention: `<slug>-<aspect>` where aspect is one of `9-16`, `1-1`, `16-9`.

## Rendering all three (compositor Phase 3)

```bash
cd <ProductVideos>

npx remotion render compositions/Root.tsx <slug>-9-16  \
  projects/<slug>/_preview/9-16-preview.mp4  \
  --codec=h264 --crf=18 --no-audio --pixel-format=yuv420p

npx remotion render compositions/Root.tsx <slug>-1-1   \
  projects/<slug>/_preview/1-1-preview.mp4   \
  --codec=h264 --crf=18 --no-audio --pixel-format=yuv420p

npx remotion render compositions/Root.tsx <slug>-16-9  \
  projects/<slug>/_preview/16-9-preview.mp4  \
  --codec=h264 --crf=18 --no-audio --pixel-format=yuv420p
```

Serial, not parallel — `--concurrency=N` (default in `remotion.config.ts`) governs parallelism *within* a render. Running 3 renders simultaneously fights for CPU and produces slower wall-clock time on most laptops.

## Per-aspect-ratio adaptation in shared components

Components inside `compositions/_components/` use `useVideoConfig()` to branch per aspect ratio:

```tsx
import { useVideoConfig } from 'remotion';

export const SafeArea: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const { width, height } = useVideoConfig();
  const isPortrait = height > width;
  const isSquare = width === height;

  // Per-aspect safe-zone insets
  const insetTop = isPortrait ? 220 : (isSquare ? 60 : 50);
  const insetBottom = isPortrait ? 350 : (isSquare ? 60 : 50);
  const insetX = isPortrait ? 30 : (isSquare ? 60 : 150);

  return (
    <AbsoluteFill style={{
      paddingTop: insetTop,
      paddingBottom: insetBottom,
      paddingLeft: insetX,
      paddingRight: insetX,
    }}>
      {children}
    </AbsoluteFill>
  );
};
```

Same pattern in `<CaptionStrip>` (bottom-position offset varies per aspect), `<LowerThird>` (bar width adjusts), `<LogoStinger>` (logo size adjusts).

## When per-aspect-ratio designs need to diverge

99% of the time, the same composition works for all 3 aspect ratios — the shared components handle adaptation. For the rare cases where a scene's layout must change drastically (e.g., a 3-column grid that only fits in 16:9):

```tsx
const { width, height } = useVideoConfig();
const isHorizontal = width > height && width / height > 1.5;

return (
  <Sequence from={...} durationInFrames={...}>
    {isHorizontal ? <ThreeColumnGrid /> : <SingleColumnStack />}
  </Sequence>
);
```

This is allowed but should be the exception, not the default — divergent layouts double the design surface and make per-aspect-ratio testing harder.

## Per-aspect-ratio durations

Don't vary duration per aspect ratio. All 3 outputs render to the same `durationInFrames` so they tell the same story at the same length. Platform-specific length variants (e.g., a 60s YouTube cut + a 30s Reels cut) are a separate video project (separate `projects/<slug-60s>` and `projects/<slug-30s>` folders).

## Verification (reviewer Phase 5)

The reviewer verifies dimensions per output:

```bash
ffprobe -v error -select_streams v -show_entries stream=width,height \
  -of csv=s=x:p=0 projects/<slug>/out/9-16.mp4
# Expected: 1080x1920
```

Mismatch → `[V1-CRITICAL] Wrong aspect ratio`.

## Render time expectations

On a modern laptop (M2 / Ryzen 5800X / i7-11800H):

- 30s @ 1080p, single aspect ratio, default concurrency → ~60–90 seconds
- 3 aspect ratios serial → ~3–5 minutes
- 60s @ 1080p, 3 aspect ratios → ~6–9 minutes

If renders are >10 min, check `remotion.config.ts` for `Config.setConcurrency(N)` — default is `os.cpus().length / 2`; bump to `os.cpus().length` on dedicated rendering boxes.
