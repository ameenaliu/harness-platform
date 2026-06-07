import { AbsoluteFill } from 'remotion';
import { brand } from '../../brand/brand.json';

interface FeatureCalloutProps {
  label: string;
  targetPosition?: { x: number; y: number };
  variant?: 'arrow' | 'pulse' | 'box';
}

export const FeatureCallout: React.FC<FeatureCalloutProps> = ({
  label,
  targetPosition,
  variant = 'arrow',
}) => {
  // Position the callout label near the target if provided; otherwise centre.
  const labelStyle: React.CSSProperties = targetPosition
    ? {
        position: 'absolute',
        top: targetPosition.y + 60,
        left: targetPosition.x - 100,
      }
    : {
        position: 'absolute',
        bottom: 240,
        left: '50%',
        transform: 'translateX(-50%)',
      };

  return (
    <AbsoluteFill>
      {targetPosition && (variant === 'pulse' || variant === 'box') && (
        <div
          style={{
            position: 'absolute',
            top: targetPosition.y - 32,
            left: targetPosition.x - 32,
            width: 64,
            height: 64,
            border: `4px solid ${brand.colors.accent}`,
            borderRadius: variant === 'pulse' ? '50%' : 12,
            boxShadow: `0 0 0 4px ${brand.colors.accent}33`,
          }}
        />
      )}
      <div
        style={{
          ...labelStyle,
          backgroundColor: brand.colors.accent,
          color: brand.colors.ink,
          fontFamily: brand.fonts.heading,
          fontWeight: 700,
          fontSize: 32,
          padding: '12px 20px',
          borderRadius: 8,
          maxWidth: 400,
          textAlign: 'center',
        }}
      >
        {label}
      </div>
    </AbsoluteFill>
  );
};
