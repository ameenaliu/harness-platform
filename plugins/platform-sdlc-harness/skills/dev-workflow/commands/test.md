# Phase 6: Test Implementation

**Phase**: 6
**Actors**: Tester agent and Reviewer agent (orchestrator coordinates)

## Prerequisites

- Human approved at GATE #2 (Phase 5 complete).
- ALL development tasks ✅ Done in the tracker.
- Phase 4 Holistic Review section populated in the tracker.

## Per-Surface Loop (Sequential)

For each affected Surface with a `T-TEST-<Surface>` task in the tracker:

1. **Update tracker** — `T-TEST-<Surface>` → 🔧 In Progress, set `Started`.
2. **GitHub sync** — set the corresponding test Task issue's Project **Status** → `In Progress` + assignee.
3. **Spawn the Tester**:
   ```
   @platform-sdlc-tester
   Write tests for <Surface>.
   - Story: #<number>
   - Test task: T-TEST-<SERVICE|WEB|MOBILE>
   - Surface: <service | web | mobile>
   - Coverage target: <80% SERVICE | 70% WEB | 85% MOBILE> on new/modified code from the dev tasks
   - Worktree: <enabled | disabled>
   - User branch: <users/<slug>/...>
   ```
4. **Parse tester status block** — check `Outcome`, `Tests passing`, `Coverage`, `Test attempts`.
   - `SUCCESS`: proceed to step 5.
   - `PARTIAL` (coverage shortfall): retry once with explicit "raise coverage on <files>" direction; escalate if still short.
   - `FAILED`: escalate after retry per orchestrator-rules.
5. **Update tracker** — `T-TEST-<Surface>` → 🔄 In Review.
6. **Spawn the Reviewer (per-task mode for tests)**:
   ```
   @platform-sdlc-reviewer
   Review test commit in Phase 6 mode.
   - Story: #<number>
   - Task: T-TEST-<Surface>
   - Surface: <Surface>
   - Diff: <test commit ref>
   ```
7. **Parse reviewer verdict**:
   - `APPROVED`:
     - Worktree squash if applicable.
     - Tracker: `T-TEST-<Surface>` → ✅ Done, set `Completed`, record commit.
     - GitHub sync: set the test Task issue's Project **Status** → `In Review`.
     - Move to next surface's T-TEST or exit loop.
   - `CHANGES_REQUESTED`: relay `[R<n>]` comments to tester, loop back to step 3 with feedback.

## Loop Termination

When every `T-TEST-<Surface>` is ✅ Done, Phase 6 is complete.

## Next

Proceed to Phase 7 (`pre-pr-review`).
