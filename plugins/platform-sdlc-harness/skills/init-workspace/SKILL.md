---
name: init-workspace
description: >
  One-time workspace setup. Ensures a git repo exists, verifies host tools and a
  scoped `gh` login, then generates a single context file
  (`.claude/context/platform-context.md`) plus pre-approved permissions
  (`.claude/settings.local.json`) that all workflows depend on — repo metadata,
  local repo path, GitHub configuration (org, `<org>/platform` repo, default /
  production branch names, branch patterns, Project v2 number + owner), user slug,
  per-surface stack, and repo-specific conventions. Ensures the harness labels
  exist. Also scaffolds the cross-tool layer (AGENTS.md + OpenAI Codex `.codex/`
  subagents + `.agents/skills/`) so the same orchestrated workflow runs on Claude
  Code and Codex. Run once before using /dev-workflow or /backlog-workflow.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
argument-hint: "[--full | --refresh-conventions | --add <path>...]"
---

# /init-workspace — Workspace Setup

One-time workspace setup, or new-developer onboarding. Generates a single context file that every other workflow reads from, and (Step 7) scaffolds the cross-tool artefacts so OpenAI Codex runs the same orchestrated workflow as Claude Code.

All remote work-tracking uses the **`gh` CLI** (`gh` / `gh api` / `gh api graphql`) — there is no MCP server. This skill verifies `gh` is installed and authenticated with the right scopes before anything else needs it.

## Usage

```
/init-workspace                                  # First-time setup or onboarding
/init-workspace --full                           # Force full regeneration
/init-workspace --refresh-conventions            # Regenerate only the Conventions section
/init-workspace --add <path>                     # Add a repo to an existing workspace (rarely needed; platform is single-monorepo)
/init-workspace --scaffold-tools                 # Re-run Step 7 only
```

## Output Files

**Local, git-ignored** (each developer generates their own by running `/init-workspace`):

| File | Description |
|------|-------------|
| `.claude/context/platform-context.md` | Single context file: Repo, GitHub Configuration, Surfaces + per-surface Stack, Workspace (tool targets), Repo-Specific Conventions |
| `.claude/settings.local.json` | Pre-approved tool permissions for background agents |

**Committed, team-shared** (scaffolded in Step 7 when Codex is a selected tool target — see *Step 7*):

| File / folder | For | Description |
|---|---|---|
| `AGENTS.md` | both tools | Universal baseline (branching, commits, data policy, conventions index, 10-phase workflow) |
| `.agents/skills/*-conventions/`, `.agents/skills/engineering-principles/` | Codex | Canonical convention bodies, copied from this plugin |
| `.codex/agents/*.toml`, `.agents/skills/platform-*-workflow/` | Codex | Subagent definitions + orchestration skills |

> **Git-ignore split.** Local-only artefacts must be ignored; team-shared ones are committed.
> - `ai/` (runtime tracker at `ai/tasks/*.md`), `.claude/context/`, `.claude/settings.local.json`, and `.claude/logs/` → **git-ignored**.
> - `.claude/settings.json` (committed marketplace config — auto-adds the marketplace + enables the plugins) → **NOT git-ignored**.
> - `AGENTS.md`, `.agents/skills/`, `.codex/`, `docs/initiatives/<slug>/` → **committed**.
>
> Ensure the local-only entries are excluded (and that `.claude/settings.json` stays tracked); if not present in `.gitignore`, add them during setup:
> ```bash
> printf 'ai/\n.claude/context/\n.claude/settings.local.json\n.claude/logs/\n' >> .gitignore
> # NEVER add .claude/settings.json — it is the committed marketplace config.
> git add .gitignore && git commit -m "chore: gitignore ai/ and local .claude/ runtime artefacts"
> ```

## Behavior

### Step 0 — Ensure Git Repository

Before anything else, check whether the current working directory is inside a git repository (`git rev-parse --is-inside-work-tree`).

- **If yes** — proceed to Step 1.
- **If no** — inform the user and run `git init` in the current working directory:
  > "This folder is not a git repository. Initializing one now so that workflows, branching, and commit conventions work correctly."

### Step 1 — Detect Existing Context

Check whether these files already exist:
- `.claude/context/platform-context.md`
- `.claude/settings.local.json`

If **both** exist, the workspace is already initialised. Inform the user:

> "Your workspace is already initialised:
> - `platform-context.md` (repo, GitHub config, surfaces/stack, conventions)
> - `settings.local.json` (background agent permissions)
>
> Nothing to do. To update:
> - `/init-workspace --refresh-conventions` regenerates the Conventions section from current code
> - `/init-workspace --full` regenerates everything from scratch
> - `/init-workspace --scaffold-tools` re-runs Step 7 (e.g. after editing `portable/` templates)"

Then **stop**.

If only one exists, generate the missing one. If neither exists, proceed with **full setup**.

### Step 1.5 — Verify host tools (auto-install on approval)

Detect the host OS via `Bash` (`uname -s` → `Linux` / `Darwin` / `MINGW*|MSYS*|CYGWIN*` = Windows) and remember it.

