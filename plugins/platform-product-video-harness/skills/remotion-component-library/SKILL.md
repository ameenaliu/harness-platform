---
name: remotion-component-library
description: >
  Catalogue + usage examples for the 7 reusable Remotion components that
  ship inside <ProductVideos>/compositions/_components/. Used by the
  compositor agent when building per-video compositions in Phase 3.
disable-model-invocation: true
user-invocable: true
---

# Remotion Component Library (ships in `<ProductVideos>/compositions/_components/`)

7 reusable components shipped by `/init-video-workspace`. Each reads `brand.json` for tokens.

| Component | Purpose | Composition placement |
|---|---|---|
| `<SafeArea>` | Adapts to active composition's aspect ratio; insets children by safe-zone padding | Wrap everything inside `<AbsoluteFill>` |
| `<BrandIntro>` | Logo + headline overlay for Scene 1 hooks | First `<Sequence>` of a composition |
| `<LogoStinger>` | Brief logo flash (30 frames default) — branded intro punctuation | First 30 frames of a `<Sequence>` |
| `<FeatureCallout>` | Annotated highlight over an asset (arrow + label) | Inside demo / feature scenes |
| `<LowerThird>` | Bottom bar with name + role (testimonials, attributions) | Bottom 12% of frame, persistent during a scene |
| `<CaptionStrip>` | Burned-in voiceover caption, auto-positioned by aspect ratio | Every scene with voiceover (mandatory) |
| `<EndCard>` | Logo + CTA + app store badges for the final scene | Last `<Sequence>` |

## Component-by-component

### `<SafeArea>`

Reads `useVideoConfig()` to determine the active aspect ratio, then applies per-aspect-ratio safe-zone padding (per `agents/shared/video-production-principles.md → Aspect-ratio safe zones`).

```tsx
<AbsoluteFill style={{ backgroundColor: brand.colors.ink }}>
  <SafeArea>
    {/* all scene content */}
  </SafeArea>
</AbsoluteFill>
```

Internally:
```tsx
const { width, height } = useVideoConfig();
const isPortrait = height > width;
const isSquare = width === height;
const insetTop = isPortrait ? 220 : (isSquare ? 60 : 50);
const insetBottom = isPortrait ? 350 : (isSquare ? 60 : 50);
const insetX = isSquare ? 60 : (isPortrait ? 30 : 150);
```

### `<BrandIntro>`

```tsx
<BrandIntro
  headline="Inventory just got smarter."
  overlay="dark"                    // 'dark' | 'light' | 'none' (background gradient)
/>
```

Renders the brand logo top-left + large headline center, with optional gradient overlay. Animates in via `spring`.

### `<LogoStinger>`

```tsx
<LogoStinger durationInFrames={30} />
```

1-second (at 30fps) full-screen logo flash. Use as the first child of a `<Sequence from={0}>` to brand the opening.

### `<FeatureCallout>`

```tsx
<FeatureCallout
  label="Tap to log a transaction"
  targetPosition={{ x: 540, y: 800 }}   // pixel coordinates of the UI element being pointed at
  variant="arrow"                        // 'arrow' | 'pulse' | 'box'
/>
```

Renders an annotation pointing at a specific UI element. Animates in synchronously with the parent `<Sequence>`'s frame range.

### `<LowerThird>`

```tsx
<LowerThird
  name="Bola Adeyemi"
  role="Smallholder farmer · Lagos"
/>
```

Bottom 96px (per `brand.lowerThird.barHeightPx`) bar with name (bold) + role (light). Used in testimonial-style. Persistent for the entire `<Sequence>` it lives in.

### `<CaptionStrip>` (mandatory for every voiceover line)

```tsx
<CaptionStrip text="Tap to log a transaction" />
```

Bottom-positioned (per aspect ratio — see `social-platform-specs`) caption. Auto-wraps at `brand.captionStrip.maxWordsPerLine` (7) per line, max `brand.captionStrip.maxLines` (2) lines. Background `brand.colors.ink` at `brand.captionStrip.bgOpacity` (0.8) for legibility on any background.

**Place inside every `<Sequence>` that has voiceover.** Reviewer rejects compositions where voiceover lines lack a matching `<CaptionStrip>`.

### `<EndCard>`

```tsx
<EndCard
  cta={`Download ${brand.name} on iOS and Android today.`}
  showStoreBadges={true}
/>
```

Renders the brand logo (large, centered), tagline (`brand.tagline`), CTA line, and optional iOS/Android download badges (loaded from `brand/badges/`). Used as the final scene's primary visual.

## Adding a new component

To add a component:

1. Create `<ProductVideos>/compositions/_components/<PascalCase>.tsx`.
2. Export named (`export const NewComponent = ...`) — not default.
3. Read brand tokens via `import { brand } from '../../brand/brand.json'` (not from any hardcoded constant).
4. Read aspect ratio via `useVideoConfig()` if behaviour differs per ratio.
5. Animate via `spring()` or `interpolate()` from `useCurrentFrame()`.
6. Update this skill's table + add a usage example.

## Anti-patterns (compositor refuses)

- Importing from a path outside `_components/` for shared UI (defeats the library)
- Hardcoded colors / fonts (use `brand`)
- Class components (use functional + hooks)
- Inline styles spanning >5 lines (extract to a `styles` object or a sub-component)
- Components without a `Props` interface
