---
name: go-conventions
description: >
  SERVICE-stack conventions for a Go backend. Loaded by Developer, Reviewer, and
  Tester agents when a `service` task's chosen stack is Go (per packs/registry.json
  → packs/go/pack.json). Where the consuming repo has `.claude/rules/backend/` and
  `.claude/architecture/.../service.md`, those are canonical and evolve with the
  code; this skill points to them AND carries idiomatic Go guidance inline so it is
  useful on a greenfield repo before any repo rules exist.
disable-model-invocation: true
user-invocable: true
---

# SERVICE / Go Conventions

The Go pack (`packs/go/pack.json`) selects this skill for any `service` surface whose stack is **Go**. Read the repo rules first where they exist; everything below is the idiomatic baseline that applies regardless.

## Mandatory reads (every SERVICE/Go task)

1. **`.claude/rules/backend/code-style.md`** — *if present in the repo.* Project-specific naming, layering, error-handling, and DI conventions. On a greenfield repo this may not exist yet; the **Idiomatic Go baseline** below stands in until it does (and Phase 8 reconciliation should promote settled patterns into this file).
2. **`.claude/rules/backend/testing.md`** — *if present.* Otherwise follow the **Testing** section below.
3. **`.claude/architecture/<area>/service.md`** — *if present.* The architecture map for the service area you are touching.
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI. Violations are blocking findings at review.

## Recommended library stack (the boring, durable choices)

Record the concrete picks in the repo's service ADR; this is the harness's recommended default for a new Go service:

| Concern | Choice | Notes |
|---|---|---|
| Go version | **1.23+** | use the toolchain pinned in `go.mod` |
| Routing | **`net/http` + `chi`** | stdlib-first; `chi` for middleware + route groups. (echo/gin are acceptable alternatives — pick one, record it) |
| DB access | **`pgx` + `sqlc`** | type-safe SQL from `.sql` files; no heavyweight ORM. (GORM only if the team explicitly wants it) |
| Migrations | **`golang-migrate`** (or `goose`/Atlas) | versioned, reversible; see `migration-safety` advisory |
| Background jobs | **`asynq`** (Redis) or **`river`** (Postgres) | idempotent handlers |
| HTTP API contract | **design-first OpenAPI + `oapi-codegen`** (or `swag`) | so `api-contract-check`/oasdiff works |
| Config | **env vars** via `envconfig`/`koanf` | never commit secrets; 12-factor |
| Logging | **`log/slog`** (stdlib structured logging) | JSON handler in prod |
| Tracing/metrics | **OpenTelemetry-Go** | see `observability` advisory |
| Testing | **stdlib `testing` + `testify`** (`assert`/`require`) | + **`testcontainers-go`** for real-DB integration tests, `net/http/httptest` for handlers |

## Idiomatic Go baseline

### Project layout
- Module path in `go.mod` matches the repo (e.g. `github.com/kawee-kids/platform/service`).
- Keep packages small and named for what they provide (`auth`, `billing`), **not** `utils`/`common`/`helpers`.
- Put process entrypoints under `cmd/<binary>/main.go`; keep `main` tiny — wire dependencies and call into packages.
- Unexported by default; export the minimum. The package API is what's capitalised.
- No `internal/` cargo-culting — use `internal/` only to genuinely forbid external import.

### Errors
- Return `error` as the last value; **handle or return, never swallow**. A bare `_ = err` or empty `catch`-equivalent is a review finding.
- Wrap with context: `fmt.Errorf("loading child profile %s: %w", id, err)` — keep `%w` so callers can `errors.Is`/`errors.As`.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) or typed errors for branches callers must distinguish; don't string-match error text.
- `panic` only for truly unrecoverable programmer errors — never for expected failures or request handling.

### Context
- First parameter is `ctx context.Context` for anything doing I/O; propagate it to DB calls, HTTP clients, and job handlers.
- Never store a `context.Context` in a struct; pass it down the call stack.
- Respect cancellation/timeouts; set deadlines on outbound calls.

