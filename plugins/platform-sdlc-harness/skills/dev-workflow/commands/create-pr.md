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
  Source branch: users/<slug>/<feat>/<impl>  (or users/<slug>/bugs/<impl>)
  Target branch: features/<feat>/main         (or develop)
  Title: <type>(<surface>): <conventional-commit summary>
  Closes: #<story-number>
  Part of / Closes Tasks: #<task1>, #<task2>, …
  Reviewers: <from platform-context.md Reviewers, matched by Affected Surfaces>

Phase 4 findings: X CRITICAL, Y WARNING, Z SUGGESTION
Phase 7 findings: A CRITICAL, B WARNING, C SUGGESTION
(See ai/tasks/<tracker> for full text.)

Suggested PR Description:
<paste the Phase 7 reviewer's Suggested PR Description>
```

Wait for explicit `APPROVED` reply. If the human requests changes to the title/description/reviewers, accept and re-present. If the human wants to fix something in code first, loop back to Phase 3 with their notes.

## Open the PR

On `APPROVED`:

1. Push the latest commit (a no-op if nothing new since Phase 2 push):
   ```bash
   git -C <repo-path> push origin <user-branch>
   ```
   (Prompts for confirmation — `git push` is intentionally NOT pre-approved in `settings.local.json`.)

2. **Build the PR body file** — start from the Phase 7 Suggested PR Description, then append the GitHub linking trailer. `Closes #<story>` auto-closes the Story on merge; each Task gets a `Part of #<task>` line (or `Closes #<task>` to auto-close the Task too):
   ```markdown
   <Phase 7 Suggested PR Description, or human-edited version>

   ---

   Closes #<story-number>

   Part of #<task1>
   Part of #<task2>
   …

   🤖 Generated with [Claude Code](https://claude.ai/claude-code)
   ```
   Write this to a temp file (e.g. `ai/tasks/.pr-body-<story>.md`, uncommitted).

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
   (No effort / scheduling fields — GitHub has none. The `Closes #` links handle issue closure on merge.)

6. **Post a tracker-summary comment on the Story**:
   ```bash
   gh issue comment <story-number> --repo <owner>/<repo> --body-file - <<'EOF'
   PR opened: <pr_url>
   Tasks completed: <count> (#<id>, #<id>, …)
   Tests written: <count> for surfaces <list>
   Phase 4 findings: X/Y/Z. Phase 7 findings: A/B/C.

   🤖 Generated with [Claude Code](https://claude.ai/claude-code)
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
- The Story + Tasks **close automatically** when the PR merges (via the `Closes #` lines). The final move to Project **Status: Done** is post-merge — the harness never auto-completes the board.
