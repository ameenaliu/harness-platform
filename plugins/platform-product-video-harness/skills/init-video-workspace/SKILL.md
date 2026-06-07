---
name: init-video-workspace
description: >
  One-time setup for platform-product-video-harness. Locates, clones, or
  scaffolds the ProductVideos Remotion workspace (a local folder, optionally
  backed by a GitHub repo you supply), runs npm install, verifies
  ffmpeg/Node, captures brand config + voice ID, generates the local context
  file. Critically: checks for ELEVENLABS_API_KEY in .env and — if missing —
  prints the standardised remediation block (the harness never auto-writes
  .env; user maintains it in their editor). Also scaffolds the Codex
  cross-tool artefacts (.codex/agents/*.toml + .agents/skills/ + AGENTS.md)
  when Codex is a selected tool target. Run once per machine before using
  /generate.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, AskUserQuestion
argument-hint: "[--full | --refresh-config | --scaffold-tools]"
user-invocable: true
---

# /platform-product-video-harness:init-video-workspace

One-time workspace setup. Sets up the ProductVideos Remotion repo + verifies all dependencies + guides ElevenLabs `.env` setup + (when Codex is a target) scaffolds the cross-tool artefacts.

## Usage

```
/platform-product-video-harness:init-video-workspace                  # first-time setup
/platform-product-video-harness:init-video-workspace --full           # force full regeneration
/platform-product-video-harness:init-video-workspace --refresh-config # regenerate the context file only
/platform-product-video-harness:init-video-workspace --scaffold-tools # re-run Step 7 (Codex scaffolding)
```

## Output files

**Local, gitignored (per-developer):**

| File | Description |
|---|---|
| `<ProductVideos>/.claude/context/platform-video-context.md` | Workspace config: repo path, default voice ID, brand kit pointer, ElevenLabs tier acknowledgement, tool targets |
| `<ProductVideos>/.claude/settings.local.json` | Pre-approved tool permissions for background agents |

**Committed (team-shared, when ProductVideos repo is empty/new):**

| File / folder | For |
|---|---|
| `package.json`, `tsconfig.json`, `remotion.config.ts` | Remotion project root |
| `brand/brand.json`, `brand/logo.svg`, `brand/fonts/` | Brand kit |
| `compositions/Root.tsx`, `compositions/_components/*.tsx` | Initial composition skeleton + reusable component library |
| `.gitignore`, `.gitattributes`, `.env.example`, `README.md` | Repo hygiene |
| `AGENTS.md`, `.codex/agents/*.toml`, `.agents/skills/platform-video-generate/SKILL.md` | Cross-tool layer (when Codex selected) |

**The harness never writes `.env`** — user creates / maintains it in their text editor.

## Behavior

### Step 0 — Locate, clone, or scaffold ProductVideos

Ask the user (via `AskUserQuestion`):

> "Where is your `ProductVideos` Remotion workspace? (Used to render videos and host your brand kit. It's a local folder — optionally backed by a GitHub repo.)"
>
> - It's at a local path I'll provide
> - Clone it from a GitHub repo I'll provide (e.g. `https://github.com/<org>/product-videos`)
> - It doesn't exist yet — scaffold a brand-new local folder (optionally push to GitHub later)

On clone: `git clone <repo-url-the-user-supplies> <local-path>`. Do **not** hardcode any org — the user provides the URL.

On scaffold-new: `mkdir <local-path>; cd <local-path>; git init -b main`. Optionally, if the user has `gh` authed and wants a GitHub backing repo, they can run `gh repo create <org>/product-videos --private --source=. --remote=origin` themselves later (the harness does not create remote repos).

Verify the resolved path exists and is (or becomes) a git repo (`git -C <path> rev-parse --is-inside-work-tree`).

### Step 1 — Detect existing initialisation

Check whether both these files exist:
- `<ProductVideos>/.claude/context/platform-video-context.md`
- `<ProductVideos>/.claude/settings.local.json`

If both exist (and `--full` not set), inform the user and stop:

> "ProductVideos workspace already initialised. Nothing to do.
> - `--refresh-config` to regenerate the context file
> - `--full` to regenerate everything (incl. brand kit prompts)
> - `--scaffold-tools` to re-run the Codex cross-tool scaffolding only"

### Step 2 — Verify external dependencies (auto-install on approval)

Detect the host OS once via `Bash` (`uname -s` → `Linux` / `Darwin` / `MINGW*|MSYS*|CYGWIN*` = Windows) and remember it.

For each tool below, run the **check** command. If it fails or returns the wrong version, follow the **auto-install protocol** — do **not** ask the user to install it themselves.

| Tool | Check | Required version | Windows pkg | macOS pkg | Linux pkg |
|---|---|---|---|---|---|
| git | `git --version` | any 2.x | `Git.Git` | `git` | `git` |
| ffmpeg | `ffmpeg -version 2>&1 \| head -1` | any | `Gyan.FFmpeg` | `ffmpeg` | `ffmpeg` |
| ffprobe | `ffprobe -version 2>&1 \| head -1` | any (bundled with ffmpeg) | (with ffmpeg) | (with ffmpeg) | (with ffmpeg) |
| Node.js | `node --version` | ≥ v20.0.0 | `OpenJS.NodeJS.LTS` | `node` | (use nvm — see below) |
| npm | `npm --version` | any | (bundled with Node) | (bundled with Node) | (bundled with Node) |

#### Auto-install protocol (per missing tool)

1. **Tell the user what's missing** in one line, e.g. `"⚙ ffmpeg not found on PATH (required for frame extraction + audio mux)."`

2. **Ask via `AskUserQuestion`** — exactly three options, in this order:
   ```
   Install ffmpeg automatically? (Recommended)   ← installs via the per-OS command below
   Skip this tool — I'll handle it manually        ← halt the workflow; user fixes + re-runs
   Cancel setup                                    ← abort entirely
   ```

3. **On "Install automatically"** — run the per-OS install command and capture exit code + last 5 lines of output:
   - **Windows**: `winget install --silent --accept-source-agreements --accept-package-agreements <pkg-id>` (e.g. `winget install --silent --accept-source-agreements --accept-package-agreements Gyan.FFmpeg`). May trigger UAC — tell the user to approve.
   - **macOS**: `brew install <formula>` (if `brew` itself is missing, halt with the *one* manual instruction "install Homebrew from https://brew.sh then re-run" — bootstrapping a package manager is a special case).
   - **Linux**: detect package manager via `command -v apt-get || command -v dnf || command -v pacman` and run accordingly: `sudo apt-get update && sudo apt-get install -y <pkg>` / `sudo dnf install -y <pkg>` / `sudo pacman -S --noconfirm <pkg>`. If `sudo` prompts for a password, surface the prompt to the user.
   - **Node on Linux specifically**: install via nvm (`curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm install 20 && nvm use 20`) — distro-packaged Node is often too old.

4. **Verify post-install** — re-run the check command. If it still fails, halt with the captured install error and a one-line fallback ("install manually via <package-manager link>") so the user has the canonical next step.

5. **On "Skip"** — halt the workflow with: `"Required tool '<name>' not installed. Install it then re-run /platform-product-video-harness:init-video-workspace."` Do **not** continue with the next steps.

6. **On "Cancel"** — abort with `"Setup cancelled. No changes made."`

The harness **never** ends a missing-tool flow with "go install X yourself" — always prompt + install on approval. The only exceptions are bootstrapping a package manager (Homebrew on macOS) and when the user explicitly picks "Skip".

### Step 3 — Scaffold Remotion project (if missing)

If `<ProductVideos>/package.json` doesn't exist:

1. Copy the scaffold templates from `${CLAUDE_PLUGIN_ROOT}/portable/templates/`:
   - `package.json` (with `remotion`, `@remotion/cli`, `react`, `react-dom`, typescript pinned)
   - `tsconfig.json`
   - `remotion.config.ts` (sets `Config.setVideoImageFormat('jpeg')`, `Config.setConcurrency(3)`)
   - `compositions/Root.tsx` (registers `<Composition>` for an example project — user can delete)
   - `compositions/_components/*.tsx` (LowerThird, LogoStinger, FeatureCallout, CaptionStrip, EndCard, BrandIntro, SafeArea — the reusable library)
   - `brand/brand.json` (**neutral starter** palette + tagline + generic personas; `name` derived from the workspace folder — Step 4.5 will overwrite this from user input, or leave it as-is on Cancel)
   - `brand/logo.svg` (neutral **placeholder** logo — Step 4.5 may replace with user-provided file/URL or generated text SVG)
   - `.gitignore` (`.env`, `.env.*`, `node_modules/`, `_cache/`, `_preview/`, `out/`, `*.mp4` under `projects/`, `public/`, `ai/video-runs/`, `.claude/context/`, `.claude/settings.local.json`, `.claude/logs/`)
   - `.gitattributes` (LF for .sh, CRLF for .ps1)
   - `.env.example` — **template only**:
     ```
     # ProductVideos credentials — keep this file out of git.
     # Get an ElevenLabs API key at https://elevenlabs.io/app/settings/api-keys
     # Starter tier ($5/mo) required for commercial use (posting to social media).
     ELEVENLABS_API_KEY=sk_paste_your_real_key_here
     ```
   - `README.md` (per-repo quick start)
2. Run `npm install` in the repo root. Capture the install output's last 5 lines; on failure surface the error.

### Step 4 — Ask which tool targets

Via `AskUserQuestion` (multi-select):

> "Which AI coding tools should this workspace support? The same `generate` workflow + conventions get scaffolded for each.
> - Claude Code (this plugin — already covers Claude)
> - OpenAI Codex (scaffolds `.codex/agents/*.toml` + `.agents/skills/` + `AGENTS.md` for cross-tool use)"

Record the selection; drives Step 7.

### Step 4.5 — Collect brand kit (interactive)

Run the **brand-collection protocol** from `skills/brand-collection/SKILL.md` in **init mode** with `<ProductVideos>` as the target.

The protocol prompts for brand identity — name (pre-filled from the workspace folder name), tagline, color palette, logo, fonts, and (lightweight) personas — and writes:
- `<ProductVideos>/brand/brand.json`
- `<ProductVideos>/brand/logo.svg`

Color palette options the user picks from: **use neutral starter defaults** (blue / amber / ink) / **generate a random pleasing palette** (deterministic per brand name) / **provide my own hex codes** (4 colors with hex validation).

Logo options: **local file path** (copied to `brand/logo.svg`) / **URL** (downloaded via curl) / **generate a text placeholder** (inline SVG with brand name on ink background).

In init mode, **personas + tone** (Step 6 in the protocol) are surfaced with the neutral starter set (`end_user` / `prospect` / `partner`) pre-selected so first-init stays fast — but they are never applied silently, and the user can refine them anytime via `/platform-product-video-harness:update-brand-kit`.

Step 7's final confirm gate is mandatory — nothing the user picked is written until they approve. On Cancel, the `brand/brand.json` + `brand/logo.svg` that Step 3 already scaffolded (neutral starter defaults) stay in place; the user can re-run `/platform-product-video-harness:update-brand-kit` later when they're ready.

### Step 5 — Capture voice config

Ask the user via `AskUserQuestion` for the voice ID:

> "Pick the default ElevenLabs voice for your product videos:
> - Rachel — energetic, friendly (default for product demos)
> - Antoni — calm, authoritative (default for launch announcements)
> - Bella — warm, casual (default for testimonials)
> - Custom voice ID — I'll paste it"

(Full list + tone-mapping in `skills/elevenlabs-voices/SKILL.md`.)

Record:
- Voice ID + tone label
- Default target duration (15s / 30s / 60s — default 30s)
- Confirmation that user is on ElevenLabs Starter tier or higher (commercial-licensed): **CRITICAL gate** — if user picks "I'm on Free tier", warn them that posting outputs is a ToS violation and halt with instructions to upgrade.

### Step 6 — `.env` setup verification

Check `<ProductVideos>/.env` exists AND contains `ELEVENLABS_API_KEY=` with a non-empty value:

```bash
[ -f "<ProductVideos>/.env" ] && grep -q "^ELEVENLABS_API_KEY=.\+" "<ProductVideos>/.env"
```

**If missing**, halt with the standardised remediation block from `skills/env-credential-recipes/SKILL.md` (verbatim — single source of truth). Do NOT use the `Write` tool on `.env`. The user creates / edits it in their text editor, then re-runs `/init-video-workspace`.

If `.gitignore` doesn't contain `.env`, halt with `"⚠ .gitignore must include .env to prevent accidental commit. Add the line '.env' then re-run."`

### Step 7 — Scaffold cross-tool artefacts (Codex selected)

Skip unless `Codex` is in tool targets from Step 4.

Source templates live under `${CLAUDE_PLUGIN_ROOT}/portable/`. Deploy into `<ProductVideos>/`:

1. `AGENTS.md` ← `portable/AGENTS.md.tmpl` with placeholders filled (`{{PROJECT}}` = the workspace/brand name, `{{REPO_URL}}` = the GitHub repo URL the user supplied in Step 0 or blank for a local-only workspace, `{{USER_SLUG}}` from `platform-context.md` if the SDLC harness is also initialised in the product repo).
2. For each role in `orchestrator, analyzer, scriptwriter, compositor, narrator, reviewer`:
   - `.codex/agents/<role>.toml` ← `portable/codex/agents/<role>.toml` with `{{DEVELOPER_INSTRUCTIONS}}` placeholder replaced by the concatenation of `portable/mechanics/codex.md` + `portable/roles/<role>.md` (TOML-escaped into the triple-quoted string).
3. `.agents/skills/platform-video-generate/SKILL.md` ← `portable/codex/skills/platform-video-generate/SKILL.md` with `{{WORKFLOW_BODY}}` replaced by `portable/workflow/generate.md`.
4. Optionally: ask whether to install the `portable/guards/` pre-commit hook (data-policy backstop for Codex which lacks Claude's runtime hooks).

### Step 8 — Write context file

Write `<ProductVideos>/.claude/context/platform-video-context.md`:

```markdown
# ProductVideos Workspace Context

Generated by `/platform-product-video-harness:init-video-workspace`. Local-only, gitignored.

## Repo

- **Local Path**: `<resolved-local-path>`
- **GitHub repo** (optional): `<repo-url-or-"(local-only)">`
- **Default branch**: `main`

## Brand

- **brand.json**: `brand/brand.json` (single source of truth for colors, fonts, logo)
- **Logo SVG**: `brand/logo.svg`

## ElevenLabs

- **Default voice ID**: `<voice-id-from-step-5>`
- **Tone**: `<energetic | calm | authoritative | warm>`
- **voice_settings**: `{ stability: 0.5, similarity_boost: 0.75, style: 0.0, use_speaker_boost: true }`
- **Tier**: Starter ($5/mo) or higher (user-acknowledged — required for commercial use)
- **API key location**: `<ProductVideos>/.env` → `ELEVENLABS_API_KEY=...` (never auto-written; user maintains)

## Defaults

- **Target duration**: 30s
- **Output aspect ratios**: 9:16 + 1:1 + 16:9 (all three rendered per project)

## Tool targets

- Claude Code (this plugin)
- <Codex (scaffolded into .codex/ + .agents/) — if selected>
```

### Step 9 — Write `.claude/settings.json` (team-shared, committed)

Write `<ProductVideos>/.claude/settings.json` so every teammate who opens this workspace in Claude Code auto-registers the marketplace + installs the video plugin. It bootstraps the workspace.

```json
{
  "extraKnownMarketplaces": {
    "harness-platform": {
      "source": {
        "source": "github",
        "repo": "ameenaliu/harness-platform"
      },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "platform-product-video-harness@harness-platform": true
  }
}
```

**If the file already exists** with other entries (e.g., the user has a previous workspace config), MERGE rather than clobber:

- Add the `harness-platform` entry to `extraKnownMarketplaces` if missing.
- Add `platform-product-video-harness@harness-platform: true` to `enabledPlugins` if missing.
- Never remove existing entries; preserve them as-is.

If you can't safely merge (e.g., JSON parsing fails or unexpected structure), halt with `"Existing .claude/settings.json found but unparseable — please review and add the entries manually."`

This file is **committed** (gitignore allows `.claude/settings.json`, only blocks `.claude/settings.local.json` + `.claude/context/`).

### Step 10 — Write `.claude/settings.local.json` (per-developer, gitignored)

Write `<ProductVideos>/.claude/settings.local.json` with pre-approved permissions for `ffmpeg`, `ffprobe`, `npx remotion`, `git`, `curl https://api.elevenlabs.io/*`, `node`, `npm`, etc. (Sourced from the plugin's `settings.json` template — same patterns, scoped to ProductVideos.) This is per-developer and gitignored.

### Step 11 — Summary

```
✅ ProductVideos workspace initialised.

Path: <resolved-local-path>
Brand: brand/brand.json
Voice: <ID> (<tone>)
ElevenLabs tier: Starter (user-confirmed)
Tool targets: Claude Code <+ Codex if selected>

Local artefacts (gitignored):
  .claude/context/platform-video-context.md
  .claude/settings.local.json
  .env (user-maintained — never auto-written)

Committed templates ready to commit (and push, if backing with GitHub):
  package.json, remotion.config.ts, compositions/, brand/, .gitignore, .env.example
  .claude/settings.json (registers marketplace + enables this plugin for the team)
  <AGENTS.md, .codex/, .agents/ if Codex selected>

Next steps:
  1. (Optional GitHub backing) cd <ProductVideos>; git add .; git commit -m "chore: init product-video workspace"; gh repo create <org>/product-videos --private --source=. --remote=origin --push
  2. Create your first video: mkdir projects/<YYYY-MM-DD>_<slug>; add brief.md + assets/ + (optional) sample.mp4
  3. Generate: /platform-product-video-harness:generate projects/<YYYY-MM-DD>_<slug>
```

## Flags

- `--full` — force regeneration of all scaffold templates + context file (confirms before overwriting committed files).
- `--refresh-config` — regenerate only the context file.
- `--scaffold-tools` — re-run Step 7 (Codex scaffolding) against the current tool targets.

## Rules

- **NEVER write to `.env`** — the `secrets-guard.sh` hook blocks it, and user owns `.env`. The harness guides; user creates.
- **NEVER scaffold over a non-empty `.env`** without explicit confirmation.
- **Hardcoded path defaults** are suggestions only — always confirm via `AskUserQuestion` before using.
- **Codex scaffolding** is opt-in; default to Claude Code only if the user doesn't explicitly pick Codex.
