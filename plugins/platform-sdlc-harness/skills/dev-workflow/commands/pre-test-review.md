# Phase 4: Holistic Pre-Test Review

**Phase**: 4
**Actor**: Reviewer agent in `holistic-pre-test` mode (orchestrator coordinates)

## Prerequisites

- Phase 3 complete — all development tasks ✅ Done in the tracker.
- No `T-TEST-*` task started yet.

## Delegate to the Reviewer

Spawn `@platform-sdlc-reviewer` with:

- `Mode: holistic-pre-test`
- `Story: #<number>`
- `Diff range: develop..<user-branch>` (the entire dev-phase diff against the integration branch `develop`)
- `Acceptance criteria: <copy of the Story's acceptance-criteria checklist from the issue body>`
- `Direction`: run Phase 0 → Phase A → Phase B against the FULL diff (every task commit). Verify every acceptance criterion is satisfied end-to-end across SERVICE/WEB/MOBILE. Output is **INFORMATIONAL** — surface findings but never block.

## Orchestrator Post-Reviewer Steps

After the reviewer returns:

1. Extract `Review comments` from the status block.
2. **Append findings to tracker** under `## Phase 4 Holistic Review` section (created at Phase 2 as an empty placeholder):
   ```markdown
   ## Phase 4 Holistic Review (YYYY-MM-DDTHH:MM:SSZ)

   Reviewer outcome: <SUCCESS | FAILED>

   [S1] ... (or [R1] ...) — all comments verbatim

   Summary: <reviewer's prose summary, if present>
   ```
3. **NO state changes** — Phase 4 doesn't flip any Task issue. It's a read-only checkpoint.

## Phase 5 — Human Approval Gate

Present a summary to the human:
- Implementation complete: N dev tasks, M commits, all per-task reviews ✅
- Phase 4 holistic findings: X CRITICAL, Y WARNING, Z SUGGESTION (or "no blocking findings")
- Top 3 themes from the findings
- Question: *"Approve the implementation for testing? (APPROVED to continue / NEEDS WORK + comments to send back to Phase 3)"*

**GATE #2** — require explicit `APPROVED`. If `NEEDS WORK`, loop back to Phase 3 with the human's comments + the Phase 4 findings as direction for the developer.

## Next

On `APPROVED`, proceed to Phase 6 (`test`).
