# platform-product-video-harness — Non-Negotiable Rules Summary

Loaded into every session using this plugin. For full documentation see README.md.
This file exists to make the most-drift-prone rules impossible to miss.

> **Why this is `CLAUDE.md` and not `AGENTS.md`:** Claude Code auto-injects a plugin's `CLAUDE.md` into every session that uses the plugin. It is the Claude mirror of the tool-neutral `AGENTS.md` that `/init-video-workspace` scaffolds into the ProductVideos workspace for Codex.

> **Brand-agnostic + GitHub-native:** this harness has no built-in brand. Each project supplies its own brand kit, collected per-workspace at init into `<ProductVideos>/brand/brand.json`. The `ProductVideos` workspace is a local folder — optionally backed by a GitHub repo the user supplies. The plugin ships in the `harness-platform` marketplace on GitHub (`ameenaliu/harness-platform`).

## What this plugin does

Generates production-grade product videos for social media from existing design assets + screen captures + (optionally) a reference video. Single workflow `/platform-product-video-harness:generate <project-folder>` runs an optional Phase 0 + a 5-phase pipeline:

0. **Brief (if `brief.md` missing)** — orchestrator hosts a Q&A inline (audience / tone / CTA / goal / notes), writes `brief.md`, confirms with the user. Skipped if `brief.md` already exists. No numbered gate.
1. **Analyze** — ffmpeg extracts frames from sample.mp4 (if present), Claude vision reads each, infers scene count / pacing / palette / suggested template.
2. **Script** — scriptwriter picks closest template from `skills/script-templates/`, fills variables from `brief.md` + analysis. **GATE #1** — human approves.
3. **Build** — compositor generates Remotion `.tsx`, renders 3 silent preview MP4s (9:16, 1:1, 16:9). **GATE #2** — human approves visual.
4. **Narrate** — narrator loads `ELEVENLABS_API_KEY` from `<ProductVideos>/.env`, calls ElevenLabs TTS + Sound Effects, ffmpeg muxes audio + video → 3 final MP4s.
5. **Review** — reviewer ffprobes each output for aspect ratio + duration + audio levels. **GATE #3** — human approves final.

## Critical rules

### Credentials live in `.env` — never auto-written, never committed

- The plugin **never writes** to `.env` via the Write tool — the `secrets-guard.sh` hook actively blocks it.
- The harness **guides the user** to create / edit `.env` themselves in their text editor with the line `ELEVENLABS_API_KEY=sk_…`.
- The narrator agent loads the key at runtime via `set -a; . "<ProductVideos>/.env"; set +a`, then uses `$ELEVENLABS_API_KEY` in `curl` calls. The key never enters Claude's prompt context.
- `.env` is **gitignored** AND the `secrets-guard.sh` hook rejects `git add .env*` / `git commit*` that stages any `.env*` file.

### Commercial use requires the Starter tier ($5/mo)

- ElevenLabs Free tier license is non-commercial — posting branded content to social media counts as commercial use.
- The narrator agent does not verify the user's tier; the user is responsible for being on Starter or above before posting any output.
- The README + `init-video-workspace` flag this prominently.

### Brand tokens always — no hardcoded hex / fonts

- All colors / fonts come from `<ProductVideos>/brand/brand.json` via `import { brand } from '../brand/brand.json'`.
- Compositor never inlines a hex literal like `#2563EB` or `"Inter"` — only `brand.colors.primary` / `brand.fonts.heading`.
- Reviewer flags any hardcoded hex (`#[0-9a-fA-F]{3,8}`) in `compositions/*.tsx` as a `CRITICAL` finding.

### Captions burned in for accessibility

- Every voiceover line gets a `<CaptionStrip>` overlay synced to scene timing.
- Reviewer rejects outputs where script has voiceover but the composition has no caption strip.

### Audio levels (social broadcast standard)

- Voiceover normalised to **-16 LUFS** integrated.
- BGM bed ducked to **-28 LUFS** integrated (sits under the voice).
- Reviewer verifies with `ffmpeg -af loudnorm=print_format=summary`; halts if voiceover is more than ±2 LU from target.

### Duration discipline