For each tool below, run the **check** command. If it fails or is too old, follow the **auto-install protocol** below — do **not** ask the user to install it themselves.

| Tool | Check | Required | Windows pkg | macOS pkg | Linux pkg |
|---|---|---|---|---|---|
| git | `git --version` | any 2.x | `Git.Git` | `git` | `git` |
| **GitHub CLI** | `gh --version` | ≥ 2.40 | `GitHub.cli` | `gh` | `gh` (see cli.github.com/manual/installation) |
| .NET SDK | `dotnet --version` | ≥ 8.0 (only if a SERVICE surface chose the `dotnet` stack) | `Microsoft.DotNet.SDK.8` | `dotnet` | `dotnet-sdk-8.0` |
| Go | `go version` | ≥ 1.23 (only if a SERVICE surface chose the `go` stack) | `GoLang.Go` | `go` | `golang-go` (or go.dev/dl) |
| Node.js | `node --version` | ≥ 20 (some Web/Mobile packages require 22) | `OpenJS.NodeJS.LTS` | `node` | use nvm (`nvm install 22 && nvm use 22`) |
| Yarn | `yarn --version` | ≥ 4.3 (only if a surface uses Yarn) | `corepack enable && corepack prepare yarn@4.3.1 --activate` | same | same |
| Docker | `docker --version` | any (only required if user runs SERVICE locally) | `Docker.DockerDesktop` | `docker` (Docker Desktop) | `docker.io` + `docker compose` plugin |

> Stack tools (.NET / Go / Node / Yarn / Docker) are only **required** for surfaces the repo actually adopts, and only for the stack each surface chose (e.g. install Go only when a SERVICE surface picked the `go` stack; .NET only when it picked `dotnet`). Repos may be empty scaffolds with all stacks `TBD` — in that case verify only `git` + `gh` and record the rest as TBD (see Step 4). Each pack's required tools are listed in its `packs/<stack>/pack.json` `tool_permissions`.

#### MOBILE / WEB capability tools

When **MOBILE** and/or **WEB** is a present surface (with a chosen stack, not `TBD`), verify the React/mobile capability tools below. These do **not** install via the OS package manager — they use `npm`, a `curl` script, or `npx`, so the install commands are the same on every OS (run the **Install** command from the table directly instead of the winget/brew/apt protocol). They follow the same Ask-on-missing flow (offer Install / Skip / Cancel), but they are **advisory capability tools, not hard blockers**: on "Skip" for these three, **warn and continue** rather than halting setup (the workflow degrades gracefully — agents note when a tool was unavailable).

| Tool | Surface | Check | Install (all OSes) | Used by |
|---|---|---|---|---|
| **agent-device** | MOBILE | `agent-device --version` | `npm install -g agent-device@latest` (needs Node 22+; iOS→Xcode, Android→SDK+adb for actual device control) | Developer — drive the running app to verify UI (Phase 3). See `agent-device` skill. |
| **Maestro** | MOBILE | `maestro --version` | `curl -fsSL "https://get.maestro.mobile.dev" \| bash` (macOS alt: `brew install maestro`; may need a shell restart / PATH update for `~/.maestro/bin`) | Tester — mobile E2E flows in `mobile/.maestro/` (Phase 6). See `maestro-e2e` skill. |
| **React Doctor** | WEB, MOBILE | `npx react-doctor@latest --version` | runs on demand via `npx` — no global install needed; pre-warm once with `npx -y react-doctor@latest --help` | Developer self-review + Reviewer Phase B — React perf/quality scan. See `react-doctor` skill. |

> Skip all three when neither MOBILE nor WEB is present (or both are `TBD`). React Doctor applies to **both** WEB and MOBILE; agent-device and Maestro are MOBILE-only.

#### Quality & security capability tools

For any present surface with a chosen stack, verify the advisory quality/security tools below. Same OS-agnostic install style (npm / pipx / brew / Go binary / `dotnet tool` / `npx`) and the same **graceful** policy as the mobile/web tools: offer Install / Skip / Cancel, but on "Skip" **warn and continue** — these are advisory layers, not hard blockers.

