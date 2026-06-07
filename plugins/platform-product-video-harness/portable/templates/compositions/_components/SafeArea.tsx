import { AbsoluteFill, useVideoConfig } from 'remotion';

interface SafeAreaProps {
  children: React.ReactNode;
}

// Adapts safe-zone padding to the active composition's aspect ratio.
// See agents/shared/video-production-principles.md → Aspect-ratio safe zones.
export const SafeArea: React.FC<SafeAreaProps> = ({ children }) => {
  const { width, height } = useVideoConfig();
  const isPortrait = height > width;
  const isSquare = width === height;

  const insetTop = isPortrait ? 220 : isSquare ? 60 : 50;
  const insetBottom = isPortrait ? 350 : isSquare ? 60 : 50;
  const insetX = isPortrait ? 30 : isSquare ? 60 : 150;

  return (
    <AbsoluteFill
      style={{
        paddingTop: insetTop,
        paddingBottom: insetBottom,
        paddingLeft: insetX,
        paddingRight: insetX,
      }}
    >
      {children}
    </AbsoluteFill>
  );
};
