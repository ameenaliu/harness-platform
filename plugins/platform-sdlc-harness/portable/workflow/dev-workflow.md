# platform-dev-workflow — orchestrated SDLC for one GitHub Story

Drive a GitHub Story issue from requirements to a reviewed PR through **10 phases**, **3 human gates**, and **3 holistic review checkpoints**, delegating each phase to a specialized role. Run as the **orchestrator** (see the orchestrator role for full coordination rules). All GitHub operations use the `gh` CLI (`gh issue`, `gh pr`, `gh project`, `gh api`, `gh api graphql`) — there is no MCP server.

**Usage**: `<command> <story-issue-number>` where command ∈ `requirements | plan | develop | pre-test-review | test | pre-pr-review | pr | pr-review` (or run the whole pipeline). Always read the workspace config (`.claude/context/platform-context.md`) and the task tracker (`ai/tasks/*<story-issue-number>*.md`) before acting; resume from recorded state.

## Phase 1 — Requirements
Sync the monorepo to the integration branch (default `develop`). Spawn the **planner** to pull the Story (`gh issue view`), identify the parent Feature via the sub-issue link (for linking / board grouping / PR-body `Part of #` context — NOT branch routing), identify affected Surfaces (`[<surface>]` title prefix + `surface:*` label), and surface clarifying questions; relay the human's answers back. No code. Ensure the Story's Project **Status** is at least `Ready` (set via `gh project item-edit` if it is in `Backlog`/`No Status`).

## Phase 2 — Plan → GATE #1
Spawn the **planner** to propose 2–3 approaches; the human selects one. The planner decomposes into Surface-tagged tasks with `[<surface>]` title prefixes, decides the branch strategy (single-branch model — one user branch off `develop`, regardless of the parent Feature), writes `docs/initiatives/<slug>/execution-plan.md` + the runtime tracker, and synchronises `work-units.md` + `test-plan.md`.

Then, as orchestrator:
- Create the Task **Issues** (`gh issue create` with `type:task` + `surface:<surface>` labels and Markdown bodies per `github-rendering`), attach each as a **sub-issue** of the Story (`gh api graphql addSubIssue`; fallback `Parent: #<story>` body line), add each to the org Project (`gh project item-add`) with its Surface field set, and add the `platform-sdlc-harness` label to the Story.
- **Cut ONE user branch** off freshly-pulled `develop` (single-branch model — no feature branch; branch names from `platform-context.md`, defaults shown):
  - Story: `users/<user-slug>/<impl-slug>`.
  - Bug: `users/<user-slug>/bugs/<impl-slug>`.
- Commit **all four initiative docs** (`README.md`, `spec.md`, `test-plan.md`, `work-units.md`) plus `execution-plan.md` on the user branch as the first commit with `docs(initiative): add execution plan for <Story title>`.
- Set the Story's Project **Status** `Ready` → `In Progress`.

**GATE #1**: present the plan; require `APPROVED` before any code.

## Phase 3 — Develop
For each task in dependency order (sequential):
- next ⏳ task → 🔧 In Progress → set the Task issue's Project Status → `In Progress` + assignee (first activation) → spawn **developer** (pass plan rows, Surface tag).
- spawn **per-task reviewer** on the diff (Phase 0 pre-check → Phase A spec → Phase B quality).
- APPROVED → integrate the task worktree into the user branch with `git merge --no-ff` if worktree is enabled (preserve task commits — never `--squash`; nothing to integrate when worktree is disabled, commits already land on the user branch) → ✅ Done, record commit hashes; set the Task issue's Project Status → `In Review`. CHANGES_REQUESTED → relay `[S<n>]`/`[R<n>]` to the developer; repeat.

Never start the next task before the current one is approved. Multi-surface tasks load multiple conventions skills in the developer agent.

## Phase 4 — Holistic Pre-Test Review
Spawn the **reviewer** in `holistic-pre-test` mode with diff range `<base-branch>..<user-branch>`. Reviewer audits the full diff vs base + every acceptance criterion on the Story. Output is `INFORMATIONAL` — appended to tracker `Phase 4 Holistic Review` section. No state changes.

