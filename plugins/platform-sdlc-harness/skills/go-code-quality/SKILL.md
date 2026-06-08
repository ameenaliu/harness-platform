---
name: go-code-quality
description: >
  Analyze SERVICE (Go) code for maintainability, code smells, and quality issues
  beyond what `go build` catches, using golangci-lint (aggregated linters),
  staticcheck, go vet, and gofumpt formatting, plus dependency hygiene via
  `go list -m -u all`. Load this in the Developer self-review and Reviewer Phase B
  for Go SERVICE tasks. Advisory — scoped to the change; never a commit gate (a
  clean `go build` + clean `golangci-lint run` remain the hard gate).
user-invocable: true
---

# go-code-quality — golangci-lint + staticcheck (service)

The Go counterpart to [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md)
(.NET service). It targets Go **maintainability and clean code** — error handling
bugs, ineffectual assignments, unused code, needless complexity, shadowed
variables, non-idiomatic constructs — and dependency freshness.

| Tool | Role |
|---|---|
| **golangci-lint** | The aggregator: runs govet, staticcheck, errcheck, gosimple, ineffassign, unused, gocritic, revive, and more in one pass. The primary agent-runnable quality scan. |
| **staticcheck** | Deep static analysis (the `SA`/`ST`/`QF` rule families); bundled inside golangci-lint but also runnable standalone for detail. |
| **go vet** | Stdlib correctness checks (printf args, struct tags, lock copies); also bundled in golangci-lint. |
| **gofumpt** | Stricter `gofmt` — formatting is non-negotiable and not a review debate. |
| **`go list -m -u all`** / **`govulncheck`** | Dependency freshness (govulncheck pairs with CVE scanning in [`security-scan`](../security-scan/SKILL.md)). |

> The harness already requires a clean `go build ./...` **and** a clean
> `golangci-lint run` — that's the hard gate. This skill is the **advisory** layer
> on top: enabling a richer linter set and triaging maintainability findings a
> minimal lint pass still allows.

## When to use it

- **Developer (Phase 3), Go SERVICE**: before committing, run `golangci-lint run`
  on the affected packages; fix findings your change introduced (unhandled errors,
  shadowing, dead code, over-complex funcs). Run `gofumpt -w .`.
- **Reviewer (Phase B), Go SERVICE**: run it on the affected packages; raise new
  high-value findings as `[R<n>]` comments. Cross-check against the
  engineering-principles (SOLID/DRY/YAGNI).

## Prerequisites / install

```bash
# golangci-lint — the aggregator (init-workspace installs when a Go service is present)
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
# gofumpt — stricter formatter
go install mvdan.cc/gofumpt@latest
# govulncheck — official module vulnerability scanner
go install golang.org/x/vuln/cmd/govulncheck@latest
golangci-lint version
```

A repo-level **`.golangci.yml`** records the enabled linter set so the result is
reproducible. Recommended baseline enables: `govet, staticcheck, errcheck,
gosimple, ineffassign, unused, gocritic, revive, gofumpt, misspell, bodyclose,
contextcheck`. (An init/infra decision, not per-Story.)

## Running

```bash
# --- Aggregated lint (primary) ---
golangci-lint run ./...                       # full report, repo .golangci.yml config
golangci-lint run ./path/to/changed/...       # scope to changed packages
golangci-lint run --new-from-rev=origin/develop   # only findings the branch introduced

# --- Formatting (Developer applies; Reviewer only checks) ---
gofumpt -l .                                   # list files needing formatting (check)
gofumpt -w .                                   # apply (Developer only)

# --- Standalone detail (optional) ---
staticcheck ./...
go vet ./...

# --- Dependency freshness ---
go list -m -u all                              # available upgrades
govulncheck ./...                              # known vulnerabilities in used code paths
```

## How to interpret (harness policy — advisory)

- **Diff-scoped**: address findings in code the change **touched** (prefer
  `--new-from-rev`); don't refactor unrelated legacy to chase a clean report
  (YAGNI) — note pre-existing debt instead of fixing it inline.
- **Maintainability first**: prioritize findings that hurt readability or invite
  bugs — unhandled errors (`errcheck`), shadowed/ineffectual assignments,
  over-complex functions (`gocyclo`/`gocritic`), dead code (`unused`). These map
  to the engineering principles and are the point of the skill.
- **Formatting is mechanical**: `gofumpt -w .` is **Developer-only** (the Reviewer
  is read-only and only *reports*). A formatting diff is never a `[R<n>]` debate —
  it's just run.
- **Outdated deps / vulns**: flag majors and any `govulncheck` hit that reaches
  live code paths; routine patch bumps are not per-Story work unless the Story is
  about upgrades.
- Don't commit lint report files — scratch only.

## See also

- [`go-conventions`](../go-conventions/SKILL.md) — the authoritative Go SERVICE rules this reinforces.
- [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md) — the .NET analog (the other supported service stack).
- [`security-scan`](../security-scan/SKILL.md) — Semgrep/Gitleaks/OSV-Scanner/govulncheck security layer (run alongside this).
- `agents/shared/engineering-principles.md` — SOLID / DRY / YAGNI, the lens for triaging findings.
- Upstream: `golangci-lint.run`, `staticcheck.dev`, `github.com/mvdan/gofumpt`, `pkg.go.dev/golang.org/x/vuln/cmd/govulncheck`.
