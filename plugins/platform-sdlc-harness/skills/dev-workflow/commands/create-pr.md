# Phase 9: PR Creation → GATE #3

**Phase**: 9
**Actor**: Orchestrator, then Human gate, then Orchestrator (PR creation)

## Prerequisites

- Phase 7 complete — `Phase 7 Holistic Review` section populated in tracker.
- All dev + test tasks ✅ Done.
- User branch pushed to origin (was pushed at end of Phase 2).
- `Suggested PR Description` captured from Phase 7 reviewer.

## GATE #3 — Present and Wait

Present a summary to the human:

```
Ready to open PR:
  Source branch: users/<slug>/<impl>          (or users/<slug>/bugs/<impl>)
  Target branch: develop
  Title: <type>(<surface>): <conventional-commit summary>
  Closes: #<story-number>, #<task1>, #<task2>, …   (auto-close on merge into develop)
  Part of: #<feature> (parent Feature — stays open)
  Merge Method: <PR Merge Method from platform-context.md — merge | squash | rebase>
  Reviewers: <from platform-context.md Reviewers, matched by Affected Surfaces>

Phase 4 findings: X CRITICAL, Y WARNING, Z SUGGESTION
Phase 7 findings: A CRITICAL, B WARNING, C SUGGESTION
(See ai/tasks/<tracker> for full text.)

Suggested PR Description:
<paste the Phase 7 reviewer's Suggested PR Description>
```

The human performs the merge (or runs `gh pr merge --<method>` with the configured **PR Merge Method**). The merge method affects only the commit history on `develop` — it does **NOT** affect issue closing, which is driven by the `Closes #` keywords in the PR description, not by commits.

Wait for explicit `APPROVED` reply. If the human requests changes to the title/description/reviewers, accept and re-present. If the human wants to fix something in code first, loop back to Phase 3 with their notes.

## Open the PR

On `APPROVED`:

1. Push the latest commit (a no-op if nothing new since Phase 2 push):
   ```bash
   git -C <repo-path> push origin <user-branch>
   ```
   (Prompts for confirmation — `git push` is intentionally NOT pre-approved in `settings.local.json`.)

2. **Build the PR body file** — start from the Phase 7 Suggested PR Description, then append the GitHub linking trailer. Because the PR base is `develop` (the repo default branch), GitHub's closing keywords fire on merge: emit `Closes #<story>` AND `Closes #<task>` for EVERY task, so the Story and all its Tasks auto-close on merge. Add ONE `Part of #<feature>` line linking the parent Feature for context — do **not** `Closes` the Feature (a Feature has multiple stories; it stays open):
   ```markdown
   <Phase 7 Suggested PR Description, or human-edited version>

   ---

   Closes #<story-number>
   Closes #<task1>
   Closes #<task2>
   …

   Part of #<feature>
   ```
   (Omit the `Part of #<feature>` line if the Story has no parent Feature.) Write this to a temp file (e.g. `ai/tasks/.pr-body-<story>.md`, uncommitted). **Never add an AI/Claude attribution line** (no `🤖 Generated with Claude Code`, no `Co-Authored-By: Claude/Anthropic`) to the PR body — hard rule, blocked by `attribution-guard`.

3. **Create the PR** via `gh pr create`:
   ```bash
   gh pr create \
     --repo <owner>/<repo> \
     --base <base-branch> \
     --head <user-branch> \
     --title "<type>(<surface>): <conventional-commit summary>" \
     --body-file ai/tasks/.pr-body-<story>.md
   ```
   `gh pr create` prints the PR URL. Capture the PR **number** and **URL**:
   ```bash
   pr_url=$(gh pr view --repo <owner>/<repo> <user-branch> --json url -q .url)
   pr_number=$(gh pr view --repo <owner>/<repo> <user-branch> --json number -q .number)
   ```

4. **Add reviewers** — matched to Affected Surfaces from `platform-context.md` `Reviewers` (individual handles or `org/team` slugs):
   ```bash
   gh pr edit <pr_number> --repo <owner>/<repo> --add-reviewer <handle-or-team> [--add-reviewer …]
   ```
   Best-effort; warn on failure.

5. **Flip every Task's Project Status → `In Review`** (no-op if Phase 3/6 already did). For each distinct Task issue # in the tracker:
   ```bash
   item_id=$(gh project item-add <project-number> --owner <owner> \
     --url "$(gh issue view <task-number> --json url -q .url)" --format json -q .id)
   gh project item-edit --project-id <project-id> --id "$item_id" \
     --field-id <status-field-id> --single-select-option-id <in-review-option-id>
   ```
   (No effort / scheduling fields — GitHub has none. The `Closes #` links handle issue closure automatically on merge into `develop`; the Project "Item closed → Done" workflow then moves them to **Status: Done**.)

6. **Post a tracker-summary comment on the Story**:
   ```bash
   gh issue comment <story-number> --repo <owner>/<repo> --body-file - <<'EOF'
   PR opened: <pr_url>
   Tasks completed: <count> (#<id>, #<id>, …)
   Tests written: <count> for surfaces <list>
   Phase 4 findings: X/Y/Z. Phase 7 findings: A/B/C.
   EOF
   ```

7. **Record PR in tracker header**:
   ```markdown
   - PR #: <pr_number>
   - PR URL: <pr_url>
   - PR created: <ISO timestamp>
   ```

## Next

Proceed to Phase 10 (`post-pr-review`) — the post-PR holistic review with GitHub comment posting.

## Notes

- `git push` confirmation is intentional — see `settings.local.json`. If you're sure, type `y` at the prompt.
- The Story + Tasks **close automatically** when the PR merges into `develop` (via the `Closes #` lines). This requires `develop` to be the repo's **GitHub default branch** — GitHub only fires closing keywords when they reach the default branch (init-workspace verifies this). The parent **Feature** is linked via `Part of #` and stays open. The move to Project **Status: Done** is handled automatically by the Project's "Item closed → Done" workflow (configured at init-workspace), not manually.
