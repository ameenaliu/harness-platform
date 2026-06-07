---
name: expo-doctor
description: >
  Validate the MOBILE (Expo) project's health and dependency compatibility with
  `npx expo-doctor` — catches mismatched Expo SDK / React Native / package
  versions, invalid app config, and common misconfigurations the build and unit
  tests miss. Load this in the Developer self-review for MOBILE tasks (especially
  after adding/upgrading any dependency). Cheap, zero-config, advisory.
user-invocable: true
---

# expo-doctor — Expo project health check

`expo-doctor` runs a battery of checks against an Expo project: dependency version
compatibility with the installed SDK, `app.json` / `app.config.*` validity, native
config consistency, and known-bad package combinations. It's essentially free to
run and catches a whole class of "works locally, breaks on EAS build" problems
early.

## When to use it

- **Developer (Phase 3), MOBILE**: run it before committing, **especially after
  adding or upgrading any dependency** or touching `app.config.ts` / native
  config. A clean `tsc`/lint/test does not prove the Expo project is internally
  consistent.
- Any time a mobile build behaves oddly or after an Expo SDK bump (see
  [`upgrading-expo`](../upgrading-expo/SKILL.md)).

## Prerequisites / install

No install — runs via `npx`. `/init-workspace` pre-warms it.

```bash
cd mobile && npx expo-doctor
```

## How to interpret (harness policy — advisory)

- **Fix what your change caused**: an incompatible dependency you added, a config
  field you edited that's now invalid. Don't chase pre-existing warnings unrelated
  to the Story.
- **Version-compatibility warnings** are the highest-value output — resolve them
  with `npx expo install <pkg>` (which pins SDK-compatible versions) rather than a
  raw `yarn add`.
- Report the result in your `📋 AGENT STATUS` block when it surfaced anything
  (e.g. "expo-doctor: 15/15 checks passed").

## See also

- [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — MOBILE rules + stack.
- [`upgrading-expo`](../upgrading-expo/SKILL.md) — SDK upgrade flows where expo-doctor is essential.
- [`agent-device`](../agent-device/SKILL.md) — verify the running UI after the project checks out healthy.
- Upstream: `docs.expo.dev` → "expo-doctor".
