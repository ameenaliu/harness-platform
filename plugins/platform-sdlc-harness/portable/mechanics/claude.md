<!-- mechanics: claude — Claude Code operational detail for each role.
     This is the SINGLE SOURCE for everything Claude-specific. The plugin's agent files
     (agents/platform-sdlc-*.md) are thin: they read their portable/roles/<name>.md body plus
     the relevant section below at startup and follow both. Paths are plugin-root-relative
     (same convention the agents already use for skills/ and agents/shared/). -->

## Mechanics — Claude Code

### Common to all roles
- **Paths are plugin-root-relative** — read each surface's pack `conventions_skill` at `skills/<conventions_skill>/SKILL.md` (resolved via `packs/registry.json`), `agents/shared/engineering-principles.md`, and `portable/roles/<name>.md` directly.
- **Conventions loading** — as your first action, resolve each `Surface` the orchestrator passed to its **stack pack**: read the surface's stack from `.claude/context/platform-context.md`, look it up in `packs/registry.json` → `packs/<stack>/pack.json`, and read that pack's `conventions_skill` (e.g. `dotnet`→`dotnet-conventions`, `go`→`go-conventions`, `react-turbo`→`react-turbo-conventions`, `expo`→`expo-mobile-conventions`). Multi-surface tasks resolve multiple packs.
- **Pre-flight** — before any work, read ALL tracker files in `ai/tasks/` matching the current Story issue number to learn what's done, prior reviewer feedback, and where to resume.
- **Status block** — end every response with the `📋 AGENT STATUS` block from your role body; the orchestrator parses it (a Stop hook backstops a missing block).

