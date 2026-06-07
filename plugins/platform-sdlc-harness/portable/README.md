# portable/ — cross-tool layer

Source templates that let the same SDLC workflow run under **Claude Code** and **OpenAI Codex**. These files are **not** loaded into Claude Code at runtime — they are deployed into the *target* repo by `/init-workspace` Step 7, adapted to whichever tools the team selected.

> Copilot is intentionally out of scope. If you add it later, mirror the Codex structure: new `portable/copilot/` subtree, new `portable/mechanics/copilot.md`, and update `init-workspace` Step 7.

## Why this exists

The harness's substance — the orchestrator + planner/developer/reviewer/tester roles, the 10-phase / 3-gate / 3-holistic-review workflow, the conventions, branching, commit format, and data policy — is tool-agnostic. Only the *mechanism* differs per tool. This layer authors the substance **once** and wraps it per tool.

## What maps to what

| Concept | Claude Code | OpenAI Codex |
|---|---|---|
| Agent definition | plugin `agents/platform-sdlc-*.md` | `.codex/agents/*.toml` |
| Orchestrator delegates | Agent/Task tool | workflow skill spawns subagents explicitly |
| Human gates (3) | orchestrator pauses for `APPROVED` | skill stops, asks for `APPROVED` |
| Read-only reviewer (Phases 3, 4, 6, 7) | `disallowedTools: Write, Edit` | `sandbox_mode = "read-only"` |
| Phase 10 reviewer PR comments | reviewer agent runs `gh` PR comment commands (`gh api` review comments + `gh pr review --comment`) | reviewer runs the same `gh` commands via shell |
| Conventions | plugin skills | `.agents/skills/*-conventions/SKILL.md` (copied) |
| Baseline rules | plugin `CLAUDE.md` + reads `AGENTS.md` | `AGENTS.md` |
| Data policy | runtime hooks (enforced: 4 guards) | prose in `AGENTS.md` + `guards/` |

GitHub mechanism is the same on both tools: the **`gh` CLI** (`gh issue`, `gh pr`, `gh project`, `gh api`, `gh api graphql`) run via shell. There is no MCP server. `gh` must be installed and authenticated (`repo`, `project`, `read:org` scopes) in each tool's environment.

## Layout

```
portable/
  AGENTS.md.tmpl           # universal hub, read by both tools (placeholders filled at scaffold time)
  roles/*.md               # SINGLE SOURCE for each agent's substance (orchestrator/planner/developer/reviewer/tester)
  mechanics/{claude,codex}.md   # per-tool isolation/delegation/gate deltas, prepended to role bodies
  workflow/*.md            # dev-workflow / backlog-workflow / discovery-workflow / pr-review narratives (single source)
  codex/                   # Codex wrappers: agents/*.toml, skills/platform-*-workflow/SKILL.md
  guards/                  # OPTIONAL data-policy fallback: pre-commit hook + GitHub Actions secret-scan workflow (for tools without runtime hooks)
```

## How assembly works (DRY)

The convention bodies are **never duplicated** — the scaffolder copies the plugin's existing `skills/*-conventions/SKILL.md` (already valid Codex/Claude skills) into the target's `.agents/skills/`.

The agent/skill wrappers are **thin**: each Codex `.toml` carries only static fields with a `{{DEVELOPER_INSTRUCTIONS}}` placeholder; each Codex workflow skill carries frontmatter + a `{{WORKFLOW_BODY}}` placeholder. At scaffold time, `/init-workspace`:

- **Codex agents** ← static TOML, with `developer_instructions` ← `mechanics/codex.md` + `roles/<name>.md` (TOML-escaped).
- **Codex skills** ← frontmatter + `workflow/<name>.md` at `{{WORKFLOW_BODY}}`.

Edit a role once in `roles/` and re-run `/init-workspace` to refresh both tools.

## Placeholders

`{{PROJECT}}`, `{{GH_ORG}}`, `{{GH_REPO}}`, `{{PROJECT_NUMBER}}`, `{{PROD_BRANCH}}`, `{{INTEGRATION_BRANCH}}`, `{{USER_SLUG}}` — filled from the workspace context gathered by `/init-workspace`.

## Caveats

- Tool feature names evolve. The Codex `sandbox_mode` key reflects the 2026 schema — adjust if your installed versions differ.
- Codex spawns subagents only when explicitly instructed; the `platform-dev-workflow` skill carries those explicit spawn directives.
- Phase 10 (post-PR review) is the only phase where the reviewer has any remote write capability — and only via `gh` PR comments, never on source files.
