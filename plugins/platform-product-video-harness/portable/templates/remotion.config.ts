import { Config } from '@remotion/cli/config';
import os from 'node:os';

// Default video output config — overridable per-render via CLI flags.
Config.setVideoImageFormat('jpeg');
Config.setOverwriteOutput(true);
Config.setPixelFormat('yuv420p');

// Concurrency: half of CPU cores by default (leave room for the OS / browser).
// On dedicated render boxes, bump to os.cpus().length via env var.
const cores = Math.max(1, Math.floor(os.cpus().length / 2));
Config.setConcurrency(Number(process.env.REMOTION_CONCURRENCY ?? cores));

// Higher quality default (CRF 18 ≈ visually lossless). Per-render flag overrides.
Config.setCodec('h264');
Config.setCrf(18);

// Bundler tweaks
Config.setEntryPoint('compositions/Root.tsx');
