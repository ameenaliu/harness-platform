# /backlog-enrich Command

Technical enrichment pass for a Story. Reads the canonical architecture + rules docs in the configured repo, locates the affected components in code, and produces per-surface technical notes — then writes them back to the Story issue.

## Invocation

The user types `/backlog-enrich [issue-number]`. Always human-invoked.

## Prerequisites

- `.claude/context/platform-context.md` must exist (provides **Org** + **Repo** + local clone path).
- `gh` CLI available and authenticated (`gh auth status`).
- The configured repo cloned locally — this command reads `.claude/architecture/*` + `.claude/rules/*` AND greps the source tree.

## Behavior

### Step 1 — Read the Story

Read the Story with `gh issue view <n> --json title,body,labels,comments` to get the title, body (Story / Acceptance criteria / Surface / Notes / optional sections), labels (`type:*`, `surface:*`), parent Feature (via the sub-issue link), current Technical notes (from the body or comments), and the `[<surface>]` title segment.

If the Story isn't refined yet (no clear AC, missing Story statement, no Surface), suggest:
> "This Story isn't fully refined yet (missing AC / Surface / parent Feature). Technical enrichment is more effective on refined items. Run `/backlog-improve` or `/backlog-refine` first?"

Proceed only if the user wants to continue anyway.

### Step 2 — Identify Affected Surfaces + Areas

Parse the title's `[<surface>]` segment(s) to get the affected surfaces (`service` / `web` / `mobile` / `cross-cutting`).

Infer the affected **area** from the parent Feature title + Story title + AC. Areas map to `.claude/architecture/<area>/<surface>.md` paths. Read the available area folders from the repo's `.claude/architecture/` directory rather than assuming a fixed set — the area names are repo-specific.

Present the inferred map to the user for confirmation:
> "Based on the Story, I'll analyse:
> - `[service]` → `.claude/architecture/<area>/service.md`
> - `[mobile]` → `.claude/architecture/<area>/mobile.md`
>
> Right? Anything to add or remove?"

Wait for confirmation.

### Step 3 — Verify Repo State

Local clone path from `platform-context.md`. Verify:

1. **Path exists** as a git repo.
2. **On the integration branch**: `git -C <path> branch --show-current` should be the repo's integration branch (typically `develop`, from `platform-context.md`). If not:
   > "⚠️ The repo is on branch `users/x_y/.../...`, not `develop`. Technical analysis should be based on the latest `develop` to be accurate. Proceed anyway, or switch first?"
3. **Up to date**: `git -C <path> rev-list HEAD..origin/develop --count`. If behind:
   > "⚠️ The repo is N commits behind origin/develop. Proceed with local version, or pull first?"
4. **No uncommitted changes** (warn only): `git -C <path> status --porcelain | head`. Uncommitted local edits could pollute the scan — surface but allow proceed.

Only proceed once the user confirms the state.

### Step 4 — Analyze (architecture-doc-driven, NOT blind grep)

**Strategy**: start from the architecture docs (authoritative); then verify in code. Do not start by `grep`-ing — that produces noise.

For each affected surface:

1. **Read the architecture doc** for the matching area + surface: `.claude/architecture/<area>/<surface>.md`. This is the authoritative component map.
2. **Read the rules** for the surface: `.claude/rules/<backend|web|mobile>/{code-style,testing}.md`. Internalise the patterns the dev will follow.
3. **For each AC** mentioned in the Story:
   - Locate the responsible component(s) in the architecture map (which service / which layer / which web app / which mobile screen).
   - Use `Grep` (content) + `Glob` (file patterns) + `Read` (full-file inspection) to find the actual files. NEVER use Bash for searches — always use the dedicated tools.
   - Record file paths + line numbers + class/method names.
