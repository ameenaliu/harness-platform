---
name: discovery-workflow
description: >
  Shape a raw product idea into a structured GitHub work-item tree (Epic →
  Feature → Story → Task) on the configured org/repo. Work items are GitHub
  Issues typed by `type:*` labels, wired into a hierarchy with native
  sub-issues and grouped on an org Project (v2) board. Pure functional
  discovery — no code, no architecture decisions, no implementation details.
  The output is a populated backlog ready for `/backlog-workflow` to enrich,
  then `/dev-workflow` to implement. Use this when starting any new initiative.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
argument-hint: "[command] [<idea-or-id>]"
user-invocable: true
---

# Discovery Workflow — Idea → Epic → Feature → Story tree

Drive a raw product idea through **3 internal phases** to produce a clean GitHub
work-item tree on the configured org/repo. Work items are **GitHub Issues**
distinguished by `type:*` labels (Epic / Feature / Story), wired into a hierarchy
with **native sub-issues** (`gh api graphql`), and added to an org **Project (v2)**
board. The output feeds `/backlog-workflow` (refine each Story) → `/dev-workflow`
(implement each Story; its Tasks come from Phase 2).

All GitHub operations use the **`gh` CLI** (and `gh api graphql`) via `Bash` — no
MCP server. Org, repo, project number/owner, branch names, and user slug are read
from `.claude/context/platform-context.md` (recorded by `/init-workspace`) — never
hardcoded.

## Usage

```
/discovery-workflow                              # Full pipeline starting from a fresh idea
/discovery-workflow "<one-line idea>"            # Full pipeline; idea provided as argument
/discovery-workflow <command> [<args>]           # Direct sub-command
```

| Command | File | Phase | Description |
|---------|------|-------|-------------|
| `explore` | `commands/explore.md` | D1 | Capture idea, ask clarifying questions, surface scope/users/value/success criteria. No writes. |
| `decompose` | `commands/decompose.md` | D2 | Propose an Epic → Feature → Story tree; allocate E/F/S numbers; iterate with human until APPROVED. No GitHub writes. |
| `create` | `commands/create.md` | D3 | Write the approved tree to GitHub via `gh issue create` + sub-issue links + Project board. Returns `#N` + URLs. |
| `extend` | `commands/extend.md` | — | Add new Feature(s) or Story(ies) to an existing Epic/Feature. Reuses D2 + D3 against a sub-tree. |

If no command is specified, run the full pipeline: D1 → D2 → D3.

## Behaviour at a glance

```
            ┌─────────────────────────────────────────────────────────────┐
            │  Phase D1 — Capture & Explore (planner, discovery mode)     │
            │    • Capture idea + context (free text or `<arg>`)          │
            │    • Loop: targeted clarifying Qs via AskUserQuestion       │
            │      (uses brainstorming + grill-me / grill-with-docs)      │
            │    • Surface: users, value, success criteria, scope,        │
            │      hard constraints, NFR hints, affected surfaces         │
            │    • Output: a "shaped idea" summary in working memory      │
            │      (drafted to ai/discoveries/<slug>.md, NOT committed)   │
            └────────────────────┬────────────────────────────────────────┘
                                 │ explicit "DONE EXPLORING"
            ┌────────────────────▼────────────────────────────────────────┐
            │  Phase D2 — Decompose & Propose Tree                        │
            │    Planner proposes:                                        │
            │      Epic(s)   — E<e> title, value, success criteria        │
            │      Features  — F<e>.<f> title, intent, parent Epic        │
            │      Stories   — S<e>.<f>.<s> title with [Surface] prefix,  │
            │                  story + AC hints, parent Feature, surface  │
            │    Allocate all E/F/S numbers up-front (sticky, 1-based).   │
            │    Presented as a Markdown tree. Human reviews.             │
            │    Options: APPROVE / EDIT (loop) / SPLIT / MERGE           │
            │    Gate: explicit `APPROVED`                                │
            └────────────────────┬────────────────────────────────────────┘
                                 │ APPROVED
            ┌────────────────────▼────────────────────────────────────────┐
            │  Phase D3 — Create in GitHub                                │
            │    Top-down create (Epic → Features → Stories):            │
            │      gh issue create with:                                  │
            │        - title: E<e>/F<e>.<f>/S<e>.<f>.<s> prefix          │
            │          (Story carries [Surface] too)                     │
            │        - body: Markdown per github-rendering structures     │
            │        - labels: type:* (+ surface:* on Story)             │
            │      Capture each returned #N.                              │
            │    Bottom-up wire sub-issues (gh api graphql addSubIssue;  │
            │      fallback type:* + Parent line + Project Parent field). │
            │    gh project item-add each + set Surface + Status=Backlog. │
            │      (verify project scope first; verify membership after)   │
            │    Native "Blocked by" deps via REST dependencies endpoint.  │
            │    Return: tree summary with human-id → #N → URL.          │
            └─────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                    Hand off to /backlog-workflow for per-Story refinement
                                 ▼
                    Hand off to /dev-workflow for implementation
```

