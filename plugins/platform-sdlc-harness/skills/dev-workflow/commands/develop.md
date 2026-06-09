# Phase 3: Development Loop

**Phase**: 3
**Actors**: Developer agent and Reviewer agent (orchestrator coordinates)

## Prerequisites

- Plan approved at GATE #1 (Phase 2 complete).
- Task tracker exists in `ai/tasks/` with pending tasks.
- User branch (cut off `develop`) exists in the monorepo worktree.
- Task issues created as sub-issues of the Story and added to the Project board.

## Per-Task Loop (Sequential — single monorepo)

For each task in dependency order:

1. **Read tracker** — pick the next ⏳ Pending dev task. Skip `T-TEST-*` (those run in Phase 6).
2. **Update tracker** — T(n) → 🔧 In Progress, set `Started` timestamp.
3. **GitHub sync** — set the corresponding Task issue's Project **Status** → `In Progress` (`gh project item-edit`) and assign it (`gh issue edit <task> --add-assignee <AssignedTo>`). Dedupe by issue number across retries. Best-effort.
4. **Spawn the Developer**:
   ```
   @platform-sdlc-developer
   Implement T(n).
   - Story: #<number>
   - Task: T(n) (Issue #<task-number>)
   - Surface(s): <service | web | mobile | combination>
   - Plan rows: <relevant rows from execution-plan.md>
   - Worktree: <enabled | disabled> (from platform-context.md)
   - User branch: <users/<slug>/...>
   ```
5. **Parse developer status block** — check `Outcome`, `Build result`, `Build attempts`, `Commit(s)`, `Self-review`.
   - `SUCCESS` / `DONE_WITH_CONCERNS`: proceed to step 6. Pass any `Concerns` to the reviewer for extra scrutiny.
   - `PARTIAL` / `FAILED`: handle per orchestrator-rules decision matrix.
6. **Update tracker** — T(n) → 🔄 In Review, record build retries.
7. **Spawn the Reviewer (per-task mode)**:
   ```
   @platform-sdlc-reviewer
   Review T(n) in per-task mode.
   - Story: #<number>
   - Task: T(n)
   - Surface(s): <as from developer>
   - Diff: <worktree path or branch ref the developer used>
   - Developer concerns: <if any>
   ```
8. **Parse reviewer status block** — check `Verdict`.
   - `APPROVED`:
     - If worktree was used: integrate the worktree branch into the user branch with `git merge --no-ff` (preserving the task's commits — do NOT squash), then `git worktree remove <path>`. When worktree is disabled, the developer already committed directly on the user branch — nothing to integrate. The develop-level history granularity is governed by the **PR Merge Method** setting (`platform-context.md`), NOT by this step.
     - Update tracker: T(n) → ✅ Done, set `Completed`, record commit hash.
     - GitHub sync: set the Task issue's Project **Status** → `In Review`.
     - Continue to T(n+1).
   - `CHANGES_REQUESTED`: extract `[S<n>]`/`[R<n>]` from `Review comments`, update tracker T(n) → 🔧 In Progress with Reviewer Verdict → 🔄 Changes Requested, relay comments to the same developer worktree (loop back to step 4 with the comments as additional context).
9. **NEVER** start T(n+1) before T(n) is `APPROVED`.

## Loop Termination

When all dev tasks (excluding `T-TEST-*`) are ✅ Done in the tracker, Phase 3 is complete.

## Next

Proceed to Phase 4 (`pre-test-review`) — the holistic reviewer audit before any tests are written.