4. **Identify per surface** (the analysis dimensions — these are the canonical-stack defaults; defer to the repo's actual conventions in `.claude/rules/*` + `.claude/architecture/*` when they differ):

   **SERVICE** (`.NET` — see `skills/dotnet-conventions/`):
   - Affected microservice(s) and which layer(s) per the repo's service-complexity model (e.g. WebApi, WebApiCore, Core, EFData, DataContract, Model, Worker, ClientSDK).
   - [Command/Query + Handler — if the service uses CQRS (e.g. MediatR)]: new Commands / Queries / Handlers / Validators (full services only).
   - Services + interfaces to add/modify (`{Entity}Service` / `I{Entity}Service`).
   - Repository changes (`{Entity}Repository`).
   - Entity / DTO / [mapping profile — if the service uses a mapper (e.g. AutoMapper)] changes.
   - EF Core: DbContext changes, new entity configurations, migrations needed.
   - Event handlers (`Worker/Handlers/`) — must be idempotent (if the service uses a message/worker layer).
   - Background jobs (`Worker/Jobs/`).
   - [Outbox / transactional messaging — if the service uses it]: identify transactions that need outbox-pattern dispatching.
   - Cache: identify reads needing a cache get/factory + invalidation patterns.
   - Integration touch-points: payment provider, email provider, push-notification provider, error monitoring, AI/LLM client — whichever the repo's architecture docs name.
   - Auth / authorization: which authorization resource needed.
   - Typed HTTP clients (e.g. Refit `I{Entity}Api`) where used, for cross-service calls.
   - Test additions: which unit / integration test projects; mention Testcontainers + base-test + collection patterns; outbox/notification testing flow where applicable. Defer to `.claude/rules/backend/*`.

   **WEB** (React + Turbo monorepo — see `skills/react-turbo-conventions/`):
   - Affected app(s) under `apps/`.
   - Shared packages to extend (UI primitives, data-fetching hooks, DTO models, state slices, helpers).
   - Banned-raw-HTML rule: new components use the design-system primitives — never raw `<div>`/`<button>` (per `.claude/rules/web/code-style.md`).
   - React Query hooks: which `useFetchData` / `useFetchSingleData` / `useMutateData` / `useFilteredPagedData` calls; never raw `useQuery`/`useMutation`.
   - Services: which `I{Entity}Service` interface + impl needed.
   - State slices: UI state only (modals, identity, toggles) — server data lives in React Query.
   - Layout components: which app-shell / filter-page / detail-page / two-column layout to compose.
   - Routing additions: nested routes.
   - Styling tokens: custom palette tokens from the repo's Tailwind config.
   - Test additions: Vitest + RTL + MSW patterns; the repo's render-with-providers utility.

   **MOBILE** (Expo + React Native — see `skills/expo-mobile-conventions/`):
   - Affected screens (Expo Router file paths under `app/`).
   - Screen containers from `components/layout/`.
   - Data hooks: `useFetchGroupedData<T>` / `useFetchDetailData` / `useFetchEditData` / `useMutateData` — which to add or modify.
   - State slices + persistence layer choice — follow the repo's `.claude/rules/mobile/code-style.md` for state/persistence layers.
   - Services: interface + class injecting the rest-service abstraction; static cache key methods.
   - Forms: React Hook Form + Yup; co-located `validation.ts`.
   - Lists: the repo's FlashList wrapper, not raw `FlatList`.
   - Native module touch-points: push messaging, error monitoring, on-device storage, secure storage.
   - Styling: `StyleSheet.create()` + the repo's theme/spacing/font constants — no hardcoded hex.
   - Test additions: Jest + `@testing-library/react-native`; centralised mocks in `jest/setup.ts`; the repo's coverage threshold.

5. **Be concrete.** Don't say *"the auth module might be affected."* Say *"`<service>/.../AuthController.cs:45` `LoginAsync` handles the token validation this Story modifies. Related tests: `.../AuthTests.cs:Login_*`."*

6. **Phase 8 reconciliation candidates** (mandatory): if AC mentions a component, integration, or pattern that is **NOT** documented in `.claude/architecture/<area>/<surface>.md`, flag it as a Phase 8 candidate. Don't propose the architecture change yourself; just record it so the dev-workflow's Phase 8 planner picks it up after implementation.

### Step 5 — Produce Technical Notes

Follow `templates/technical-notes.md`. Structure (Markdown — GitHub renders it natively):

```markdown
## Technical notes (`/backlog-enrich` at <UTC timestamp>)

### Affected surfaces
- SERVICE — <service/area> (per `.claude/architecture/<area>/service.md`)
- MOBILE — <app/area> (per `.claude/architecture/<area>/mobile.md`)

### SERVICE analysis
**Affected microservices**: <service> (<complexity tier>)
**Affected layers**: WebApi, WebApiCore, Core, EFData
**Concrete files**:
- `<service>/.../CreateTransactionCommandHandler.cs` — add idempotency check
- `<service>/.../TransactionService.cs:78` — wrap in the repo's transaction wrapper with a named local method
- `<service>/.../TransactionConfiguration.cs` — add unique index on (ProviderReference, ProviderEventId)

**Patterns this will use**:
- [Command/Query + Handler — if the service uses CQRS (e.g. MediatR)] (full service)
- [Outbox / transactional messaging — if the service uses it] (write `TransactionConfirmed` event in the same DB transaction as the state change)
- Event handler `TransactionConfirmedHandler` in `<service>.Worker/Handlers/` — must be idempotent on `ProviderEventId` (if the service uses a message/worker layer)
- Cache invalidation after the state change

**Tests needed**:
- Integration test: `<service>.IntegrationTests/Features/TransactionTests.cs` — happy path + duplicate-webhook idempotency + invalid-signature path. Inherits the base test, uses Testcontainers.
- Outbox testing: drain → clear recording API → process → assert notification sent.

### MOBILE analysis
...same structure...

### Cross-surface considerations
- The service webhook posts an outbox event consumed by the notification worker → push to mobile.
- Mobile listens via the background message handler + foreground push provider.
- No new contracts between Service and Mobile; the existing DTO is sufficient.

### Phase 8 reconciliation candidates
- `<service>.Core/Services/TransactionService.cs` introduces a new public method `RetryFailedTransactionAsync` — not in `.claude/architecture/<area>/service.md` today. Phase 8 should add it.
- New unique index on the Transactions table — `.claude/architecture/<area>/service.md` should mention the idempotency strategy.

### References
- `.claude/architecture/<area>/service.md`
- `.claude/architecture/<area>/mobile.md`
- `.claude/rules/backend/code-style.md`
- `.claude/rules/backend/testing.md`
- `.claude/rules/mobile/code-style.md`
- `.claude/rules/mobile/testing.md`
```

### Step 6 — Present and Confirm

Show the technical notes in conversation. Then ask:
> "Apply? Options: (A) UPDATE the Story body's `## Technical notes` section + post a comment with the full report, (B) COMMENT ONLY (don't touch the body). Pick?"

If the user wants tweaks, iterate. Developer input is valuable mid-analysis — they may know about planned refactors, tech debt, or constraints not visible in code.

**Write A** (UPDATE body, default):

Read the current body, replace the `## Technical notes` section with the new notes (or append a `## Technical notes` section at the bottom if absent), preserving all other sections (Story, In/Out of Scope, Acceptance criteria, Surface, Implementation dependencies, Open Questions, Notes / links). Write the merged Markdown to a temp file, then:

```bash
gh issue edit <n> --body-file <body.md>
```

GitHub renders Markdown natively — no MD→HTML conversion. Use `##`/`###` headers, `-` bullets, fenced code blocks, and `#<n> (<human-id> <title>)` references for cross-links.

**Write B** (always, regardless of A choice):

Write the full report to a temp file and post with `gh issue comment <n> --body-file <file>`:

```markdown
## Technical notes posted via `/backlog-enrich` at <UTC timestamp>

<full report — same Markdown as the body update>
```

Report back: updated issue URL + comment URL.

## Important

- **Start from `.claude/architecture/<area>/<surface>.md`, not from grep.** Blind grep produces noise; the architecture doc is the authoritative map. Use it to know what's supposed to exist, then verify in code via `Grep`/`Glob`/`Read`.
- **Never use Bash for searches** — use `Grep`/`Glob`/`Read` tools. Bash searches are slower and lose tool-call audit. (Bash is fine for the read-only `git -C <path>` repo-state checks in Step 3 and for `gh` writes.)
- **Never auto-switch git branches or auto-pull.** Only check + report status. The developer controls their git state.
- **Phase 8 reconciliation candidates section is non-negotiable.** Every AC mention of a component / pattern absent from the architecture doc must be flagged for Phase 8.
- **Be concrete** — file paths + line numbers + class/method names. Vague analysis is worthless.
- **Don't prescribe implementation.** Frame as *"here's what I see in the code"*, not *"here's how you should implement it."*. The Developer (in dev-workflow Phase 3) makes implementation calls based on the plan, not based on this technical notes pass.
- **If a scan reveals concerning tech-debt unrelated to the Story**, mention briefly (1-2 lines) but keep focus on the item at hand. Don't derail enrichment with unrelated findings.
- **If you cannot determine technical impact with reasonable confidence, say so explicitly.** *"I couldn't determine how the X cache is currently invalidated — this should be discussed during dev-workflow Phase 2 planning."* is a valid + helpful finding.
- **No source-file writes — issue edits + comments only.** Enrichment never modifies source code or `.claude/architecture/*` — that's `/dev-workflow` Phase 3 (developer) and Phase 8 (planner architecture-audit) respectively.