## Critical rules

- **Functional only.** Discovery never makes architecture or implementation decisions. Don't propose database tables, API contracts, file structures, or code patterns. Those belong to `/dev-workflow` Phase 2 (plan).
- **No initiative docs.** Discovery does NOT write to `docs/initiatives/<slug>/`. That's `/dev-workflow` Phase 2's job (per Story).
- **No code, no tests, no commits to the product repo.** Discovery only writes to GitHub via `gh` and (optionally) writes a local-only tracker stub at `ai/discoveries/<slug>.md` for session resume.
- **Tree depth**: Epic → Feature → Story only. Do NOT create Tasks at discovery time — Tasks are created by `/dev-workflow` Phase 2 from the approved plan.
- **Surface labels**: every Story title MUST carry a `[service]` / `[web]` / `[mobile]` / `[cross-cutting]` prefix (or combination), and every Story Issue carries a matching `surface:<surface>` label. If unsure, ask via `AskUserQuestion` in D2.
- **One Epic per cohesive capability.** Multiple Epics only if the idea genuinely spans separate capability surfaces (e.g. "Order processing" is one Epic; "Order processing + Subscription billing" is two).
- **Sub-command semantics**:
  - `explore` ends at "DONE EXPLORING"; writes tracker stub.
  - `decompose` reads tracker stub, produces tree, allocates E/F/S numbers, waits at GATE for APPROVED, persists approved tree to stub.
  - `create` reads approved tree from stub, writes to GitHub (issues + sub-issues + Project board), updates stub with `#N`.
  - `extend <epic-or-feature-#>` runs D2 → D3 in a sub-scope, attaches new items to the existing parent.

## Orchestration

Discovery is **planner-only** — no developer, reviewer, or tester. The planner agent runs in `discovery` mode:
- D1: invokes `brainstorming` + `grill-me` + `grill-with-docs` as supporting skills.
- D2: composes the tree per `skills/github-rendering/SKILL.md` (uses `gh issue list` / `gh search issues` to mirror the repo's existing item style; no writes).
- D3: GitHub writes only (`gh issue create`, `gh api graphql`, `gh project`).

The orchestrator (`dev-workflow`'s heavyweight coordinator) is NOT used here — discovery is light enough that the main session drives it.

## Tracker stub format (`ai/discoveries/<slug>.md`)

Local-only, git-ignored. The **source of truth** — survives session interruptions, and keeps holding the tree even when individual GitHub writes fail.

```markdown
# Discovery: <slug>

- Date started: <ISO timestamp>
- Phase: <D1-explore | D2-decompose | D3-create | DONE>
- Status: <in-progress | awaiting-approval | created-in-github>

## Idea
<the raw idea + context captured in D1>

## Shape (output of D1)
- Users: <who>
- Value: <why>
- Success criteria: <how we'll know>
- Scope: <in / out>
- Affected surfaces: <service / web / mobile / cross-cutting>
- NFR hints: <perf, security, accessibility, etc.>

## Proposed tree (D2)
<Markdown tree, before approval — carries allocated E/F/S numbers + slugs>

## Approved tree (D2 gate)
<Markdown tree, after APPROVED — per-item content + human-id→slug + dependency map>

## GitHub issues (D3)
- E1 → #<N>: <title> — <url>
  - F1.1 → #<N>: <title> — <url>
    - S1.1.1 → #<N>: <title> — <url>
```

## Next workflows

After `/discovery-workflow` creates the tree:
1. For each Story that needs deeper definition before development: `/backlog-workflow improve <story-#>` (or `refine`, `enrich`, `analyze`).
2. When a Story is ready for implementation: `/dev-workflow <story-#>` runs the full 10-phase build (its Tasks are created in Phase 2).
