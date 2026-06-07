---
name: platform-video-generate
description: >
  Run the 5-phase product-video generation pipeline for a project folder
  under <ProductVideos>/projects/. Spawns specialised subagents (analyzer,
  scriptwriter, compositor, narrator, reviewer) and stops at each of the 3
  human gates for APPROVED.
---

# platform-video-generate (Codex)

You are the **orchestrator**. Drive the workflow below by **explicitly spawning Codex subagents** and **stopping at each gate**.

## Codex orchestration rules

- Subagents live in `.codex/agents/` (`platform-video-analyzer`, `platform-video-scriptwriter`, `platform-video-compositor`, `platform-video-narrator`, `platform-video-reviewer`). Spawn them explicitly — e.g. *"spawn the platform-video-analyzer subagent for project <slug>; wait for its result"*.
- **Sequential phases** — never start phase N+1 until phase N is approved. Video generation is heavy I/O / CPU-bound; serial is correct.
- After each subagent returns, parse its `📋 AGENT STATUS` block to decide the next step.
- **STOP at each of the 3 human gates** (GATE #1 after Phase 2 script, GATE #2 after Phase 3 preview render, GATE #3 after Phase 5 review) and ask the human to reply `APPROVED` before continuing. Gates are hosted by the relevant subagent via its own AskUserQuestion-equivalent; you wait for that subagent's `SUCCESS (APPROVED)` outcome.
- **`.env` is the user's territory** — no agent writes it. If narrator returns `BLOCKED (missing API key)`, surface the standardised remediation block (verbatim) and wait for the user to set up `.env` themselves.
- You (orchestrator) own the runtime tracker at `<ProductVideos>/ai/video-runs/<slug>.md` (gitignored). Update at every phase transition.

<!-- WORKFLOW BODY ASSEMBLED BY /init-video-workspace: portable/workflow/generate.md -->
{{WORKFLOW_BODY}}