| Tool | Surface | Check | Install | Used by (skill) |
|---|---|---|---|---|
| **Semgrep** | all (C#/TS/RN) | `semgrep --version` | `pipx install semgrep` (or `python3 -m pip install semgrep`; macOS `brew install semgrep`) | SAST — `security-scan` |
| **Gitleaks** | all | `gitleaks version` | `brew install gitleaks` (macOS); Linux/Windows: release binary or `go install github.com/gitleaks/gitleaks/v8@latest` | secrets — `security-scan` |
| **OSV-Scanner** | all (NuGet+npm) | `osv-scanner --version` | `brew install osv-scanner`; else release binary or `go install github.com/google/osv-scanner/cmd/osv-scanner@latest` | dependency CVEs — `security-scan` |
| **Roslynator** | SERVICE (dotnet) | `roslynator --version` | `dotnet tool install -g roslynator.dotnet.cli` | .NET maintainability — `dotnet-code-quality` |
| **golangci-lint** | SERVICE (go) | `golangci-lint version` | `brew install golangci-lint` (macOS); else `go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest` | Go lint aggregator — `go-code-quality` |
| **gofumpt** | SERVICE (go) | `gofumpt -version` | `go install mvdan.cc/gofumpt@latest` | Go formatting — `go-code-quality` |
| **govulncheck** | SERVICE (go) | `govulncheck -version` | `go install golang.org/x/vuln/cmd/govulncheck@latest` | Go module CVEs — `security-scan` |
| **Knip** | WEB, MOBILE | `npx knip --version` | runs via `npx` (pre-warm `npx -y knip --help`) | unused code/deps — `dead-code-analysis` |
| **madge** | WEB, MOBILE | `npx madge --version` | runs via `npx` (pre-warm `npx -y madge --version`) | circular deps — `dead-code-analysis` |
| **expo-doctor** | MOBILE | `npx expo-doctor --help` | runs via `npx` | Expo health — `expo-doctor` |
| **size-limit** | WEB, MOBILE | n/a (project devDep) | per-surface `yarn add -D size-limit @size-limit/preset-app` + a `.size-limit.json` budget — **do not add automatically**; note it for the team to opt in | bundle budget — `bundle-budget` |
| **oasdiff** | SERVICE | `oasdiff --version` | `brew install oasdiff` (macOS); else release binary or `go install github.com/oasdiff/oasdiff@latest` | API breaking-change diff — `api-contract-check` |

> `dotnet list package --vulnerable` / `--outdated`, `dotnet ef migrations script`, and `yarn npm audit` need no install (ship with the SDK / EF tools / Yarn). **migration-safety** and **observability** are review-lens skills with no CLI to install. **size-limit** is the one tool that requires repo changes (a devDependency + config), so init-workspace only **recommends** it — it never adds dependencies to the user's repo. Skip the whole subsection for surfaces that are `TBD`.

#### `gh` authentication + scopes (mandatory)

`gh` must be **installed AND authenticated** with the scopes the harness uses for Issues, Projects, and org reads.

1. Run `gh auth status`.
   - If it reports **not logged in**, instruct the user to authenticate (this is interactive — the harness cannot complete it headlessly):
     > "GitHub CLI is not authenticated. Run `gh auth login` (choose GitHub.com → HTTPS → authenticate via browser), then re-run `/init-workspace`."
     Halt until done.
2. Verify the token carries the required scopes: **`repo`, `project`, `read:org`** (and **`workflow`** for the Actions secret-scan guard). `gh auth status` prints the token scopes; confirm all four are present.
   - If `project` (or any required scope) is missing, instruct:
     > "Your `gh` token is missing the `project` scope (needed to read/write the Project v2 board). Run `gh auth refresh -s project,read:org,workflow` then re-run `/init-workspace`."
   - Re-run `gh auth status` after the user refreshes; only continue once all scopes are present.

#### Auto-install protocol (per missing tool)

1. **Tell the user** in one line: e.g. `"⚙ GitHub CLI not found on PATH (required for all work-tracking + PR operations)."`

2. **Ask via `AskUserQuestion`** with three options in this order:
   ```
   Install <tool> automatically? (Recommended)   ← installs via per-OS command below
   Skip — I'll handle it manually                  ← halt; user fixes + re-runs
   Cancel setup                                    ← abort entirely
   ```

3. **On "Install automatically"** — run the per-OS install command and capture exit code + last 5 lines of output:
   - **Windows**: `winget install --silent --accept-source-agreements --accept-package-agreements <pkg-id>` (may trigger UAC — tell the user).
   - **macOS**: `brew install <formula>`. If `brew` is itself missing, halt with the one manual instruction "install Homebrew from https://brew.sh then re-run" — package-manager bootstrap is the single allowed exception.
   - **Linux**: detect package manager (`command -v apt-get || command -v dnf || command -v pacman`) and run accordingly: `sudo apt-get update && sudo apt-get install -y <pkg>` / `sudo dnf install -y <pkg>` / `sudo pacman -S --noconfirm <pkg>`. For `gh` on Debian/Ubuntu, follow the apt repo steps at cli.github.com if the distro package is too old.
   - **Node on Linux**: prefer nvm (`curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh" && nvm install 22 && nvm use 22`) — distro Node is often too old for our Web/Mobile.
   - **Yarn 4.3+ everywhere**: `corepack enable && corepack prepare yarn@4.3.1 --activate` (Corepack ships with Node 16.10+).

4. **Verify post-install** — re-run the check. If it still fails, halt with the captured error and a single fallback link to the manual installer. After installing `gh`, run the `gh auth login` flow above.

5. **On "Skip"** — halt the workflow: `"Required tool '<name>' not installed. Install it then re-run /init-workspace."` Do **not** continue.

6. **On "Cancel"** — abort with `"Setup cancelled. No changes made."`

The harness **never** ends a missing-tool flow with "go install X yourself" — always prompt + install on approval. Bootstrapping Homebrew on macOS, the interactive `gh auth login`/`gh auth refresh` step, and the explicit "Skip" choice are the only exceptions.

### Step 2 — Repo Discovery

The platform is single-monorepo (`<org>/platform`) by design, so this step typically resolves to one repo. Ask the user:

> "Provide the local path to your `platform` clone. Example: `~/dev/<org>/platform`."

For the path:
1. Verify it exists and is a git repo (`git -C <path> rev-parse --is-inside-work-tree`).
2. Identify the **default branch** locally (`git -C <path> symbolic-ref refs/remotes/origin/HEAD`) and via GitHub (`gh repo view --json defaultBranchRef -q .defaultBranchRef.name`). Expected: `develop`. If not `develop`, ask the user to confirm — the harness's two-tier model uses `develop` as the integration / default branch.
3. Confirm the **production branch** exists: `main` (protected). Verify with `git -C <path> ls-remote --heads origin main` (or `gh api repos/<org>/<repo>/branches/main`). If only `master` exists, ask the user which name to record (`main` default; `master` allowed literally if they say so).
4. Scan the repo for the **surfaces** present and **decide each surface's stack**, driven by `packs/registry.json` (`surfaces` → each entry's `dir` + the `stacks` it supports). For each surface directory that exists (`service/`, `web/`, `mobile/`) plus the logical **CROSS-CUTTING** surface (`docs/`, `.github/`, CI — not a directory requirement):
   - **Detect** the stack by testing each supported stack's `detect` files/globs from its `packs/<stack>/pack.json` (e.g. SERVICE: `go.mod` → `go`; `*.csproj`/`global.json` → `dotnet`. WEB: `turbo.json` → `react-turbo`. MOBILE: `app.config.*`/`app.json` → `expo`).
   - **If a stack is unambiguously detected**, record it and confirm with the user.
   - **If the surface is an empty scaffold (no stack files) OR detection is ambiguous, ASK the user which stack to adopt** via `AskUserQuestion` — the options are exactly that surface's `stacks` list from the registry (e.g. SERVICE → `dotnet` / `go`; WEB → `react-turbo`; MOBILE → `expo`), plus a **"Decide later (TBD)"** option. **Never silently assume the registry `default`** — stack choice is the user's decision (the `default` is only a last-resort fallback if they defer and a later phase forces one). This is the stack-decision point the user owns.
   - Record the chosen stack + its `conventions_skill` (from the pack) per surface; `TBD` only when the user explicitly defers.
