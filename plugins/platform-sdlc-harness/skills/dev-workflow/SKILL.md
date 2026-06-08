---
name: dev-workflow
description: >
  Master orchestrator for the AI-driven development workflow. Use when
  starting a new Story implementation. Coordinates the Planner, Developer,
  Reviewer, and Tester agents through 10 phases with 3 human approval gates and
  3 holistic review checkpoints (pre-test, pre-PR, post-PR). Single-monorepo
  scope — sequential execution. Runs on GitHub Issues + Projects (v2) via the
  `gh` CLI (no MCP server).
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
argument-hint: "[command] <story-issue-number>"
---

# AI-Driven Development Workflow

## Workflow Overview

This skill orchestrates a multi-agent development workflow for GitHub **Story** issues on a single in-scope monorepo (SERVICE under `service/` + WEB under `web/` + MOBILE under `mobile/`). Four specialized agents (Planner, Developer, Reviewer, Tester) are coordinated through **10 phases with 3 human approval gates and 3 holistic review checkpoints**.

Work tracking is GitHub-native: **Issues** typed by `type:*` label, wired into the **Epic → Feature → Story → Task** tree via native **sub-issues** (`gh api graphql`), grouped on an org **Project (v2)** board where a single-select **Status** field (`Backlog → Ready → In Progress → In Review → Done`) drives the lifecycle. Every remote operation uses the `gh` CLI / `gh api graphql` — there is no MCP server.

### Workflow Phases

1. **Requirements** — Planner pulls the Story issue, identifies the parent **Feature** via the sub-issue link (drives branch routing), identifies affected **Surfaces** from the title prefix, asks clarifying questions, and (optionally) drafts the four initiative MD files under `docs/initiatives/<slug>/`. Ensures the Story's Project **Status** is at least `Ready`.
2. **Plan** — Planner proposes 2–3 approaches, human selects one. Planner writes `docs/initiatives/<slug>/execution-plan.md` and syncs `work-units.md` + `test-plan.md`; creates the local runtime tracker at `ai/tasks/*.md`. Orchestrator creates **Task issues** (`gh issue create` with `type:task` + `surface:*` labels), attaches each as a **sub-issue** of the Story (`gh api graphql addSubIssue`), adds each to the Project board with its **Surface** field set, cuts branches per the parent-Feature finding, commits the initiative docs, adds the `platform-sdlc-harness` label to the Story, and sets the Story's Status → `In Progress`. **— GATE #1**
3. **Develop** — Per-task developer + per-task reviewer loop on the monorepo (**sequential**). Orchestrator squash-merges on approval; sets each Task's Project Status `In Progress → In Review`.
4. **Pre-Test Review** — Reviewer in `holistic-pre-test` mode audits the full diff (`<base>..<user-branch>`) vs every acceptance criterion. Findings appended to tracker `Phase 4 Holistic Review`. Informational — no state changes.
5. **Approval** — Human reads Phase 4 findings + summary. **— GATE #2** before testing.
6. **Test** — Tester writes tests per affected Surface, meeting each surface's pack `coverage_threshold` on new/modified code (resolved from `packs/<stack>/pack.json` — e.g. `dotnet`/`go` 80, `react-turbo` 70, `expo` 85), per-task reviewer reviews each.
7. **Pre-PR Review** — Reviewer in `holistic-pre-pr` mode audits full diff incl tests. Findings appended to tracker `Phase 7 Holistic Review`.
8. **Architecture & Rules Reconciliation** — Planner in `architecture-audit` mode reads `.claude/architecture/*.md` + `.claude/rules/*/*.md` in the repo, diffs against the implementation, proposes doc updates, gets human approval, commits approved updates on the user branch as `docs(architecture):` / `docs(rules):`. INFORMATIONAL — never blocks.
9. **PR Creation** — Orchestrator pushes the branch, opens one PR via `gh pr create`, with a body carrying `Closes #<story>` (auto-closes the Story on merge) + per-Task `Part of #<task>` links, sets reviewers via `gh pr edit --add-reviewer`, flips each Task's Project Status → `In Review`, and posts a tracker-summary comment on the Story. **— GATE #3** before opening.
10. **PR Review** — Reviewer in `holistic-post-pr` mode posts inline + summary comments to the GitHub PR via `gh api` review comments / `gh pr review`. **Comment-only — never blocks the PR.** Tracker records comment IDs.

### Critical Ownership Rules

