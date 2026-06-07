# Technical Notes Template

This is the output format for the Technical notes section produced by `/backlog-enrich`. **Per-surface** breakdown (the monorepo holds multiple surfaces under `service/`, `web/`, `mobile/`) — NOT per-repo as in multi-repo organisations.

The notes go to two places (per the user's choice in `/backlog-enrich` Step 6):
- **Body** — appended to / replaces the Story's `## Technical notes` section (GitHub renders Markdown natively — no HTML conversion).
- **Comment** — full report posted as a GitHub issue comment (always, regardless of body write choice — for audit trail).

Adapt the concrete component names below to the repo's actual conventions in `.claude/architecture/*` + `.claude/rules/*`; the canonical-stack defaults (dotnet / react-turbo / expo) are placeholders.

```markdown
## Technical notes (`/backlog-enrich` at <UTC timestamp>)

### Affected surfaces
- [SERVICE | WEB | MOBILE | combinations] — <area>, per `.claude/architecture/<area>/<surface>.md`

### SERVICE analysis (omit if not affected)

**Affected microservices**: <service(s)> ([Lean | Medium | Full] complexity per `.claude/rules/backend/code-style.md`)

**Affected layers**: [WebApi | WebApiCore | Core | EFData | DataContract | Model | Worker | ClientSDK]

**Concrete files** (file:line — purpose):
- `service/<service>/.../<File>.cs:<line>` — <what changes / what to add>
- `service/<service>/.../<File>.cs:<line>` — <what changes / what to add>

**Patterns this will use**:
- [MediatR CQRS Command/Query + Handler — name them]
- [Event handler — must be idempotent, locate in `<service>.Worker/Handlers/`]
- [Background job — locate in `<service>.Worker/Jobs/`]
- [Outbox pattern — write event in same DB transaction as state change]
- [Cache pattern — get-with-factory + invalidation by pattern]
- [AutoMapper profile addition in `<service>.Core/<Feature>Mappings.cs`]
- [EF entity configuration in `<service>.EFData/Configurations/`]
- [Migration needed — additive / breaking]

**Integration touch-points** (whichever the repo's architecture docs name):
- [Payment provider client]
- [Email provider client]
- [Push-notification provider client]
- [AI / LLM client]
- [Error monitoring]

**Tests needed**:
- Unit: `<service>.UnitTests/Features/<Feature>Tests.cs` — <count> new tests
- Integration: `<service>.IntegrationTests/Features/<Feature>Tests.cs` — inherits the base test, uses `[Collection]`, Testcontainers. Happy path + <error case> + <edge case>
- Outbox testing: drain → clear recording API → process → assert notification sent
- Coverage target: **SERVICE** per `.claude/rules/backend/testing.md`

### WEB analysis (omit if not affected)

**Affected app(s)**: [`web/apps/<app>` …]

**Shared packages to extend**: [UI components | data-fetching hooks | DTO models | state slices | helpers]

**Concrete files**:
- `web/apps/<app>/src/pages/<Page>.tsx:<line>` — <what changes>
- `web/packages/<pkg>/src/<file>.ts:<line>` — <what changes>

**Patterns this will use**:
- Design-system components (never raw `<div>`/`<button>` per `.claude/rules/web/code-style.md` → Banned Elements)
- React Query via the shared hooks (`useFetchData` / `useFetchSingleData` / `useMutateData` / `useFilteredPagedData`) — never raw `useQuery`
- State slice for UI state (modals, identity); React Query for server state
- Layout from the shared layout components (app-shell / filter-page / detail-page / two-column)
- Service interface + class injecting the rest-service abstraction
- Forms: React Hook Form + Yup with co-located `validation.ts`

**Tests needed**:
- Vitest + React Testing Library + MSW per `.claude/rules/web/testing.md`
- Co-located `Component.test.tsx`
- Coverage target: **WEB** per `.claude/rules/web/testing.md`

### MOBILE analysis (omit if not affected)

**Affected screens / routes** (Expo Router file paths):
- `mobile/app/(tabs)/<route>.tsx` — <what changes>
- `mobile/app/<feature>/[id].tsx` — <what changes>

**Screen containers used**: [home / detail / form / modal / back-navigation / main containers] — from `components/layout/`

**Concrete files**:
- `mobile/src/<feature>/<file>.tsx:<line>` — <what changes>

**Patterns this will use**:
- Data hooks: `useFetchGroupedData<T>` / `useFetchDetailData` / `useFetchEditData` / `useMutateData`
- State slice + persistence: [secured (SecureStore) | farm (on-device store) | feature (cleared on context switch) | global | user-local | non-persisted (in-memory)]
- Service: interface + class injecting the rest-service abstraction with static cache key methods
- Forms: React Hook Form + Yup with co-located `validation.ts`
- Lists: the repo's FlashList wrapper — NEVER raw `FlatList`
- Styling: `StyleSheet.create()` + the repo's theme / spacing / font constants — NO hardcoded hex

**Native module touch-points**:
- [Push messaging — background handler → store; foreground provider → toast]
- [Error monitoring — initialised in the app's monitoring init]
- [On-device storage (encrypted / plain)]
- [Secure storage — small secrets only]

**Tests needed**:
- Jest via jest-expo + `@testing-library/react-native` per `.claude/rules/mobile/testing.md`
- Tests in `__tests__/` mirroring `src/`
- Centralised native module mocking in `jest/setup.ts`
- Coverage target: **MOBILE** per `.claude/rules/mobile/testing.md`

### Cross-surface considerations (omit if single-surface)

[Describe coordination between SERVICE / WEB / MOBILE. Typical examples:
- Service webhook posts outbox event → notification worker consumes → push to mobile
- New cross-process contract → add to the shared `Model` project first, then consume in WEB / MOBILE
- Deployment order considerations (SERVICE before client consumers, or feature-flag for safe rollout)]

### Phase 8 Architecture Reconciliation candidates

[List components / patterns / integrations mentioned in this Story's AC that are NOT documented in the relevant `.claude/architecture/<area>/<surface>.md`. These flag updates the `/dev-workflow` Phase 8 (Architecture & Rules Reconciliation) planner will likely need to make. Don't propose the architecture change yourself — just flag the gap.]

- New: `<service>.Core.Services.RetryFailedTransactionService` — not in `.claude/architecture/<area>/service.md`. Phase 8 should add.
- New: unique index on `Transactions(ProviderReference, ProviderEventId)` — Phase 8 should add to architecture doc.

### References consulted

- `.claude/architecture/<area>/<surface>.md` — <list>
- `.claude/rules/<backend|web|mobile>/code-style.md` — <list>
- `.claude/rules/<backend|web|mobile>/testing.md` — <list>
- `.claude/CLAUDE.md`

---

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

## Guidelines

**Be concrete.** Don't say *"the auth module might be affected."* Say *"`service/identity/.../AuthController.cs:45` `LoginAsync` handles the token validation this Story modifies. Related tests: `service/tests/identity/.../AuthTests.cs:Login_*`."*

**Use the repo's real vocabulary.** Real service names, real integrations, real conventions named in `.claude/architecture/*` + `.claude/rules/*` (service-complexity model, banned-HTML rule, screen containers, persistence layers). Don't assume a specific product's components exist — read them from the docs.

**Per-surface, not per-repo.** The monorepo holds multiple surfaces; the breakdown is by SERVICE / WEB / MOBILE under the monorepo, not by independent repos.

**Start from architecture docs.** Read `.claude/architecture/<area>/<surface>.md` BEFORE grepping the codebase. The architecture doc is the authoritative component map; grep verifies what the doc says exists.

**Phase 8 reconciliation candidates** are mandatory. Every gap between the Story's AC mentions and the architecture doc must be flagged. Don't propose the architecture change yourself — that's `/dev-workflow` Phase 8's job. Just flag the gap with the doc path the human can verify.

**Don't prescribe implementation.** Frame as *"here's what I see in the code + here are the patterns this will use"*, NOT *"here's how you should implement it"*. The Developer (in dev-workflow Phase 3) makes implementation calls based on the plan, not based on technical notes.

**Risk** — not a separate section; flag risk inline within each surface's analysis where relevant. Typical risks: webhook idempotency, outbox event ordering, mobile-offline sync conflicts, web bundle-size regression, breaking typed-client contract changes.
