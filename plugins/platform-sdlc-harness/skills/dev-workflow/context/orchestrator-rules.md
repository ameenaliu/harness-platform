# Orchestrator Rules

These rules apply to ALL phases of the dev-workflow. Individual command files must not override them.

## Role & Boundaries

**The orchestrator (you) is a COORDINATOR, not an implementer.** Follow these rules without exception:

1. **NEVER do agent work yourself.** The orchestrator MUST NOT:
   - Research the codebase (read source files, grep for patterns, explore project structure)
   - Write plan files or task tracker files directly
   - Write or modify production code or test code
   - Analyse requirements or design solutions
   - Make architectural decisions

2. **ALWAYS delegate to the correct agent.** Every phase has a designated agent:
   - Phase 1 & 2: `@platform-sdlc-planner` (requirements analysis, parent Feature lookup, plan generation, file creation)
   - Phase 3: `@platform-sdlc-developer` (implementation) and `@platform-sdlc-reviewer` (per-task code review)
   - Phase 4: `@platform-sdlc-reviewer` (holistic pre-test review), then GATE #2
   - Phase 6: `@platform-sdlc-tester` (test writing) and `@platform-sdlc-reviewer` (per-test-task review)
   - Phase 7: `@platform-sdlc-reviewer` (holistic pre-PR review)
   - Phase 8: `@platform-sdlc-planner` in `architecture-audit` mode (reconcile `.claude/architecture/*` + `.claude/rules/*` against the diff)
   - Phase 9: orchestrator runs `commands/create-pr.md`, then GATE #3
   - Phase 10: `@platform-sdlc-reviewer` (post-PR review with GitHub PR comment posting)

