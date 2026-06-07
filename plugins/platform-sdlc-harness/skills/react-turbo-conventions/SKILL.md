---
name: react-turbo-conventions
description: >
  Pointer to the the project WEB stack rules + architecture. Loaded by Developer,
  Reviewer, and Tester agents when a task is tagged WEB. The canonical rules
  live in the this repo under `.claude/rules/web/` and
  `.claude/architecture/{farm-management,marketplace,web-apps}/web.md` — this
  skill tells the agent where to read them so they evolve with the codebase,
  not with the harness.
disable-model-invocation: true
user-invocable: true
---

# WEB / React + Turbo Conventions — Pointer

**This skill is a thin pointer.** The canonical the project WEB rules + architecture live in the this repo and evolve with the code. Read them directly:

## Mandatory reads (every WEB task)

1. **`.claude/rules/web/code-style.md`** — Banned raw HTML elements (use `@app/components`), components, compound components, file structure, imports, TypeScript naming, state management (Redux for UI / React Query for server data), data fetching (shared hooks `useFetchData`, `useFetchSingleData`, `useMutateData`, `useFilteredPagedData`), hook organisation, services, DI, layout components, pages, styling (TailwindCSS v4), forms (React Hook Form + Yup), error handling, routing (React Router).
2. **`.claude/rules/web/testing.md`** — Vitest + RTL + MSW, co-location, `userEvent` over `fireEvent`, `renderWithProviders` utility.
3. **`.claude/architecture/<area>/web.md` or `.claude/architecture/web-apps/<app>.md`** matching the affected app:
   - `.claude/architecture/farm-management/web.md` — the monorepo web dashboard
   - `.claude/architecture/marketplace/web.md` — Marketplace web app
   - `.claude/architecture/web-apps/admin.md` — Admin app
   - `.claude/architecture/web-apps/farm-globe.md` — Farm Globe app
   - `.claude/architecture/web-apps/landing.md` — Landing app
   - `.claude/architecture/web-apps/partner.md` — Partner Portal app
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI.

## Harness-process rules (encoded here because they cross-cut the workflow, not the codebase)

### Stack identification

The the project Web monorepo lives under `/Web/`. It's a **Turbo + Yarn 4.3.1 + Vite 7 monorepo** with **6 apps + 11 shared packages** (per `.claude/CLAUDE.md → Key Dependencies` and `.claude/architecture/web-apps/`). React 19, React Router 7, Redux Toolkit 2, React Query 5, MUI 7, TailwindCSS 4.

When the task title carries `[WEB]`, agents must:
- Detect which app the change targets (file path under `apps/<app>/`).
- Load the matching app architecture doc (see list above) in addition to the cross-cutting `.claude/rules/web/code-style.md`.

### Commits — Conventional Commits with stack scope

```
<type>(web): <imperative lowercase description>
```

Multi-stack: `<type>(web,service): …`. See `dotnet-conventions/SKILL.md → Commits` for the full rule set; it applies identically here.

### Branching — the project two-tier model

Same model as SERVICE. See `dotnet-conventions/SKILL.md → Branching`.

### Coverage thresholds (used by Reviewer Phase B + Tester Phase 6)

- **WEB**: ≥ 70% line coverage on new/modified code (Vitest with `--coverage`, V8 provider).

> Per `.claude/rules/web/testing.md`, the test suite is **not yet established** — when adding tests, follow the conventions in that file as the seed. Do not back-fill tests for unchanged code; the threshold applies only to new/modified lines.

### Web tooling (quality, security, cleanliness — advisory)

All run in Developer self-review + Reviewer Phase B, scoped to new/modified files; none blocks commits (`/init-workspace` installs/pre-warms them).

- **React Doctor** — `npx react-doctor@latest` over `web/` (or the affected app) for performance (unnecessary re-renders), accessibility, dead-code, bundle-size risks. See [`react-doctor`](../react-doctor/SKILL.md).
- **Security** — [`security-scan`](../security-scan/SKILL.md): Semgrep (TS/React SAST), Gitleaks (secrets), OSV-Scanner + `yarn npm audit` (npm CVEs). Fix high/critical the change introduced.
- **Cleanliness** — [`dead-code-analysis`](../dead-code-analysis/SKILL.md): Knip (unused files/exports/deps) + madge (circular deps). Remove dead code / new cycles the change created.
- **Bundle budget** — [`bundle-budget`](../bundle-budget/SKILL.md): size-limit; justify or fix bundle-size jumps from the diff.
- **Observability** — [`observability`](../observability/SKILL.md): new screens/flows capture errors via Sentry (error boundaries, `captureException` with context), leave breadcrumbs, track key events; never log PII.

### Things the reviewer auto-blocks (Phase 0 + hook backstops)

- Sensitive files (same list as SERVICE) — blocked by `sensitive-file-guard.sh`.
- Provider secrets in source (same list as SERVICE) — blocked by `secret-scan-guard.sh`. **Public** keys in `VITE_*` env vars are fine; private keys must stay server-side.
- Writes under `ai/` from non-orchestrator/non-planner agents — Phase 0 catches.
- Commit subject that doesn't match the Conventional Commits regex — Phase 0 catches.
- Raw HTML elements (`<div>`, `<button>`, etc.) in `apps/` code — flagged by Phase B as a violation of `.claude/rules/web/code-style.md → Banned Elements`.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) when the task also touches SERVICE.
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) when the task also touches MOBILE.
- [`react-doctor`](../react-doctor/SKILL.md) — React performance + quality scan (web + mobile).
- [`security-scan`](../security-scan/SKILL.md) — SAST + secrets + dependency CVEs.
- [`dead-code-analysis`](../dead-code-analysis/SKILL.md) — unused code/deps + circular deps.
- [`bundle-budget`](../bundle-budget/SKILL.md) — bundle-size budgets.
- [`observability`](../observability/SKILL.md) — Sentry error capture + key events.
