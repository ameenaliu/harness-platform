import { AbsoluteFill, useCurrentFrame, spring, useVideoConfig, Img, staticFile } from 'remotion';
import { brand } from '../../brand/brand.json';

interface EndCardProps {
  cta: string;
  showStoreBadges?: boolean;
}

export const EndCard: React.FC<EndCardProps> = ({ cta, showStoreBadges = true }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const enter = spring({ frame, fps, config: { damping: 200 } });

  return (
    <AbsoluteFill
      style={{
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: brand.colors.ink,
        opacity: enter,
        padding: 40,
      }}
    >
      <Img
        src={staticFile(brand.logo.path)}
        style={{ width: 320, marginBottom: 24 }}
      />
      <p style={{
        fontFamily: brand.fonts.body,
        fontWeight: 400,
        fontSize: 28,
        color: brand.colors.muted,
        textAlign: 'center',
        margin: 0,
        marginBottom: 32,
      }}>
        {brand.tagline}
      </p>
      <p style={{
        fontFamily: brand.fonts.heading,
        fontWeight: 700,
        fontSize: 42,
        color: brand.colors.accent,
        textAlign: 'center',
        margin: 0,
        marginBottom: 32,
        maxWidth: '90%',
      }}>
        {cta}
      </p>
      {showStoreBadges && (
        <div style={{ display: 'flex', gap: 24, justifyContent: 'center', alignItems: 'center' }}>
          {/* Placeholder pill badges — replace with real iOS/Android SVG badges in brand/badges/ */}
          <div style={{
            backgroundColor: brand.colors.paper,
            color: brand.colors.ink,
            padding: '12px 24px',
            borderRadius: 999,
            fontFamily: brand.fonts.body,
            fontWeight: 600,
            fontSize: 24,
          }}>
            iOS
          </div>
          <div style={{
            backgroundColor: brand.colors.paper,
            color: brand.colors.ink,
            padding: '12px 24px',
            borderRadius: 999,
            fontFamily: brand.fonts.body,
            fontWeight: 600,
            fontSize: 24,
          }}>
            Android
          </div>
        </div>
      )}
    </AbsoluteFill>
  );
};
