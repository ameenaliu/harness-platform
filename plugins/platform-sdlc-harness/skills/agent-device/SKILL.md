---
name: agent-device
description: >
  Drive a real iOS/Android app on a simulator, emulator, or device to verify
  MOBILE changes in the agentic build→run→inspect→fix loop. Load this when
  implementing or debugging an Expo / React Native screen and you need to
  confirm the running UI behaves as intended — not just that it compiles. Wraps
  the `agent-device` CLI (Callstack): a token-efficient way for an agent to open
  the app, read a compact accessibility snapshot, tap/type on real elements, and
  capture screenshots / logs / performance evidence.
user-invocable: true
---

# agent-device — Drive the running mobile app to verify UI

`agent-device` is a CLI from Callstack that lets a coding agent control a real
app on iOS, Android (and TV/desktop) through compact, token-efficient
accessibility snapshots — open the app, inspect the current UI, interact with
visible elements via refs (`@e3`) or selectors, and collect screenshots, videos,
logs, and performance evidence. It is to mobile what a browser-automation tool is
to the web: it closes the agentic loop so the Developer **verifies the running
screen**, not just a green build.

> **Scope.** This is for **verifying behaviour during development** (Phase 3,
> Developer). It is NOT the E2E test framework — automated end-to-end flows are
> written with **Maestro** in Phase 6 (see [`maestro-e2e`](../maestro-e2e/SKILL.md)).
> Think: agent-device = interactive verification by the agent; Maestro =
> repeatable committed test artifacts.

## When to use it

- After implementing or changing a mobile screen/flow, to confirm it renders and
  behaves correctly on a simulator/emulator before committing.
- To reproduce a reported mobile bug and gather evidence (snapshot + screenshot +
  logs) before fixing it.
- To sanity-check navigation, form input, list scrolling, empty/error states, and
  permission prompts on the real UI.

Do **not** use it to write or commit tests, and do not treat its session output
as a deliverable — it is a verification aid. The committed artifacts are the
production code (Developer) and Maestro flows (Tester).

## Prerequisites

- **Node.js 22+**.
- **iOS**: Xcode + an available simulator. **Android**: Android SDK + `adb` + a
  running emulator or connected device.
- A built/installed app to drive. Per [`building-native-ui`](../building-native-ui/SKILL.md),
  try **Expo Go** first (`npx expo start`); only use a dev/custom build when the
  change needs native code.

If the `agent-device` CLI is missing, `/init-workspace` installs it
(`npm install -g agent-device@latest`); you may also install it on demand. Verify
with `agent-device --version`.

## Core loop (commands)

The CLI is session-based. Names below are the stable entry points — run
`agent-device help` / `agent-device help <cmd>` for the exact flags in your
installed version.

```bash
agent-device --version            # verify install
agent-device apps                 # list installable / running apps & targets
agent-device open <app>           # start a session against an app on a sim/emulator/device
agent-device snapshot             # compact accessibility tree (refs like @e3) — read the UI
agent-device tap @e3              # interact with a visible element by ref or selector
agent-device fill @e7 "acme account" # type into a field
agent-device screenshot out.png   # capture visual evidence
agent-device close                # end the session
```

Typical Developer loop for a mobile task:

1. `npx expo start` (or run the dev build) so the app is launchable.
2. `agent-device open <app>` → `agent-device snapshot` to read the current screen.
3. Drive the change you implemented (`tap` / `fill` / scroll), re-`snapshot` to
   confirm the expected state, `screenshot` any state worth recording.
4. If the UI is wrong, fix the code and repeat. Only commit once the running UI
   matches the task's acceptance criteria.
5. `agent-device close`.

## Conventions for this harness

- **Surface gating** — only relevant to `MOBILE` tasks. Skip for SERVICE/WEB.
- **No secrets / real PII** — never type real credentials or customer PII into the
  app during a session; use seeded/sandbox accounts. The harness data-policy rules
  still apply.
- **Evidence, not noise** — keep screenshots/logs in a scratch dir; do not commit
  them. Reference key findings in your `📋 AGENT STATUS` block (e.g. "verified the
  order-processing screen renders results + empty state via agent-device").
- **Don't fake a pass** — if a simulator/emulator isn't available in the
  environment, say so in your status block rather than claiming UI verification
  you didn't perform.

## See also

- [`building-native-ui`](../building-native-ui/SKILL.md) — get the app running (Expo Go vs custom build) before driving it.
- [`maestro-e2e`](../maestro-e2e/SKILL.md) — turn a verified flow into a committed E2E test (Phase 6).
- [`react-doctor`](../react-doctor/SKILL.md) — static perf/quality scan of the React code you just verified.
- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — the MOBILE rules this verification checks against.
- Upstream: `callstack/agent-device` on GitHub and `agent-device.dev`.
