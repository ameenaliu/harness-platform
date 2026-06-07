---
name: expo-mobile-conventions
description: >
  Pointer to the the project MOBILE stack rules + architecture. Loaded by Developer,
  Reviewer, and Tester agents when a task is tagged MOBILE. The canonical rules
  live in the this repo under `.claude/rules/mobile/` and
  `.claude/architecture/farm-management/mobile.md` — this skill tells the agent
  where to read them so they evolve with the codebase, not with the harness.
disable-model-invocation: true
user-invocable: true
---

# MOBILE / Expo Conventions — Pointer

**This skill is a thin pointer.** The canonical the project MOBILE rules + architecture live in the this repo and evolve with the code. Read them directly:

## Mandatory reads (every MOBILE task)

1. **`.claude/rules/mobile/code-style.md`** — Components (`FC<Props>`, `interface Props`, `StyleSheet.create()`), Compound Components, Screen Containers (`FeatureHomeScreenContainer`, `FeatureDetailScreenContainer`, `ModalScreenContainer`, etc. from `components/layout/`), Expo Router navigation (use `AppRoutes` constant), imports order, TypeScript DTO hierarchy, **state management (Redux Toolkit + Persist with 6 persistence layers: `persistedSecured` (SecureStore), `persistedFarm` (MMKV), `persistedFeature` (MMKV, cleared on farm switch), `persistedGlobal` (MMKV), `userLocalPersisted` (MMKV), `nonPersisted` (in-memory))**, data fetching hooks (`useFetchGroupedData`, `useFetchDetailData`, `useFetchEditData`, `useMutateData`), services, DI (`ServiceProvider`), styling (`StyleSheet.create()` + `ColorTheme`/`ColorConstants`/`SpacingConstants`/`FontsConstants` — NEVER hardcoded hex), forms (React Hook Form + Yup), lists (`CustomFlashList` — Shopify FlashList wrapper, NOT `FlatList`), error handling (services throw → hooks toast), storage (MMKV `SecureStorage`/`DefaultStorage` + Expo SecureStore for refresh token; access tokens in-memory only), push notifications (background = `setBackgroundMessageHandler` → MMKV; foreground = `PushNotificationProvider` → toast).
2. **`.claude/rules/mobile/testing.md`** — Jest 29 via jest-expo + `@testing-library/react-native` + `@testing-library/jest-native` + `userEvent`. **Coverage threshold: 85% minimum** (branches, functions, lines, statements). Tests in `__tests__/` mirroring `src/`. Centralised native module mocking in `jest/setup.ts`.
3. **`.claude/architecture/farm-management/mobile.md`** — Mobile-app-specific architecture.
4. **`agents/shared/engineering-principles.md`** (in this plugin) — SOLID / DRY / YAGNI.

## Harness-process rules (encoded here because they cross-cut the workflow, not the codebase)

### Stack identification

the project mobile lives at `/Mobile/farm-management/`. **React Native 0.79+, Expo 53, React 19, TypeScript** (per `.claude/CLAUDE.md → Key Dependencies`). Yarn 4.3.1 (corepack).

When the task title carries `[MOBILE]`, agents work under `/Mobile/farm-management/`.

### Commits — Conventional Commits with stack scope

```
<type>(mobile): <imperative lowercase description>
```

Multi-stack: `<type>(mobile,service): …`. See `dotnet-conventions/SKILL.md → Commits` for the full rule set; it applies identically here.

### Branching — the project two-tier model

Same model as SERVICE. See `dotnet-conventions/SKILL.md → Branching`.

### Coverage thresholds (used by Reviewer Phase B + Tester Phase 6)

- **MOBILE**: ≥ **85%** branches, functions, lines, statements on new/modified code (Jest coverage threshold per `.claude/rules/mobile/testing.md`).

> Note: this is HIGHER than the harness-default 70% — the project enforces 85% on mobile via Jest config. The Reviewer and Tester must respect the repo-set threshold, not a harness default.

### Things the reviewer auto-blocks (Phase 0 + hook backstops)

- Sensitive files (same list as SERVICE) — blocked by `sensitive-file-guard.sh`. Note: `GoogleService-Info.plist` and `google-services.json` are public mobile config (only contain client identifiers) — they are NOT blocked. Service-account JSON private keys (`serviceAccount*.json`) ARE blocked.
- Provider secrets in source (same list as SERVICE) — blocked by `secret-scan-guard.sh`. **Public** keys in `EXPO_PUBLIC_*` are fine; private keys must use EAS secrets.
- Writes under `ai/` from non-orchestrator/non-planner agents — Phase 0 catches.
- Commit subject that doesn't match the Conventional Commits regex — Phase 0 catches.
- Inline styles (other than dynamic merges) — flagged by Phase B as a violation of `.claude/rules/mobile/code-style.md → StyleSheet.create()`.
- Use of `FlatList` instead of `CustomFlashList` — flagged by Phase B.
- Hardcoded hex colors — flagged by Phase B.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) when the task also touches SERVICE.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) when the task also touches WEB.
- [`building-native-ui`](../building-native-ui/SKILL.md) — Expo Router patterns, animations, native tabs (load for new mobile screens).
- [`native-data-fetching`](../native-data-fetching/SKILL.md) — React Query patterns, error handling, caching (load for any data-fetch work).
- [`expo-dev-client`](../expo-dev-client/SKILL.md) — building Expo dev clients.
- [`expo-module`](../expo-module/SKILL.md) — Expo native modules (load when adding native code).
- [`upgrading-expo`](../upgrading-expo/SKILL.md) — SDK upgrade workflows.
