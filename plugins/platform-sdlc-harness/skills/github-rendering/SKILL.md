---
name: github-rendering
description: >
  Single source of truth for how work-item content is rendered into GitHub —
  canonical Markdown structures for Epic / Feature / Story / Task issue bodies
  (aligned with the repo's issue-form templates), the hierarchical numbering
  scheme (E1 / F1.1 / S1.1.1), the sub-issue linking protocol via the gh CLI /
  GraphQL API, the Project (v2) board field conventions, and the Blocked-by /
  Blocks dependency convention. Used by /discovery-workflow (decompose + create),
  /backlog-workflow (improve / refine / enrich), and /dev-workflow Phase 2 task
  creation so every write to GitHub follows one consistent shape.
disable-model-invocation: true
user-invocable: true
---

# GitHub Rendering & Dependency Protocol

GitHub Issues are **Markdown-native** — no HTML conversion is needed (unlike Azure DevOps). Every issue this harness creates must look native and well-formed: structured headings, checklists for acceptance criteria, explicit parent/child and dependency links — not skeletal one-liners. This skill defines the canonical shape for every write.

## The four structural levels

| Level | Source | `type:` label | Issue type (if org-enabled) | Body shape |
|---|---|---|---|---|
| Epic | discovery decompose | `type:epic` | Epic | §Epic structure |
| Feature | discovery decompose / extend | `type:feature` | Feature | §Feature structure |
| Story | discovery decompose / backlog-improve / refine | `type:story` | Story / User Story | §Story structure (matches `story.yml`) |
| Task | dev-workflow Phase 2 | `type:task` | Task | §Task structure (matches `task.yml`) |
| Bug | discovery / dev | `type:bug` | Bug | matches `bug.yml` |

Every issue also carries a **`surface:<service|web|mobile|cross-cutting>`** label and is added to the org **Project (v2)** board with its **Surface** and **Status** fields set.

## Title numbering scheme (mandatory on every Epic, Feature, Story)

Every issue title MUST carry a hierarchical numbering prefix so the parent–child structure is visible directly on the Project board, in search results, and in PR titles that reference the item — without expanding the sub-issue panel. GitHub also assigns a native `#N` issue number; the human-meaningful E/F/S prefix is **in addition to** `#N`.

| Type | Format | Example |
|---|---|---|
| Epic | `E<e>: <title>` | `E1: Disease Detection v1` |
| Feature | `F<e>.<f>: <title>` | `F1.2: Inference + result UI` |
| Story | `S<e>.<f>.<s>: [<Surface>] <title>` | `S1.2.3: [mobile] Result display screen` |
| Task | `[<Surface>] <title>` (no number — Tasks are leaf sub-issues of a Story) | `[mobile] Wire result API call` |

Where:
- `<e>` = 1-based Epic index in the discovery (E1, E2, E3 …).
- `<f>` = 1-based Feature index within its parent Epic (F1.1, F1.2 … F2.1 …).
- `<s>` = 1-based Story index within its parent Feature (S1.2.1, S1.2.2 …).
- `<Surface>` = `service` / `web` / `mobile` / `cross-cutting` (combos allowed, e.g. `[service][mobile]`) — the Story's affected surface, matching the issue-form **Surface** dropdown.

**Rules**:
- **1-based, sticky**. Once assigned at discovery time, a number never changes — not even if siblings are reordered, renamed, or deleted. Deletion leaves a gap, never a renumber.
- **Scope-local**. Two Epics can each have an `F1.1`; collisions are rare since discovery typically produces a single Epic. When using `/discovery-workflow extend`, walk the Epic's existing Feature numbers (`gh issue list --label type:feature --search "in:title F<e>."`) and pick the next unused integer.
- **Title-prefix validation regex** (used by the reviewer Phase 0 + discovery sanity check):
  - Epic: `^E\d+:\s+\S`
  - Feature: `^F\d+\.\d+:\s+\S`
  - Story: `^S\d+\.\d+\.\d+:\s+\[(service|web|mobile|cross-cutting)\](\[(service|web|mobile|cross-cutting)\])*\s+\S`
- **Cross-references** in bodies (e.g. an Epic's "Features in this Epic" list, a Story's "Implementation dependencies") use the form `#<N> (<human-id> <title>)` — e.g. `#42 (F1.1 Insights Foundation)` — so readers can find the item by GitHub number OR by the E/F/S label.

### Index allocation at discovery time

During `/discovery-workflow decompose`, before composing item content, allocate every E/F/S number across the whole proposed tree so they are stable before any `gh issue create` runs. Record the mapping (human-id → planned title) in the discovery draft so `create` can wire sub-issues after the issues get their `#N`.

## Epic structure (issue body, Markdown)

```markdown
## Value
<1–2 sentences: the outcome this Epic delivers and for whom.>

## Success criteria
- [ ] <measurable outcome>
- [ ] <measurable outcome>

## Features in this Epic
- [ ] #<N> (F1.1 <title>)
- [ ] #<N> (F1.2 <title>)

## Out of scope
- <explicitly excluded>
```
Labels: `type:epic`. No Surface (Epics span surfaces). Added to Project with Status `Backlog`.

## Feature structure (issue body, Markdown)

```markdown
## Intent
<what capability this Feature adds, and why now.>

## Stories in this Feature
- [ ] #<N> (S1.1.1 [surface] <title>)
- [ ] #<N> (S1.1.2 [surface] <title>)

## Acceptance / done
- [ ] <feature-level done condition>

## Notes / links
<design-doc references, dependencies, open questions>
```
Labels: `type:feature`. Parent: Epic (sub-issue). Surface optional.

## Story structure (issue body — MUST match `story.yml` fields)

```markdown
## Story
As a <role>, I want <capability>, so that <benefit>.

## Acceptance criteria
- [ ] <Given / When / Then, or done condition>
- [ ] <…>

## Surface
<service | web | mobile | cross-cutting>

## Notes / links
<design-doc references, dependencies, open questions>
```
Labels: `type:story`, `surface:<surface>`. Parent: Feature (sub-issue). Project Status `Backlog`→`Ready` when refined.

## Task structure (issue body — MUST match `task.yml` fields)

```markdown
## Task
<concise technical description of the unit of work.>

## Surface
<service | web | mobile | cross-cutting | ci/infra>

## Definition of done
- [ ] <done condition>
```
Labels: `type:task`, `surface:<surface>`. Parent: Story (sub-issue). Created by dev-workflow Phase 2.

## Sub-issue linking protocol (the hierarchy mechanism)

GitHub sub-issues create the Epic→Feature→Story→Task tree. Prefer the **native sub-issue API**; degrade gracefully if the org/repo doesn't have it enabled.

### Primary: native sub-issues via GraphQL

```bash
# 1. Resolve the parent + child issue node IDs (GraphQL global IDs)
parent_id=$(gh issue view <parent-number> --json id -q .id)
child_id=$(gh issue view <child-number> --json id -q .id)

# 2. Attach child as a sub-issue of parent
gh api graphql -f query='
  mutation($parent:ID!, $child:ID!) {
    addSubIssue(input:{issueId:$parent, subIssueId:$child}) {
      issue { number }
      subIssue { number }
    }
  }' -f parent="$parent_id" -f child="$child_id"
```

To read children: `gh api graphql` with `issue(number:N){ subIssues(first:50){ nodes { number title } } }`.

> **Sub-issues ARE the native Parent relationship.** A sub-issue link is what populates the **Parent / Sub-issues** relationship panel on the issue and the **Parent** column on the Project board. Do **not** also write a `Parent: #n` body line in the happy path — the native link is the relationship. The body line is only a fallback (below).

### Fallback: when sub-issues are unavailable

If `addSubIssue` errors (feature not enabled, e.g. older GitHub Enterprise), record the relationship two ways so nothing is lost:
1. Add a `Parent: #<parent-number>` line at the top of the child body, and a checklist entry `- [ ] #<child>` under the parent's "… in this Epic/Feature" section.
2. Set the **Parent** field on the Project board (single-select / text) so the board still shows the tree.

Detect support once per run (try `addSubIssue` on the first link; if it fails, switch the whole run to fallback and `log()` that sub-issues were unavailable — never silently flatten).

## Dependency convention (native "Blocked by" relationships)

GitHub has **native issue dependencies** (GA August 2025): typed **Blocked by** / **Blocking** relationships that render in the issue's relationship panel and on the Project board. **Use the native relationship as the primary mechanism — not a `blocked` label and not a body link.** The label/body form is a fallback only.

### Primary: native dependency via the REST API

The blocker is identified by its **integer database `id`** (the `.id` field of the REST issue object) — **not** its `#number`, and **not** the GraphQL node id.

```bash
# 1. Resolve the BLOCKER's REST database id (an integer)
blocker_id=$(gh api "repos/<org>/<repo>/issues/<blocker-number>" --jq '.id')

# 2. Mark <dependent> as "blocked by" <blocker>. The reciprocal "Blocking" side
#    is created automatically — there is no mirror call to make.
gh api --method POST \
  "repos/<org>/<repo>/issues/<dependent-number>/dependencies/blocked_by" \
  -F issue_id="$blocker_id"
```

Read / remove:
- What an issue is blocked by: `gh api "repos/<org>/<repo>/issues/<n>/dependencies/blocked_by"`
- What an issue is blocking:   `gh api "repos/<org>/<repo>/issues/<n>/dependencies/blocking"`
- Remove a dependency:         `gh api --method DELETE "repos/<org>/<repo>/issues/<n>/dependencies/blocked_by/<blocker_id>"`

Do **not** add a `Blocked by:` body line or the `blocked` label in the happy path — the native relationship is the source of truth and is what the user sees on the board.

### Fallback: only if the native dependency API is unavailable

If the `dependencies/blocked_by` endpoint returns 404/422 (feature not present on this GitHub Enterprise version), degrade — never silently drop the dependency:
- In the **dependent** body under `## Implementation dependencies`: `Blocked by: #<n> (<human-id> <title>)` (mirror `Blocks:` on the blocker optional).
- Add the `blocked` label for board filtering.
Detect once per run (try the native call on the first dependency; on failure switch the run to fallback and `log()` it).

`/backlog-workflow` maintains these native relationships (adds/removes `blocked_by`) as scope changes — never leave a stale dependency.

## Project (v2) board membership + fields

**Every Epic/Feature/Story/Task MUST be added to the org Project (v2) board** — creating the issue in the repo is not enough; an issue that exists only in the repo Issues tab and not on the board is a defect, not an acceptable degraded state. Add it, then set its fields:

```bash
# Add to the board (returns the project item id)
gh project item-add <project-number> --owner "<project-owner>" --url "<issue-url>"
```

```bash
# Set fields via gh project item-edit (resolve field + option ids once with
# `gh project field-list <project-number> --owner "<project-owner>" --format json`)
```

| Field | Values | Set when |
|---|---|---|
| **Status** | `Backlog → Ready → In Progress → In Review → Done` | lifecycle transitions (see orchestrator-rules) |
| **Surface** | `service / web / mobile / cross-cutting` | at creation |
| **Iteration** | (optional) sprint window | at planning, if used |
| **Parent** | parent issue | only when native sub-issues unavailable (otherwise the sub-issue link populates Parent automatically) |

The project number/owner is read from `.claude/context/platform-context.md` (recorded by `/init-workspace`).

### Board-add requires the `project` token scope

`gh project item-add` / `item-edit` need the **`project`** scope on the `gh` token (and, for an org project, org-level project permission). This is the **most common reason issues land in the repo but never on the board.** Before a create/sync run that writes to the board, verify:

```bash
gh auth status        # the printed token scopes must include `project` (and `read:org`)
```

If `project` is missing, stop and instruct: `gh auth refresh -s project,read:org`. Do not treat a board-add failure that affects **every** item as a per-item warning — that is a systemic scope/permission problem; surface it loudly and stop so the human can fix the token, then re-run. (Per-item transient failures remain best-effort.) A known GitHub incident can also make `item-add` succeed but not persist — if items report added yet don't appear, re-run after verifying scope, then check the GitHub status page.

## Attribution

Every issue body and issue comment the harness writes ends with:
```
🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```
