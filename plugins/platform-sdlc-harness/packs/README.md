# Stack Packs

This directory makes the harness **language- and framework-agnostic**. Each *stack* (a language/framework choice for a surface) is described by a **pack manifest** — a single `pack.json` that declares everything the workflow needs to know to build, test, lint, review, and scaffold that stack. The agents, the portable roles, the dev-workflow orchestrator, and `init-workspace` **resolve a surface's stack from `registry.json` → its `pack.json`** instead of hardcoding `.NET` / `React` / `Expo` anywhere.

## Why

Before this layer, the surface→stack→tooling mapping was copy-pasted across ~18 files (every agent, every portable role, the orchestrator rules, the conventions skills, `hooks.json`, `settings.json`, the Codex scaffold). Adding a stack meant ~13 edits with no single source of truth. Now there is one: **`registry.json` + the pack manifests**.

## The model

```
packs/
  registry.json        # surface → supported stacks (+ default); stack key → pack.json path
  README.md            # this file
  <stack-key>/
    pack.json          # the manifest (build/test/lint cmds, coverage, detect globs, tools, skills, hook)
```

Discoverable `SKILL.md` bodies **stay in `skills/`** — Claude Code only discovers skills from `skills/<name>/SKILL.md`, so the pack *references* its skills by name; it does not contain them. A pack is metadata + wiring; the skills are the content.

### `registry.json`

```jsonc
{
  "surfaces": {
    "service": { "dir": "service/", "stacks": ["dotnet", "go"], "default": "dotnet" },
    "web":     { "dir": "web/",     "stacks": ["react-turbo"],   "default": "react-turbo" },
    "mobile":  { "dir": "mobile/",  "stacks": ["expo"],          "default": "expo" }
  },
  "packs": {
    "dotnet": "packs/dotnet/pack.json",
    "go":     "packs/go/pack.json",
    ...
  }
}
```

### `pack.json` (the contract)

| Field | Purpose | Consumed by |
|---|---|---|
| `key` / `surface` / `label` / `language` | identity | all |
| `detect.files` / `detect.globs` | how `init-workspace` recognises this stack already present in a repo | init-workspace |
| `conventions_skill` | the `skills/<name>` an agent loads before working this surface | developer, reviewer, tester, planner |
| `advisory_skills` | the advisory/quality/security skills run as self-checks + in review Phase B | developer (self-scan), reviewer (Phase B) |
| `coverage_threshold` | minimum coverage on new/modified code | tester, reviewer |
| `commands.build` / `build_gate` / `test` / `e2e` / `lint` / `format` | the surface's commands (placeholders like `<solution>` / `<affected-app>` filled at runtime) | developer, tester, reviewer |
| `test_frameworks` | human-readable test stack summary | tester, dev-workflow tech-stack section |
| `quality_hook` | the `hooks/*.sh` script that guards commits to this surface | hooks.json |
| `tool_permissions` | the `Bash(...)` permission tokens `init-workspace` writes into the repo's `settings.local.json` | init-workspace, settings.json |
| `commit_scope` | the Conventional-Commit scope tag (`service` / `web` / `mobile`) | developer, tester, reviewer Phase 0 |
| `review_checklist_anchor` | the heading in the conventions skill holding the per-stack PR checklist | reviewer Phase B |

## How to add a stack (e.g. Java service, Svelte web, Flutter mobile)

1. **Author the conventions skill** at `skills/<stack>-conventions/SKILL.md` — same shape as the existing ones (mandatory reads → stack/versions → coverage → advisory tooling → per-stack PR checklist under a heading matching `review_checklist_anchor`). This is the substance.
2. *(Optional)* **Author stack-exclusive advisory skills** at `skills/<name>/SKILL.md` (e.g. a `java-code-quality` analog of `dotnet-code-quality`). Shared advisory skills (`security-scan`, `observability`, `api-contract-check`, `react-doctor`, `dead-code-analysis`, `bundle-budget`) are reused by name — don't duplicate them.
3. **Write `packs/<stack>/pack.json`** filling every field in the contract above.
4. **Register it** in `registry.json`: add the key to the surface's `stacks` array and a `packs` pointer.
5. **Add a quality-hook branch**: in `hooks/<surface>-quality-check.sh`, add detection (your `detect.files`) → run your `build` + `lint` + `test`. Reuse the surface's existing hook; don't add a new one unless the surface is new.
6. *(New surface only)* add the surface to `registry.json.surfaces` and create `hooks/<surface>-quality-check.sh`.

Nothing in `agents/`, `portable/roles/`, the dev-workflow, or `init-workspace` needs editing — they are all registry-driven. That is the whole point.

## Stacks supported today

| Surface | Stacks | Default |
|---|---|---|
| service | `dotnet` (.NET 8), `go` (Go) | `dotnet` |
| web | `react-turbo` (React 19 + Turbo) | `react-turbo` |
| mobile | `expo` (Expo / React Native) | `expo` |

A repo records its chosen stack per surface in `.claude/context/platform-context.md` (written by `/init-workspace`). The workflow reads that file first; the registry `default` is only a fallback when the context file is silent.
