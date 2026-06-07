---
name: platform-dev-workflow
description: >
  Run the orchestrated 10-phase / 3-gate / 3-holistic-review SDLC workflow for a GitHub
  Story issue on the monorepo. Use when asked to implement, develop, or "run the workflow
  for" a Story (e.g. "develop story 2823"). Spawns specialized subagents (planner,
  developer, reviewer, tester) and stops at each human gate for approval.
---

# platform-dev-workflow (Codex)

You are the **orchestrator**. Drive the workflow below by **explicitly spawning Codex subagents** and **stopping at each gate**.

## Codex orchestration rules

- Subagents live in `.codex/agents/` (`platform-sdlc-planner`, `platform-sdlc-developer`, `platform-sdlc-reviewer`, `platform-sdlc-tester`). Spawn them explicitly — e.g. *"spawn the platform-sdlc-developer subagent for task T1; wait for its result"*.
- **Sequential within the monorepo**: never start T(n+1) until T(n) is reviewer-approved. Single-repo so no cross-repo parallelism — phases run in strict order.
- After each subagent returns, parse its `📋 AGENT STATUS` block to decide the next step.
- **STOP at each of the 3 human gates** (GATE #1 after planning, GATE #2 after Phase 4 holistic pre-test review, GATE #3 before PR creation) and ask the human to reply `APPROVED` before continuing. Do not auto-advance.
- **Holistic reviews (Phases 4, 7, 10)** are reviewer-only and informational — even on CRITICAL findings, the verdict is `INFORMATIONAL` and the workflow continues to the next gate where the human decides.
- The reviewer subagent runs `read-only` for source code; in Phase 10 it posts PR comments via the `gh` CLI (`gh api` review comments + `gh pr review --comment`) — its only writes. **Phase 10 never blocks the PR.**
- You (orchestrator) own the tracker, GitHub Issues + Project board writes, branch creation, PR creation (`gh pr create` with `Closes #<story>`), and issue → PR linking — all via the `gh` CLI (no MCP server; `gh` must be authed).

<!-- WORKFLOW BODY ASSEMBLED BY /init-workspace: portable/workflow/dev-workflow.md -->
{{WORKFLOW_BODY}}
