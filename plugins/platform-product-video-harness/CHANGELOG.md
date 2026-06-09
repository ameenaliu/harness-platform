# Changelog

## 1.0.1 — De-genericize demo theming

Removed FarmManagement product theming from examples so the video harness is brand-neutral: `inventory-launch` / `InventoryLaunch` → `product-launch` / `ProductLaunch`, "smallholder farmer" → "small business owner", "Meet Inventory" → "Meet your product", farm-sales testimonial captions → neutral. A stray `master` push-trigger → `main`. **Kept** 9jaLingo as an *optional* Nigerian-language (yo/ha/ig/pcm) TTS provider with captions-only fallback — a real feature, just framed as optional.

## 1.0.0 — Brand-agnostic, GitHub-native product-video harness

Initial release of `platform-product-video-harness` — a Claude Code + OpenAI Codex harness that generates production-grade product videos (Remotion + ElevenLabs) for social media. Brand-agnostic and GitHub-native: designed to be installed once from the `harness-platform` marketplace and used across any number of projects, each supplying its own brand kit.

### Brand model

- **No built-in brand.** Each project supplies its own brand kit, collected per-workspace at init into `<ProductVideos>/brand/brand.json` (+ `brand/logo.svg`).
- `brand.name` is **derived from the workspace folder name** (e.g. `kawee-kids` → "Kawee Kids"); palette, logo, personas, and tone start from **neutral starter defaults** (primary `#2563EB`, accent `#F59E0B`, ink `#0B1020`; generic personas `end_user` / `prospect` / `partner`).
- `/init-video-workspace` **prompts** for brand identity (name / palette / logo / personas / tone) — nothing brand-specific is ever applied silently. `/update-brand-kit` refreshes any of it later.
- Compositions read every color and font from `brand.json` via `import { brand }` — no hardcoded hex / font names; the reviewer flags violations as CRITICAL.

### Provider / workspace

- The `ProductVideos` workspace is a **local folder**, optionally backed by a **GitHub** repo the user supplies (clone from your own `https://github.com/<org>/...`, or scaffold a local folder and `gh repo create` it later). No org is hardcoded.
- Ships in the `harness-platform` marketplace on GitHub (`ameenaliu/harness-platform`); install via a committed `.claude/settings.json` or `/plugin marketplace add ameenaliu/harness-platform`.
- `gh` auth is only needed when backing the workspace with a GitHub repo; a purely local workspace needs no remote auth.

### Pipeline

- Single workflow `/platform-product-video-harness:generate <project-folder>` — optional **Phase 0** (guided brief drafting) + a **5-phase pipeline** (Analyze → Script → Build → Narrate → Review) with **3 human approval gates**.
- Phase 3 includes inline V8 (animation-pacing) + V9 (callout-alignment) vision QA before GATE #2.
- Renders **9:16 + 1:1 + 16:9** in one pass; ElevenLabs voiceover + ambient bed muxed via ffmpeg into 3 final MP4s in `projects/<slug>/out/`.
- `/translate` localises a generated video to N languages — ElevenLabs for English + 31 other languages, 9jaLingo for Yoruba / Hausa / Igbo / Nigerian Pidgin, captions-only fallback otherwise.

### Components

- **5 agents**: analyzer, scriptwriter, compositor, narrator, reviewer (thin pointers to single-source `portable/roles/` bodies).
- **4 user-invocable skills**: `init-video-workspace`, `generate`, `translate`, `update-brand-kit`. 18 skills total (4 user-invocable + 3 conventions + `brand-collection` + `9jalingo-voices` + 9 supporting).
- **4 data-policy hooks**, all gated on the `platform-video-context.md` sentinel (fire only inside an initialised workspace):
  - `secrets-guard.sh` — blocks API-key shapes (ElevenLabs `sk_`, 9jaLingo `nl-`, Figma, JWT, …) in Write/Edit content + direct writes to / commits of `.env*` and other sensitive files.
  - `large-media-guard.sh` — blocks files >10MB from being written or staged.
  - `render-quality-check.sh` — `npx remotion lint` + 1-frame dry render on `git commit`.
  - `pii-pattern-guard.sh` — blocks PII/credential patterns in user prompts.
- Credentials live in `<ProductVideos>/.env` (gitignored, hook-protected, never auto-written by the harness).

### Cross-tool (Claude Code + OpenAI Codex)

- `portable/` layer is the single source for roles, workflow narrative, and mechanics. `/init-video-workspace` scaffolds `AGENTS.md` + `.codex/agents/*.toml` + `.agents/skills/` into the workspace so Codex runs the same orchestrated pipeline. Codex runs local tooling only (ffmpeg / Node / curl / git) — no MCP servers.
- Optional data-policy backstops for Codex: a git `pre-commit` hook and a **GitHub Actions** secret-scan workflow (`portable/guards/github-actions-secret-scan.yml`, triggered on `pull_request` + `push`) that mirrors `secrets-guard.sh` + `large-media-guard.sh`.
