---
name: dotnet-code-quality
description: >
  Analyze SERVICE (.NET 8 / C#) code for maintainability, code smells, and
  quality issues beyond what the compiler catches, using Roslynator (analyzers +
  automated refactorings) and optionally SonarAnalyzer.CSharp, plus dependency
  hygiene via `dotnet list package --outdated`. Load this in the Developer
  self-review and Reviewer Phase B for SERVICE tasks. Advisory — scoped to the
  change; never a commit gate (the zero-warnings build remains the hard gate).
user-invocable: true
---

# dotnet-code-quality — Roslynator + analyzers (service)

The SERVICE counterpart to [`dead-code-analysis`](../dead-code-analysis/SKILL.md)
(web/mobile) and [`react-doctor`](../react-doctor/SKILL.md) (React). It targets
C# **maintainability and clean code** — long methods, unnecessary complexity,
dead/unreachable code, redundant constructs, naming — and dependency freshness.

| Tool | Role |
|---|---|
| **Roslynator CLI** | 500+ analyzers + automated refactorings/fixes over a solution; the primary agent-runnable quality scan |
| **SonarAnalyzer.CSharp** (optional, build-integrated) | Deeper code-smell / bug / maintainability ruleset as a NuGet analyzer package; surfaces as build warnings |
| **`dotnet list package --outdated`** | Dependency freshness (pairs with `--vulnerable` in [`security-scan`](../security-scan/SKILL.md)) |

> The harness already requires `dotnet build` with **zero errors AND zero
> warnings** and `dotnet format` — that's the hard gate. This skill is the
> **advisory** layer on top: maintainability findings a clean build still allows.

## When to use it

- **Developer (Phase 3), SERVICE**: before committing, run Roslynator on the
  affected project/solution; address maintainability findings your change
  introduced (over-long methods, duplicated logic, needless complexity).
- **Reviewer (Phase B), SERVICE**: run it on the affected solution; raise new
  high-value findings as `[R<n>]` comments. Cross-check against the
  engineering-principles (SOLID/DRY/YAGNI).

## Prerequisites / install

```bash
# Roslynator CLI — a .NET global tool
dotnet tool install -g roslynator.dotnet.cli      # `/init-workspace` does this when SERVICE is present
roslynator --version
```

SonarAnalyzer.CSharp is added per-project as a NuGet `<PackageReference>` (an
init/infra decision, not per-Story) — when present it just shows up as build
warnings, no separate command. `dotnet list package --outdated` ships with the SDK.

## Running

```bash
# --- Maintainability analyzers (Roslynator) ---
roslynator analyze <solution-or-project>                       # full analyzer report
roslynator analyze <solution> --severity-level info           # include suggestions
roslynator analyze <solution> --output roslynator.xml         # machine-readable
# Roslynator can also APPLY safe fixes — Developer only, never the Reviewer:
#   roslynator fix <solution>            (review the diff before committing)

# --- Dependency freshness ---
dotnet list <solution> package --outdated --include-transitive
```

## How to interpret (harness policy — advisory)

- **Diff-scoped**: address findings in code the change **touched**; don't refactor
  unrelated legacy to chase a clean report (YAGNI) — note pre-existing debt
  instead of fixing it inline.
- **Maintainability first**: prioritize findings that hurt readability or invite
  bugs (complex methods, duplication, unclear naming) — these map to the
  engineering principles and are the point of the skill.
- **Roslynator `fix`** is **Developer-only**: the Reviewer is read-only and only
  *reports* findings; it never applies fixes.
- **Outdated deps**: flag majors that carry security/maintenance risk; routine
  patch bumps are not per-Story work unless the Story is about upgrades.
- Don't commit analyzer report files — scratch only.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) — the authoritative SERVICE rules this reinforces.
- [`security-scan`](../security-scan/SKILL.md) — Semgrep/Gitleaks/`--vulnerable` security layer (run alongside this).
- `agents/shared/engineering-principles.md` — SOLID / DRY / YAGNI, the lens for triaging findings.
- Upstream: `github.com/dotnet/roslynator`, `rules.sonarsource.com/csharp`.