- The **Orchestrator** (you) is the sole owner of the task tracker. Update status after every agent verdict. The tracker stays **uncommitted**, ever.
- The **Developer** commits production code only (no tracker, no tests). Uses Conventional Commits `<type>(<surface>): <description>` with NO issue ID.
- The **Reviewer** is strictly read-only for source — NEVER writes or edits any source file. In Phase 10 only, may post PR comments via `gh` (inline review comments + one summary). Returns its report to the orchestrator.
- The **Tester** commits test code only with `test(<surface>): <description>` Conventional Commits.

### Phase 3 Execution Order (NON-NEGOTIABLE)

**Within the monorepo (Sequential):**
1. Update tracker: T(n) → In Progress; set the Task issue's Project Status → `In Progress`.
2. Developer implements T(n) in worktree, commits code only with `<type>(<surface>): <desc>`.
3. Update tracker: T(n) → In Review.
4. Reviewer (per-task mode) reviews worktree diff, returns verdict.
5. Handle verdict:
   - APPROVED → `git merge --squash`, tracker → Done, set Task issue's Project Status → `In Review`, clean up worktree.
   - CHANGES_REQUESTED → relay `[S<n>]`/`[R<n>]` comments to Developer, fix in SAME worktree, repeat from step 3.

**NEVER start T(n+1) before Reviewer approves T(n).**
**NEVER squash-merge a worktree before Reviewer approves it.**
**NEVER have the Reviewer write or edit any source file.**

### Legal Tracker Status Transitions

```
⏳ Pending       → 🔧 In Progress
🔧 In Progress   → 🔄 In Review
🔄 In Review     → ✅ Done           (reviewer approved)
🔄 In Review     → 🔧 In Progress    (changes requested)
✅ Done           → 🔧 In Progress    (rework)
```

### Non-Negotiable Rules

