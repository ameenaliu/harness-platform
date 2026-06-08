# Extend: add Features or Stories to an existing Epic/Feature

**Command**: `/discovery-workflow extend <epic-#-or-feature-#>`
**Actor**: Planner agent in `discovery` mode
**Phase**: runs D2 + D3 on a sub-tree

## When to use

- An Epic exists in GitHub and you want to add more Features (or more Stories under an existing Feature).
- Hindsight-driven additions after the initial `/discovery-workflow` completed.
- Avoids touching the original tree or re-doing discovery from scratch.

## Prerequisites

- The `<epic-#-or-feature-#>` is a real GitHub issue (verify with `gh issue view <#>`).
- The target issue must be typed `type:epic` or `type:feature` (check its labels). Story issues are rejected — use `/backlog-workflow` to refine an existing Story; use this command to add siblings under a parent.
- `.claude/context/platform-context.md` present (`Org`, `Repo`, project number/owner). Read every config value from it — never hardcode.

All GitHub writes are **best-effort** — warn clearly on failure and continue.

## Steps

1. **Verify the parent**. Read `Org` / `Repo` from `platform-context.md`, then:
   ```bash
   gh issue view <#> --repo "<org>/<repo>" --json number,title,labels,body
   ```
   Reject if the labels don't include `type:epic` or `type:feature`. Extract the parent's title prefix (`E<e>` if Epic, `F<e>.<f>` if Feature) — needed for step 4 to allocate new IDs in the right scope.

2. **Pull existing siblings + extract used IDs**. List the parent's current children to avoid duplicates and to allocate the next free number. Prefer the native sub-issue read; fall back to label/search:
   ```bash
   # Native sub-issues:
   gh api graphql -f query='
     query($owner:String!, $repo:String!, $num:Int!) {
       repository(owner:$owner, name:$repo) {
         issue(number:$num) { subIssues(first:50) { nodes { number title } } }
       }
     }' -F owner="<org>" -F repo="<repo>" -F num=<#>
   # Fallback (sub-issues unavailable): search by title prefix
   gh issue list --repo "<org>/<repo>" --label type:feature --search "in:title F<e>." --json number,title   # children of an Epic
   gh issue list --repo "<org>/<repo>" --label type:story   --search "in:title S<e>.<f>." --json number,title # children of a Feature
   ```
   - If parent is `E<e>`: parse child Feature titles for `F<e>.<f>` prefixes; record the set of used `<f>` integers.
   - If parent is `F<e>.<f>`: parse child Story titles for `S<e>.<f>.<s>` prefixes; record the set of used `<s>` integers.
   - Also note any existing `Blocked by:` / `Blocks:` lines on the siblings — useful context for step 4 when proposing new items that depend on existing ones.
   Display siblings as read-only context so the planner doesn't duplicate.

3. **Mini-explore** (lightweight D1): ask the human what they want to add and why. 1-2 question batches max via `AskUserQuestion` — this isn't full discovery, it's an addition. Confirm the surface(s) for any new Story.

4. **Propose sub-tree** (D2-style):
   - If parent is an Epic → propose new Features (each with their own Stories). Allocate Feature IDs starting at `max(existing <f>) + 1`. **Never re-use a gap** — gaps from deleted items are intentional, like JIRA issue keys.
   - If parent is a Feature → propose new Stories only. Allocate Story IDs starting at `max(existing <s>) + 1`.
   - Use the full prefix on every new item title (`F<e>.<f>: <title>` or `S<e>.<f>.<s>: [<surface>] <title>`).
   - Compose the rich per-item bodies per `skills/github-rendering/SKILL.md` (§Feature structure or §Story structure, in full), with **no AI/Claude attribution footer** (hard rule).
   - If new items depend on existing siblings (or existing siblings would now depend on the new items), capture those dependencies — same `blocked by <slug-or-#>` convention as decompose Step 5.
   - Render as a Markdown tree under the existing parent. Show existing siblings (read-only context) + new items (proposed, with their new IDs).

5. **Present** via `AskUserQuestion`: `APPROVED` / `EDIT` / `CANCEL`. Iterate on EDIT until APPROVED.

6. **Create on APPROVED** (D3-style — all `gh`, best-effort):
   - `gh issue create` for each new item with the same shape as the full `create` command (fully-prefixed title per the allocated ID, `type:*` label, `surface:*` on Stories, rich Markdown `--body-file` per `github-rendering`). Capture each `#N`.
   - **Sub-issue link** each new item to the existing parent via `gh api graphql addSubIssue` (resolve node IDs with `gh issue view <#> --json id -q .id`). On failure, switch to fallback: `Parent: #<parent-#>` body line + Project **Parent** field.
   - **Add to the Project board** (`gh project item-add`) and set **Status** = `Backlog` + **Surface**.
   - **Patch** the parent's "… in this Epic/Feature" checklist (`gh issue edit`) to list the new children as `- [ ] #<child-#> (<human-id> <title>)`.
   - For any captured dependency (new ↔ existing OR new ↔ new): create the **native "Blocked by" relationship** — `p_id=$(gh api "repos/<org>/<repo>/issues/<blocker-#>" --jq '.id')` then `gh api --method POST "repos/<org>/<repo>/issues/<dependent-#>/dependencies/blocked_by" -F issue_id="$p_id"` — per `github-rendering` § Dependency convention (label/body fallback only on older GitHub Enterprise).
   - Log + continue on any per-write failure.

7. **Tracker stub**: if a discovery tracker stub exists for the parent's discovery (locate by searching `ai/discoveries/*.md` for the parent `#N`), **append** the new items to its `## GitHub issues (D3)` section. If no stub exists (parent was created manually or by another tool), don't create one — extend is for GitHub additions, not for re-doing the discovery record.

8. **Output**: short tree summary listing the parent + new items only (human-id → #N → URL, with their new full-prefix titles).

## Rules

- **No restructuring of existing items.** Extend can only ADD. Editing an existing Epic/Feature/Story is the responsibility of `/backlog-workflow refine` (for Stories) or manual GitHub edits (for Epics/Features).
- **Hierarchical numbering prefix rule** (`E<e>` / `F<e>.<f>` / `S<e>.<f>.<s>`) and the **`[Surface]` prefix rule** apply to any new item. See `skills/github-rendering/SKILL.md` § Title numbering scheme.
- **Allocate IDs from `max(existing) + 1`**. Never re-use a gap. Sticky IDs are the contract.
- **No Tasks created.** Tasks are dev-workflow Phase 2 only.
- **Status block** the planner ends with:
  ```
  📋 AGENT STATUS
  - Agent: planner
  - Mode: discovery
  - Phase: extend
  - Parent: #<#> (<type>)
  - Created: <N Features, M Stories>
  - Outcome: <SUCCESS | PARTIAL | FAILED>
  - Next action: <"refine new Stories via /backlog-workflow" | "re-run after fix">
  ```
