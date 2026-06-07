import { AbsoluteFill, useVideoConfig } from 'remotion';
import { brand } from '../../brand/brand.json';

interface CaptionStripProps {
  text: string;
}

export const CaptionStrip: React.FC<CaptionStripProps> = ({ text }) => {
  const { width, height } = useVideoConfig();
  const isPortrait = height > width;
  const isSquare = width === height;

  // Bottom-position offset per aspect ratio (above platform UI overlays)
  const bottomPx = isPortrait ? 380 : isSquare ? 180 : 130;
  const fontSizePx = isPortrait || isSquare ? brand.captionStrip.fontSizePx : 56;

  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', alignItems: 'center', paddingBottom: bottomPx }}>
      <div
        style={{
          backgroundColor: brand.colors.ink,
          opacity: brand.captionStrip.bgOpacity,
          padding: brand.captionStrip.paddingPx,
          borderRadius: 8,
          maxWidth: '90%',
        }}
      >
        <p style={{
          fontFamily: brand.fonts.body,
          fontWeight: 600,
          fontSize: fontSizePx,
          lineHeight: `${brand.captionStrip.lineHeightPx}px`,
          color: brand.colors.paper,
          textAlign: 'center',
          margin: 0,
          whiteSpace: 'pre-line',
        }}>
          {text}
        </p>
      </div>
    </AbsoluteFill>
  );
};