### Orchestrator (the dev-workflow skill main thread)
- **Delegation** via the Agent/Task tool. The repo is a single monorepo so phases are sequential — `run_in_background` is NOT used.
- Read `.claude/context/platform-context.md` → `Repo`, GitHub `Org` / `Repo` / `Project number`, branch names, and the `Worktree: enabled | disabled` flag; pass them in each agent's REPO CONTEXT block.
- **Worktree merge**: after a per-task reviewer APPROVES a worktree task, integrate the worktree commits into the user branch with `git merge --no-ff` (preserve the task's commits — never `--squash`). Skip when `Worktree: disabled` (commits land directly on the user branch). The `develop` history granularity is governed by the **PR Merge Method** (`platform-context.md`), not here.
- **GitHub sync** via the `gh` CLI (`gh issue`, `gh pr`, `gh project`, `gh api`, `gh api graphql`) — there is no MCP server. `gh` must be authenticated (`repo`, `project`, `read:org` scopes). Org / repo / project number / Status field options from `platform-context.md`; never hardcode org/repo or state literals. Best-effort: on failure emit `⚠️ GitHub sync failed at <step>: <error>. Continuing workflow.` and proceed.
- **Task issue creation**: `gh issue create --title "[<surface>] ..." --label type:task --label surface:<surface> --body "..."` (Markdown body per `github-rendering`), then attach as a sub-issue of the Story via `gh api graphql addSubIssue` (fallback: `type:task` label + `Parent: #<story>` body line). Add to the Project (`gh project item-add`) and set the Surface + Status fields (`gh project item-edit`).
- **PR creation** via `gh pr create --base develop --head <user-branch> --title "..." --body "..."` (base is always `develop`): title from the tracker (a Conventional Commit summary), body from the Suggested PR Description in the Phase 7 review report and carrying `Closes #<story>` + a `Closes #<task>` for EVERY Task (all auto-close on merge into `develop`) + ONE `Part of #<feature>` link to the parent Feature (stays open). Set reviewers via `gh pr edit --add-reviewer`.
- **Subagent file-op errors**: after any planner invocation, scan for `⚠️ FILE OPERATION FAILED` / `⚠️ FILE OPERATION BLOCKED`; correct the path and re-invoke, or pause and report to the human.
- Full GitHub sync points and tracker-update transition table live in `skills/dev-workflow/context/orchestrator-rules.md`.

### Planner
- **Write with the `Write`/`Edit` tools only** — never `Bash` (`echo`/`cat`/`tee`/heredocs). After every write, verify by reading the file back; retry once on failure, then report.
- **Allowed write paths**: `docs/initiatives/<slug>/{execution-plan.md,work-units.md,test-plan.md,spec.md,README.md}` (committed initiative docs) and `ai/tasks/<YYYY-MM-DD>_<story-issue-number>_<slug>.md` (local tracker, never committed). Do not write elsewhere.
- **Locate the initiative folder** by grepping `README.md` files under `docs/initiatives/` for the Story issue number; create the folder from a kebab-case slug if absent.
- **Parent Feature lookup** — `gh api graphql` `issue(number:N){ parent { number title } }` (native sub-issue) or, in fallback mode, read the `Parent: #<n>` body line / Project Parent field. Record the parent's number + title for sub-issue linking, board grouping, and the PR-body `Part of #<feature>` link — NOT for branch routing (single-branch model).
- GitHub reads via the `gh` CLI (`gh issue view`, `gh api`, `gh api graphql`).
- On any file error report `⚠️ FILE OPERATION FAILED` with operation, target path, error, and action taken — never swallow it.

### Developer
- **Worktree isolation** (when `Worktree: enabled` — typically SERVICE; WEB/MOBILE may have Husky hooks that prefer working from the main checkout): create a worktree off the user branch with a collision-safe 8-char id, then work entirely inside it.
  ```bash
  UID8=$(uuidgen 2>/dev/null \
         || python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null \
         || python  -c "import uuid; print(uuid.uuid4())" 2>/dev/null \
         || printf '%s%s' "$(date +%s)" "$RANDOM")
  UID8=$(printf '%s' "$UID8" | tr '[:upper:]' '[:lower:]' | tail -c 8)
  WORKTREE_BRANCH="worktree/<story-issue-number>-t<n>-${UID8}"
  WORKTREE_PATH="<REPO_PATH>/../worktrees/<repo>-t<n>"
  git -C "<REPO_PATH>" worktree add "$WORKTREE_PATH" -b "$WORKTREE_BRANCH" "<user-branch>"
  ```
- **WEB/MOBILE cache forwarding** (after creating the worktree, to avoid a 10-min install): copy `.yarn`, `node_modules`, `.pnp.cjs`, `.pnp.loader.mjs` (Yarn) or `node_modules`, `.pnpm-store` (pnpm) from `<REPO_PATH>` into `$WORKTREE_PATH`. Do NOT run `yarn`/`pnpm install` unless a build fails on missing deps.
- Commits go to the **worktree branch** with Conventional Commits (`<type>(<surface>): <description>`); the orchestrator integrates them into the user branch via `git merge --no-ff` after review approval (multiple commits per task are fine — they are preserved, never squashed).
- **Git error fallback**: if worktree creation fails (e.g. `could not lock config file .git/config: File exists` on Windows, or Husky errors on first commit), report `Worktree: failed (<error>)` and `Next action: "worktree failed — retry without isolation"`; the orchestrator re-invokes you to work directly on the user branch.
- **When `Worktree: disabled`**: do NOT create a worktree; `cd "<REPO_PATH>"` and commit directly on the user branch, one commit per task. Report `Worktree: not used (disabled by repo config)`.
- Tooling fields in your STATUS block (`Surface(s)`, `Worktree`, `Worktree branch`, `Commit(s)`) are required — the orchestrator uses them to route the reviewer and to integrate the worktree (`git merge --no-ff`).

### Reviewer
- **Per-task / holistic modes (Phases 3, 4, 6, 7)**: `disallowedTools: Write, Edit` enforces read-only on source code. You cannot modify any file, including the tracker. The orchestrator updates the tracker from your verdict.
- **Phase 10 mode**: you may run `gh` PR comment commands (`gh api repos/{owner}/{repo}/pulls/<n>/comments` for inline comments + `gh pr review <n> --comment` for the summary). **These are the only writes you ever perform**, and they only happen in Phase 10. Code writes remain disallowed (`disallowedTools: Write, Edit` stays in effect; `gh` runs via Bash).
- Inspect changes at the **worktree path** the orchestrator passed (or the repo's user branch if no worktree). All reads and builds happen there, not the orchestrator's CWD.
- Read the execution plan at `docs/initiatives/<slug>/execution-plan.md`.
- **Phase 0 enforcement note**: of the five pre-checks, only `sensitive-file-guard.sh` runs as a write-time hook. The `ai/` write rule, Conventional-Commits format, `[<surface>]` title prefix rule, and emoji-shortcode rule have **no** hook backstop — Phase 0 must catch every violation.
- **Holistic mode diff range**: when the orchestrator passes `holistic-pre-test` or `holistic-pre-pr`, run `git -C "<REPO_PATH>" diff <base-branch>...<user-branch>` to get the full diff. Audit the entire range, not per-task.
- **Phase 10 PR mode**: input is `<pr-number>`. Pull PR data via `gh pr view <pr-number> --json ...`, fetch local branches via `git fetch origin`, then `gh pr diff <pr-number>`. After review, post inline comments via `gh api repos/{owner}/{repo}/pulls/<pr-number>/comments` (per finding, with `path` + `line` + `side` + `commit_id`=PR head SHA) and a summary via `gh pr review <pr-number> --comment`. Record every returned comment ID in your status block.

### Tester
- Same worktree setup as the Developer when `Worktree: enabled`, including cache forwarding for WEB/MOBILE. SERVICE on `Worktree: disabled` mode: `cd "<REPO_PATH>"` and commit on the user branch directly.
- Activation: confirm every dev task (T1, T2, …) is ✅ Done AND the tracker's `Phase 4 Holistic Review` section has GATE #2 sign-off before writing tests; if not, notify the orchestrator and stop.
- Commits use `test(<surface>): <description>` Conventional Commits — never reference issue IDs in commit messages.