- Final MP4 must be within **±2 seconds** of the script's target duration (per-template constraint).
- Reviewer halts on overshoot; loops back to scriptwriter with the actual vs target.

### Hook timing + CTA placement

- Scene 1 must establish the product/problem within the **first 3 seconds**. Scriptwriter enforces template-side; reviewer flags violations.
- Last scene reserved for CTA (download / try / learn more). Reviewer rejects trailing logo-only endings without a CTA line.

### No raw HTML in compositions

- Use Remotion primitives (`<AbsoluteFill>`, `<Img>`, `<Audio>`, `<Sequence>`) or components from `compositions/_components/`.
- Never `<div>` / `<img>` / `<button>` (mirrors the WEB stack's banned-HTML rule in the SDLC harness).

### Composition decomposition

- Any reusable component extracted into `compositions/_components/`.
- Per-video composition (`compositions/<slug>.tsx`) flagged for refactor at **>150 lines**.

## Workflow Surface (4 user-invocable skills)

| Command | Purpose | Frequency |
|---|---|---|
| `/platform-product-video-harness:init-video-workspace` | One-time setup — clone/scaffold ProductVideos repo, verify ffmpeg/Node (auto-install on approval), guide `.env` setup, collect brand kit | Once per machine |
| `/platform-product-video-harness:generate <project-folder>` | The full 5-phase pipeline (+ optional Phase 0 brief drafting + V8/V9 vision QA inline before GATE #2) | Per video |
| `/platform-product-video-harness:translate <project-folder> <iso-codes>` | Localise a generated video to N languages — re-render captions + re-synthesise voice via ElevenLabs multilingual. Comma-separated ISO codes (e.g. `"yo,ha,ig,pcm"` for Yoruba / Hausa / Igbo / Nigerian Pidgin — last 3 fall back to `captions-only` mode) | After `/generate`, per language set |
| `/platform-product-video-harness:update-brand-kit` | Update brand kit (colors / logo / tagline / fonts / personas / tone) after init | As brand evolves |

## Agents (5)

- `platform-video-analyzer` — Phase 1, ffmpeg + Claude vision
- `platform-video-scriptwriter` — Phase 2, template pick + variable fill
- `platform-video-compositor` — Phase 3, Remotion .tsx + 3-aspect-ratio silent render
- `platform-video-narrator` — Phase 4, ElevenLabs TTS + SFX + ffmpeg mux
- `platform-video-reviewer` — Phase 5, ffprobe verification

Each agent is a thin pointer that reads `portable/roles/<name>.md` + `portable/mechanics/claude.md` at runtime.

## Hooks (4)

- `hooks/secrets-guard.sh` — blocks API-key patterns in Write/Edit content AND blocks `.env*` files from being written, edited, or staged for commit
- `hooks/large-media-guard.sh` — blocks files >10MB from being written or staged
- `hooks/render-quality-check.sh` — fires on `git commit*` inside ProductVideos; runs `npx remotion lint` + 1-frame dry render
- `hooks/pii-pattern-guard.sh` — UserPromptSubmit; blocks PII patterns in prompts (copy of SDLC harness's guard, retuned to gate on the video sentinel)

All gated by the `<ProductVideos>/.claude/context/platform-video-context.md` sentinel — only fire inside an initialised ProductVideos workspace; never interfere with unrelated Claude Code sessions.

## Output

Final MP4s land in `<ProductVideos>/projects/<slug>/out/`:
- `9-16.mp4` — Instagram Reels, TikTok, YouTube Shorts (vertical)
- `1-1.mp4` — Instagram Feed (square)
- `16-9.mp4` — YouTube long-form, LinkedIn (horizontal)

All gitignored. Posting to platforms is **manual** in v0.1.0 — no Buffer/Hootsuite integration.

## Generated-Output Attribution

Every committed artefact (script.md, compositions/*.tsx, brand.json updates) ends with:
```
🤖 Generated with platform-product-video-harness
```

## Full Reference

- `skills/generate/SKILL.md` — phase-by-phase workflow
- `skills/init-video-workspace/SKILL.md` — one-time setup
- `README.md` — install + quick start + FAQ
