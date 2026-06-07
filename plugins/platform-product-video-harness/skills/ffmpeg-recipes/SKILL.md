---
name: ffmpeg-recipes
description: >
  ffmpeg + ffprobe command recipes used by the analyzer, compositor,
  narrator, and reviewer agents. Frame extraction, aspect-ratio crop,
  audio normalisation (loudnorm to -16 / -28 LUFS), voiceover-bgm
  mixing with sidechain ducking, mux audio+video, output verification.
disable-model-invocation: true
user-invocable: true
---

# ffmpeg recipes (video pipeline)

All commands assume ffmpeg ≥ 6.0 (older versions miss `sidechaincompress`-with-`compand` improvements).

## 1. Frame extraction (analyzer Phase 1)

```bash
ffmpeg -i sample.mp4 -vf "fps=1" -y _cache/frames/frame-%03d.png 2>&1 | tail -5
```

- `fps=1` → 1 frame per second. Adjust to `fps=0.5` for longer samples (>60s) or `fps=2` for shorter ones (<10s).
- Output is sequential PNG (`frame-001.png` … `frame-NNN.png`).

## 2. Probe a video for metadata

```bash
ffprobe -v error \
  -show_entries format=duration,format_name,size,bit_rate \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,nb_frames,duration \
  -of json sample.mp4
```

## 3. Aspect-ratio detection (just dimensions)

```bash
ffprobe -v error -select_streams v:0 \
  -show_entries stream=width,height \
  -of csv=s=x:p=0 sample.mp4
# Output: 1920x1080
```

## 4. Audio normalisation — voiceover stem to -16 LUFS

```bash
ffmpeg -y -i scene-01-voice-raw.mp3 \
  -af loudnorm=I=-16:LRA=11:TP=-1.5 \
  -c:a libmp3lame -b:a 192k \
  scene-01-voice.mp3
```

- `I=-16` integrated loudness target
- `LRA=11` loudness range (allows natural dynamics)
- `TP=-1.5` true peak ceiling (prevents clipping after re-encode)

## 5. Audio normalisation — BGM bed to -28 LUFS (ducked under voice)

```bash
ffmpeg -y -i bgm-raw.mp3 \
  -af loudnorm=I=-28:LRA=11:TP=-1.5 \
  -c:a libmp3lame -b:a 128k \
  bgm-normalised.mp3
```

## 6. Loop a short BGM clip to a target duration + fade in/out

```bash
TOTAL_DURATION=30.0    # seconds; derived from preview MP4

ffmpeg -y -stream_loop -1 -i bgm-normalised.mp3 \
  -t "$TOTAL_DURATION" \
  -af "afade=t=in:st=0:d=0.5,afade=t=out:st=$(echo "$TOTAL_DURATION-0.5" | bc):d=0.5" \
  -c:a libmp3lame -b:a 128k \
  bgm.mp3
```

## 7. voiceover-bgm-mix (concat voiceover stems aligned to scene starts + overlay BGM with sidechain ducking)

This is the central recipe. Goal: voice stems at correct scene start times, BGM continuous underneath, BGM ducks when voice is present.

Build a `filter_complex` with one `[v_i]` stream per voice stem (padded to scene start), concat them, then mix with BGM via sidechain compression.

For 4 voice stems at scene starts `[0.0, 3.0, 11.0, 17.0]` (seconds):

```bash
ffmpeg -y \
  -i scene-01-voice.mp3 \
  -i scene-02-voice.mp3 \
  -i scene-03-voice.mp3 \
  -i scene-04-voice.mp3 \
  -i bgm.mp3 \
  -filter_complex "
    [0:a]adelay=0|0[v0];
    [1:a]adelay=3000|3000[v1];
    [2:a]adelay=11000|11000[v2];
    [3:a]adelay=17000|17000[v3];
    [v0][v1][v2][v3]amix=inputs=4:duration=longest:dropout_transition=0:normalize=0[voice];
    [4:a][voice]sidechaincompress=threshold=0.05:ratio=8:attack=20:release=300[ducked_bgm];
    [voice][ducked_bgm]amix=inputs=2:duration=longest:weights=1 0.6:normalize=0[mix]
  " \
  -map "[mix]" \
  -c:a libmp3lame -b:a 192k \
  mixed.mp3
```

- `adelay=Nms|Nms` pads each voice stem to its scene start (left + right channels).
- `amix` combines voice stems into one continuous track.
- `sidechaincompress` ducks the BGM when the voice signal exceeds the threshold (BGM drops ~15dB while voice plays).
- Final `amix` combines ducked BGM (weight 0.6) with voice (weight 1.0).

Generate this `filter_complex` programmatically in the narrator agent — script-driven from `script.md`'s scene start times.

## 8. Mux audio + video (final output)

```bash
for ratio in 9-16 1-1 16-9; do
  ffmpeg -y \
    -i _preview/${ratio}-preview.mp4 \
    -i audio/mixed.mp3 \
    -map 0:v -map 1:a \
    -c:v copy \
    -c:a aac -b:a 192k \
    -shortest \
    -movflags +faststart \
    out/${ratio}.mp4
done
```

- `-c:v copy` reuses the silent preview's video stream (fast, no re-encode).
- `-c:a aac -b:a 192k` transcodes audio to AAC (Instagram/YouTube/TikTok compatible).
- `-shortest` cuts to the shorter of the two inputs (defensive — video should already be the right length).
- `-movflags +faststart` moves moov atom to file head for instant web playback.

## 9. Output verification (reviewer Phase 5)

### Duration
```bash
ffprobe -v error -show_entries format=duration -of csv=p=0 out/9-16.mp4
# Output: 30.067000
```

### Dimensions
```bash
ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 out/9-16.mp4
# Output: 1080x1920
```

### Integrated loudness
```bash
ffmpeg -i out/9-16.mp4 -af loudnorm=print_format=summary -f null - 2>&1 | grep "Input Integrated"
# Output: Input Integrated:    -16.1 LUFS
```

### Clipping detection
```bash
ffmpeg -i out/9-16.mp4 -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.Number_of_clipped_samples" -f null - 2>&1 | grep clipped | head -3
# Expect: lavfi.astats.Overall.Number_of_clipped_samples=0
```

### File size (cross-platform — use stat)
```bash
# Linux
stat -c %s out/9-16.mp4
# macOS / BSD
stat -f %z out/9-16.mp4
```

## 10. GIF preview (for sharing in Slack/Teams)

```bash
ffmpeg -y -i out/9-16.mp4 \
  -vf "fps=10,scale=480:-1:flags=lanczos" \
  -loop 0 \
  preview.gif
```

## 11. Thumbnail extraction (single frame for posting)

```bash
ffmpeg -y -i out/16-9.mp4 \
  -ss 00:00:01 \
  -vframes 1 \
  -q:v 2 \
  thumbnail.jpg
```

`-ss 00:00:01` picks the 1-second mark (skips the logo-stinger frame at 0:00).