## Phase 5 — Approval → GATE #2
Present the implementation summary + Phase 4 findings to the human. Require `APPROVED` before tests. If the human wants Phase 3 rework, loop back with their comments.

## Phase 6 — Test
For each affected Surface with a `T-TEST-<surface>` task: set the Task issue's Project Status → `In Progress` → spawn the **tester** for that surface (`SERVICE` ≥ 80%, `WEB` ≥ 70%, `MOBILE` ≥ 85% coverage on new/modified code). Then spawn the **per-task reviewer** (Phase 6 mode) for that test commit. APPROVED → set the Task issue's Project Status → `In Review`. CHANGES_REQUESTED → relay comments, tester retries.

## Phase 7 — Holistic Pre-PR Review
Spawn the **reviewer** in `holistic-pre-pr` mode with diff range `<base-branch>..<user-branch>` (now includes test commits). Confirms spec compliance + acceptance criteria + test coverage. Output is `INFORMATIONAL` — appended to tracker `Phase 7 Holistic Review`.

## Phase 8 — Architecture & Rules Reconciliation
Spawn the **planner** in `architecture-audit` mode with the full diff range. Planner reads `.claude/architecture/<area>/<surface>.md`, `.claude/rules/<surface>/{code-style,testing}.md`, and `.claude/CLAUDE.md` in the repo, compares against the diff, and proposes updates wherever architecture, rules, or top-level capability has changed materially. Human approves each proposed update via `AskUserQuestion`. Approved updates are written and committed on the user branch as `docs(architecture):` / `docs(rules):` commits so they land in the same PR as the implementation. **INFORMATIONAL — never blocks.** If no updates needed, the planner returns `Proposed updates: none` and the phase completes immediately. See `commands/architecture-reconciliation.md`.

## Phase 9 — PR Creation → GATE #3
Present the per-surface summary + Phase 4 + Phase 7 review reports. **GATE #3**: require `APPROVED`. Then:
- Push the user branch to origin.
- Create the PR via `gh pr create --base develop --head <user-branch>`: base is always `develop`.
- Title format: a Conventional Commit summary (e.g. `feat(mobile,service): <Story title>`).
- Body: link to initiative docs, summary of changes per Surface, and `Closes #<story>` + a `Closes #<task>` for EVERY Task (all auto-close on merge into `develop`), plus ONE `Part of #<feature>` link to the parent Feature (which stays open).
- Set each Task issue's Project Status → `In Review`. Post a tracker-summary comment on the Story (`gh issue comment`).
- Set reviewers via `gh pr edit --add-reviewer` from `platform-context.md` (or rely on CODEOWNERS).
- Record the PR number + URL in the tracker header.

## Phase 10 — Post-PR Review
Spawn the **reviewer** in `holistic-post-pr` mode with `<pr-number>`. Reviewer audits the open PR's diff (`gh pr diff`), posts inline comments via `gh api repos/{owner}/{repo}/pulls/<n>/comments`, then posts a summary review via `gh pr review <n> --comment`. **Comment-only — never blocks the PR.** Append comment IDs to tracker `Phase 10 PR Review`. The harness's job is now done; on merge into `develop` the Story + all Tasks auto-close via `Closes #` (requires `develop` to be the GitHub default branch — verified at init-workspace) and the Project's "Item closed → Done" workflow moves them to Done automatically. The parent Feature stays open.

## Invariants

- Three gates are mandatory; never auto-advance past one.
- Three holistic reviews (4, 7, 10) are mandatory but informational — they shape decisions at gates, they don't gate by themselves.
- The tracker (`ai/tasks/*`) is local runtime state — never committed.
- Every commit builds cleanly; the reviewer verifies builds independently.
- The approved plan is the single source of truth.
- Phase 10 never blocks the PR — comment-only.
- Issues auto-close on PR merge into `develop` via `Closes #` (develop must be the GitHub default branch); the Project's "Item closed → Done" workflow then moves them to Done automatically. The parent Feature stays open.
