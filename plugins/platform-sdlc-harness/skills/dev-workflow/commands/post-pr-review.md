# Phase 10: Post-PR Review

**Phase**: 10
**Actor**: Reviewer agent in `holistic-post-pr` mode (orchestrator coordinates)

## Prerequisites

- Phase 9 complete — PR exists on GitHub, number + URL recorded in tracker.

## Delegate to the Reviewer

Spawn `@platform-sdlc-reviewer` with:

- `Mode: holistic-post-pr`
- `PR #: <pr_number>`
- `Repository: <owner>/<repo>`
- `Direction`: Pull the PR via `gh pr view <pr_number> --json …` and the diff via `gh pr diff <pr_number>` (or `git fetch origin && git diff <target>...<source>`). Run Phase 0 → Phase A → Phase B at the full PR-diff scope. For each `[S<n>]`/`[R<n>]` finding, post an **inline** PR review comment:
  ```bash
  gh api repos/<owner>/<repo>/pulls/<pr_number>/comments \
    -f body='<finding text>' \
    -f commit_id="$(gh pr view <pr_number> --json headRefOid -q .headRefOid)" \
    -f path='<file path>' \
    -F line=<line> -f side=RIGHT
  # (for a multi-line range add -F start_line=<n> -f start_side=RIGHT;
  #  for removed code use side=LEFT)
  ```
  Capture each returned comment `id`. Then post **one summary review** at PR root listing counts, top themes, and a pointer to the inline threads:
  ```bash
  gh pr review <pr_number> --repo <owner>/<repo> --comment \
    --body-file <summary.md>
  ```

**Phase 10 is comment-only. Never blocks the PR — verdict is always `INFORMATIONAL`.** (Use `--comment`, never `--request-changes` / `--approve`.)

## Orchestrator Post-Reviewer Steps

After the reviewer returns:

1. Extract `Review comments` + `PR comment IDs` from the status block.
2. **Append findings + comment IDs to tracker** under `## Phase 10 PR Review`:
   ```markdown
   ## Phase 10 PR Review (YYYY-MM-DDTHH:MM:SSZ)

   Reviewer outcome: <SUCCESS | FAILED>

   PR: #<pr_number> <pr_url>

   Inline comment IDs posted: <list of integer IDs returned by gh api .../comments>

   Inline comments:
   [R1] ... → comment <id>
   [R2] ... → comment <id>
   ...

   Summary review: <summary review submitted via gh pr review --comment>
   ```
3. **No further GitHub state changes.** The PR is open; resolution is the human's + assigned reviewers' responsibility. The Story + Tasks close automatically on merge via the `Closes #` links; the final Project **Status: Done** move is **manual** post-merge.

## Workflow Complete

Phase 10 ends the dev-workflow. Present a closing summary to the human:

```
Workflow complete for Story #<number>.
PR: <pr_url>
Phase 4 findings: X/Y/Z
Phase 7 findings: A/B/C
Phase 10 comments posted: N inline + 1 summary

The PR is ready for human + team review. On merge, the Story and Tasks close
automatically (Closes #). Move them to Project Status "Done" if your board
workflow doesn't do it on close — the harness does not auto-complete.
```

## Standalone Mode

This command is also callable standalone on any existing PR (not just ones created by the dev-workflow):

```
/dev-workflow post-pr-review <pr-number>   # or use the top-level /pr-review <pr-number>
```

In standalone mode, skip the tracker-update step (tracker may not exist) — the local report at `.claude/pr-reviews/PR-<number>-<YYYY-MM-DD>.md` is the only persistent artefact.
