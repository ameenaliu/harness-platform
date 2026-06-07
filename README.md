# harness-platform

A GitHub-native **Claude Code + Codex plugin marketplace**, designed to be installed once and shared across projects. It ships two plugins:

- **`platform-sdlc-harness`** — a multi-agent SDLC workflow (orchestrator → planner / developer / reviewer / tester) with **3 human approval gates and 3 holistic review phases**, driven by **GitHub Issues + sub-issues + Projects (v2)** and the **`gh` CLI** (no MCP server). Lifecycle: **Epic → Feature → Story → Task**; two-tier branching; Conventional Commits; `gh` PRs.
- **`platform-product-video-harness`** — Remotion + ElevenLabs product-video generation + multilingual localisation for social media, with a **per-project brand kit**.

Both are stack-flexible (defaults: .NET 8 `service/` + React 19 Turbo `web/` + Expo `mobile/`) and configured per-repo by `/init-workspace` into `.claude/context/`.

**Works with two AI coding tools.** The plugins are the canonical source; running the relevant `init` scaffolds the equivalent setup for **OpenAI Codex** as well as **Claude Code**, so a team runs the same workflow + conventions whichever tool they use. A data-policy layer (hooks in Claude; `AGENTS.md` rules + optional pre-commit/CI guards elsewhere) keeps PII, customer data, and credentials away from the model.

---

## Install

The marketplace lives on GitHub at **`ameenaliu/harness-platform`**.

### Team-shared (recommended) — auto-registration via `.claude/settings.json`

Commit this to a project repo's `.claude/settings.json` so every teammate gets the marketplace auto-registered and the plugins enabled when they open the repo in Claude Code (one-time trust prompt):

```json
{
  "extraKnownMarketplaces": {
    "harness-platform": {
      "source": { "source": "github", "repo": "ameenaliu/harness-platform" },
      "autoUpdate": true
    }
  },
  "enabledPlugins": {
    "platform-sdlc-harness@harness-platform": true,
    "platform-product-video-harness@harness-platform": true
  }
}
```

### Manual

```
/plugin marketplace add ameenaliu/harness-platform
/plugin install platform-sdlc-harness@harness-platform
/plugin install platform-product-video-harness@harness-platform
```

## First run

```
/init-workspace
```

- discovers your GitHub org/repo, default + production branch names, and your user slug;
- ensures the harness label set (`type:*`, `surface:*`, `status:*`) and the org **Project (v2)** board exist;
- writes `.claude/context/platform-context.md` + `.claude/settings.local.json`;
- scaffolds the cross-tool layer — `AGENTS.md`, `.codex/agents/*.toml`, `.agents/skills/platform-*-workflow/` — so Codex runs the same workflow.

## Prerequisites

| Requirement | Notes |
|---|---|
| **`gh` CLI** | Authed (`gh auth status`) with scopes `repo, project, read:org, workflow`. |
| **Stack toolchains** | Per adopted surface: .NET 8 SDK (service), Node 20+/Yarn 4 (web), Expo/Node (mobile). |
| **ffmpeg + ElevenLabs key** | Only for the product-video plugin. |

## Layout

```
harness-platform/
  .claude-plugin/marketplace.json     # 2 plugins
  plugins/
    platform-sdlc-harness/            # SDLC pipeline (GitHub Issues + Projects + gh)
    platform-product-video-harness/   # Remotion + ElevenLabs videos (per-project brand)
  scripts/                            # marketplace maintenance (validate, conflicts, context-bloat)
  README.md  AGENTS.md  LICENSE
```

See each plugin's `README.md` and `CLAUDE.md` for the full rules and workflows.
