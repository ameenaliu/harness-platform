---
name: react-doctor
description: >
  Scan React code (WEB and MOBILE / React Native) for performance risks,
  anti-patterns, accessibility issues, dead code, and bundle bloat using React
  Doctor — a CLI that returns a 0–100 health score with file-level diagnostics.
  Load this when implementing or reviewing React/React Native code: the Developer
  runs it as a self-check before committing, and the Reviewer runs it in Phase B
  to catch quality/perf regressions the build and unit tests don't surface.
user-invocable: true
---

# react-doctor — React/React Native performance & quality scan

[React Doctor](https://github.com/millionco/react-doctor) (by the million.js
author) scans a React codebase and returns a **health score (0–100)** plus
file-level diagnostics across 60+ rules: performance (unnecessary re-renders,
expensive patterns), code smells, accessibility, bundle size, security, and dead
code. It supports **Next.js, Vite, Remix, and React Native**, so it applies to
both this harness's **WEB** (React 19 + Turbo) and **MOBILE** (Expo) surfaces.

> **Scope.** This is a **static quality/performance gate**, complementary to:
> the build (compiles?), unit/integration tests (correct?), and `agent-device` /
> Maestro (runtime UI). React Doctor answers: *is this React code healthy and
> performant?* It is **advisory** — it informs review findings; it is not a
> commit-blocking hook.

## When to use it

- **Developer (Phase 3), WEB or MOBILE**: run it as part of self-review before
  committing changed React/React Native code; fix regressions you introduced.
- **Reviewer (Phase B), WEB or MOBILE**: run it on the diff's surface and raise
  any new high-severity findings (perf, a11y, dead code) as `[R<n>]` comments.
- Any time you're asked to audit React/RN code quality or chase re-render / bundle
  issues.

## Running

No install needed — it runs via `npx`. `/init-workspace` pre-warms it, but `npx`
will fetch it on demand regardless.

```bash
# Scan the current React project (run from web/ or mobile/, or pass a path)
npx react-doctor@latest
npx react-doctor@latest --no-telemetry        # disable Sentry telemetry

# Install React Doctor's rules as an agent skill (optional, for richer in-editor help)
npx react-doctor@latest install

# Live diagnostics via LSP (editor integrations)
npx react-doctor experimental-lsp --stdio
```

For this harness:

```bash
cd web    && npx react-doctor@latest --no-telemetry     # WEB surface
cd mobile && npx react-doctor@latest --no-telemetry     # MOBILE surface
```

Optional repo config (`doctor.config.{ts,js,json,jsonc}` at the surface root) can
turn rules off or set `lint` behaviour — only add one if the team agrees a rule is
noise:

```ts
import type { ReactDoctorConfig } from "react-doctor/api";
export default {
  lint: true,
  rules: { "react-doctor/no-array-index-as-key": "off" },
} satisfies ReactDoctorConfig;
```

## How to interpret results (harness policy)

React Doctor is **advisory, not a hard gate** — the harness does not block commits
on the score. Apply judgement against the **diff**, not the whole legacy codebase:

- **Focus on new/modified files.** Do not chase pre-existing findings in code the
  Story didn't touch — same principle as the coverage threshold (new/modified
  lines only).
- **Developer**: fix high-severity findings (performance, accessibility, dead
  code, security) that **your change introduced** before committing. Note the
  before/after score in your status block when meaningful.
- **Reviewer**: if the diff adds high-severity findings, raise them as
  `[R<n>] WARNING|SUGGESTION` comments with the file:line and the fix. A dropped
  score caused by the diff is a quality finding; a low absolute score from legacy
  code is not blocking on its own — note it as context.
- **CI** (optional, out of per-Story scope): React Doctor ships a GitHub Action
  (`millionco/react-doctor@v2`) that posts a PR score; teams can gate merges below
  a threshold there. Wiring it is an init-time / infra choice, not part of the
  per-Story loop.

## Conventions for this harness

- **Surfaces**: WEB and MOBILE only — not SERVICE (.NET).
- **No source writes from the Reviewer** — the Reviewer only *reports* React Doctor
  findings; it never applies fixes (read-only on code).
- **Don't commit config churn** — only add `doctor.config.*` when the team has
  agreed to silence a rule; don't disable rules just to raise a score.

## See also

- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) — WEB rules React Doctor reinforces (re-renders, design-system usage).
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — MOBILE rules (FlashList, StyleSheet, no hardcoded colors).
- [`agent-device`](../agent-device/SKILL.md) / [`maestro-e2e`](../maestro-e2e/SKILL.md) — runtime verification + E2E, the behavioural complement to this static scan.
- Upstream: `millionco/react-doctor` on GitHub; `react.doctor`.
