import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig } from 'remotion';
import { brand } from '../brand/brand.json';
import { SafeArea } from './_components/SafeArea';
import { BrandIntro } from './_components/BrandIntro';
import { CaptionStrip } from './_components/CaptionStrip';

// Renderable smoke-test composition that init-video-workspace ships. Verifies the
// pipeline (brand tokens load, components render across all 3 aspect ratios,
// Remotion CLI is wired). Compositor will REPLACE this file in Phase 3 per video.
export const ExampleHello: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const fadeIn = spring({ frame, fps, config: { damping: 200 } });

  return (
    <AbsoluteFill style={{ backgroundColor: brand.colors.ink, opacity: interpolate(fadeIn, [0, 1], [0, 1]) }}>
      <SafeArea>
        <BrandIntro headline={brand.name} />
        <CaptionStrip text={brand.tagline} />
      </SafeArea>
    </AbsoluteFill>
  );
};
