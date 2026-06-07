import { Composition } from 'remotion';
import { ExampleHello } from './example-hello';

const FPS = 30;
const DEMO_DURATION_FRAMES = 90; // 3s

// Three example compositions registered (one per aspect ratio) so init-video-workspace
// produces a renderable project out of the box. Per-video compositions are added
// by the compositor agent in Phase 3.
export const RemotionRoot: React.FC = () => (
  <>
    <Composition
      id="example-hello-9-16"
      component={ExampleHello}
      durationInFrames={DEMO_DURATION_FRAMES}
      fps={FPS}
      width={1080}
      height={1920}
    />
    <Composition
      id="example-hello-1-1"
      component={ExampleHello}
      durationInFrames={DEMO_DURATION_FRAMES}
      fps={FPS}
      width={1080}
      height={1080}
    />
    <Composition
      id="example-hello-16-9"
      component={ExampleHello}
      durationInFrames={DEMO_DURATION_FRAMES}
      fps={FPS}
      width={1920}
      height={1080}
    />
  </>
);
