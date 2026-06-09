# platform-pr-review — holistic PR review with `gh` comment posting

Review the **full diff** of an open GitHub Pull Request and post inline + summary comments back to the PR. This is the standalone form of Phase 10 of the dev workflow — callable on any PR, including ones not created by `platform-dev-workflow`. Read-only on source; the only writes are PR comments via the `gh` CLI (no MCP server).

**Usage**: `<pr-number>` (the numeric PR number from `https://github.com/<org>/<repo>/pull/<n>`)

## Steps

1. **Pull the PR** via `gh pr view <pr-number> --json number,title,body,headRefName,baseRefName,files,headRefOid` to get title, body, source/target branches, and the head SHA.
2. **Resolve the local repo path** from `.claude/context/platform-context.md`.
3. **Gather the diff**: `gh pr diff <pr-number>` (or `git -C <repo-path> diff <base>...<head>` after `git fetch origin`).
4. **Identify affected Surfaces** from the diff paths: `service/...` → SERVICE, `web/...` → WEB, `mobile/...` → MOBILE.
5. **Read conventions** for every affected Surface plus the engineering principles.
6. **Build & test verification** — run the build and the test suite yourself:
   - SERVICE: `dotnet build <solution>` (zero warnings) + `dotnet test`.
   - WEB: `yarn turbo lint typecheck build test --filter=...<affected-app>`.
   - MOBILE: `yarn tsc:build && yarn lint && yarn test:coverage:check`.
   Never trust prior CI green — re-run.
7. **Evaluate the whole change set holistically** — not per task: cohesion across all commits, no leftover scaffolding, consistent naming, no cross-commit duplication, the linked Story's acceptance criteria met end-to-end, security, and git hygiene (branch naming matches `^users/[a-z0-9_]+/(bugs/)?[a-z0-9-]+$`, PR base `develop`, Conventional Commits with surface scope, no issue IDs in commits, `Closes #<story>` present in the PR body, no build-breaking commits).
8. **Produce inline comments** via `gh api repos/{owner}/{repo}/pulls/<pr-number>/comments` for each `[S<n>]` (spec) and `[R<n>]` (quality) finding. Set `path`, `line`, `side: RIGHT` (or `side: LEFT` + `start_line` for findings on removed code), and `commit_id` = the PR head SHA.
9. **Produce a summary review** via `gh pr review <pr-number> --comment --body "..."` with: count of CRITICAL / WARNING / SUGGESTION, top themes, build/test/coverage results, links to each inline comment.
10. **Output a local report** for the human's reference at `.claude/pr-reviews/PR-<pr-number>-<YYYY-MM-DD>.md` with verdict, all comments inline, and a **Suggested PR Description** block.

## Rules

- **Comment-only — never blocks the PR.** Even CRITICAL findings result in `SUCCESS` outcome; the human + reviewers decide resolution.
- Strictly read-only on source code; the only writes are PR comments and the local report.
- One PR review per call; multi-PR audits run this skill repeatedly.
- Coverage thresholds when commenting on test coverage: SERVICE ≥ 80%, WEB ≥ 70%, MOBILE ≥ 85% on new/modified code.
- If the PR has no Surface indication in the title and the diff spans multiple surfaces, flag this as a SUGGESTION (not blocking) in the summary comment.
