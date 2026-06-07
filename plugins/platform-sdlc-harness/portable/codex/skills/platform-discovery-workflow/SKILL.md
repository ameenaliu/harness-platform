---
name: platform-discovery-workflow
description: >
  Shape a raw product idea into a GitHub Epic → Feature → Story tree (Issues +
  sub-issues) on the repo. Pure functional discovery — no code, no architecture
  decisions, no implementation details. The output feeds platform-backlog-workflow
  (refine each Story) and platform-dev-workflow (implement each). Use when starting
  any new initiative.
---

# platform-discovery-workflow (Codex)

Spawn the `platform-sdlc-planner` subagent in `discovery` mode. Planner-only workflow — no orchestrator, no developer, no reviewer, no tester. Uses the `gh` CLI (run via shell; no MCP server, `gh` must be authed) for D3 writes.

## Codex orchestration rules

- Subagent: `platform-sdlc-planner` (`.codex/agents/planner.toml`).
- The planner runs through **3 internal phases**: D1 explore → D2 decompose → D3 create. Each phase ends at an explicit human signal:
  - D1 ends on `DONE EXPLORING`.
  - D2 ends on `APPROVED` (after iterating EDIT / SPLIT / MERGE if needed).
  - D3 creates the GitHub Issues + sub-issue links + Project items and ends with a tree summary.
- **STOP at the D2 → D3 gate** and ask the human to reply `APPROVED` before writing to GitHub. Do not auto-advance.
- **Discovery only creates the issue tree**: no Tasks, no Status flips on Stories beyond creation (`Backlog`), no PRs.
- After D3 completes, return a summary listing all created Epic/Feature/Story issue numbers + URLs and the slug. Hand off to `platform-backlog-workflow` (per-Story refinement) and ultimately `platform-dev-workflow` (implementation).

<!-- WORKFLOW BODY ASSEMBLED BY /init-workspace: portable/workflow/discovery-workflow.md -->
{{WORKFLOW_BODY}}
