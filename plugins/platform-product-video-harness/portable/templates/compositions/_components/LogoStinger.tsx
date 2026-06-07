import { AbsoluteFill, useCurrentFrame, interpolate, spring, useVideoConfig, Img, staticFile } from 'remotion';
import { brand } from '../../brand/brand.json';

interface LogoStingerProps {
  durationInFrames?: number;
}

export const LogoStinger: React.FC<LogoStingerProps> = ({ durationInFrames = 30 }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scaleIn = spring({ frame, fps, config: { damping: 80, mass: 0.3 } });
  const fadeOut = interpolate(
    frame,
    [durationInFrames - 10, durationInFrames],
    [1, 0],
    { extrapolateRight: 'clamp' }
  );

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', backgroundColor: brand.colors.ink }}>
      <Img
        src={staticFile(brand.logo.path)}
        style={{ width: 360, transform: `scale(${scaleIn})`, opacity: fadeOut }}
      />
    </AbsoluteFill>
  );
};
