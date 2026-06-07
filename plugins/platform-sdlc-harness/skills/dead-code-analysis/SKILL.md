---
name: dead-code-analysis
description: >
  Find dead code, unused exports, unused files, unused dependencies, and circular
  imports in the WEB (React 19 / Turbo) and MOBILE (Expo / RN) TypeScript code
  using Knip (unused exports/files/deps) and madge (circular dependencies). Load
  this in the Developer self-review and Reviewer Phase B for WEB/MOBILE to keep
  the codebase clean, simple, and maintainable. Advisory — scoped to what the
  change introduced; never a commit gate.
user-invocable: true
---

# dead-code-analysis — Knip + madge (web + mobile)

Two tools that directly serve "clean, simple, maintainable":

| Tool | Finds |
|---|---|
| **Knip** | Unused files, unused exports, unused `package.json` dependencies, unused exported types, and unresolved imports across a TS/monorepo |
| **madge** | Circular dependencies and the module dependency graph |

SERVICE (.NET) is out of scope here — see [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md)
for its analyzer-driven equivalent.

## When to use it

- **Developer (Phase 3), WEB/MOBILE**: before committing, check that your change
  didn't leave orphaned exports/files/deps and didn't introduce a circular import.
- **Reviewer (Phase B), WEB/MOBILE**: run on the affected surface; raise new dead
  code / unused deps / new cycles **introduced by the diff** as `[R<n>]`
  suggestions.

## Prerequisites / install

No global install — both run via `npx`. `/init-workspace` pre-warms them.

```bash
npx knip --version
npx madge --version        # circular-dep detection needs no graphviz; only image output (--image) does
```

## Running

Run from the surface root (`web/` or `mobile/`); scope judgement to the diff.

```bash
# --- Unused code / exports / deps (Knip) ---
cd web    && npx knip                       # reports unused files, exports, deps
cd mobile && npx knip
npx knip --reporter json                    # machine-readable
# Monorepo: knip understands workspaces; add a knip.json at the root to tune entry points

# --- Circular dependencies (madge) ---
cd web    && npx madge --circular --extensions ts,tsx src
cd mobile && npx madge --circular --extensions ts,tsx src
npx madge --circular --extensions ts,tsx --json src    # machine-readable
```

Optional `knip.json` at the surface root tunes entry points and silences known
false positives (e.g. config files, generated code) — only add one when the team
agrees a report is noise, not to mask real dead code.

## How to interpret (harness policy — advisory)

- **Diff-scoped**: remove dead code / unused deps **your change created**; don't
  delete pre-existing unused code the Story didn't touch (that's a separate
  cleanup task — note it, don't scope-creep).
- **Circular deps**: a new cycle introduced by the diff is a real maintainability
  finding — refactor it (extract the shared piece, invert the dependency).
- **Unused deps**: a dependency added but not used → remove it; a dependency
  flagged-but-actually-used (dynamic import, plugin) → keep and tune `knip.json`.
- **Developer**: fix introduced findings before committing. **Reviewer**: raise as
  `[R<n>] SUGGESTION` (or WARNING for a new cycle); read-only — never edits code.
- Don't commit JSON reports — scratch only.

## See also

- [`react-doctor`](../react-doctor/SKILL.md) — React perf/quality (overlaps slightly on dead code; this is the dependency-graph + unused-deps specialist).
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) / [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — the surface rules this keeps clean.
- [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md) — the SERVICE equivalent.
- Upstream: `knip.dev`, `github.com/pahen/madge`.
