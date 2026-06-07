import { AbsoluteFill, useCurrentFrame, spring, useVideoConfig, Img, staticFile } from 'remotion';
import { brand } from '../../brand/brand.json';

interface BrandIntroProps {
  headline: string;
  overlay?: 'dark' | 'light' | 'none';
}

export const BrandIntro: React.FC<BrandIntroProps> = ({ headline, overlay = 'dark' }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ frame, fps, config: { damping: 200, mass: 0.5 } });

  const overlayStyle =
    overlay === 'dark' ? { backgroundColor: 'rgba(11,31,42,0.7)' }
    : overlay === 'light' ? { backgroundColor: 'rgba(248,250,252,0.7)' }
    : {};

  return (
    <AbsoluteFill style={{ justifyContent: 'center', alignItems: 'center', ...overlayStyle }}>
      <Img
        src={staticFile(brand.logo.path)}
        style={{ width: 280, marginBottom: 40, transform: `scale(${enter})` }}
      />
      <h1 style={{
        fontFamily: brand.fonts.heading,
        fontWeight: 800,
        fontSize: 96,
        color: brand.colors.paper,
        textAlign: 'center',
        margin: 0,
        opacity: enter,
      }}>
        {headline}
      </h1>
    </AbsoluteFill>
  );
};
