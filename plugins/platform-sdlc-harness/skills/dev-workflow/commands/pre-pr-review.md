# Phase 7: Holistic Pre-PR Review

**Phase**: 7
**Actor**: Reviewer agent in `holistic-pre-pr` mode (orchestrator coordinates)

## Prerequisites

- Phase 6 complete — every `T-TEST-<Surface>` is ✅ Done in the tracker.
- Phase 4 Holistic Review section already populated.

## Delegate to the Reviewer

Spawn `@platform-sdlc-reviewer` with:

- `Mode: holistic-pre-pr`
- `Story: #<number>`
- `Diff range: <base-branch>..<user-branch>` (now includes test commits)
- `Acceptance criteria: <as before>`
- `Direction`: re-audit the full diff including test commits. Verify spec compliance, AC satisfaction, test coverage meets per-Surface thresholds, no regressions introduced by the tests, no leftover scaffolding from the dev phase, git hygiene (no merge commits from base, no build-breaking commits). Output is **INFORMATIONAL** — never blocks.

## Orchestrator Post-Reviewer Steps

After the reviewer returns:

1. Extract `Review comments` from the status block.
2. **Append to tracker** under `## Phase 7 Holistic Review`:
   ```markdown
   ## Phase 7 Holistic Review (YYYY-MM-DDTHH:MM:SSZ)

   Reviewer outcome: <SUCCESS | FAILED>

   [S1] ... (or [R1] ...) — all comments verbatim

   Suggested PR Description:
   <reviewer's suggested PR body — saved here so create-pr can reuse verbatim>
   ```
3. **Capture the Suggested PR Description** — the reviewer typically produces a recommended PR body in `holistic-pre-pr` mode. Save it; Phase 9 (`create-pr`) reuses it (and appends the `Closes #<story>` + per-Task link lines).
4. **NO state changes** — Phase 7 doesn't flip any Task issue. Findings inform the human at GATE #3.

## Next

Proceed to Phase 9 (`create-pr`) — GATE #3 before the PR is actually opened.
