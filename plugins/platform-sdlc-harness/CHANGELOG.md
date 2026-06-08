# Changelog

## 1.4.0 — Pluggable stack packs + Go service stack

The harness is now **language/framework-agnostic**. Stacks are no longer hardwired to .NET/React/Expo — each surface's stack is a pluggable "pack" resolved from a registry, and **Go joins .NET as a first-class SERVICE stack**.

### Stack pack architecture

- **`packs/registry.json`** — single source of truth mapping each surface to the stacks it supports (`service` → `dotnet` | `go`; `web` → `react-turbo`; `mobile` → `expo`) and each stack to its manifest.
- **`packs/<stack>/pack.json`** — per-stack manifest: `conventions_skill`, `advisory_skills`, build/test/lint commands + `build_gate`, `coverage_threshold`, detection globs, `tool_permissions`, `quality_hook`, `review_checklist_anchor`.
- **`packs/README.md`** — the contract + a recipe for adding a stack (Java/Rust service, Angular/Svelte/Vue web, native/Flutter mobile) with no agent/role edits.
- Every decision point now resolves the stack from the registry instead of hardcoding it: the 4 agents, the 4 portable roles, `portable/mechanics/claude.md`, `AGENTS.md.tmpl`, the dev-workflow SKILL + orchestrator-rules. Per-stack PR checklists moved into each conventions skill (anchored via the pack's `review_checklist_anchor`).

### Go support (first-class SERVICE stack)

- **`go-conventions`** — idiomatic Go service conventions (package layout, error wrapping with `%w`, context propagation, concurrency, testing) + a recommended library stack (chi, pgx+sqlc, golang-migrate, asynq/river, OTel+slog, oapi-codegen, testify+testcontainers-go) and a `SERVICE (Go)` PR checklist.
- **`go-code-quality`** — golangci-lint (aggregator) + staticcheck + go vet + gofumpt + govulncheck; the Go analog of `dotnet-code-quality`.
- `service-quality-check` hook detects the stack (`go.mod` → Go gate `go build ./...` + `golangci-lint run` + `go test ./...`; `*.sln` → the existing .NET gate).
- `/init-workspace` + plugin `settings.json` add Go tool detection and Bash permissions (`go`, `golangci-lint`, `gofumpt`, `staticcheck`, `govulncheck`, `migrate`, `sqlc`, `oapi-codegen`).

### init-workspace now prompts for the stack

Stack selection is no longer assumed from a default — Step 2.4 detects the stack via each pack's `detect` globs and, when a surface is an empty scaffold or detection is ambiguous, **asks the user** which stack to adopt (options drawn from the registry) before recording it in `platform-context.md`. Step 7a's skill-scaffold copy is now the union of each chosen pack's `conventions_skill` + `advisory_skills` (adding a pack auto-scaffolds with no edit here).

Skill count: 30 → 32 (`go-conventions`, `go-code-quality`).

## 1.3.0 — Native GitHub relationships, production-safety review, and a tested harness

### Critical fix — data-policy hooks were silently non-functional

`secret-scan-guard` and `pii-pattern-guard` piped input into `python <<'PY'`, where the heredoc — not the pipe — becomes Python's stdin. `sys.stdin.read()` returned `''`, JSON parsing failed, and both hooks printed `ALLOW` for **everything**: no secret or PII was ever detected. Fixed by passing the payload via an env var (`HOOK_INPUT`) so detection actually runs. (`sensitive-file-guard` and `prompt-injection-guard` used `python -c` and were unaffected.) Found by the new hook test suite.

### Harness is now tested + CI'd

- `plugins/platform-sdlc-harness/tests/run-tests.sh` — behavioral tests for all 7 hooks (secret blocks a planted key, sensitive-file blocks `.env`, pii blocks a BVN batch, injection warns, quality-checks no-op off a commit / without the workspace sentinel) + the structure validator.
- `plugins/platform-sdlc-harness/tests/validate-skills.py` — skill frontmatter (`name`/`description`), skill-to-skill cross-reference links, and `hooks.json` command paths.
- `.github/workflows/ci.yml` — runs `validate-plugins.sh`, the link/path validator, shellcheck, and the hook tests on every push/PR (the existing scripts had no CI wiring).

### Discovery / backlog — native GitHub relationships + guaranteed board membership

- **Dependencies now use GitHub's native issue dependencies** (GA Aug 2025): the typed **Blocked by** relationship via `POST /repos/{owner}/{repo}/issues/{n}/dependencies/blocked_by` (body `issue_id` = blocker's integer db id). Replaces the old `blocked` label + `Blocked by:` body-line convention, which is now a GitHub-Enterprise-only fallback. Parent stays native sub-issues (already correct). Updated in `github-rendering` (source of truth), discovery `create`/`decompose`/`extend`, backlog `improve`/`refine`/`analyze`, and the cross-tool `AGENTS.md`.
- **Project (v2) board membership is now mandatory + verified, not silent best-effort.** Discovery `create` pre-checks the `project` token scope (the #1 reason issues land in the repo but not the board), stops loudly on systemic board-add failure, and verifies membership after — reporting on-board count in the summary.

### New review skills — production safety + operability

- **`migration-safety`** (service) — EF Core migration review: destructive ops (dropped columns/tables, non-nullable-without-default, narrowing), locking index builds, missing `Down()`; expand→contract guidance.
- **`api-contract-check`** (service) — OpenAPI breaking-change detection with oasdiff (removed endpoints/fields, newly-required params, type narrowing) so service changes don't silently break web/mobile.
- **`observability`** (all surfaces) — structured logging + tracing (Serilog/OpenTelemetry) and error capture + key events (Sentry) on new code paths, with a no-PII-in-telemetry guardrail.

Wired into the conventions, the `developer`/`reviewer` roles (self-review + Phase B + checklist), `/init-workspace` (oasdiff install + Codex skill copy + permissions), and the metadata. Skill count: 27 → 30. All three are advisory — the hard gates remain the zero-warnings build, the data-policy hooks, and the quality-check hooks.

## 1.2.0 — Security, cleanliness & quality tooling

Adds advisory security/quality/maintainability tooling across all surfaces, driven by the Developer self-review and Reviewer Phase B (and auto-installed by `/init-workspace`). All **advisory** — none blocks commits; the zero-warnings build, data-policy hooks, and quality-check hooks remain the hard gates. Findings are scoped to new/modified code.

### New skills

- **`security-scan`** (all surfaces) — Semgrep (SAST), Gitleaks (secrets, `--redact`), and dependency-CVE auditing (OSV-Scanner + `dotnet list package --vulnerable` + `yarn npm audit`). Broadens the regex-only data-policy hooks into real SAST + secret + dependency scanning.
- **`dead-code-analysis`** (web + mobile) — Knip (unused files/exports/deps) + madge (circular dependencies).
- **`dotnet-code-quality`** (service) — Roslynator analyzers/refactorings (+ optional SonarAnalyzer.CSharp) and `dotnet list package --outdated`.
- **`bundle-budget`** (web + mobile) — size-limit bundle-size budgets (init recommends but never auto-adds the devDependency).
- **`expo-doctor`** (mobile) — `npx expo-doctor` project + dependency-compatibility health.

### Wiring

- The three conventions skills reference the new tools per surface; `developer` and `reviewer` portable roles run them as advisory self-review / Phase B scans, with broadened STATUS-block + checklist fields.
- `/init-workspace` Step 1.5 verifies + installs them (graceful skip/warn), Step 7a copies the new skills into `.agents/skills/` for Codex, and Step 6 + plugin `settings.json` pre-approve their Bash permissions (`semgrep`, `gitleaks`, `osv-scanner`, `knip`, `madge`, `size-limit`, `roslynator`, `dotnet list`, `dotnet tool`). `AGENTS.md.tmpl` capability table updated.
- Skill count: 22 → 27.

## 1.1.0 — Mobile & React capability tooling

Adds three capability tools to the MOBILE/WEB surfaces, driven by the dev/test/review roles and auto-installed by `/init-workspace` (advisory — none is a commit gate).

### New skills

- **`agent-device`** — the Developer drives the running app on a simulator/emulator to verify MOBILE UI in the agentic loop (Phase 3), not just confirm a green build. Installs via `npm install -g agent-device@latest`.
- **`maestro-e2e`** — the Tester writes committed end-to-end flows in `mobile/.maestro/*.yaml` (happy + one key error/empty path) alongside the Jest suite (Phase 6). Installs via `curl -fsSL "https://get.maestro.mobile.dev" | bash`.
- **`react-doctor`** — Developer self-review + Reviewer Phase B run `npx react-doctor@latest` over `web/` and `mobile/` for React performance / a11y / dead-code findings, scoped to new/modified files.

### Wiring

- `expo-mobile-conventions` and `react-turbo-conventions` reference the new skills; the `developer`, `tester`, and `reviewer` portable roles invoke them per surface (with new STATUS-block fields for UI verification, quality scan, and E2E flows).
- `/init-workspace` Step 1.5 verifies + installs the three tools when MOBILE/WEB is present (graceful skip/warn — not hard blockers), Step 7a copies the new skills into `.agents/skills/` for Codex, and Step 6 pre-approves `agent-device` / `maestro` / `react-doctor` Bash permissions. Plugin `settings.json` and `AGENTS.md.tmpl` updated to match.
- Skill count: 19 → 22.

## 1.0.0 — GitHub-native SDLC harness

Initial release of `platform-sdlc-harness` — a GitHub-native port of the Azure DevOps SDLC pipeline, designed to be installed once and shared across GitHub projects.

### Provider

- **GitHub Issues + sub-issues + Projects (v2)** for work tracking (replaces ADO work items).
- **`gh` CLI + `gh api graphql`** for every remote operation — no MCP server.
- Per-repo configuration in `.claude/context/platform-context.md` (org, repo, Project number/owner, branch names, user slug, per-surface stack), generated by `/init-workspace`.

### Work-item model

- Lifecycle **Epic → Feature → Story → Task / Bug**, wired with native sub-issues (`addSubIssue`), degrading to `type:*` labels + `Parent: #n` body line + a Project "Parent" field where sub-issues aren't enabled.
- Issue types via `type:epic|feature|story|task|bug` labels (+ native Issue Types when org-enabled).
- **Surface** (`service|web|mobile|cross-cutting`) replaces ADO's `[Stack]`, via issue-form dropdown + `surface:*` label.
- Hierarchical title numbering `E1` / `F1.1` / `S1.1.1` alongside native `#N`.
- State on the Project (v2) board `Status` field: `Backlog → Ready → In Progress → In Review → Done`; issues close on PR merge via `Closes #`.
- Markdown issue bodies aligned with the repo's `story.yml` / `task.yml` / `bug.yml` issue forms (no HTML conversion).
- Dependencies via `Blocked by: #n` / `Blocks: #m` body lines + a `blocked` label.

### Branching & PRs

- Two-tier branching: `main` (prod) / `develop` (integration) / `features/<feature-slug>/main` / `users/<user-slug>/…`.
- Conventional Commits `<type>(<surface>): …`, no issue id in the commit; PR body carries `Closes #<story>` + per-Task links.
- PRs via `gh pr create`; reviewers via `gh pr edit --add-reviewer`; Phase 10 review comments via `gh api` + `gh pr review --comment` (comment-only, never blocks).

### Components

- 4 agents (planner with 5 modes, developer, reviewer with 5 modes, tester).
- 7 hooks (4 data-policy + 3 stack quality-check; quality checks no-op when a surface's toolchain isn't present).
- 19 skills, including `github-rendering` (canonical issue bodies + numbering + sub-issue/dependency/Project protocol).
- Cross-tool `portable/` layer for Claude Code + OpenAI Codex parity, with a GitHub Actions secret-scan guard.
