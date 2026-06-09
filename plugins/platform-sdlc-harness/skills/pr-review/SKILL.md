---
name: pr-review
description: >
  Standalone Phase 10 — holistic review of an open GitHub Pull Request on the in-scope
  monorepo, with inline + summary comments posted back to the PR via the `gh` CLI. Use to
  review any PR (whether created by dev-workflow or by a human), produce a structured
  report, and post the findings as PR comments. Comment-only — never approves, requests
  changes, or blocks the PR.
allowed-tools: Bash, Read, Grep, Glob
argument-hint: "<pr-number>"
user-invocable: true
---

# /pr-review — Standalone Phase 10 PR Review

**Usage:** `/pr-review <pr-number>`

Performs a holistic review of an open GitHub Pull Request and posts the findings as inline + summary comments to the PR via the `gh` CLI. **Comment-only — never approves, requests changes, or blocks the PR.**

## When This Runs

The skill has a single implementation invoked through two doors:

- **Inside `/dev-workflow`** — at Phase 10, after PR creation in Phase 9 / GATE #3. `dev-workflow/commands/post-pr-review.md` invokes this skill to close out the workflow with a final auditable PR review.
- **Standalone** — invoke directly any time on any PR, even ones not created by `/dev-workflow`. Useful for ad-hoc reviews of human-driven PRs.

Both paths execute the same logic below.

## Argument Parsing

Parse `$ARGUMENTS`:

- **PR number** (required): The numeric GitHub Pull Request number (e.g. `1234` from `https://github.com/<owner>/<repo>/pull/1234`).

## Resolve owner/repo

Read `<owner>` / `<repo>` from `.claude/context/platform-context.md` (the **Repo** section). If that file is absent or the value is unclear, fall back to `gh repo view --json owner,name -q '.owner.login + "/" + .name'` from inside the local repo. **Never hardcode an owner or repo name.** All `gh api` calls below use `repos/{owner}/{repo}/...`.

## Review Process

### Step 1: Pull the PR

```bash
gh pr view <pr-number> --json number,title,body,headRefName,baseRefName,files,commits
```

Extract: `title`, `body`, `headRefName` (source branch), `baseRefName` (target branch), `files` (changed paths), and `commits`. The **latest commit SHA** (used as `commit_id` for inline comments) is the last element of `commits`:

```bash
COMMIT_ID=$(gh pr view <pr-number> --json commits -q '.commits[-1].oid')
```

