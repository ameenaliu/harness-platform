---
name: maestro-e2e
description: >
  Write and run end-to-end (E2E) UI tests for the MOBILE app (and, where
  applicable, WEB) using Maestro — human-readable YAML flows (launchApp, tapOn,
  assertVisible, inputText) executed against a simulator, emulator, or device.
  Load this in Phase 6 (Tester) when adding E2E coverage for a mobile flow, or
  when asked to write/run a Maestro flow. Complements the unit/integration tests
  (Jest + @testing-library/react-native) — Maestro covers the real
  navigate-and-assert user journeys those can't.
user-invocable: true
---

# maestro-e2e — Mobile (and web) end-to-end tests with Maestro

[Maestro](https://maestro.dev) is a single framework for mobile and web E2E
testing. Flows are **human-readable YAML** interpreted at runtime (no
compilation), so they are fast to write and resilient. It runs React Native /
Expo, native, Flutter, and hybrid apps on emulators, simulators, and real
devices.

> **Scope.** This is the **committed E2E test artifact** layer, written by the
> **Tester in Phase 6** alongside the unit/integration suite. It is distinct from
> [`agent-device`](../agent-device/SKILL.md), which the Developer uses for
> interactive verification during Phase 3. Maestro flows are checked in and run
> repeatably; agent-device sessions are throwaway verification.

## When to use it

- **Phase 6, MOBILE surface**: add E2E flows that exercise the user journey the
  Story delivers (e.g. log in → select an account → record a transaction →
  assert the new balance is visible).
- To cover cross-screen navigation, deep links, permission prompts, and
  offline/empty/error states that unit tests can't reach.
- Web E2E is also possible with Maestro, but the WEB surface's primary suite stays
  Vitest + RTL + MSW per [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md);
  add Maestro web flows only when explicitly asked.

## Prerequisites

- A running simulator/emulator (or device) and a launchable build of the app — try
  **Expo Go** first per [`building-native-ui`](../building-native-ui/SKILL.md).
- The `maestro` CLI. If missing, `/init-workspace` installs it
  (`curl -fsSL "https://get.maestro.mobile.dev" | bash`); verify with
  `maestro --version`. (On macOS Homebrew is an alternative; the install script is
  the cross-platform default.)

## Flow layout & conventions

- Flows live under **`mobile/.maestro/`** (one `.yaml` per journey), named after
  the journey: `mobile/.maestro/record-transaction.yaml`.
- Each flow declares the `appId` and a sequence of commands:

```yaml
# mobile/.maestro/record-transaction.yaml
appId: com.yourorg.app           # from app.config.ts (ios.bundleIdentifier / android.package)
---
- launchApp
- tapOn: "Sign in"
- inputText: "demo@example.test"
- tapOn: "Continue"
- assertVisible: "Select an account"
- tapOn: "Acme Demo Account"
- tapOn:
    id: "fab-add-transaction"    # prefer testID/accessibility id over visible text where stable
- inputText: "25"
- tapOn: "Save"
- assertVisible: "Balance: 125"
```

- Prefer stable **`id:` selectors** (testID / accessibility id already required by
  `expo-mobile-conventions` for components) over brittle visible-text matching.
- Keep flows **independent and idempotent** — each `launchApp` starts clean; don't
  chain state across flows.
- Use **subflows** (`runFlow:`) for shared setup like login; keep them in
  `mobile/.maestro/subflows/`.
- Cover at least the **happy path + one key error/empty path** per Story flow —
  mirroring the integration-test bar in [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md).

## Running

```bash
maestro --version                                   # verify install
maestro test mobile/.maestro/                        # run all flows
maestro test mobile/.maestro/record-transaction.yaml   # run one
maestro studio                                       # interactive flow authoring / element inspector
```

All flows must pass before the Tester commits. On failure, read Maestro's output
(it reports the failing command + a screenshot), fix the flow or the underlying
code path (production fixes are NOT the Tester's job — flag them to the
orchestrator), and re-run.

## Conventions for this harness

- **Commit as test code** — Maestro flows are committed by the **Tester** with a
  `test(mobile): …` Conventional Commit (no issue ID), same rules as the unit
  suite. They are NOT production code and the Tester may add them in Phase 6.
- **No secrets / real PII** in flows — use seeded sandbox accounts and synthetic
  data only; the harness data-policy rules apply to YAML too.
- **CI**: E2E flows can run on EAS Workflows / GitHub Actions against a build
  artifact; wiring CI is out of scope for the per-Story workflow unless asked.
- Report E2E results (flows added, pass count) in your `📋 AGENT STATUS` block.

## See also

- [`agent-device`](../agent-device/SKILL.md) — interactive verification during development (Phase 3) that a flow is even worth codifying.
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — MOBILE test bar, coverage threshold, and testID requirement.
- [`building-native-ui`](../building-native-ui/SKILL.md) — getting the app running before a flow can drive it.
- Upstream: `mobile-dev-inc/Maestro` on GitHub and `maestro.dev`.
