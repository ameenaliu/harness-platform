import { AbsoluteFill, useCurrentFrame, spring, useVideoConfig } from 'remotion';
import { brand } from '../../brand/brand.json';

interface LowerThirdProps {
  name: string;
  role: string;
}

export const LowerThird: React.FC<LowerThirdProps> = ({ name, role }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();
  const slideIn = spring({ frame, fps, config: { damping: 100, mass: 0.5 } });

  return (
    <AbsoluteFill style={{ justifyContent: 'flex-end', paddingBottom: 200 }}>
      <div
        style={{
          backgroundColor: brand.colors.ink,
          opacity: brand.lowerThird.barOpacity,
          height: brand.lowerThird.barHeightPx,
          paddingLeft: 32,
          paddingRight: 32,
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'center',
          transform: `translateX(${(1 - slideIn) * -100}%)`,
        }}
      >
        <p style={{
          fontFamily: brand.fonts.heading,
          fontWeight: 700,
          fontSize: 36,
          color: brand.colors.paper,
          margin: 0,
        }}>
          {name}
        </p>
        <p style={{
          fontFamily: brand.fonts.body,
          fontWeight: 400,
          fontSize: 24,
          color: brand.colors.muted,
          margin: 0,
          marginTop: 4,
        }}>
          {role}
        </p>
      </div>
    </AbsoluteFill>
  );
};