### Concurrency
- Don't reach for goroutines by default. When you do: every goroutine has a clear owner and a way to stop (context or channel).
- Guard shared state with a mutex or a channel; run `go test -race` (the pack's test command already sets `-race`).
- Use `errgroup` for fan-out with error propagation.

### API & HTTP
- Handlers are thin: decode → validate → call a service → encode. Business logic lives in service packages, not handlers.
- Validate input explicitly; return RFC-7807-style problem responses or a consistent error envelope (record the choice in the ADR).
- Set timeouts on `http.Server` (`ReadHeaderTimeout` at minimum).

### Style
- `gofumpt` formats (superset of `gofmt`) — run `gofumpt -w .` before committing. No manual formatting debates.
- `golangci-lint run` must be clean — see `go-code-quality`.
- Accept interfaces, return structs. Define interfaces in the **consumer** package, keep them small (1–3 methods).
- No global mutable state; inject dependencies via constructors (`NewServer(db, logger, ...)`).

## Testing

- Table-driven tests are the default; name subtests with `t.Run`.
- Unit tests next to code as `<file>_test.go`, package `foo` (white-box) or `foo_test` (black-box, preferred for public API).
- Use **`testify/require`** to stop on fatal preconditions, **`testify/assert`** for soft checks.
- Integration tests spin real dependencies with **`testcontainers-go`** (no mocking the DB layer); HTTP via `httptest.NewServer` / `httptest.NewRecorder`.
- **Coverage ≥ 80%** on new/modified code (unit + integration combined) — `go test ./... -race -coverprofile=coverage.out`; check with `go tool cover -func=coverage.out`. Don't chase coverage on code this story didn't touch.
- Every integration test covers at least the happy path + one key error path. No coverage-padding tests.

## Harness-process rules (cross-cut the workflow, not the codebase)

### Commits — Conventional Commits with surface scope, no issue ID
```
<type>(<surface>): <imperative lowercase description>
```
- `<type>` ∈ `feat | fix | chore | refactor | perf | docs | ci | test | build`.
- `<surface>` = `service` for Go service commits (finer scopes like `service/billing` allowed); comma-separated for multi-surface.
- **No `#<issue-id>` in the commit line** — GitHub linking happens in the PR body via `Closes #<n>`.
- Reviewer Phase 0 enforces the Conventional-Commits regex.

### Branching — two-tier model
| When | Branch | PR target |
|---|---|---|
| Story has a parent Feature | `users/<user-slug>/<feature-slug>/<impl-slug>` | `features/<feature-slug>/main` |
| Bug or no parent Feature | `users/<user-slug>/bugs/<impl-slug>` | `develop` |

`<user-slug>` = `<first-initial>_<surname>` lowercase (from `platform-context.md`).

### The hard build gate
Every commit: **`go build ./...` succeeds AND `golangci-lint run` is clean.** This is the Go analog of the .NET zero-warnings rule — the reviewer runs it independently in Phase B, never trusting the developer's claim.

### Things the reviewer auto-blocks (Phase 0 + hook backstops)
- Sensitive files: `.env*`, `.secret`, `.key`, `.pfx`, `.pem`, `serviceAccount*.json` — blocked by `sensitive-file-guard.sh`.
- Provider secrets in source — blocked by `secret-scan-guard.sh`.
- Writes under `ai/` from non-orchestrator/non-planner agents.
- Commit subject not matching the Conventional Commits regex.

## Quality & security tooling (advisory — Developer self-review + Reviewer Phase B)

`/init-workspace` installs these when a Go service is present; none blocks commits (the green `go build` + clean `golangci-lint` + data-policy hooks are the hard gates). Apply to new/modified code only.

- **Maintainability** — [`go-code-quality`](../go-code-quality/SKILL.md): `golangci-lint` (govet, staticcheck, errcheck, gosimple, ineffassign, unused, gocritic, …), `staticcheck`, `gofumpt`. The Go analog of `dotnet-code-quality`.
- **Security** — [`security-scan`](../security-scan/SKILL.md): Semgrep (Go SAST: SQL injection, weak crypto, command exec), Gitleaks (secrets), OSV-Scanner / `govulncheck` (module CVEs). Fix high/critical findings the change introduced.
- **API contract** — [`api-contract-check`](../api-contract-check/SKILL.md): when handlers/DTOs/routes change, diff the emitted OpenAPI spec (oasdiff) for breaking changes that would hurt web/mobile consumers. Requires the service to emit an OpenAPI spec (oapi-codegen design-first, or swag).
- **Migration safety** — [`migration-safety`](../migration-safety/SKILL.md): when the change adds/edits a migration (golang-migrate/goose/Atlas), review for destructive/locking ops (dropped columns, non-nullable-without-default, locking index builds) before commit. (The skill's examples are EF-Core-flavoured; the *risks* are identical for SQL migrations.)
- **Observability** — [`observability`](../observability/SKILL.md): new endpoints/handlers emit structured `slog` logs + OpenTelemetry spans; no PII in telemetry.

## PR checklist — SERVICE (Go)

> Reviewer Phase B reference (anchor `SERVICE (Go)` in `packs/go/pack.json`).

- Package layout idiomatic; `main` thin; no `utils`/`common` dumping grounds; interfaces defined in the consumer, small.
- Errors handled or wrapped with `%w` context; none swallowed; no string-matching on error text; `panic` not used for expected failures.
- `ctx context.Context` threaded through all I/O; not stored in structs; deadlines on outbound calls.
- Handlers thin (decode→validate→service→encode); business logic in service packages; input validated.
- Concurrency: every goroutine has an owner + stop path; shared state guarded; `go test -race` clean.
- DB access via `pgx`/`sqlc` (or the recorded choice); no SQL string concatenation with user input.
- `gofumpt` clean; `golangci-lint run` clean (the hard gate); `go vet`/`staticcheck` surface no new finding (`go-code-quality`).
- Migrations non-destructive/non-locking (`migration-safety`); no accidental breaking OpenAPI change (`api-contract-check`).
- New endpoints/handlers instrumented (slog + OpenTelemetry), no PII (`observability`); no secrets in source (`security-scan`); module CVEs triaged (`govulncheck`/OSV-Scanner).
- Build & tests: `go build ./...` clean; tests green; coverage ≥ 80% on new/modified code.

## See also

- [`go-code-quality`](../go-code-quality/SKILL.md) — Go linters / static analysis.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) when the task also touches WEB.
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) when the task also touches MOBILE.
- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) — the .NET service stack (the other supported `service` stack).
- [`security-scan`](../security-scan/SKILL.md) · [`api-contract-check`](../api-contract-check/SKILL.md) · [`migration-safety`](../migration-safety/SKILL.md) · [`observability`](../observability/SKILL.md).
- [`brainstorming`](../brainstorming/SKILL.md), [`grill-me`](../grill-me/SKILL.md), [`grill-with-docs`](../grill-with-docs/SKILL.md) (Planner Phase 1).
