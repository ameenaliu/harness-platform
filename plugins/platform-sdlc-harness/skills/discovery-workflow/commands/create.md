# Phase D3: Create in GitHub

**Phase**: D3
**Actor**: Planner agent in `discovery` mode

## Prerequisites

- `ai/discoveries/<slug>.md` exists with `## Approved Tree (D2 gate)` section populated.
- `gh` CLI authenticated with `repo` + `project` + `read:org` scopes (verify with `gh auth status`).
- `.claude/context/platform-context.md` present with `Org`, `Repo`, project number/owner, and user slug.

All GitHub writes are **best-effort** — warn clearly on any failure and continue.
The local discovery draft (`ai/discoveries/<slug>.md`) stays the **source of truth**;
any item whose `#N` never resolves is recorded as `[FAILED]` and skipped by downstream
wiring. Read every config value (`Org`, `Repo`, project number/owner) from
`platform-context.md` — never hardcode an org or repo.

## Steps

1. **Read the approved tree** from `ai/discoveries/<slug>.md`, and `Org` / `Repo` / project number/owner from `.claude/context/platform-context.md`. Define a `log()` helper that emits `⚠️` warnings to the console and appends to the tracker stub.

2. **Sanity check** before any write (regexes from `skills/github-rendering/SKILL.md` § Title-prefix validation):
   - Every Epic title matches `^E\d+:\s+\S` (e.g. `E1: Disease Detection v1`).
   - Every Feature title matches `^F\d+\.\d+:\s+\S` (e.g. `F1.2: Inference + result UI`).
   - Every Story title matches `^S\d+\.\d+\.\d+:\s+\[(service|web|mobile|cross-cutting)\](\[(service|web|mobile|cross-cutting)\])*\s+\S` (e.g. `S1.2.3: [mobile] Result display screen`).
   - Hierarchical numbering is consistent: every `F<e>.*` lives under `E<e>`; every `S<e>.<f>.*` lives under `F<e>.<f>`.
   - Every Feature has at least one Story; every Story has a parent Feature; every Feature has a parent Epic.
   If any check fails, surface the violations and ask the human whether to fix in D2 (`/discovery-workflow decompose <slug>`) or proceed anyway. Default: fix in D2.

3. **Compose each item's Markdown body** per `skills/github-rendering/SKILL.md` (§Epic / §Feature / §Story structure). GitHub is Markdown-native — no HTML conversion. Build all bodies up-front in memory, keyed by human-id, so the create pass is pure `gh` posting. Cross-reference lists ("Features in this Epic", "Stories in this Feature") use `#(TBD)` placeholders that get patched in step 6 once each child has its real `#N`. Every body carries **no AI/Claude attribution footer** — hard rule (`attribution-guard` blocks `🤖 Generated with Claude Code` / `Co-Authored-By: Claude`).

4. **Create issues, top-down** (`gh issue create`), building a `human-id → #N` map as you go. Create the Epic first, then its Features, then each Feature's Stories. Capture the returned issue number and URL from `gh issue create --json number,url` (or parse the URL it prints). Write each `#N` back into the tracker stub immediately so a crash mid-run is resumable.

   - **Epic**:
     ```bash
     gh issue create --repo "<org>/<repo>" \
       --title "E<e>: <Epic title>" \
       --label "type:epic" \
       --body-file <epic-body.md>
     ```
   - **Feature** (per Epic):
     ```bash
     gh issue create --repo "<org>/<repo>" \
       --title "F<e>.<f>: <Feature title>" \
       --label "type:feature" \
       --body-file <feature-body.md>
     ```
   - **Story** (per Feature) — carries the surface label too:
     ```bash
     gh issue create --repo "<org>/<repo>" \
       --title "S<e>.<f>.<s>: [<surface>] <Story title>" \
       --label "type:story" --label "surface:<surface>" \
       --body-file <story-body.md>
     ```
     For multi-surface Stories, pass one `--label surface:<surface>` per surface.
   - Capture `#N` for each. On any single create failure: `log("⚠️ create failed for <human-id> <title>: <error>")`, mark `[FAILED]` in the stub, and continue with the rest. **Exception**: if the Epic create fails, stop (usually an auth/permissions problem, not a data one) and surface to the human.

