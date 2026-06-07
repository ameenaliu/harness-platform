# Phase D1: Capture & Explore

**Phase**: D1
**Actor**: Planner agent in `discovery` mode

## Prerequisites

None — this is the entry point.

## Steps

1. **Capture the idea**. If the user passed an idea as argument (`/discovery-workflow "ship farm-health alerts"`), record it. Otherwise prompt:
   > "Describe the idea you want to shape. One paragraph is fine; include the *why* if you can."
2. **Slugify** the idea title to derive `<slug>` (kebab-case, ≤ 40 chars). Check `ai/discoveries/<slug>.md` — if it exists, ask whether to resume (load existing state) or fork (append a numeric suffix).
3. **Create the tracker stub** at `ai/discoveries/<slug>.md` with:
   - Date started (UTC)
   - Phase: `D1-explore`
   - Status: `in-progress`
   - Idea (verbatim from step 1)
4. **Run the clarifying-question loop**. Use the imported skills explicitly:
   - **`brainstorming`** to explore the idea space — what's the broader problem, what alternatives exist, what's the simplest viable version.
   - **`grill-me`** to identify the decision tree and walk each branch with the human.
   - **`grill-with-docs`** to ground questions against the existing product: pull samples of similar past initiatives with `gh search issues` / `gh issue list` (read org/repo from `.claude/context/platform-context.md`; look at Epic titles and Story shapes — see decompose.md step 2).
   Ask questions in structured batches via `AskUserQuestion` (2-4 at a time, multi-select where appropriate). Avoid burying the human in a wall of questions; iterate.
5. **Cover at minimum**:
   - **Users**: who is this for? (end users? admins? buyers? partners? specific role?)
   - **Value**: what problem does it solve, what's the desired outcome
   - **Success criteria**: how we'll know it works (qualitative + 1-2 measurable signals if possible)
   - **Scope**: what's in, what's explicitly out
   - **Hard constraints**: regulatory, deadlines, integrations, dependencies
   - **NFR hints**: perf-critical paths, security/privacy concerns, accessibility, offline support
   - **Affected surfaces**: `service` / `web` / `mobile` / `cross-cutting` (any subset) — drives the Story `[Surface]` prefix + `surface:*` label in D2
6. **Persist progress** to the tracker stub after each meaningful answer batch. If the session is interrupted, the next session can `resume`.
7. **Stop on explicit signal**. The human types `DONE EXPLORING` (or equivalent — "ok proceed", "we're good", etc.). Record `Phase: D1-DONE` in the stub and write a `## Shape` section summarising what was learned.
8. Hand off to D2 (decompose). If invoked from the full pipeline, automatically continue. If invoked as a standalone `explore` sub-command, end here and tell the human to run `/discovery-workflow decompose <slug>` when ready.

## Output

- Updated `ai/discoveries/<slug>.md` with `## Idea` + `## Shape` sections populated.
- Verbal hand-off summary to the human listing the slug + the next step.

## Rules

- **No GitHub writes** in D1.
- **No code or architecture decisions** — keep it functional.
- **Question discipline**: every question is multi-choice (via AskUserQuestion) wherever possible; free-form questions only for genuinely open inputs.
- **Don't over-ask**. 2-3 batches of clarifying questions usually suffice. If after 3 batches there's still major ambiguity, surface that as a risk in the Shape and proceed — D2 will surface it as a tree-shape decision the human resolves.
- **Status block** (planner agent ends responses with):
  ```
  📋 AGENT STATUS
  - Agent: planner
  - Mode: discovery
  - Phase: D1-explore
  - Slug: <slug>
  - Outcome: <SUCCESS (ready for D2) | IN-PROGRESS | BLOCKED>
  - Next action: <"run decompose" | "continue exploring" | "human input needed">
  ```