If the PR is closed/merged, warn and continue (you can still review historical PRs, just don't post new comments).

### Step 2: Resolve Local Repo Path

Read `.claude/context/platform-context.md` → **Repo** section to find the local checkout path for `<repo>`. Fetch + checkout the PR's source branch:

```bash
cd <repo-path>
git fetch origin
git checkout <headRefName>
git pull --ff-only origin <headRefName>
```

Alternatively `gh pr checkout <pr-number>` (from inside the repo) checks out the PR head directly.

### Step 3: Identify Affected Surfaces

From the diff paths (`files` from Step 1, or `git diff --name-only <baseRefName>...<headRefName>`):

- `service/...` → `SERVICE`
- `web/...` → `WEB`
- `mobile/...` → `MOBILE`

Multi-surface PRs load multiple conventions.

### Step 4: Read Linked Story Context (if any)

Parse the PR body for `Closes #<n>` (also accept `Fixes #<n>` / `Resolves #<n>`). Each captured number is a linked issue. For the linked **Story** (and any linked parent), read it:

```bash
gh issue view <n> --json title,body
```

From the Story body, extract the title and the **`## Acceptance criteria`** checklist (the `- [ ]` / `- [x]` items under that heading) — this is the AC text for the AC compliance check.

If the PR body links no issue (no `Closes #<n>`), skip AC compliance verification and note this in the report.

### Step 5: Load Conventions

Always load `.claude/context/platform-context.md` (Repo-Specific Conventions section) plus the surface-specific conventions skill(s):

- `SERVICE` → `dotnet-conventions`
- `WEB` → `react-turbo-conventions`
- `MOBILE` → `expo-mobile-conventions`

### Step 6: Gather the Full Diff

```bash
cd <repo-path>
git diff <baseRefName>...HEAD --stat
git diff <baseRefName>...HEAD
git log <baseRefName>..HEAD --oneline
```

Or, without a local checkout: `gh pr diff <pr-number>` for the unified diff and `gh pr diff <pr-number> --name-only` for the file list.

### Step 7: Read All Changed Files

Read every file that appears in the diff to understand the complete changeset holistically. Do not rely solely on the diff — read the full file to understand context around changes.

### Step 8: Build & Test Verification

Re-run the build + tests locally; never trust prior CI green:

**SERVICE:**
```bash
cd <repo-path>
dotnet build <affected-solution> 2>&1  # zero errors AND zero warnings
dotnet test <affected-solution> 2>&1
```

**WEB:**
```bash
cd <repo-path>
yarn turbo lint typecheck build test --filter=...<affected-app> 2>&1
```

**MOBILE:**
```bash
cd <repo-path>
yarn tsc:build && yarn lint && yarn test:coverage:check 2>&1
```

Coverage thresholds: `SERVICE ≥ 80%`, `WEB ≥ 70%`, `MOBILE ≥ 85%` on new/modified code.

### Step 9: Evaluate Each Review Area

Work through each section of the report template below. For each checklist item, verify by reading the actual code — never assume compliance.

### Step 10: Produce the Report

Generate the PR Review Report below. Save it to `.claude/pr-reviews/PR-<pr-number>-<YYYY-MM-DD>.md` for the human's reference.

### Step 11: Post Comments to the GitHub PR

For each `[S<n>]` / `[R<n>]` / `[SEC<n>]` finding, post an **inline review comment** via the GitHub API. Use the latest commit SHA from Step 1 as `commit_id`:

```bash
gh api --method POST repos/{owner}/{repo}/pulls/<pr-number>/comments \
  -f path='<path relative to repo root, no leading slash>' \
  -F line=<n> \
  -f side='RIGHT' \
  -f commit_id="$COMMIT_ID" \
  -f body='[<S/R/SEC><n>] <CRITICAL|WARNING|SUGGESTION>: <description>

Suggested fix: <fix>'
```

- `side='RIGHT'` targets the post-change (added/modified) line; use `side='LEFT'` when the finding is about a removed/changed line on the base side.
- For a finding spanning multiple lines, add `-F start_line=<a> -f start_side='RIGHT'` alongside `line=<b>`.
- Each call returns a JSON object — capture its `id` (the review-comment ID) for the report.

After all inline comments, post **one summary review** in comment-only mode (this is the only summary mechanism — it **must not** be `--approve` or `--request-changes`):

```bash
# Write the summary body to a file first, then:
gh pr review <pr-number> --comment --body-file <summary-file>
```

Where `<summary-file>` contains:

```markdown
## Holistic PR Review (platform-sdlc-harness)

**Counts**: X CRITICAL, Y WARNING, Z SUGGESTION

**Top themes**:
- <theme 1>
- <theme 2>

**Build**: <PASS | FAIL>
**Tests**: <PASS | FAIL>
**Coverage**: <surface>=<pct>% (target <threshold>%)

Inline comments: <count> posted across files.
```

Record every returned comment `id` for the orchestrator's tracker update. **Never** call `gh pr review` with `--approve` or `--request-changes`, and never `gh pr merge` / `gh pr close` — Phase 10 is comment-only.

---

## PR Review Report Template

```markdown
# PR Review Report — PR #<pr-number>: <Title>

**Repository**: <owner>/<repo>
**Source -> Target**: <headRefName> -> <baseRefName>
**Linked Story**: #<n> (or "none")
**Affected Surfaces**: <SERVICE | WEB | MOBILE | combinations>
**Date**: <UTC timestamp>

---

## 1. Summary Verdict

| Area                     | Verdict |
|--------------------------|---------|
| Acceptance Criteria      | PASS / PARTIAL / FAIL / N/A (no linked Story) |
| Conventions Compliance   | PASS / FAIL |
| Architecture & Design    | PASS / FAIL |
| Code Quality             | PASS / FAIL |
| Test Coverage            | PASS (XX%) / FAIL (XX%) |
| Security                 | PASS / ADVISORY / FAIL |
| Git Hygiene              | PASS / FAIL |
| **Overall**              | **INFORMATIONAL — N findings posted to PR** |

> **Phase 10 verdict is always INFORMATIONAL. Even CRITICAL findings result in comments only, not blocking. The PR is open; resolution is the human's + assigned reviewers' responsibility.**

---

## 2. Acceptance Criteria Check

**Mindset:** treat each acceptance criterion as unverified until you have located the code yourself. For each AC, use Grep/Glob/Read to locate the specific code that satisfies it, then find at least one test that exercises that code path.

| # | Criterion (from Story) | Status | Implementation | Test |
|---|------------------------|--------|---------------|------|
| AC1 | <text> | ✅ Met / ⚠️ Partial / ❌ Missing | <file:line> | <test-file:line or "❌ none"> |

*(omit if no Story is linked to the PR)*

---

## 3. Conventions Compliance

Checked against the loaded conventions + `.claude/context/platform-context.md`.

### SERVICE-Specific (when Surface includes SERVICE)

- [ ] Layered structure: WebApi -> Application -> Domain -> Infrastructure
- [ ] Domain has zero infrastructure dependencies
- [ ] No business logic in controllers / minimal APIs
- [ ] Constructor injection only
- [ ] Wolverine handlers idempotent; outbox writes inside the same transaction as state changes
- [ ] EF Core: Fluent API only; dedicated `IEntityTypeConfiguration<T>`; descriptive migration names
- [ ] Naming: PascalCase types, `_camelCase` private fields, `Async` suffix, `I` prefix on interfaces
- [ ] Structured logging via `ILogger<T>` / OpenTelemetry / Seq — no string interpolation in log messages
- [ ] xUnit + FluentAssertions + Moq + Testcontainers + WebApplicationFactory + Refit; integration tests use real DB (no repository-layer mocks)
- [ ] Coverage ≥ 80% on new/modified SERVICE code

### WEB-Specific (when Surface includes WEB — React 19 + Turbo)

- [ ] New code lives in the right `apps/<app>` or shared `packages/<pkg>` per Turbo monorepo layout
- [ ] No cross-package deep imports (`packages/foo/src/internal/...`)
- [ ] Uses the shared component primitives — never raw `<div>` / `<button>` (banned-HTML rule per `.claude/rules/web/code-style.md`)
- [ ] React Query 5 (TanStack Query) hooks via the shared hooks package for server state; Redux Toolkit slice for UI state — never raw `useQuery` / `useMutation`
- [ ] No secret leaked into the client bundle (`VITE_*` for public, server-side for secret)
- [ ] Vitest + RTL tests; MSW for API mocks
- [ ] Coverage ≥ 70% on new/modified WEB code

### MOBILE-Specific (when Surface includes MOBILE — Expo)

- [ ] File-based routing in `app/` (Expo Router)
- [ ] State via **Redux Toolkit + Persist** with the right persistence layer (`persistedSecured` / `persistedFarm` / `persistedFeature` / `persistedGlobal` / `userLocalPersisted` / `nonPersisted` — per `.claude/rules/mobile/code-style.md`)
- [ ] `CustomFlashList` (Shopify FlashList wrapper) — NOT `FlatList`
- [ ] Styling via `StyleSheet.create()` + `ColorTheme` / `SpacingConstants` / `FontsConstants` — NO hardcoded hex
- [ ] Firebase + Sentry initialised in the right entry point
- [ ] No secret in JS bundle (use `expo-secure-store` for refresh token only; EAS secrets for build-time)
- [ ] Permissions guarded; offline state handled
- [ ] Deep links registered in `app.config.ts`
- [ ] Jest + `@testing-library/react-native` tests; mocks for `expo-secure-store`, Firebase, Sentry
- [ ] Coverage ≥ 85% on new/modified MOBILE code

### Git Hygiene (all surfaces)

- [ ] Working branch matches `^users/[a-z0-9_]+/(bugs/)?[a-z0-9-]+$` (stories `users/<slug>/<impl>`, bugs `users/<slug>/bugs/<impl>`) and the PR base is `develop` (single-branch model — no feature branch)
- [ ] Commits follow Conventional Commits with surface scope: `^(feat|fix|chore|refactor|perf|docs|ci|test|build)\(([a-z]+(/[a-z]+)?)(,[a-z]+(/[a-z]+)?)*\):\s+[a-z].*$`
- [ ] **No issue ID `#<n>` in commit lines** (linking happens in the PR body via `Closes #<n>`)
- [ ] PR body carries `Closes #<story>` so the Story auto-closes on merge
- [ ] No merge commits from base onto user branch (rebase instead)
- [ ] No build-breaking commits

**Violations** (if any):

| ID | Severity | File:Line | Convention Violated | Detail |
|----|----------|-----------|---------------------|--------|
| [C1] | CRITICAL / WARNING | <path>:<line> | <which rule> | <what's wrong> -> <fix> |

---

## 4. Holistic Code Quality

| ID | Severity | File:Line | Description |
|----|----------|-----------|-------------|
| [Q1] | CRITICAL / WARNING / SUGGESTION | <path>:<line> | <description> -> <suggested fix> |

---

## 5. Security Review

- [ ] No secrets / connection strings / tokens in source
- [ ] Paystack / SendGrid / Firebase / OpenAI / Sentry keys never client-side
- [ ] New config documented with defaults; no `appsettings.Production.json` committed
- [ ] Auth/SAML/OIDC changes follow established patterns
- [ ] No injection vectors (SQL, XSS, command)
- [ ] Input validation at system boundaries (controllers, hooks, route params)

| ID | Severity | File:Line | Description |
|----|----------|-----------|-------------|
| [SEC1] | CRITICAL / ADVISORY | <path>:<line> | <description> |

---

## 6. Test Coverage Summary

| Surface | Coverage | Threshold | Tests passing |
|---------|----------|-----------|---------------|
| SERVICE | XX% | 80% | X / X |
| WEB | XX% | 70% | X / X |
| MOBILE | XX% | 85% | X / X |

---

## 7. Files Changed Overview

<output of `git diff --stat <baseRefName>...<headRefName>` (or `gh pr diff <pr-number> --name-only`)>

---

## 8. Posted PR Comments

| Comment ID | Comment | File:Line |
|------------|---------|-----------|
| <id> | [S1] <summary> | <file>:<line> |
| <id> | [R1] <summary> | <file>:<line> |
| (summary review) | (summary) | n/a |

---

## 9. Verdict Notes

**Phase 10 verdict is always INFORMATIONAL.** This report is comment-only. The PR remains open and the human + assigned reviewers decide resolution. The harness's job is complete.
```

---

## 📋 AGENT STATUS

When invoked from `/dev-workflow` Phase 10, end the response with the contract block the orchestrator parses:

```
📋 AGENT STATUS
Mode: holistic-post-pr
Outcome: SUCCESS | FAILED
PR: #<pr-number>
Counts: <X CRITICAL> / <Y WARNING> / <Z SUGGESTION>
Build: PASS | FAIL
Tests: PASS | FAIL
Review comments: [R1] ... ; [S1] ... ; [SEC1] ...
PR comment IDs: <inline comment id>, <inline comment id>, ... ; summary review posted
Report: .claude/pr-reviews/PR-<pr-number>-<YYYY-MM-DD>.md
Verdict: INFORMATIONAL (comment-only — never blocks)
```

---

## Key Rules

- This skill writes to GitHub PR comments only (inline review comments via `gh api` + one summary review via `gh pr review --comment`) — never to source files, never to the local tracker (the orchestrator owns the tracker; this skill writes to `.claude/pr-reviews/` for the local report).
- **Independently verify** build, tests, and coverage — never trust prior CI claims or per-task review claims.
- Be specific and actionable — every finding must include a file path, line number, and concrete fix suggestion.
- Read the **full files**, not just the diff, to understand context around changes.
- **Comment-only — never blocks the PR.** Even CRITICAL findings result in an `INFORMATIONAL` verdict. Never `--approve`, never `--request-changes`, never `gh pr merge` / `gh pr close`.
- When invoked from `/dev-workflow` Phase 10, return the posted comment IDs so the orchestrator can record them in tracker `Phase 10 PR Review`.
- When run standalone (not via dev-workflow), the local report at `.claude/pr-reviews/` is the only persistent artefact besides the PR comments.
