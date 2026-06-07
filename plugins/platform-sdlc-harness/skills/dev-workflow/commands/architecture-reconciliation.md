# Phase 8: Architecture & Rules Reconciliation

**Phase**: 8
**Actor**: Planner agent in `architecture-audit` mode (orchestrator coordinates)

## Prerequisites

- Phase 7 complete — `Phase 7 Holistic Review` section populated in tracker.
- All dev + test tasks ✅ Done.
- User branch contains all the implementation + tests for this Story.

## Why this phase exists

The repo's architecture and convention rules live in-repo at:

- `.claude/architecture/<area>/<surface>.md` (per-area architecture docs covering each area × {mobile, service, web})
- `.claude/rules/{backend,web,mobile}/{code-style,testing}.md` (rules docs)
- `.claude/CLAUDE.md` (top-level index + cross-cutting workflow rules)

These evolve **with the codebase**, not with the harness. When a Story materially changes the architecture (new service, new layer, new shared package, deprecated pattern, new convention) the docs above must be updated **in the same PR** so future readers (and future agents) see truth.

Phase 8 is the place that audit happens.

## Delegate to the Planner

Spawn `@platform-sdlc-planner` with:

- `Mode: architecture-audit`
- `Story: #<number>`
- `Diff range: <base-branch>..<user-branch>`
- `Affected Surfaces: <service | web | mobile | combinations>`
- `Direction`:
  1. **Read the current state** of the relevant docs:
     - For each Affected Surface, read `.claude/rules/<surface>/{code-style,testing}.md`.
     - For each affected area, read `.claude/architecture/<area>/<surface>.md` (e.g. the matching service doc if the diff touches `service/`).
     - Read `.claude/CLAUDE.md`.
  2. **Compare against the diff** at three levels:
     - **Architecture impact**: new service / new layer / removed layer / new shared package / new external integration / changed module boundaries → architecture doc needs an update.
     - **Convention impact**: new pattern introduced (not yet documented) / pattern documented but deprecated by this change / convention violation that should be normalised → rules doc needs an update.
     - **Top-level capability impact**: new top-level feature / new key dependency / changed build command → `CLAUDE.md` needs an update.
  3. **Produce a proposed update set**:
     - List each doc that needs updating with a 1-paragraph rationale + the proposed diff (added/changed sections).
     - If no updates needed, return `Outcome: SUCCESS` with `Proposed updates: none`.
  4. **Present to the human** via `AskUserQuestion`:
     - For each proposed update, ask: *"Apply this update?"* with options `Yes (apply as proposed)` / `Yes (with my edits — I'll dictate)` / `No (skip)`.
  5. **Write approved updates** to the corresponding `.claude/<path>.md` files.
  6. **Stage and commit** the doc changes on the user branch:
     ```
     git add .claude/
     git commit -m "docs(architecture): reflect <Story title> in <surface> docs"
     ```
     Or `docs(rules): …` if only rules changed, or split into two commits if both architecture + rules changed.

## Orchestrator Post-Planner Steps

1. Extract `Proposed updates`, `Updates written`, `Commits` from the planner status block.
2. **Append to tracker** under a new `## Phase 8 Architecture & Rules Reconciliation` section:
   ```markdown
   ## Phase 8 Architecture & Rules Reconciliation (YYYY-MM-DDTHH:MM:SSZ)

   Proposed updates: <count> across docs <list>
   Approved + applied: <count>
   Commits: <hash list, or "none if no updates were needed">

   Summary: <planner's prose summary>
   ```
3. **No GitHub state changes** in Phase 8. The audit is INFORMATIONAL at the board level; the value is the in-PR doc updates.

## Verdict semantics

- `Outcome: SUCCESS` with `Proposed updates: none` → architecture/rules already accurate. Proceed to Phase 9.
- `Outcome: SUCCESS` with N updates applied → proceed to Phase 9; updates land in the same PR.
- `Outcome: PARTIAL` → human approved some but skipped others; the skipped ones go into tracker as "Open follow-up" notes. Proceed to Phase 9.
- `Outcome: FAILED` → planner couldn't read the docs (missing? renamed?). Pause and report; the human decides whether to skip Phase 8 entirely or fix the underlying issue.

## Next

Proceed to Phase 9 (`create-pr`).

## Note on cross-cutting workflow rules

Workflow-process rules (Conventional Commits format, branching, the 10-phase workflow itself, the harness's gate semantics) live in the **harness**, not in `.claude/rules/`. If the planner spots an attempt to put a process rule into the repo's `.claude/rules/` files, it should redirect that to the harness instead. Conversely, codebase rules (naming, layering, framework conventions) belong in `.claude/rules/`, not in the harness — the harness only points at them.
