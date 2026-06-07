# platform-discovery-workflow — shape an idea into a GitHub Epic → Feature → Story tree

Drive a raw product idea through **3 internal phases** (D1 explore → D2 decompose → D3 create) to produce a structured GitHub Issue tree (Issues + sub-issues + Project items) on the repo. The output feeds `/backlog-workflow` (refine each Story) → `/dev-workflow` (implement each). All GitHub writes use the `gh` CLI (`gh issue create`, `gh api graphql addSubIssue`, `gh project item-add/item-edit`) — there is no MCP server.

**Usage**: `<command> [<idea-or-slug>]` where command ∈ `explore | decompose | create | extend` (or run the whole pipeline by passing just an idea string).

**This is functional discovery only.** No code, no architecture decisions, no implementation details. The output is a populated backlog skeleton.

## Phase D1 — Capture & Explore

Planner in `discovery` mode. Captures the raw idea, then runs a clarifying-question loop using `brainstorming` + `grill-me` + `grill-with-docs`. Surfaces: users, value, success criteria, scope, hard constraints, NFR hints, affected surfaces.

Writes a tracker stub at `ai/discoveries/<slug>.md` (local-only, git-ignored). Survives session interruption — re-running `/discovery-workflow` with the same idea offers to resume.

Stops on explicit `DONE EXPLORING` from the human. No GitHub writes in D1.

## Phase D2 — Decompose & Propose Tree

Planner reads the tracker stub's `## Shape`, samples existing work-item style via `gh issue list --search` (to mirror native conventions), allocates the E/F/S numbering across the whole tree (per `github-rendering`), then proposes a tree:
- **1+ Epic** per cohesive capability surface (`E<e>:` title prefix).
- **2-5 Features** per Epic (each = a releasable slice; `F<e>.<f>:` prefix).
- **2-6 Stories** per Feature (each = a 1-5 day developer outcome; `S<e>.<f>.<s>:` prefix).
- Every Story title also starts with `[<surface>]` (`[service]`, `[web]`, `[mobile]`, `[cross-cutting]`, or multi-surface `[mobile][service]`).
- Stories get titles + 2-3 sentence bodies only — **no Acceptance Criteria** (those come from `/backlog-workflow refine`).

Presented to the human as a Markdown tree. Options: `APPROVED` / `EDIT` (iterate) / `SPLIT` (more Epics) / `MERGE` (fewer items). Loop until APPROVED.

No GitHub writes in D2. The approved tree (with its planned E/F/S numbers) is persisted to the tracker stub.

## Phase D3 — Create in GitHub

Sanity-checks the approved tree (every Story has `[<surface>]` prefix + `S` number; every item has a parent), then walks top-down:
- Creates each `Epic` via `gh issue create --label type:epic` with a Markdown body per `github-rendering`.
- Creates each `Feature` (`--label type:feature`) under its Epic; wires it as a sub-issue via `gh api graphql addSubIssue` (fallback: `Parent: #<n>` body line + Project Parent field).
- Creates each `Story` (`--label type:story --label surface:<surface>`) under its Feature; wires the sub-issue link the same way.
- Adds every item to the org Project (`gh project item-add`) with Status `Backlog` + Surface set (`gh project item-edit`).
- Posts a discovery-summary comment on every Epic.

Detect native sub-issue support once on the first link; if `addSubIssue` errors, switch the whole run to fallback mode and log it — never silently flatten.

Updates the tracker stub with all returned issue numbers + URLs. Hands off:
- Per-Story refinement → `/backlog-workflow improve <issue-number>` (or `refine`, `enrich`, `analyze`).
- Implementation → `/dev-workflow <issue-number>` (the full 10-phase build).

## Extend (sub-command)

`/discovery-workflow extend <epic-or-feature-issue-number>` runs a mini D2 + D3 against an existing parent — for adding Features to an existing Epic, or Stories to an existing Feature, without re-doing full discovery. Walk the parent's existing child numbers (`gh issue list --search "in:title F<e>."`) and continue the numbering from the next unused integer.

## Invariants

- Discovery is **planner-only**. No developer, reviewer, or tester. The heavyweight `dev-workflow` orchestrator is NOT used.
- **No code, no commits to the repo.** Discovery writes only to GitHub Issues + the Project board + a local-only tracker stub.
- **No Tasks created.** Tasks come from `/dev-workflow` Phase 2 per Story.
- **No Acceptance Criteria.** AC comes from `/backlog-workflow refine`.
- **Tree depth is fixed**: Epic → Feature → Story only.
- **Surface prefix + E/F/S numbering on every Story title** is mandatory.
- **D2 gate is mandatory**: nothing lands in GitHub without explicit `APPROVED`.
