---
name: expo-mobile-conventions
description: >
  Pointer to the project MOBILE stack rules + architecture. Loaded by Developer,
  Reviewer, and Tester agents when a task is tagged MOBILE. The canonical rules
  live in this repo under `.claude/rules/mobile/` and
  `.claude/architecture/<area>/mobile.md` — this skill tells the agent
  where to read them so they evolve with the codebase, not with the harness.
disable-model-invocation: true
user-invocable: true
---

# MOBILE / Expo Conventions — Pointer

**This skill is a thin pointer.** The canonical MOBILE rules + architecture live in this repo and evolve with the code. Read them directly:

## Mandatory reads (every MOBILE task)

1. **`.claude/rules/mobile/code-style.md`** — Components (`FC<Props>`, `interface Props`, `StyleSheet.create()`), Compound Components, Screen Containers (`FeatureHomeScreenContainer`, `FeatureDetailScreenContainer`, `ModalScreenContainer`, etc. from `components/layout/`), Expo Router navigation (use `AppRoutes` constant), imports order, TypeScript DTO hierarchy, **state management (Redux Toolkit + Persist — follow the repo's `.claude/rules/mobile/code-style.md` for the exact state/persistence layers; e.g. `persistedSecured` (SecureStore), `persistedGlobal` (MMKV), `nonPersisted` (in-memory))**, data fetching hooks (`useFetchGroupedData`, `useFetchDetailData`, `useFetchEditData`, `useMutateData`), services, DI (`ServiceProvider`), styling (`StyleSheet.create()` + `ColorTheme`/`ColorConstants`/`SpacingConstants`/`FontsConstants` — NEVER hardcoded hex), forms (React Hook Form + Yup), lists (`CustomFlashList` — Shopify FlashList wrapper, NOT `FlatList`), error handling (services throw → hooks toast), storage (MMKV `SecureStorage`/`DefaultStorage` + Expo SecureStore for refresh token; access tokens in-memory only), push notifications via **`expo-notifications` OR Firebase Cloud Messaging (FCM) — both valid** (background handler → MMKV; foreground = `PushNotificationProvider` → toast). Firebase is fine for push/analytics, but it is NOT the app backend — the service surface is.
2. **`.claude/rules/mobile/testing.md`** — Jest 29 via jest-expo + `@testing-library/react-native` + `@testing-library/jest-native` + `userEvent`. **Coverage threshold: 85% minimum** (branches, functions, lines, statements). Tests in `__tests__/` mirroring `src/`. Centralised native module mocking in `jest/setup.ts`.
3. **`.claude/architecture/<area>/mobile.md`** — Mobile-app-specific architecture.
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI.

## Harness-process rules (encoded here because they cross-cut the workflow, not the codebase)

### Stack identification

The mobile app lives under `mobile/`. **React Native 0.79+, Expo 53, React 19, TypeScript** (per `.claude/CLAUDE.md → Key Dependencies`). Yarn 4.3.1 (corepack).

When the task title carries `[MOBILE]`, agents work under `mobile/`.

### Commits — Conventional Commits with stack scope

```
<type>(mobile): <imperative lowercase description>
```

Multi-stack: `<type>(mobile,service): …`. See `dotnet-conventions/SKILL.md → Commits` for the full rule set; it applies identically here.

### Branching — the project branching model

Same model as SERVICE. See `dotnet-conventions/SKILL.md → Branching`.

### Coverage thresholds (used by Reviewer Phase B + Tester Phase 6)

- **MOBILE**: ≥ **85%** branches, functions, lines, statements on new/modified code (Jest coverage threshold per `.claude/rules/mobile/testing.md`).

> Note: this is HIGHER than the harness-default 70% — when the repo enforces 85% on mobile via Jest config. The Reviewer and Tester must respect the repo-set threshold, not a harness default.

### Things the reviewer auto-blocks (Phase 0 + hook backstops)

- Sensitive files (same list as SERVICE) — blocked by `sensitive-file-guard.sh`. Note: `GoogleService-Info.plist` and `google-services.json` are public mobile config (only contain client identifiers) — they are NOT blocked. Service-account JSON private keys (`serviceAccount*.json`) ARE blocked.
- Provider secrets in source (same list as SERVICE) — blocked by `secret-scan-guard.sh`. **Public** keys in `EXPO_PUBLIC_*` are fine; private keys must use EAS secrets.
- Writes under `ai/` from non-orchestrator/non-planner agents — Phase 0 catches.
- Commit subject that doesn't match the Conventional Commits regex — Phase 0 catches.
- Inline styles (other than dynamic merges) — flagged by Phase B as a violation of `.claude/rules/mobile/code-style.md → StyleSheet.create()`.
- Use of `FlatList` instead of `CustomFlashList` — flagged by Phase B.
- Hardcoded hex colors — flagged by Phase B.

### Mobile tooling (verification, E2E, quality, security)

Part of the MOBILE capability. `/init-workspace` installs them if missing; all advisory (none blocks commits) and scoped to new/modified code. Load the matching skill for usage.

**Verification & E2E**
- **agent-device** (Developer, Phase 3) — drive the running app on a simulator/emulator to verify the UI behaves as intended, not just that it compiles. See [`agent-device`](../agent-device/SKILL.md). Interactive only — not a committed artifact.
- **Maestro** (Tester, Phase 6) — committed E2E flows in `mobile/.maestro/*.yaml` (`launchApp`/`tapOn`/`assertVisible`), happy + one key error/empty path per journey. See [`maestro-e2e`](../maestro-e2e/SKILL.md). Additive to the Jest suite + 85% threshold.

**Quality, security, cleanliness** (Developer self-review + Reviewer Phase B)
- **React Doctor** — `npx react-doctor@latest` over `mobile/` for performance / a11y / dead-code. See [`react-doctor`](../react-doctor/SKILL.md).
- **expo-doctor** — `npx expo-doctor` for Expo project + dependency-compatibility health, especially after any dependency change. See [`expo-doctor`](../expo-doctor/SKILL.md).
- **Security** — [`security-scan`](../security-scan/SKILL.md): Semgrep (RN/TS SAST), Gitleaks (secrets), OSV-Scanner + `yarn npm audit` (npm CVEs).
- **Cleanliness** — [`dead-code-analysis`](../dead-code-analysis/SKILL.md): Knip + madge. **Bundle budget** — [`bundle-budget`](../bundle-budget/SKILL.md): size-limit on the exported JS bundle.
- **Observability** — [`observability`](../observability/SKILL.md): new screens/flows capture errors via Sentry (RN error handler, `captureException` with context), leave breadcrumbs, track key events; never log PII.

## PR checklist — MOBILE (Expo)

> Reviewer Phase B reference (anchor `MOBILE (Expo)` in `packs/expo/pack.json`).

- File-based routing in `app/` (Expo Router); state via Redux Toolkit + Persist (per `.claude/rules/mobile/code-style.md`).
- Push notifications via `expo-notifications` OR Firebase Cloud Messaging (FCM) — both valid; Firebase is fine for push/analytics but is NOT the app backend (the service surface is). Sentry initialised in the right entry point; no secret in the JS bundle (use `expo-secure-store` / EAS secrets).
- Permissions guarded; offline state handled; deep links registered in `app.config.ts`.
- React Doctor + Knip/madge + expo-doctor surface no new high-severity finding.
- New screens/flows capture errors via Sentry with no PII in telemetry (`observability`); no secrets in source (`security-scan`).
- Maestro E2E flows present for the Story's journey (Phase 6).
- Build & tests: `yarn tsc:build && yarn lint && yarn test` clean; coverage ≥ 85% on new/modified code.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) when the task also touches SERVICE.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) when the task also touches WEB.
- [`agent-device`](../agent-device/SKILL.md) — verify the running app during development (Phase 3).
- [`maestro-e2e`](../maestro-e2e/SKILL.md) — mobile E2E flows (Phase 6).
- [`react-doctor`](../react-doctor/SKILL.md) — React/RN performance + quality scan.
- [`expo-doctor`](../expo-doctor/SKILL.md) — Expo project health check.
- [`security-scan`](../security-scan/SKILL.md) — SAST + secrets + dependency CVEs.
- [`dead-code-analysis`](../dead-code-analysis/SKILL.md) — unused code/deps + circular deps.
- [`bundle-budget`](../bundle-budget/SKILL.md) — bundle-size budgets.
- [`observability`](../observability/SKILL.md) — Sentry error capture + key events.
- [`building-native-ui`](../building-native-ui/SKILL.md) — Expo Router patterns, animations, native tabs (load for new mobile screens).
- [`native-data-fetching`](../native-data-fetching/SKILL.md) — React Query patterns, error handling, caching (load for any data-fetch work).
- [`expo-dev-client`](../expo-dev-client/SKILL.md) — building Expo dev clients.
- [`expo-module`](../expo-module/SKILL.md) — Expo native modules (load when adding native code).
- [`upgrading-expo`](../upgrading-expo/SKILL.md) — SDK upgrade workflows.