- Show a brief plan before taking action on any task. Wait for approval before executing.
- All commits: `<type>(<surface>): <imperative lowercase description>` — Conventional Commits, NO issue ID in commit line. `<type>` ∈ `feat | fix | chore | refactor | perf | docs | ci | test | build`. `<surface>` ∈ `service | web | mobile` (comma-separated for multi-surface). GitHub linking happens in the **PR body** via `Closes #<n>`, never in commits.
- All branches follow the two-tier model: user branch is `users/<user-slug>/<feature-slug>/<impl-slug>` (Story with parent Feature) or `users/<user-slug>/bugs/<impl-slug>` (Bug or no parent Feature). PR targets `features/<feature-slug>/main` or `develop` respectively. Branch names are parameterized in `platform-context.md` (defaults `main`/`develop`). See `commands/plan.md`.
- Each surface's pack `build_gate` must pass at all times — resolved from `packs/<stack>/pack.json` (e.g. `dotnet` → `dotnet build` zero warnings; `go` → `go build ./...` + `golangci-lint run` clean; `react-turbo` → `yarn turbo lint typecheck build`; `expo` → `yarn tsc:build && yarn lint && yarn test`).
- Coverage thresholds come from each surface's pack `coverage_threshold`, new/modified code only (defaults today: `dotnet`/`go` 80, `react-turbo` 70, `expo` 85).
- Task tracker must be updated (in working tree) after every status change.
- Reviewer NEVER writes or edits source files. Phase 10 GitHub PR comments are the only remote write the reviewer ever makes.
- No code before plan approval (GATE #1). No tests before pre-test review approval (GATE #2). No PR before pre-PR review approval (GATE #3).
- All agents must end responses with a `📋 AGENT STATUS` block.
- **Sequential within the monorepo.** No cross-repo parallelism — the in-scope project is single-repo by design.
- **One PR per Story.**
- Holistic reviews (Phases 4, 7, 10) are **informational** — they shape decisions at gates but don't gate by themselves. Phase 10 PR comment posting never blocks the PR.

### Worktree Fallback (Windows)

Git worktree creation may fail with `error: could not lock config file .git/config: File exists`, or with Husky pre-commit hook errors when WEB/MOBILE worktrees can't find their pnpm/yarn cache. If this happens, the Developer reports `Worktree: failed` in its status, and the orchestrator re-invokes without worktree isolation (commits land directly on the user branch).

### Technology Stack — pluggable via packs

Stacks are **pluggable**, not hardcoded. `packs/registry.json` maps each surface to the stacks it supports; each `packs/<stack>/pack.json` declares that stack's build/test/lint commands, `coverage_threshold`, detection globs, tool permissions, `conventions_skill`, and `advisory_skills`. Every agent, role, and phase **resolves the surface's chosen stack** (recorded per surface in `platform-context.md` at `/init-workspace` time) from the registry instead of assuming one. To add a stack — Java/Rust (service), Angular/Svelte/Vue (web), native/Flutter (mobile) — follow `packs/README.md`: author a conventions skill, write `packs/<stack>/pack.json`, register it. No agent/role/phase edits required.

Supported today:

**SERVICE** — `dotnet` (.NET 8: C# 12, EF Core, Wolverine, Hangfire, OTel+Seq; xUnit + FluentAssertions + Moq + Testcontainers + WebApplicationFactory + Refit — `skills/dotnet-conventions/`) **or** `go` (Go 1.23+: chi, pgx + sqlc, golang-migrate, asynq/river, OTel + slog, oapi-codegen; testing + testify + testcontainers-go — `skills/go-conventions/`).

**WEB** — `react-turbo` (React 19 + Turbo + Vite + Yarn; React Query 5, Redux Toolkit, MUI + TailwindCSS; Vitest + React Testing Library + MSW — `skills/react-turbo-conventions/`).

**MOBILE** — `expo` (Expo Router; Redux Toolkit + Persist (MMKV-backed), Firebase + Sentry, EAS secrets, `expo-secure-store`; Jest + `@testing-library/react-native`; Maestro E2E — `skills/expo-mobile-conventions/`).

---

## Usage

```
/dev-workflow <story-issue-number>             # Full pipeline (all 10 phases)
/dev-workflow <command> <story-issue-number>    # Specific phase
```

## Argument Parsing

Parse `$ARGUMENTS`:

- **First token**: If numeric, treat as the Story issue number and run the **full pipeline**.
  If it matches a command name, use that command (**direct phase mode**).
- **Story issue number** (required): The GitHub issue number of the Story (e.g. `42`).
- **Repo / project config** (optional): Resolved from `.claude/context/platform-context.md` (the `Org`, `Repo`, `Project Number`, branch names). If `platform-context.md` is missing, halt with: *"Workspace not initialized — run `/init-workspace` first."*

## Commands

| Command | File | Phase | Description |
|---------|------|-------|-------------|
| `requirements` | `commands/requirements.md` | 1 | Pull Story issue, identify parent Feature, gather requirements (incl. optional 4-file initiative docs) |
| `plan` | `commands/plan.md` | 2 | Design approaches, plan + tracker, Task sub-issue creation + board, branch strategy — GATE #1 |
| `develop` | `commands/develop.md` | 3 | Per-task developer + per-task reviewer loop (sequential) |
| `pre-test-review` | `commands/pre-test-review.md` | 4 | Holistic pre-test review by reviewer; informational findings to tracker |
| (gate)         | (inline) | 5 | Human approval — GATE #2 |
| `test` | `commands/test.md` | 6 | Per-surface tester writes tests, per-task reviewer reviews |
| `pre-pr-review` | `commands/pre-pr-review.md` | 7 | Holistic pre-PR review by reviewer; informational findings to tracker |
| `architecture-reconciliation` | `commands/architecture-reconciliation.md` | 8 | Planner audits `.claude/architecture/*` + `.claude/rules/*` against the diff; commits doc updates on the user branch |
| `create-pr` | `commands/create-pr.md` | 9 | Push branch, open PR via `gh pr create` with `Closes #<story>` + per-Task links — GATE #3 |
| `post-pr-review` | `commands/post-pr-review.md` | 10 | Post inline + summary comments to the open GitHub PR via `gh`; comment-only |

If the first token doesn't match a command name and isn't numeric, show this usage table and stop.

## Orchestrator Rules

**Before executing any command**, read `context/orchestrator-rules.md`. These rules apply to ALL phases and cannot be overridden by individual commands.

## Full Pipeline Mode

When no command is specified (first argument is the Story issue number), execute all commands in sequence:

1. `requirements` → 2. `plan` (GATE #1) → 3. `develop` → 4. `pre-test-review` → 5. (GATE #2) → 6. `test` → 7. `pre-pr-review` → 8. `architecture-reconciliation` → 9. `create-pr` (GATE #3) → 10. `post-pr-review`

Read each command file **as you reach that phase**. Do not pre-load all command files — load one at a time to conserve context.

After each command completes, proceed to the next automatically (unless a human gate blocks).

## Direct Phase Mode

When a command is specified, read its command file and execute it. Each command file states its own prerequisites — verify them before proceeding.

This mode is useful for:
- **Resuming** a workflow after a session interruption
- **Re-running** a specific phase (e.g., re-running tests after manual fixes)
- **Standalone PR review** of an existing PR not created by the workflow (`post-pr-review <pr-number>`, or the top-level `/pr-review <pr-number>`)
- **Debugging** a single phase in isolation
