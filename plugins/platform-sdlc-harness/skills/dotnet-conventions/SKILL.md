---
name: dotnet-conventions
description: >
  Pointer to the project SERVICE stack rules + architecture. Loaded by Developer,
  Reviewer, and Tester agents when a task is tagged SERVICE. The canonical rules
  live in this repo under `.claude/rules/backend/` and
  `.claude/architecture/<area>/service.md` — this skill
  tells the agent where to read them so they evolve with the codebase, not with
  the harness.
disable-model-invocation: true
user-invocable: true
---

# SERVICE / .NET Conventions — Pointer

**This skill is a thin pointer.** The canonical SERVICE rules + architecture live in this repo and evolve with the code. Read them directly:

## Mandatory reads (every SERVICE task)

1. **`.claude/rules/backend/code-style.md`** — naming, file/code organisation, Service Complexity Spectrum (Lean/Medium/Full), layering rules, async/CancellationToken, controllers, services, caching, repositories, entities, DTOs, DI registration, error handling, code style. Where the repo's rules call for them: CQRS command/query + handlers (e.g. MediatR), a mapping profile (e.g. AutoMapper), and background workers (e.g. Wolverine + Hangfire) — apply only when the service actually uses those patterns.
2. **`.claude/rules/backend/testing.md`** — xUnit + FluentAssertions + Moq + Testcontainers + WebApplicationFactory; typed HTTP clients (e.g. Refit) where used. `BaseTests` + `[Collection]` pattern. Outbox / transactional-messaging testing if the service uses it.
3. **`.claude/architecture/<area>/service.md`** where `<area>` matches the affected service area — refer to the service areas / apps defined in the repo's architecture docs.
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI.

## Harness-process rules (encoded here because they cross-cut the workflow, not the codebase)

### Commits — Conventional Commits with stack scope, no issue ID

```
<type>(<stack>): <imperative lowercase description>
```

- `<type>` ∈ `feat | fix | chore | refactor | perf | docs | ci | test`.
- `<stack>` ∈ `service` (for SERVICE commits), `web`, `mobile`, comma-separated for multi-stack.
- **NO `#<issue-id>` in commit lines.** GitHub links issues via the PR body `Closes #<issue>`.
- Enforced by Reviewer Phase 0 regex `^(feat|fix|chore|refactor|perf|docs|ci|test)\(([a-z]+([a-z]+)*)\):\s+[a-z].*$`.

### Branching — single-branch model

| When | Branch |
|---|---|
| Story (parent Feature is backlog structure only) | `users/<user-slug>/features/<impl-slug>` (cut from `develop`). PR target = `develop`. |
| Bug | `users/<user-slug>/bugs/<impl-slug>` (cut from `develop`). PR target = `develop`. |

`<user-slug>` = `<last-initial>_<first-name>` lowercase (e.g. `a_aliu`). The item Feature (Epic → Feature → Story → Task) is a backlog grouping — it does not map to a git branch.

> If `.claude/CLAUDE.md` in the repo says `feature/<snake-case>` from develop, **that text is stale** — the live convention is the single-branch model above (every Story/Bug branches off `develop`, PR base `develop`). Phase 8 (Architecture & Rules Reconciliation) is the place to clean up stale rules.

### Coverage thresholds (used by Reviewer Phase B + Tester Phase 6)

- **SERVICE**: ≥ 80% line coverage on new/modified code (unit + integration combined). Every integration test hits at least the happy path and one key error path.

### Things the reviewer auto-blocks (Phase 0 + hook backstops)

- Sensitive files: `.env*`, `.secret`, `.key`, `.pfx`, `.pem`, `serviceAccount*.json`, `appsettings.{Production,Local}.json` — blocked by `sensitive-file-guard.sh`.
- Provider secrets in source: Paystack `sk_/pk_`, SendGrid `SG.x.y`, Firebase `AIza[35]`, Sentry DSN, OpenAI `sk-/sk-proj-`, Azure storage `AccountKey=`, Azure SAS `sig=` — blocked by `secret-scan-guard.sh`.
- Writes under `ai/` from non-orchestrator/non-planner agents — Phase 0 catches these.
- Commit subject that doesn't match the Conventional Commits regex — Phase 0 catches.

### Quality & security tooling (advisory — Developer self-review + Reviewer Phase B)

`/init-workspace` installs these when SERVICE is present; none blocks commits (the zero-warnings `dotnet build` + data-policy hooks remain the hard gates). Apply to new/modified code only.

- **Security** — [`security-scan`](../security-scan/SKILL.md): Semgrep (C# SAST), Gitleaks (secrets), and `dotnet list package --vulnerable` (NuGet CVEs). Fix high/critical findings the change introduced.
- **Maintainability** — [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md): Roslynator analyzers/refactorings (+ optional SonarAnalyzer.CSharp) and `dotnet list package --outdated`. Triage findings through SOLID/DRY/YAGNI.
- **Migration safety** — [`migration-safety`](../migration-safety/SKILL.md): when the change adds/edits an EF Core migration, review for destructive/locking ops (dropped columns, non-nullable-without-default, locking index builds) before commit.
- **API contract** — [`api-contract-check`](../api-contract-check/SKILL.md): when controllers/DTOs/routing change, diff the OpenAPI spec (oasdiff) for breaking changes that would hurt web/mobile consumers.
- **Observability** — [`observability`](../observability/SKILL.md): new endpoints/handlers emit structured Serilog logs + OpenTelemetry traces; no PII in telemetry.

## PR checklist — SERVICE (.NET)

> Reviewer Phase B reference (anchor `SERVICE (.NET)` in `packs/dotnet/pack.json`).

- Layered structure respected (WebApi → Application → Domain → Infrastructure); domain has zero infra deps; no business logic in controllers; minimal APIs documented.
- Background/message handlers idempotent (e.g. Wolverine/Hangfire, where the service uses them); outbox / transactional-messaging writes inside the same transaction as state changes, if the service uses that pattern.
- Integration tests use a real DB (no mocks for the repository layer).
- Roslynator surfaces no new maintainability finding from the diff (`dotnet-code-quality`); any EF Core migration is non-destructive/non-locking (`migration-safety`); no accidental breaking OpenAPI change (`api-contract-check`).
- New endpoints/handlers instrumented (Serilog/OpenTelemetry, no PII) (`observability`); no secrets in source (`security-scan`).
- Build & tests: `dotnet build` zero warnings; tests green; coverage ≥ 80% on new/modified code.

## See also

- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) when the task also touches WEB.
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) when the task also touches MOBILE.
- [`security-scan`](../security-scan/SKILL.md) — SAST + secrets + dependency CVEs (all surfaces).
- [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md) — .NET maintainability analyzers.
- [`migration-safety`](../migration-safety/SKILL.md) — EF Core migration review.
- [`api-contract-check`](../api-contract-check/SKILL.md) — OpenAPI breaking-change detection.
- [`observability`](../observability/SKILL.md) — logging / tracing / error capture.
- [`brainstorming`](../brainstorming/SKILL.md) (Planner Phase 1 — explore design before approaches).
- [`grill-me`](../grill-me/SKILL.md), [`grill-with-docs`](../grill-with-docs/SKILL.md) (Planner Phase 1 — sharpen clarifying questions).
- [`brainstorming`](../brainstorming/SKILL.md) (Planner Phase 1 — explore design before approaches).
- [`grill-me`](../grill-me/SKILL.md), [`grill-with-docs`](../grill-with-docs/SKILL.md) (Planner Phase 1 — sharpen clarifying questions).
