---
name: dotnet-conventions
description: >
  Pointer to the the project SERVICE stack rules + architecture. Loaded by Developer,
  Reviewer, and Tester agents when a task is tagged SERVICE. The canonical rules
  live in the this repo under `.claude/rules/backend/` and
  `.claude/architecture/{farm-management,marketplace}/service.md` — this skill
  tells the agent where to read them so they evolve with the codebase, not with
  the harness.
disable-model-invocation: true
user-invocable: true
---

# SERVICE / .NET Conventions — Pointer

**This skill is a thin pointer.** The canonical the project SERVICE rules + architecture live in the this repo and evolve with the code. Read them directly:

## Mandatory reads (every SERVICE task)

1. **`.claude/rules/backend/code-style.md`** — naming, file/code organisation, Service Complexity Spectrum (Lean/Medium/Full), layering rules, async/CancellationToken, controllers, MediatR CQRS, services, caching (Redis), repositories, entities, DTOs, AutoMapper, workers (Wolverine + Hangfire), DI registration, error handling, code style.
2. **`.claude/rules/backend/testing.md`** — xUnit + FluentAssertions + Moq + Testcontainers + WebApplicationFactory + Refit. `BaseTests` + `[Collection]` pattern. Outbox notification testing.
3. **`.claude/architecture/<area>/service.md`** where `<area>` matches the affected service area:
   - `.claude/architecture/farm-management/service.md` — the monorepo, Identity, Notification, Platform service area
   - `.claude/architecture/marketplace/service.md` — Marketplace service area
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI.

## Harness-process rules (encoded here because they cross-cut the workflow, not the codebase)

### Commits — Conventional Commits with stack scope, no work item ID

```
<type>(<stack>): <imperative lowercase description>
```

- `<type>` ∈ `feat | fix | chore | refactor | perf | docs | ci | test`.
- `<stack>` ∈ `service` (for SERVICE commits), `web`, `mobile`, comma-separated for multi-stack.
- **NO `#<work-item-id>` in commit lines.** the project links Work Items via the PR's Work Items panel.
- Enforced by Reviewer Phase 0 regex `^(feat|fix|chore|refactor|perf|docs|ci|test)\(([a-z]+([a-z]+)*)\):\s+[a-z].*$`.

### Branching — the project two-tier model

| When | Branch |
|---|---|
| Backlog Item has parent Feature | `features/<feature-slug>/master` (cut from `develop`) + `users/<user-slug>/<feature-slug>/<impl-slug>` (cut from feature/master). PR target = feature/master. |
| Bug OR no parent Feature | `users/<user-slug>/bugs/<impl-slug>` (cut from `develop`). PR target = `develop`. |

`<user-slug>` = `<last-initial>_<first-name>` lowercase (e.g. `a_aliu`).

> If `.claude/CLAUDE.md` in the repo says `feature/<snake-case>` from develop, **that text is stale** — the live convention is the two-tier model above (as actually used in current PRs). Phase 8 (Architecture & Rules Reconciliation) is the place to clean up stale rules.

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
- Wolverine/Hangfire handlers idempotent; outbox writes inside the same transaction as state changes.
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
