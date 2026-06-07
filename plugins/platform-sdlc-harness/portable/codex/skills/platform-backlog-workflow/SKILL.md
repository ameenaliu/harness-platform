---
name: platform-backlog-workflow
description: >
  Refine, analyze, improve, or enrich a GitHub Story issue before development.
  Use when asked to improve/refine/analyze/enrich a Story or issue across the
  monorepo. Outputs go to the Story issue itself as body / acceptance-criteria
  edits + change-log comments.
---

# platform-backlog-workflow (Codex)

Spawn the `platform-sdlc-planner` subagent in `refinement` mode. Read-mostly against GitHub; the only writes are Story-quality artefacts (issue body / acceptance-criteria edits + change-log comments) posted back **after the human confirms**. GitHub access is via the `gh` CLI run through the shell (`gh issue view`, `gh issue edit`, `gh issue comment`) — there is no MCP server; `gh` must be authenticated in the Codex environment.

Refined Story titles MUST carry the `[<surface>]` prefix matching the affected surfaces (`[service]`, `[web]`, `[mobile]`, `[cross-cutting]`, or combinations) and follow the numbering scheme in `.agents/skills/github-rendering/SKILL.md`.

<!-- WORKFLOW BODY ASSEMBLED BY /init-workspace: portable/workflow/backlog-workflow.md -->
{{WORKFLOW_BODY}}
