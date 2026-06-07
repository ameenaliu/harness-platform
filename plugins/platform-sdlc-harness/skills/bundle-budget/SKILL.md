---
name: bundle-budget
description: >
  Enforce JavaScript bundle-size budgets on WEB (React 19 / Vite) and MOBILE
  (Expo / RN) using size-limit, so a change that bloats the bundle (a heavy
  dependency, an accidental barrel import) is caught as a hard number rather than
  noticed in production. Load this in the Developer self-review and Reviewer
  Phase B for WEB/MOBILE. Advisory — reports the delta; never a commit gate
  unless the team wires a CI threshold.
user-invocable: true
---

# bundle-budget — size-limit (web + mobile)

[size-limit](https://github.com/ai/size-limit) measures the real cost of your
bundle (minified + gzipped/brotli, optionally with time-to-load estimates) and
compares it against configured budgets. It turns "this feels heavy" into a
concrete byte delta — the quantitative complement to React Doctor's qualitative
perf findings.

## When to use it

- **Developer (Phase 3), WEB/MOBILE**: after adding a dependency or a sizable
  feature, check the bundle delta before committing — a new multi-hundred-KB dep
  is a design decision, not an accident.
- **Reviewer (Phase B), WEB/MOBILE**: if the diff adds a dependency or a large
  surface, confirm the bundle impact is justified; raise an unjustified jump as a
  `[R<n>]` finding.

## Prerequisites / setup

size-limit is config-driven, so it needs a small one-time setup per surface (an
init/infra decision, not per-Story) — a `devDependency` + a `.size-limit.json`
budget file. `/init-workspace` notes this; it does not silently add deps to the
repo.

```jsonc
// web/.size-limit.json  (example)
[
  { "name": "main bundle", "path": "dist/assets/index-*.js", "limit": "250 kB" }
]
```

```bash
# one-time, per surface (web shown):
cd web && yarn add -D size-limit @size-limit/preset-app
```

Once configured:

```bash
cd web && yarn build && npx size-limit            # measure vs budget
npx size-limit --json                              # machine-readable
```

For **MOBILE** (Metro/RN), budget the production JS bundle from
`npx expo export` output, or use `react-native-bundle-visualizer` for a treemap
when investigating a regression.

## How to interpret (harness policy — advisory)

- **Delta over absolute**: focus on what *this change* added to the bundle, not
  the total (legacy size is a separate optimization effort).
- **Justify, don't just pass**: a budget breach from a genuinely needed dependency
  is acceptable if documented (and the budget bumped deliberately); a breach from
  a barrel import / duplicate dep / oversized polyfill should be fixed
  (tree-shake, dynamic import, lighter alternative).
- **Not auto-blocking** in the per-Story loop. Teams that want a hard gate wire
  size-limit's GitHub Action with a CI threshold — an infra choice.
- Report the measured delta in the status block when meaningful.

## See also

- [`react-doctor`](../react-doctor/SKILL.md) — flags bundle-size *risks* qualitatively; this measures them exactly.
- [`dead-code-analysis`](../dead-code-analysis/SKILL.md) — unused deps are a common bundle-bloat source.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) / [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md).
- Upstream: `github.com/ai/size-limit`.
