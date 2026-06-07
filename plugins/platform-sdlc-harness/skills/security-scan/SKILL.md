---
name: security-scan
description: >
  Scan a change for security issues across all surfaces (SERVICE/.NET, WEB,
  MOBILE) using three complementary tools — Semgrep (static analysis / SAST for
  injection, authz, crypto and dangerous-API patterns), Gitleaks (hardcoded
  secrets / credentials), and dependency-CVE auditing (OSV-Scanner, plus
  `dotnet list package --vulnerable` and `yarn npm audit`). Load this in the
  Developer self-review and the Reviewer's Phase B to catch vulnerabilities the
  build and unit tests don't. Advisory — surfaces findings; does not block on its
  own (the data-policy hooks remain the hard backstop for secrets).
user-invocable: true
---

# security-scan — SAST, secret, and dependency-CVE scanning

Three tools, one goal: *is this change secure?* They complement — not replace —
the harness's runtime **data-policy hooks** (`secret-scan-guard`,
`sensitive-file-guard`, etc.), which stay the hard backstop. This skill is the
**advisory in-loop** scan run by the Developer (self-review) and the Reviewer
(Phase B).

| Tool | Catches | Surfaces |
|---|---|---|
| **Semgrep** | SAST — injection, broken authz, unsafe deserialization, weak crypto, dangerous APIs, taint flows | SERVICE (C#), WEB + MOBILE (TS/JS/React/RN) |
| **Gitleaks** | Hardcoded secrets / credentials in the diff and history (far broader than the regex hook) | all |
| **OSV-Scanner** + `dotnet list package --vulnerable` + `yarn npm audit` | Known CVEs in dependencies (NuGet + npm) | SERVICE (NuGet), WEB + MOBILE (npm) |

## When to use it

- **Developer (Phase 3), every surface**: before committing, scan the diff; fix
  any **high/critical** finding your change introduced (injected query, unsafe
  redirect, a new vulnerable dependency, an accidental secret).
- **Reviewer (Phase B), every surface**: run the scans on the diff's surface and
  raise new high/critical findings as `[R<n>] CRITICAL|WARNING` comments with
  file:line and a fix.

## Prerequisites / install

`/init-workspace` installs these when a code surface is present (advisory — it
warns and continues if install is declined). Manual install:

```bash
# Semgrep — Python-based; pipx is cleanest, brew on macOS
pipx install semgrep            # or: python3 -m pip install semgrep ; or: brew install semgrep
semgrep --version

# Gitleaks — single Go binary
brew install gitleaks           # macOS ; Linux: download release binary or `go install github.com/gitleaks/gitleaks/v8@latest`
gitleaks version

# OSV-Scanner — single Go binary
brew install osv-scanner        # macOS ; Linux: download release binary or `go install github.com/google/osv-scanner/cmd/osv-scanner@latest`
osv-scanner --version
```

`dotnet list package --vulnerable` and `yarn npm audit` need no install (ship
with the SDK / package manager).

## Running

Scope to the **diff** where possible — these are advisory and you only own what
your change introduced, not the whole legacy codebase.

```bash
# --- SAST (Semgrep) ---
semgrep --config auto --error --json --output semgrep.json <changed-paths>   # `--config auto` pulls language rulesets
# Tip: scope to the diff — `git diff --name-only <base>...HEAD | xargs semgrep --config auto`

# --- Secrets (Gitleaks) ---
gitleaks detect --redact --report-format json --report-path gitleaks.json     # full tree
gitleaks protect --staged --redact                                            # staged diff only (pre-commit style)

# --- Dependency CVEs ---
osv-scanner --lockfile=service/**/packages.lock.json --lockfile=web/yarn.lock --lockfile=mobile/yarn.lock   # or: osv-scanner -r .
dotnet list <solution> package --vulnerable --include-transitive            # SERVICE
( cd web    && yarn npm audit --severity high )                             # WEB  (Yarn 4: `yarn npm audit`)
( cd mobile && yarn npm audit --severity high )                             # MOBILE
```

## How to interpret (harness policy — advisory)

- **Severity gate**: act on **high/critical**; treat medium/low as suggestions.
- **Diff-scoped**: fix findings the change **introduced**; a pre-existing CVE or
  legacy SAST hit in untouched code is context, not a blocker — note it.
- **Developer**: fix introduced high/critical findings before committing; if a
  vulnerable dependency is unavoidable, document why and the mitigation.
- **Reviewer**: raise new high/critical findings as `[R<n>]` comments; never edits
  code (read-only). React Doctor covers React *quality/perf*; this covers
  *security* — they don't overlap.
- **`--redact`** is mandatory on Gitleaks output — never let a real secret value
  reach the model or a log. Findings reference the location, not the value.
- Don't commit the JSON reports (`semgrep.json`/`gitleaks.json`) — they're scratch.

## See also

- [`react-doctor`](../react-doctor/SKILL.md) — React perf/quality (the quality counterpart to this security scan).
- [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md) — .NET maintainability + `--outdated` dependency hygiene.
- [`dead-code-analysis`](../dead-code-analysis/SKILL.md) / [`bundle-budget`](../bundle-budget/SKILL.md) — the cleanliness/perf counterparts run alongside this.
- Data-policy hooks (`secret-scan-guard`, `sensitive-file-guard`) remain the hard, non-optional backstop — this skill is the broader advisory layer.
- Upstream: `semgrep.dev`, `github.com/gitleaks/gitleaks`, `google.github.io/osv-scanner`.
