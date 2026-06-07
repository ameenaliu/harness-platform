# portable/ — cross-tool layer (video plugin)

Source templates that let the same video-generation workflow run under **Claude Code** and **OpenAI Codex**. These files are **not** loaded into Claude Code at runtime — they are deployed into the *target* repo (`ProductVideos`) by `/init-video-workspace` Step 7, adapted to whichever tools the team selected.

> Copilot is intentionally out of scope. If you add it later, mirror the Codex structure: new `portable/copilot/` subtree, new `portable/mechanics/copilot.md`, and update `init-video-workspace` Step 7.

## Why this exists

The harness's substance — the 5-phase pipeline, the agent roles (analyzer, scriptwriter, compositor, narrator, reviewer), the human gates, the brand / production principles, the `.env` protocol — is tool-agnostic. Only the *mechanism* differs per tool. This layer authors the substance **once** and wraps it per tool.

## What maps to what

| Concept | Claude Code | OpenAI Codex |
|---|---|---|
| Agent definition | plugin `agents/platform-video-*.md` | `.codex/agents/*.toml` (scaffolded) |
| Orchestrator delegates | Agent tool, sequential | workflow skill spawns subagents explicitly |
| Human gates (3) | inline `AskUserQuestion` pauses | skill stops, asks for `APPROVED` |
| Read-only reviewer (Phase 5) | `disallowedTools: Write, Edit` | `sandbox_mode = "read-only"` |
| `.env` protection | runtime `secrets-guard.sh` hook | `portable/guards/pre-commit` (optional CI/git backstop) |
| Brand kit | `<ProductVideos>/brand/brand.json` (same for both tools) | same |
| Data policy | runtime hooks (4 guards) | prose in `AGENTS.md` + optional `portable/guards/` |

## Layout

```
portable/
  AGENTS.md.tmpl               # universal hub, read by both tools (placeholders filled at scaffold time)
  roles/                       # SINGLE SOURCE for each agent's substance
    orchestrator.md            #   the generate workflow body
    analyzer.md                #   Phase 1
    scriptwriter.md            #   Phase 2 (hosts GATE #1)
    compositor.md              #   Phase 3 (hosts GATE #2)
    narrator.md                #   Phase 4
    reviewer.md                #   Phase 5 (hosts GATE #3)
  mechanics/                   # per-tool isolation/delegation/gate deltas
    claude.md                  #   prepended to role bodies for Claude
    codex.md                   #   prepended to role bodies for Codex
  workflow/                    # workflow narratives (single source)
    generate.md                #   the 5-phase narrative
  codex/                       # Codex wrappers
    agents/                    #   <name>.toml for each role (orchestrator + 5 agents)
    skills/                    #   platform-video-generate/SKILL.md with {{WORKFLOW_BODY}} placeholder
  guards/                      # OPTIONAL data-policy fallback for Codex
    pre-commit                 #   git pre-commit hook backstopping secrets-guard
    github-actions-secret-scan.yml  # CI policy for GitHub Actions (PR + push)
```

## How assembly works (DRY)

The plugin's `init-video-workspace` scaffolds Codex artefacts into `<ProductVideos>/` from this `portable/` tree:

- **Codex agents** ← static TOML from `portable/codex/agents/<name>.toml`, with `developer_instructions = """{{DEVELOPER_INSTRUCTIONS}}"""` replaced by the concatenation of `mechanics/codex.md` + `roles/<name>.md` (TOML-escaped into the triple-quoted string).
- **Codex skill** ← `portable/codex/skills/platform-video-generate/SKILL.md` with `{{WORKFLOW_BODY}}` placeholder replaced by `portable/workflow/generate.md`.
- **`AGENTS.md`** (universal hub) ← `portable/AGENTS.md.tmpl` with placeholders filled (`{{REPO_URL}}`, `{{VOICE_ID}}`, etc.).

Edit a role once in `portable/roles/` and re-run `/init-video-workspace --scaffold-tools` to refresh both tools.

## Placeholders

`{{PROJECT}}`, `{{REPO_URL}}`, `{{VOICE_ID}}`, `{{VOICE_TONE}}`, `{{TARGET_DURATION_SECONDS}}` — filled from the workspace context gathered by `/init-video-workspace`.

## Caveats

- Tool feature names evolve. The Codex `sandbox_mode` / `mcp_servers` keys reflect current schemas — adjust if your installed versions differ.
- Codex spawns subagents only when explicitly instructed; the `platform-video-generate` skill carries those explicit spawn directives.
- The reviewer (Phase 5) is read-only in BOTH tools — Codex via `sandbox_mode = "read-only"`, Claude via `disallowedTools: Write, Edit`.