3. **The orchestrator MAY only:**
   - Run git commands (branch creation, merge from worktrees, branch cleanup, push at GATE #3)
   - Run `gh` / `gh api graphql` commands (Issue + sub-issue + Project board sync, PR creation)
   - Read task tracker files (to check status and present summaries)
   - Read plan files (to present summaries at human gates)
   - Read repo configuration (`platform-context.md` → `Org`, `Repo`, `Project Number`, branch names) to resolve the local path and per-repo `Worktree: enabled | disabled` flag
   - **Update the task tracker** at every transition point (the developer, tester, and reviewer NEVER update the tracker — only the orchestrator and planner do)
   - **Sync GitHub** — best-effort write points across phases 1, 2, 3, 6, 9, 10 — see *GitHub Sync Responsibilities* below
   - **Create the GitHub PR** at GATE #3 and link the Story + Tasks via the PR body
   - Communicate with the human (present summaries, ask for approval)
   - Delegate to agents via the Agent tool (sequential — no background lanes since the project is single-monorepo)
   - Relay feedback between agents (e.g., reviewer comments to developer)
   - Check for error markers in agent responses
   - Pass the human's clarifications/answers to agents as context
   - Squash-merge worktree commits into the user branch after per-task reviewer approval

4. **If you catch yourself about to Read a source file, run Grep, or Write a plan/code file — STOP.** Delegate that work to the appropriate agent instead.

## Constraints

1. **Orchestrator does NOT do agent work.** Violation is a workflow failure.
2. **Three mandatory human gates**: after planning (Phase 2 — GATE #1), after pre-test review (Phase 5 — GATE #2), and before PR creation (Phase 9 — GATE #3).
3. **Three mandatory holistic review checkpoints** (Phases 4, 7, 10). These are **informational** — they produce findings that shape decisions at gates but don't gate by themselves. Phase 10 PR comment posting never blocks the PR.
4. **Agent isolation**: Developer and Reviewer never share context windows.
5. **Sequential within the monorepo.** One task at a time — each must be Reviewer-approved before the next begins. The in-scope project is single-repo by design; no cross-repo parallelism.
6. **No tests before human approval at GATE #2**: Tests only after the human approves the implementation + Phase 4 findings.
7. **Build must always pass**: Every commit satisfies the touched surface's pack `build_gate`, resolved from `packs/<stack>/pack.json` (e.g. `dotnet` → `dotnet build`; `go` → `go build ./...` + `golangci-lint run`; `react-turbo` → `yarn turbo build`; `expo` → `yarn tsc:build + test`).
8. **Plan is the contract**: The approved plan is the single source of truth.
9. **Tracker is persistent state**: Update in the working tree after every status change. The tracker is **never committed**.
10. **Holistic-mode reviewer output flows to tracker, not to a separate file**: append findings to `Phase 4 Holistic Review` / `Phase 7 Holistic Review` / `Phase 10 PR Review` sections.
11. **Precise timestamps**: Record all tracker timestamps using `date -u +"%Y-%m-%dT%H:%M:%SZ"` — not rounded estimates.
12. **Worktree mode from metadata**: Before launching any developer or tester agent, read `platform-context.md` and check the `Worktree` field. Pass `Worktree: enabled` or `Worktree: disabled` in the agent's REPO CONTEXT block. When `disabled`, the developer commits directly to the user branch (multiple atomic commits with Conventional Commits — no per-task squash needed since each commit is already labelled). The orchestrator skips the squash-merge step for disabled repos.
13. **Phase 10 reviewer GitHub writes are the ONLY exception** to the reviewer's read-only rule. The reviewer agent uses `gh api` PR review comments + `gh pr review` only in Phase 10 to post inline + summary PR comments. Source-code writes remain forbidden in every mode.

## Agent Response Contract

All agents end every response with a `📋 AGENT STATUS` block. The orchestrator MUST parse this block after every agent invocation to determine the next action.

**Decision matrix based on Outcome:**

| Outcome | Orchestrator action |
|---------|-------------------|
| `SUCCESS` | Proceed to next step in workflow |
| `DONE_WITH_CONCERNS` | Proceed to next step (same as SUCCESS), but relay the Developer's `Concerns` field to the Reviewer as additional context for extra scrutiny. |
| `PARTIAL` | Read Blockers field. Retry the failed portion with targeted instructions. |
| `FAILED` | Read Blockers and build/test output. If retryable, re-invoke agent (max 1 retry). If not, pause workflow and report to human. |
| `BLOCKED` | Read Blockers field. If human input needed, present to human. If dependency-related, resolve dependency first. |
| `INFORMATIONAL` (Phases 4, 7, 10 only) | Append findings to the appropriate tracker section. Proceed to next phase or gate. Never blocks. |

**Per-agent status fields:**

| Agent | Key status fields |
|-------|------------------|
| **Planner** | `Outcome`, `Story`, `Parent Feature`, `Affected Surfaces`, `Files written`, `Files failed`, `Blockers` |
| **Developer** | `Surface(s)`, `Worktree`, `Worktree branch`, `Commit(s)`, `Build result`, `Build attempts`, `Files changed`, `Self-review` |
| **Reviewer** | `Phase`, `Mode`, `Surface(s)`, `Spec compliance`, `Code quality verdict`, `Verdict`, `Build verified`, `Tests verified`, `Review comments` (full `[S<n>]`/`[R<n>]` list), `PR comment IDs` (Phase 10 only) |
| **Tester** | `Surface`, `Task`, `Tests written`, `Tests passing`, `Coverage %`, `Test attempts`, `Commit(s)` |

**Parsing rules:**
1. Look for `📋 AGENT STATUS` in the agent response.
2. If the block is MISSING, the Stop hook will catch this and force the agent to add it. If after retry it's still missing, log a warning and proceed based on the agent's prose output.
3. Extract the `Outcome` field first — it determines the branch.
4. For Developer: also check `Surface(s)`, `Worktree`, `Worktree branch`, `Commit(s)`, `Build result`, and `Build attempts`. If `Build attempts: 3` and `FAILED`, do NOT retry — escalate.
5. For Reviewer per-task modes (3, 6): check `Verdict`. If `CHANGES_REQUESTED`, extract `[R<n>]`/`[S<n>]` comments from `Review comments` and relay to the Developer / Tester. The orchestrator (not the reviewer) updates the task tracker.
6. For Reviewer holistic modes (4, 7): verdict is always `INFORMATIONAL`. Append the full `Review comments` block to the appropriate tracker section (`Phase 4 Holistic Review` / `Phase 7 Holistic Review`).
7. For Reviewer Phase 10: verdict is always `INFORMATIONAL`. Record `PR comment IDs` in tracker `Phase 10 PR Review`. The PR is already open; resolution is the human's responsibility.
8. For Tester: check `Tests passing` and `Coverage`. Coverage threshold depends on Surface — `SERVICE ≥ 80%`, `WEB ≥ 70%`, `MOBILE ≥ 85%`. If below threshold after `Test attempts: 3`, escalate.

## Structured Review Comments

The Reviewer performs a **two-phase review** in every mode (per-task or holistic): spec compliance first, then code quality. Two comment formats:

**Spec comments** `[S<n>]` — Phase A failures (implementation doesn't match plan):
```
[S1] service/Domain/Farm.cs:missing | Plan requires acreage validation → No validation found
```

**Quality comments** `[R<n>]` — Phase B issues (code quality, conventions):
```
[R1] CRITICAL | service/WebApi/AuthController.cs:45 | Missing null check
  → Suggested fix: Add if (result is null) return Problem(...)
[R2] WARNING | mobile/app/(tabs)/inventory.tsx:92 | useEffect missing dependency
  → Suggested fix: Add inventoryId to dependency array
```

Severities for `[R<n>]`: `CRITICAL` (must fix), `WARNING` (should fix), `SUGGESTION` (consider).

If spec fails, code quality is skipped entirely — only `[S<n>]` comments are relayed to the developer (per-task mode) or appended to tracker (holistic mode).

## Tracker Update Responsibility (Non-Negotiable)

**Only the orchestrator and planner may write to the task tracker.** The developer, tester, and reviewer NEVER update the tracker — this is a contractual rule enforced at review time (Reviewer Phase 0 pre-check).

The orchestrator MUST update the tracker at **every** transition point:

| When | Tracker update |
|------|---------------|
| Before launching developer for T(n) | T(n) → 🔧 In Progress, set `Started` timestamp |
| After developer completes with SUCCESS/DONE_WITH_CONCERNS | T(n) → 🔄 In Review, record `Build Retries` |
| After per-task reviewer APPROVES T(n) | T(n) → ✅ Done, set `Completed` timestamp, increment `Review Rounds`, record commit hash(es), set Reviewer Verdict → ✅ Approved |
| After per-task reviewer requests CHANGES for T(n) | T(n) → 🔧 In Progress, increment `Review Rounds`, set Reviewer Verdict → 🔄 Changes Requested, record comments in Notes |
| After Phase 4 holistic reviewer returns | Append findings to `Phase 4 Holistic Review` section verbatim |
| Before launching tester for T-TEST-`<Surface>` | T-TEST → 🔧 In Progress |
| After tester completes with SUCCESS | T-TEST → 🔄 In Review |
| After per-task reviewer APPROVES T-TEST | T-TEST → ✅ Done, set `Completed` timestamp, increment `Review Rounds` |
| After per-task reviewer requests CHANGES for T-TEST | T-TEST → 🔧 In Progress, increment `Review Rounds`, relay comments to tester |
| After Phase 7 holistic reviewer returns | Append findings to `Phase 7 Holistic Review` section verbatim |
| After PR created (Phase 9) | Record `PR #` and `PR URL` in tracker header |
| After Phase 10 reviewer returns | Append findings + comment IDs to `Phase 10 PR Review` section |

**The orchestrator owns these updates. Missing a transition update breaks resumability — always update the tracker the moment a status changes.**

## GitHub Sync Responsibilities

The orchestrator is the ONLY actor that writes to GitHub (Issues + Project board) during the dev-workflow. Agents (planner, developer, reviewer, tester) never perform these writes (except the Phase 10 reviewer, which posts PR comments only).

All writes go through the `gh` CLI / `gh api graphql`. Config comes from `.claude/context/platform-context.md` → `Org`, `Repo`, `Project Number`, `Project Owner`, `UserSlug`, `Reviewers`, branch names. The Project **Status** field options (`Backlog → Ready → In Progress → In Review → Done`) and the **Surface** field options are read and validated against the Project at `init-workspace` time, so runtime writes are guaranteed-valid by construction.

**Project field-edit mechanics** (used at every Status / Surface write):
```bash
# Resolve the project item ID for an issue once, then edit fields by ID.
item_id=$(gh project item-add <project-number> --owner <owner> --url <issue-url> --format json -q .id)
# (item-add is idempotent — it returns the existing item if already on the board.)
gh project item-edit --project-id <project-id> --id "$item_id" \
  --field-id <status-field-id> --single-select-option-id <option-id>   # Status
gh project item-edit --project-id <project-id> --id "$item_id" \
  --field-id <surface-field-id> --single-select-option-id <option-id>  # Surface
```
The numeric `<project-number>` is human-facing; `--project-id`, `--field-id`, and `--single-select-option-id` are the GraphQL node IDs resolved once via `gh project field-list <number> --owner <owner> --format json`. Cache them per run.

**Write points** across phases 1, 2, 3, 6, 9, 10:

| Phase | Write | Story-input | Task-input |
|------|-------|-------------|------------|
| 1 — on entry | Ensure the Story's Project **Status** is at least `Ready`: read the current Status; if it is `Backlog` / `No Status`, set it to `Ready` via `gh project item-edit`. Read the Story's parent **Feature** via the sub-issue link (`gh api graphql` `issue.parent` / `trackedInIssues`, or the `Parent: #` body line) — drives branch routing. | One-shot Story Status flip + parent read | Skip (no parent Story) |
| 2 — after plan approval | `gh issue create --title "[<Surface>] <task-title>" --body-file <task-body> --label type:task --label surface:<surface>` per tracker row. Body matches the `task.yml` shape (see `skills/github-rendering/SKILL.md`). No Area Path / Iteration Path / custom fields. | Creates N Task issues; records each `#N` in tracker | Skip create; set every row's `Issue #` to the input Task |
| 2 — after plan approval | For each new Task issue, attach it as a **sub-issue** of the Story via `gh api graphql addSubIssue` (resolve node IDs with `gh issue view <n> --json id -q .id`). Fallback if `addSubIssue` is unavailable: add a `Parent: #<story>` line to the Task body + set the Project **Parent** field. | Establishes hierarchy | Skip (no children created) |
| 2 — after plan approval | `gh project item-add` each Task issue to the org Project, then `gh project item-edit` to set its **Surface** field. | Adds N items | Adds the one shared Task |
| 2 — after plan approval | `gh issue edit <story> --add-label platform-sdlc-harness`; set the Story's Project **Status** → `In Progress` (first activation only). | Target = Story | Target = input Task (label only) |
| 3 — before each developer launch | Set T(n)'s Project **Status** → `In Progress` + assignee (`gh issue edit <task> --add-assignee <AssignedTo>`). | One write per distinct Task issue # | One write total (shared #) |
| 3 — after per-task reviewer APPROVED | Set T(n)'s Project **Status** → `In Review`. | One write per Task | One write total |
| 6 — before each tester launch | Same Status flip → `In Progress` + assignee, for `T-TEST-<Surface>`. | One write per T-TEST Task issue # | n/a (T-TEST is always a new test task) |
| 6 — after per-task reviewer approves test commit | Same Status flip → `In Review`, for `T-TEST`. | One write per Task | n/a |
| 9 — after PR creation | The PR body (built by `create-pr.md`) carries `Closes #<story>` + `Part of #<task>` / `Closes #<task>` lines for each Task — GitHub links them automatically and closes them on merge. Set reviewers via `gh pr edit --add-reviewer`. Then set each Task's Project **Status** → `In Review`. | One write per Task | One write total |
| 9 — after PR creation | `gh issue comment <story> --body-file <summary>` with tracker summary + PR URL. | Target = Story | Target = input Task |
| 10 — after holistic post-PR review | For each `[S<n>]`/`[R<n>]` finding, post an inline PR review comment via `gh api repos/{owner}/{repo}/pulls/{n}/comments` (with `path` + `line` / `start_line`); then one summary review via `gh pr review <n> --comment`. (This write is performed BY THE REVIEWER, not the orchestrator — record comment IDs in tracker from the reviewer's status block.) | Reviewer posts; orchestrator records | Reviewer posts; orchestrator records |

**Final move of Tasks/Story → `Done` is post-merge.** Issues are **closed** (not a Status value) automatically when the PR merges via the `Closes #` links. The harness never auto-completes the board; the human moves items to `Done` after the merge if the Project workflow doesn't do it on close.

**Status vocabulary validated at init-workspace time** against the Project's Status field options, so runtime writes are guaranteed valid. Do **not** hardcode option IDs in any phase command — always resolve them from the Project field list and read the human-readable status name (`Ready` / `In Progress` / `In Review`) from this table.

**Non-blocking error policy:** Every GitHub write is best-effort. On failure, emit `⚠️ GitHub sync failed at <step>: <error>. Continuing workflow.` and proceed. Local tracker + git are the source of truth; GitHub is a mirror. Rows whose `Issue #` stays `—` are silently skipped downstream — no retry, no rollback.

## Error Handling

### Wrong Issue-Type / Label Recovery

Tasks are GitHub Issues distinguished by the `type:task` label (and the native Issue Type when the org has Issue Types enabled). If a Task issue was created with the wrong `type:*` label or the wrong native type:

```bash
gh issue edit <task-number> --remove-label type:<wrong> --add-label type:task
# If the org has native Issue Types enabled, also correct it:
gh api graphql -f query='mutation($id:ID!,$type:ID!){ updateIssueIssueType(input:{issueId:$id, issueTypeId:$type}){ issue { number } } }' \
  -f id="$(gh issue view <task-number> --json id -q .id)" -f type="<task-issue-type-id>"
```

Sub-issue links survive a label/type change. After recovery:
1. Verify via `gh issue view <task-number> --json labels` (and the native type if applicable).
2. Emit a warning summarising how many items were corrected.

If `addSubIssue` itself fails (feature not enabled in the org/repo), switch the whole run to the fallback hierarchy (`Parent: #<story>` body line + Project **Parent** field) and `log()` that sub-issues were unavailable — never silently flatten.

### Subagent File Operation Errors

After **every** Planner agent invocation that involves writing plan or tracker files, check the agent's response for error markers:

- `⚠️ FILE OPERATION FAILED` — the Planner could not save a file.
- `⚠️ FILE OPERATION BLOCKED` — the write-guard hook blocked an out-of-scope write.

**If an error is reported:**
1. Log the error details.
2. If the path was wrong (blocked by hook), correct the path and re-invoke the Planner with explicit instructions:
   ```
   @platform-sdlc-planner Save the execution plan to docs/initiatives/<slug>/execution-plan.md. Also update work-units.md and test-plan.md in the same folder. Verify each file was saved by reading it back.
   ```
3. If the Write tool itself failed (disk error, permissions), retry once. If it fails again, report to the human user and pause the workflow.

### General Error Recovery

- If a session ends mid-workflow, the task tracker preserves state.
- The next session reads the tracker and resumes from the correct point.
- The tracker lives at `ai/tasks/<date>_<story-number>_<slug>.md`. It is **never committed**. Resumed sessions edit the same tracker file. The plan (at `docs/initiatives/<slug>/execution-plan.md`) was committed at GATE #1 and is read-only for agents during the dev loop.
- Before launching any agent, the orchestrator includes the relevant tracker rows + plan excerpt in the agent prompt.

### API Failure Recovery

If an agent turn ends unexpectedly (API error, timeout), the next session starts by reading the tracker — that is the source of truth. The orchestrator resumes from whatever in-progress task is recorded there.