5. **Wire sub-issues, bottom-up** (native sub-issues via GraphQL). Attach each Story to its parent Feature, then each Feature to its parent Epic. Resolve node IDs with `gh issue view <n> --json id -q .id`, then call `addSubIssue` per `skills/github-rendering/SKILL.md` § Sub-issue linking protocol:
   ```bash
   parent_id=$(gh issue view <parent-#> --repo "<org>/<repo>" --json id -q .id)
   child_id=$(gh issue view <child-#>  --repo "<org>/<repo>" --json id -q .id)
   gh api graphql -f query='
     mutation($parent:ID!, $child:ID!) {
       addSubIssue(input:{issueId:$parent, subIssueId:$child}) {
         issue { number } subIssue { number }
       }
     }' -f parent="$parent_id" -f child="$child_id"
   ```
   **Detect support once**: try `addSubIssue` on the first link. If it errors (feature not enabled), `log()` that sub-issues are unavailable and switch the whole run to **fallback** — never silently flatten:
   1. Add a `Parent: #<parent-#>` line at the top of the child body (`gh issue edit <child-#> --body-file …`), and ensure the parent's "… in this Epic/Feature" checklist already lists `- [ ] #<child-#>` (patched in step 6).
   2. Set the **Parent** field on the Project board (step 7).

   Per-link failures are non-blocking: `log("⚠️ sub-issue link failed <child-#> → <parent-#>: <error>")` and continue.