5. **Worktree**: `enabled` by default; set `disabled` if a surface's Husky `commit-msg` hook references `commitlint` in a way incompatible with worktrees (e.g. Yarn PnP `.pnp.cjs` cache). Keep this as a per-workspace toggle.
6. Present extracted info to the user for confirmation.

**Adding other repos**: only via `--add <path>`. Default scope is single-monorepo; the harness's planner / orchestrator are not designed for cross-repo coordination.

### Step 3 — Conventions Extraction

For the `platform` repo, scan the codebase for **repo-specific** conventions NOT already covered by the canonical skills. Only scan surfaces that have a chosen stack (skip `TBD` surfaces).

Each surface's conventions come from its **chosen stack's pack** (`packs/<stack>/pack.json` → `conventions_skill`). Supported packs today:

- **SERVICE** → `dotnet-conventions` (`.NET 8`: C# naming, WebApi/Application/Domain/Infrastructure layering, EF Core, Wolverine/Hangfire, xUnit + FluentAssertions + Moq + Testcontainers + WebApplicationFactory + Refit, OTel/Seq) **or** `go-conventions` (`Go`: package layout, error wrapping with `%w`, context propagation, chi / pgx+sqlc / golang-migrate / asynq|river / OTel+slog / oapi-codegen, testing + testify + testcontainers-go).
- **WEB** → `react-turbo-conventions` (React 19 + Yarn + Turbo + Vite, React Query 5 + Redux Toolkit, shared design-system banned-HTML rule, Vitest + RTL + MSW).
- **MOBILE** → `expo-mobile-conventions` (Expo Router, Redux Toolkit + Persist (MMKV-backed), Firebase + Sentry, EAS secrets, `expo-secure-store`, Jest + `@testing-library/react-native`).

(To support a new language/framework, add a pack per `packs/README.md` — this list reflects the registry, it is not a fixed set.)

**Only extract** patterns specific to this repo that supplement the canonical conventions:
- Custom message handlers / job routing
- Tenant resolution / scoping middleware
- Domain-specific patterns (domain enums, aggregates, payment-provider abstractions)
- Internal shared libraries / custom design-system packages
- Deviations from canonical conventions
- Configuration patterns (env-specific config files, feature flags)
- Infrastructure specifics (payment adapter shape, email templates, push integration, Sentry-aware logging)

If a surface's stack is `TBD` (empty scaffold), record `Conventions: TBD (no stack chosen yet)` for it and move on — do not invent conventions.

Present to the user for review before saving.

### Step 4 — GitHub Configuration

**Skip if the GitHub Configuration section already exists in `platform-context.md` and you are not in `--full` mode.**

Discover values via `gh` rather than hardcoding anything. Never bake in a specific org/repo — read them from the clone + GitHub.

| Field | How to discover | Notes |
|---|---|---|
| **Org** | `gh repo view --json owner -q .owner.login` (run inside the clone, or pass `<org>/<repo>`) | e.g. `kawee-kids` |
| **Repo** | `gh repo view --json nameWithOwner -q .nameWithOwner` | e.g. `<org>/platform` |
| **Default / integration branch** | `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` | expected `develop` |
| **Production branch** | branch existence check (Step 2.3) | default `main` |
| **Feature-branch pattern** | (constant) | `features/<feature-slug>/main` |
| **User-branch pattern** | (constant) | `users/<user-slug>/<feature-slug>/<impl-slug>` (feature work) and `users/<user-slug>/bugs/<impl-slug>` (bug / no-parent-Feature) |
| **`<user-slug>`** | derive from `gh api user -q .name` (fallback `gh api user -q .login`, then `git config user.name`) | format `<last-initial>_<first-name>` lowercase — e.g. `Aliu Ameen` → `a_aliu`, `K. Moshood` → `k_moshood`. Suggest, then ask the human to confirm. |
| **Project (v2) number + owner** | `gh project list --owner <org>` | the org Project board this repo's issues live on (see flow below) |

#### User slug derivation

1. `name=$(gh api user -q .name)` (falls back to login, then `git config user.name`).
2. Split into first / last words; slug = `<lowercase last-initial>_<lowercase first-name>`.
3. Show the suggestion and confirm with the user before recording. The slug must satisfy `^[a-z0-9_]+$` (used inside `users/<user-slug>/…` branch names).

#### Project (v2) discovery + validation

1. List org projects: `gh project list --owner <org> --format json`.
2. **If exactly one** plausible board exists, propose it. **If several**, ask the user which one this repo tracks against. Record its **number** and **owner**.
3. **If none exists**, offer to create one:
   > "No GitHub Project (v2) found for org `<org>`. Create one now so the harness can track Status / Surface / Iteration / Parent? (recommended)"
   On yes: `gh project create --owner <org> --title "<org> platform"`, capture the returned number.
4. **Validate the Status field** has the harness vocabulary. Read fields with
   `gh project field-list <number> --owner <org> --format json`. The single-select **Status** field must contain options:
   `Backlog`, `Ready`, `In Progress`, `In Review`, `Done`.
   - GitHub's default Status field ships `Todo / In Progress / Done`. If options are missing, add them (UI or `gh api graphql` `updateProjectV2SingleSelectField` mutation), or tell the user which options to add. Do not proceed with a Status vocabulary the runtime writes can't satisfy.
5. Ensure (or note for creation) the additional fields the harness uses: **Surface** (single-select: `service / web / mobile / cross-cutting`), **Iteration** (optional sprint field), **Parent** (used as the sub-issue fallback). Record what exists.

Record `Project Number` + `Project Owner` in the context file — every downstream workflow reads them for `gh project item-add` / `gh project item-edit`.

#### Stack (per surface)

For each present surface, record the chosen tech + versions. Repos may be empty scaffolds, so be **TBD-aware**: detect from manifest files where possible (`.csproj`/`global.json`, `package.json`/`turbo.json`, `app.json`/`package.json`), otherwise ask, otherwise record `TBD`. Also record which conventions skill applies to that surface (or `TBD`).

#### Required labels

Ensure the harness labels exist on the repo. Run the shipped idempotent label script — `scripts/setup-labels.sh` (lives at the marketplace root; if it is not on PATH, invoke it inline via `gh label create … --force` per label). It is safe to re-run: each `gh label create` either creates or no-ops.

```bash
# Idempotent: marketplace root scripts/setup-labels.sh, or run inline.
bash scripts/setup-labels.sh <org>/<repo>     # if shipped/available
```

Labels created (with stable colors/descriptions):
- **type**: `type:epic`, `type:feature`, `type:story`, `type:task`, `type:bug`
- **surface**: `surface:service`, `surface:web`, `surface:mobile`, `surface:cross-cutting`
- **status** (optional fallback — the Project **Status** field is the source of truth; create these anyway as a lightweight, board-independent signal): `status:ready`, `status:in-dev`, `status:in-review`, `status:blocked`

If `gh` lacks permission to create labels (read-only token), warn and continue — downstream writes degrade gracefully.

### Step 4.5 — Tool Targets

Ask which AI coding tools the team uses (multi-select, default **both**):

> "**Step 4.5 — Tool targets.** Which AI coding tools should this workspace support? The same orchestrated workflow + conventions will be made available to each one. (multi-select)
> - **Claude Code** — uses the installed `platform-sdlc-harness` plugin (no repo files needed).
> - **OpenAI Codex** — scaffolds `.codex/agents/*.toml` + `.agents/skills/` + `AGENTS.md`."

Record the selection; it drives Step 7. If only Claude Code is selected, Step 7 is skipped entirely (the plugin already provides everything). `AGENTS.md` + convention bodies are written whenever **Codex** is selected.

> Note: Copilot is intentionally out of scope. To add it later, add a `portable/copilot/` subtree + `portable/mechanics/copilot.md` + a Copilot branch in Step 7.

### Step 5 — Assemble `platform-context.md`

Write the single context file at `.claude/context/platform-context.md`:

```markdown
# Platform Workspace Context

Generated by `/init-workspace`. Local-only, git-ignored.

## Repo

### platform

- **Local Path**: `~/dev/<org>/platform`
- **Type**: Monorepo (service + web + mobile + cross-cutting)
- **Surfaces present**: <subset of SERVICE / WEB / MOBILE / CROSS-CUTTING>
- **Domain**: <one line — what this product is>
- **Key Patterns**: <repo-specific, or TBD for empty scaffolds>
- **Default / Integration Branch**: `develop`
- **Production Branch**: `main`
- **Worktree**: `enabled` (or `disabled` if Husky hooks block worktrees)
- **Description**: Single in-scope monorepo containing all engineering work for this product.

## GitHub Configuration

- **Org**: `<org>` (e.g. `kawee-kids`)
- **Repo**: `<org>/platform`
- **Default / Integration Branch**: `develop`
- **Production Branch**: `main` (protected)
- **Feature-branch pattern**: `features/<feature-slug>/main` (cut off `develop` when a Story has a parent Feature)
- **User-branch pattern**:
  - Feature work: `users/<user-slug>/<feature-slug>/<impl-slug>` → PR base = `features/<feature-slug>/main`
  - Bug / no-parent-Feature: `users/<user-slug>/bugs/<impl-slug>` → PR base = `develop`
- **UserSlug**: `<last-initial>_<first-name>` lowercase, e.g. `a_aliu` (from `gh api user`)
- **Work Item Hierarchy**: Epic → Feature → Story → Task / Bug (native sub-issues; `type:*` label fallback)
- **Issue Types**: distinguished by `type:epic|feature|story|task|bug` labels (+ native Issue Types if org-enabled)
- **Surface labels**: `surface:service|web|mobile|cross-cutting`
- **Project (v2) Number**: `<n>`
- **Project (v2) Owner**: `<org>`
- **Project Status vocabulary**: `Backlog → Ready → In Progress → In Review → Done` (validated against the Project's Status field)
- **Project Fields**: Status, Surface, Iteration (optional), Parent (sub-issue fallback)

## Surfaces & Stack

> Stacks are pluggable (see `packs/registry.json`); each surface's stack is **chosen at init (Step 2.4)** and its `conventions_skill` comes from the pack. Empty scaffolds record `TBD` until a stack is chosen.

| Surface | Stack (chosen via registry) | Conventions skill |
|---|---|---|
| SERVICE | <`.NET 8` (dotnet) / `Go` (go) / TBD> | <`dotnet-conventions` / `go-conventions` / TBD> |
| WEB | <`React 19 + Turbo` (react-turbo) / TBD> | <`react-turbo-conventions` / TBD> |
| MOBILE | <`Expo` (expo) / TBD> | <`expo-mobile-conventions` / TBD> |
| CROSS-CUTTING | <shared tooling / CI / docs> | — |

## Workspace

- **Tool Targets**: <comma-separated subset of `Claude Code`, `Codex` — from Step 4.5>

## Repo-Specific Conventions

> Supplements the canonical conventions skill for each surface's chosen stack (`dotnet-conventions` / `go-conventions` / `react-turbo-conventions` / `expo-mobile-conventions`, resolved via `packs/registry.json`). For standard rules, refer to the matching conventions skill. This section contains only patterns specific to this repo. Surfaces with a `TBD` stack have no conventions yet.

### <Category — e.g. "Message handlers", "Tenant scoping", "Payment integration">

- <Convention>
- <Convention>
```

### Step 6 — Generate Permissions

**Skip if `.claude/settings.local.json` already exists, unless `--full`.**

Write `.claude/settings.local.json`, pre-approving the `gh` read/list commands (and local dev tooling) that background agents run without prompting. The stack-specific `Bash(...)` entries are the **union of `tool_permissions` from each chosen stack pack** (`packs/<stack>/pack.json`); the template below carries all supported stacks — keep the superset (harmless) or trim to the chosen stacks:

```json
{
  "permissions": {
    "allow": [
      "Read", "Write", "Edit", "Grep", "Glob",
      "Bash(ls:*)", "Bash(cd :*)", "Bash(mkdir:*)", "Bash(find:*)", "Bash(date:*)",
      "Bash(cat .claude/:*)",
      "Bash(dotnet build:*)", "Bash(dotnet restore:*)", "Bash(dotnet test:*)", "Bash(dotnet format:*)",
      "Bash(dotnet list:*)", "Bash(dotnet tool:*)", "Bash(dotnet ef:*)", "Bash(roslynator:*)",
      "Bash(go:*)", "Bash(golangci-lint:*)", "Bash(gofumpt:*)", "Bash(staticcheck:*)", "Bash(govulncheck:*)", "Bash(migrate:*)", "Bash(sqlc:*)", "Bash(oapi-codegen:*)",
      "Bash(pnpm:*)", "Bash(yarn:*)", "Bash(npm:*)", "Bash(npx:*)", "Bash(node:*)",
      "Bash(eslint:*)", "Bash(prettier:*)",
      "Bash(eas:*)", "Bash(expo:*)",
      "Bash(agent-device:*)", "Bash(maestro:*)", "Bash(react-doctor:*)",
      "Bash(semgrep:*)", "Bash(gitleaks:*)", "Bash(osv-scanner:*)", "Bash(knip:*)", "Bash(madge:*)", "Bash(size-limit:*)", "Bash(oasdiff:*)",
      "Bash(git status:*)", "Bash(git log:*)", "Bash(git diff:*)", "Bash(git fetch:*)",
      "Bash(git rev-parse:*)", "Bash(git symbolic-ref:*)", "Bash(git remote:*)", "Bash(git -C:*)",
      "Bash(git branch:*)", "Bash(git checkout:*)", "Bash(git add:*)", "Bash(git commit:*)",
      "Bash(git merge:*)", "Bash(git pull:*)", "Bash(git worktree:*)",
      "Bash(gh auth status:*)",
      "Bash(gh repo view:*)",
      "Bash(gh issue list:*)", "Bash(gh issue view:*)", "Bash(gh issue create:*)",
      "Bash(gh issue edit:*)", "Bash(gh issue comment:*)", "Bash(gh issue develop:*)",
      "Bash(gh pr list:*)", "Bash(gh pr view:*)", "Bash(gh pr diff:*)", "Bash(gh pr checks:*)",
      "Bash(gh pr create:*)", "Bash(gh pr edit:*)", "Bash(gh pr comment:*)", "Bash(gh pr review:*)",
      "Bash(gh label list:*)", "Bash(gh label create:*)",
      "Bash(gh project list:*)", "Bash(gh project view:*)", "Bash(gh project field-list:*)",
      "Bash(gh project item-list:*)", "Bash(gh project item-add:*)", "Bash(gh project item-edit:*)",
      "Bash(gh search:*)",
      "Bash(gh api:*)"
    ],
    "deny": []
  }
}
```

`git push` is intentionally NOT pre-approved — Phase 9 prompts for confirmation. `gh pr create` / `gh pr edit` / `gh pr review` are pre-approved so the orchestrator and Phase 10 reviewer can open the PR and post inline + summary comments without prompting. `gh api` is broad on purpose — sub-issue (`addSubIssue`) and Project (v2) mutations all go through `gh api graphql`.

### Step 7 — Scaffold Cross-Tool Artifacts

**Run only if `Codex` is in the Step 4.5 tool targets.** If only `Claude Code` was selected, skip this step — the installed plugin already provides everything.

Source templates live under the plugin at `${CLAUDE_PLUGIN_ROOT}/portable/`. Deploy them into the **`platform` repo root**. Use the `Write` tool for every file (UTF-8, no BOM). **Idempotent**: if a destination file already exists and differs, show a diff and ask before overwriting; never silently clobber a hand-edited `AGENTS.md`.

**Placeholder substitution** — replace in every emitted file:
- `{{PROJECT}}` → `platform`
- `{{GH_ORG}}` → the org (e.g. `kawee-kids`)
- `{{GH_REPO}}` → `<org>/platform`
- `{{PROJECT_NUMBER}}` → the Project (v2) number (GitHub Configuration → Project Number)
- `{{USER_SLUG}}` → GitHub Configuration → UserSlug
- `{{PROD_BRANCH}}` → `main`
- `{{INTEGRATION_BRANCH}}` → `develop`

#### 7a — Always (Codex selected)

1. **`AGENTS.md`** (repo root) ← `portable/AGENTS.md.tmpl` with placeholders filled.
2. **Convention + advisory skill bodies** → copy into `.agents/skills/` (Codex reads these natively), **driven by the chosen stack packs**. For each surface with a chosen stack (skip `TBD` surfaces — re-run via `--scaffold-tools` once a stack is adopted), read `packs/<stack>/pack.json` and copy:
   - its `conventions_skill` body: `skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md` (e.g. `dotnet`→`dotnet-conventions`, `go`→`go-conventions`, `react-turbo`→`react-turbo-conventions`, `expo`→`expo-mobile-conventions`);
   - each entry in its `advisory_skills` body: `skills/<name>/SKILL.md` → `.agents/skills/<name>/SKILL.md`. These resolve per stack — e.g. `dotnet` → `dotnet-code-quality`, `migration-safety`, `api-contract-check`, `security-scan`, `observability`; `go` → `go-code-quality`, `api-contract-check`, `security-scan`, `observability`; `react-turbo`/`expo` → `react-doctor`, `dead-code-analysis`, `bundle-budget`, `security-scan`, `observability`; `expo` also → `expo-doctor`, `agent-device`, `maestro-e2e`. **Deduplicate** skills shared across surfaces (copy once).
   - `agents/shared/engineering-principles.md` → `.agents/skills/engineering-principles/SKILL.md` (all surfaces), **prepending** SKILL.md frontmatter:
     ```
     ---
     name: engineering-principles
     description: Universal engineering principles (SOLID / DRY / YAGNI) applied to all code in all languages. Read when writing or reviewing any code.
     ---
     ```
   Copy bodies verbatim — they are already valid SKILL.md skills. Because the copy set is the **union of each chosen pack's `conventions_skill` + `advisory_skills`**, adding a new stack pack automatically scaffolds its skills here with no edit to this step.

#### 7b — Codex agents and workflow skills

3. **`.codex/agents/<name>.toml`** ← for each of orchestrator, planner, developer, reviewer, tester, take the static TOML from `portable/codex/agents/<name>.toml` and replace the `{{DEVELOPER_INSTRUCTIONS}}` line inside the triple-quoted `developer_instructions` string with the concatenation of `portable/mechanics/codex.md` + `portable/roles/<name>.md`. **TOML-escape**: the body uses `"""` strings, so escape any literal `"""` (none expected) and keep the closing `"""` on its own line.
4. **`.agents/skills/platform-<workflow>/SKILL.md`** ← for each of `platform-discovery-workflow`, `platform-backlog-workflow`, `platform-dev-workflow`, `platform-pr-review`, take `portable/codex/skills/platform-<workflow>/SKILL.md` and replace the `{{WORKFLOW_BODY}}` marker with the contents of the matching `portable/workflow/<workflow-name>.md` (`discovery-workflow`, `backlog-workflow`, `dev-workflow`, `pr-review`).

#### 7c — Optional data-policy guard

Ask: *"Install the portable data-policy guard (pre-commit hook + GitHub Actions secret scan)? Recommended for Codex, which lacks Claude's runtime hooks."* If yes:
- copy `portable/guards/pre-commit` → `.git/hooks/pre-commit` (and `chmod +x`), or wire via the repo's Husky setup if present.
- copy the GitHub Actions secret-scan guard from `portable/guards/` → `.github/workflows/secret-scan.yml`, so every PR to `develop` / `features/*/main` runs the scan as a CI backstop. (This replaces the old Azure Pipelines guard; it is the GitHub Actions equivalent shipped under `portable/guards/`.)

#### 7d — Update `.gitignore`

Ensure the local-only artefacts are ignored and the scaffolded files are **not** (see the git-ignore split in *Output Files*). Add the local entries (`ai/`, `.claude/context/`, `.claude/settings.local.json`, `.claude/logs/`) if missing; never add `AGENTS.md`, `.agents/`, `.codex/`, or `.claude/settings.json` to `.gitignore`.

### Step 8 — Summary

After all steps complete:

> "Workspace initialised:
> - `platform-context.md` — `<org>/platform` repo, GitHub config (Project #<n>), surfaces/stack, tool targets, conventions (local)
> - `settings.local.json` — background agent permissions pre-approved (local)
> - Labels ensured on `<org>/platform` (type / surface / status)
> - Tool targets: <list>. Scaffolded for Codex: <AGENTS.md, .codex/…, .agents/skills/… — or "none (Claude Code only)">
>
> Local artefacts are git-ignored. The committed `.claude/settings.json` (marketplace config) stays tracked. The scaffolded `AGENTS.md`, `.agents/skills/`, and `.codex/` are team-shared — **commit them** so teammates on Codex inherit the workflow.
> You're ready to use `/dev-workflow` and `/backlog-workflow` (Claude), or the `platform-dev-workflow` skill (Codex)."

## Flags

- `--full` — Force full regeneration, including re-running Step 7 scaffolding. Confirms before overwriting.
- `--refresh-conventions` — Regenerate only the Repo-Specific Conventions section.
- `--scaffold-tools` — Re-run only Step 7 (cross-tool scaffolding) against the current Tool Targets. Use after editing the `portable/` templates, adding a tool target, or adopting a stack for a previously-`TBD` surface. Re-prompts the Step 4.5 selection if no Tool Targets are recorded yet.
- `--add <path>...` — Add an extra repo to the workspace (rarely needed — platform is single-monorepo by design).

## --add Behavior

When `--add` is passed, skip the normal init flow.

### Prerequisites

`.claude/context/platform-context.md` must exist. If missing → "Workspace not initialized — run `/init-workspace` first."

### Steps

For each path passed after `--add` (or asked for interactively):

1. Verify the path exists and is a git repo. If invalid, report and continue with remaining paths.
2. Check the **Repo** section of `platform-context.md` for an existing entry with the same name (case-insensitive). Duplicate → skip with `"<name> is already registered. Skipping."`
3. Scan and extract metadata as in Step 2 of the normal init flow.
4. Present for confirmation, apply corrections.
5. **Append** a new `### <repo-name>` block to the **Repo** section. Never overwrite existing entries. Never touch the GitHub Configuration section.
6. If `--refresh-conventions` was also passed, scan the new repo and append patterns to the **Repo-Specific Conventions** section.
7. Summarise: `"Added [N] repo(s). [total] repos now registered."`

> Caveat: the harness's planner/orchestrator assume single-monorepo scope. Multi-repo registrations are recorded but the dev-workflow planner will still ask which repo each Story touches; cross-repo coordination is unsupported.
