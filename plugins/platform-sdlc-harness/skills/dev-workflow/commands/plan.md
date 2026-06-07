# Phase 2: Planning & Approval → GATE #1

**Phase**: 2
**Actor**: Planner agent, then Orchestrator, then Human gate

## Prerequisites

- Phase 1 complete — requirements confirmed by the Planner, including the **Parent Feature** finding from the Story's sub-issue link.
- `platform-context.md` accessible.

## Delegate to the Planner

Spawn `@platform-sdlc-planner` with:

- Story issue number + Phase 1 outputs (Parent Feature, Affected Surfaces)
- Direction:
  1. Propose 2–3 architectural approaches; ask the human to select one via `AskUserQuestion`.
  2. Decompose into ordered atomic tasks with `[<Surface>]`-prefixed titles, intra-order dependencies, complexity (S/M/L). Create one `T-TEST-<Surface>` per affected Surface.
  3. Decide **branch strategy** from the Parent Feature finding (branch names from `platform-context.md`; defaults `main`/`develop`):
     - Parent Feature exists → base `features/<feature-slug>/main`, user branch `users/<user-slug>/<feature-slug>/<impl-slug>`, PR target = `features/<feature-slug>/main`.
     - No Parent Feature OR issue type = `Bug` → user branch `users/<user-slug>/bugs/<impl-slug>`, PR target = `develop`.
  4. Produce Mermaid diagrams (class, sequence, flow).
  5. Write `docs/initiatives/<slug>/execution-plan.md` + `work-units.md` + `test-plan.md` (kebab-case slug from the Story title).
  6. Create the runtime tracker at `ai/tasks/<YYYY-MM-DD>_<story-number>_<slug>.md` with task table (incl. an `Issue #` column), Branch Strategy section, empty `Phase 4 Holistic Review` / `Phase 7 Holistic Review` / `Phase 10 PR Review` sections.

## Orchestrator Post-Planner Steps

Once the planner returns `SUCCESS`. All GitHub writes are best-effort — warn on failure, continue with the local tracker as source of truth. Resolve Project field/option node IDs once via `gh project field-list <project-number> --owner <owner> --format json` and cache them.

1. **Create Task issues** — for each task row in the tracker, create a GitHub Issue whose body matches the `task.yml` shape (see `skills/github-rendering/SKILL.md` → Task structure):
   ```bash
   gh issue create \
     --title "[<Surface>] <task-title>" \
     --body-file <task-body.md> \
     --label type:task --label surface:<surface> \
     --repo <owner>/<repo>
   ```
   No Area Path / Iteration Path / custom fields. Record each returned `#N` in the tracker's `Issue #` column.

2. **Attach each Task as a sub-issue of the Story**:
   ```bash
   parent_id=$(gh issue view <story-number> --json id -q .id)
   child_id=$(gh issue view <task-number> --json id -q .id)
   gh api graphql -f query='
     mutation($parent:ID!, $child:ID!) {
       addSubIssue(input:{issueId:$parent, subIssueId:$child}) { subIssue { number } }
     }' -f parent="$parent_id" -f child="$child_id"
   ```
   Fallback if `addSubIssue` is unavailable: add a `Parent: #<story>` line to the Task body and set the Project **Parent** field. Detect support on the first link; if it fails, switch the whole run to fallback and log it — never silently flatten.

3. **Add each Task to the Project board + set Surface**:
   ```bash
   item_id=$(gh project item-add <project-number> --owner <owner> \
     --url "$(gh issue view <task-number> --json url -q .url)" --format json -q .id)
   gh project item-edit --project-id <project-id> --id "$item_id" \
     --field-id <surface-field-id> --single-select-option-id <surface-option-id>
   ```

4. **Label + activate the Story**:
   ```bash
   gh issue edit <story-number> --add-label platform-sdlc-harness
   ```
   Then set the Story's Project **Status** → `In Progress` (first activation only):
   ```bash
   story_item=$(gh project item-add <project-number> --owner <owner> \
     --url "$(gh issue view <story-number> --json url -q .url)" --format json -q .id)
   gh project item-edit --project-id <project-id> --id "$story_item" \
     --field-id <status-field-id> --single-select-option-id <in-progress-option-id>
   ```

5. **Cut branches** per the chosen strategy:
   - If parent Feature exists and `features/<feature-slug>/main` doesn't exist on origin: cut it off the freshly-pulled integration branch (`develop`), push.
   - Cut the user branch off the chosen base.
   - Push the user branch to origin so the PR has somewhere to point later.

6. **Commit the initiative docs** on the user branch:
   ```bash
   git add docs/initiatives/<slug>/
   git commit -m "docs(initiative): add execution plan for <Story title>"
   git push -u origin <user-branch>
   ```
   (The `docs(initiative): ...` commit subject matches Conventional Commits; the user branch is now ready for development.)

## GATE #1 — Present the Plan and Wait

Present a summary to the human:
- Story title + `#<number>` + Parent Feature
- Affected Surfaces
- Selected approach + 1-line rationale
- Task count + brief listing (`Issue #`, `[<Surface>]` prefix, title, complexity)
- Branch strategy (base + user branch)
- Initiative docs committed as `<commit-hash>`

Wait for explicit `APPROVED` reply. If the human requests changes, re-invoke the planner with their notes, then re-present. **No code before approval.**

## Next

On `APPROVED`, proceed to Phase 3 (`develop`).
