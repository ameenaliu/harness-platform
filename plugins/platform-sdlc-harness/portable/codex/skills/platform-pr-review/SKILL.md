---
name: platform-pr-review
description: >
  Holistic review of an open GitHub Pull Request on the monorepo, with inline +
  summary comments posted back to the PR via the gh CLI. Use at the end of the dev
  workflow (Phase 10) OR standalone on any PR — including ones not created by
  platform-dev-workflow.
---

# platform-pr-review (Codex)

Spawn the `platform-sdlc-reviewer` subagent (or perform the review directly if no subagent split is desired). The reviewer is read-only for source code; for this skill it needs shell/network access so it can post PR comments via the `gh` CLI (`gh api repos/{owner}/{repo}/pulls/<n>/comments` for inline findings + `gh pr review <n> --comment` for the summary). There is no MCP server; `gh` must be authenticated in the Codex environment.

**Comment-only — never blocks the PR.** Even on CRITICAL findings, verdict is `INFORMATIONAL`; the human + reviewers decide resolution.

<!-- WORKFLOW BODY ASSEMBLED BY /init-workspace: portable/workflow/pr-review.md -->
{{WORKFLOW_BODY}}