6. **Patch cross-reference placeholders**. The bodies from step 3 carried `#(TBD)` in their child checklists. Now that every child has its `#N`, `gh issue edit <parent-#> --body-file <patched-body.md>` to replace each `#(TBD)` with the real `#<child-#> (<human-id> <title>)` form. Epic + Feature only (Stories don't list children).

7. **Add every issue to the Project board and set fields** (per `skills/github-rendering/SKILL.md` § Project (v2) board membership + fields). **Every Epic/Feature/Story MUST land on the board** — an issue that exists only in the repo Issues tab is a defect, not an acceptable degraded outcome.

   **7a — Pre-check the `project` scope (do this before the loop).** Board writes need the `project` token scope; a missing scope is the #1 reason issues land in the repo but never on the board. Run `gh auth status` and confirm the printed scopes include `project` (and `read:org`). If `project` is missing, **stop** and tell the human: `"GitHub board sync needs the project scope. Run: gh auth refresh -s project,read:org — then re-run /discovery-workflow create <slug>."` Do not run the loop without it.

   **7b — Add + set fields per issue:**
   ```bash
   gh project item-add <project-number> --owner "<project-owner>" --url "<issue-url>"
   ```
   Then set fields via `gh project item-edit` (resolve field + option IDs once with `gh project field-list <project-number> --owner "<project-owner>" --format json`):
   - **Status** = `Backlog` — on every Epic / Feature / Story.
   - **Surface** = the item's surface — on Stories (and Features where a single surface applies). Epics span surfaces; leave Surface unset.
   - **Parent** = parent issue — **only** when native sub-issues were unavailable (fallback path from step 5); otherwise the sub-issue link populates Parent automatically.

   **7c — Failure policy (not silent best-effort):**
   - A **single** item's add/edit failing → `log("⚠️ project add/edit failed for #<n>: <error>")` and continue (transient).
   - **Every** add failing (systemic — scope/permission/wrong project number) → **stop** and surface loudly: `"❌ Project board sync is failing for all items — likely a missing project scope or wrong project number/owner in platform-context.md. Issues were created in the repo but are NOT on the board. Fix and re-run create (it will append, not duplicate)."` Do not finish the run reporting success.
   - **7d — Verify membership** after the loop: `gh project item-list <project-number> --owner "<project-owner>" --format json` and confirm every created `#N` is present. Report the on-board count vs created count in the summary; any missing item is listed explicitly.

8. **Write dependency links as native "Blocked by" relationships** (per `skills/github-rendering/SKILL.md` § Dependency convention). Walk the approved tree's `Blocked by` entries (Feature→Feature and Story→Story). For each `<dependent>` blocked by `<blocker>`:
   - Resolve both ends via the `human-id → #N` map.
   - Resolve the **blocker's REST database id** (integer, not `#number`): `blocker_id=$(gh api "repos/<org>/<repo>/issues/<blocker-#>" --jq '.id')`.
   - Create the native relationship (the reciprocal "Blocking" side is automatic — no mirror call):
     ```bash
     gh api --method POST \
       "repos/<org>/<repo>/issues/<dependent-#>/dependencies/blocked_by" \
       -F issue_id="$blocker_id"
     ```
   - Do **not** write a `Blocked by:` body line or add the `blocked` label in the happy path — the native relationship is the source of truth and is what shows on the board.
   - **Detect support once**: on the first dependency, if the endpoint 404s/422s (native dependencies not on this GitHub Enterprise), `log()` it and switch the whole run to the **fallback** for the rest: append `Blocked by: #<blocker-#> (<human-id> <title>)` under `## Implementation dependencies` in the dependent body + add the `blocked` label.
   - **Failure policy**: per-link failures are non-blocking — log + continue, record `[LINK FAILED: <a> → <b>: <error>]` in the stub.

9. **Post a discovery-summary comment on every Epic** (`gh issue comment <epic-#> --body …`):
   ```
   Created by `/discovery-workflow` from idea: "<idea title>"
   Features: <count>; Stories: <count>; Implementation dependencies: <link-count>
   Next step: refine each Story via `/backlog-workflow improve <#>`, then implement via `/dev-workflow <#>`.
   ```

10. **Update the tracker stub** with a `## GitHub issues (D3)` section listing every created item with its `#N` + URL, the resolved `human-id → #N` map, and an `## Implementation dependency links` subsection listing every link (blocked-by → blocks + status). Set `Phase: D3-DONE`, `Status: created-in-github`.

11. **Output to the human** — a clean mapping table + tree summary:
   ```
   Created in <org>/<repo> (https://github.com/<org>/<repo>):

   | Human ID  | Issue | Title                          | URL |
   |-----------|-------|--------------------------------|-----|
   | E1        | #<N>  | <title>                        | <url> |
   | F1.1      | #<N>  | <title>                        | <url> |
   | S1.1.1    | #<N>  | [surface] <title>              | <url> |
   | …         | …     | …                              | …   |

   Tree:
   E1 #<N>: <title>
     F1.1 #<N>: <title>
       S1.1.1 #<N>: [surface] <title>
       S1.1.2 #<N>: [surface] <title>
     F1.2 #<N>: <title>
       …

   Total: <N Epics, M Features, K Stories>.  Failed: <count, or "none">.
   On Project board: <X>/<Y> items (Project #<number>).  Native "Blocked by" links: <count>.
   Slug saved at: ai/discoveries/<slug>.md

   Next steps:
     • Refine each Story:    `/backlog-workflow improve <#>`
     • Implement when ready: `/dev-workflow <#>`
   ```

## Error policy

- **Best-effort, non-blocking.** Every GitHub write can fail without aborting the run — `log()` a clear `⚠️` warning and continue. The local discovery draft remains the source of truth.
- **Best-effort per item.** If `gh issue create` fails for a single Feature or Story, mark it `[FAILED]` in the stub and continue with the rest. Don't abandon the whole tree.
- **On Epic creation failure**: stop. An Epic failure usually means an auth or permissions issue, not a data issue. Surface to the human; suggest re-trying with `/discovery-workflow create <slug>` after the underlying issue is fixed.
- **Sub-issue / Project / dependency failures**: the issue itself is still created. Log the failure as a warning; the human can fix in the GitHub UI or via a follow-up `gh api graphql` / `gh project` call. If native sub-issues are unavailable, switch the whole run to the fallback (Parent body line + Project Parent field).

## Rules

- **D3 is the only place where discovery writes to GitHub.** D1 and D2 do not.
- **Idempotency hint**: if the tracker stub's `## GitHub issues (D3)` section is already populated, ask the human before re-running: "Tree was created at <timestamp>. Re-create from scratch (duplicates risk!) / append new items only / cancel?"
- **No Tasks created here.** Tasks come from `/dev-workflow` Phase 2 per Story.
- **Status block** the planner ends with:
  ```
  📋 AGENT STATUS
  - Agent: planner
  - Mode: discovery
  - Phase: D3-create
  - Slug: <slug>
  - Created: <N Epics, M Features, K Stories>
  - On Project board: <X>/<Y> (Project #<number>)
  - Native "Blocked by" links: <count> (or "fallback: body+label" if native API unavailable)
  - Failed: <count, or "none">
  - Outcome: <SUCCESS | PARTIAL (some items failed) | FAILED>
  - Next action: <"hand off to /backlog-workflow" | "re-run create after fix" | "human review failures">
  ```
