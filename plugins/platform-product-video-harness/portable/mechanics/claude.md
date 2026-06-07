<!-- mechanics: claude — Claude Code operational detail for each role.
     This is the SINGLE SOURCE for everything Claude-specific. The plugin's agent files
     (agents/platform-video-*.md) are thin: they read their portable/roles/<name>.md body plus
     the relevant section below at startup and follow both. Paths are plugin-root-relative
     (or ProductVideos-repo-relative where noted). -->

## Mechanics — Claude Code

### Common to all roles

- **Paths are plugin-root-relative** when referring to skills (e.g. `skills/script-templates/SKILL.md`); **ProductVideos-repo-relative** when referring to compositions / brand / projects.
- **Conventions loading** — as your first action, read any conventions skills your phase needs (the role body lists them).
- **Status block** — end every response with the `📋 AGENT STATUS` block from your role body; the orchestrator parses it.
- **`.env` never read into your prompt context** — only the narrator agent loads it, and only into the subshell via `set -a; . .env; set +a`. Other agents (analyzer, scriptwriter, compositor, reviewer) never touch `.env`.

### Orchestrator (the `generate` skill main thread)

- **Delegation** via the Agent tool. Phases are sequential — `run_in_background` is NOT used.
- **Cache check before Phase 1** — verify `<project-folder>/_cache/analysis.json` exists AND its `source.hash` field matches `git hash-object <project-folder>/sample.mp4`. If matched, mark Phase 1 cached and skip directly to Phase 2.
- **Tracker writes** to `<repo-path>/ai/video-runs/<slug>.md` are local-only — never committed.
- **No file writes outside the tracker** — every other artefact is the relevant agent's job.

### Analyzer

- **ffmpeg subprocess**: launch via `Bash`. Capture stderr; if non-zero exit, halt with the error.
- **Vision-reading frames**: `Read` each PNG path; Claude sees the image as part of the assistant turn. Batch up to 8 frames per turn to keep context manageable.
- **Write only under `<project-folder>/_cache/`** — analyzer outputs are local-only.

### Scriptwriter

- **Write tool only** for `script.md` — never `Bash` (`echo`/`cat`/`heredoc`). After writing, verify by reading the file back; retry once on failure, then report `FILE OPERATION FAILED`.
- **AskUserQuestion** for GATE #1 — present the full draft + 4 options (APPROVED / NEEDS CHANGES / WRONG TEMPLATE / CANCEL).
- **No Bash** — disallowed for this role.

### Compositor

- **Write/Edit only** for `compositions/*.tsx` and `compositions/Root.tsx`. Verify each write by reading back.
- **Bash subprocess** for `npx remotion render` (one call per aspect ratio). Capture stderr. On render failure, retry once with `--log=verbose`; on second failure, surface to human.
- **Asset copy** via `Bash cp` from `projects/<slug>/assets/` → `public/<slug>/`.
- **AskUserQuestion** for GATE #2 — present 3 file paths + 4 options.

### Narrator

- **Source `.env`** at the START of every bash invocation that needs the key:
  ```bash
  set -a; . "<repo-path>/.env"; set +a
  ```
  Then use `$ELEVENLABS_API_KEY` (never echo it, never include literal in any file).
- **curl** the ElevenLabs APIs (TTS + Sound Effects). Capture output to `<project-folder>/audio/` directly via `--output`.
- **ffmpeg subprocesses** for normalisation, BGM loop, voiceover-bgm mix, final mux. Each as a separate `Bash` call so failures surface cleanly.
- **NEVER `Edit` on `.env`** — the `secrets-guard.sh` hook will block it. If key missing, halt with the standardised remediation block from `skills/env-credential-recipes/SKILL.md` (verbatim).

### Reviewer

- **Read-only** (`disallowedTools: Write, Edit`) — enforced. You cannot modify any file, including the tracker.
- **Bash for ffprobe / ffmpeg / grep** — verification only. Capture output, parse, report. Never edit or move output files.
- **AskUserQuestion** for GATE #3 — present the report + 5 options (APPROVED / re-narrate / re-build / re-script / CANCEL).
