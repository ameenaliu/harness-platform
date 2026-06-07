---
name: api-contract-check
description: >
  Detect breaking API changes on the SERVICE surface before a PR ships, by
  diffing the OpenAPI/Swagger spec of the change against the base branch with
  oasdiff. In a service↔web↔mobile monorepo a silently-broken endpoint contract
  breaks consumers at runtime — this catches removed endpoints, removed/renamed
  fields, newly-required parameters, and type changes. Load this in the Reviewer
  Phase B (and Developer self-review) for SERVICE tasks that touch controllers,
  DTOs, or routing. Advisory — surfaces breaking changes; never auto-blocks.
user-invocable: true
---

# api-contract-check — OpenAPI breaking-change detection (service)

The service exposes an OpenAPI/Swagger document; web and mobile consume it. A
change that removes a field or makes a parameter required is invisible to the
build but breaks every consumer. [oasdiff](https://github.com/oasdiff/oasdiff)
diffs two OpenAPI specs and reports **breaking** changes specifically.

## When to use it

- **Developer (Phase 3), SERVICE**: after changing controllers / minimal-API
  endpoints / request-response DTOs, confirm you didn't break the contract (or
  that the break is intended + versioned).
- **Reviewer (Phase B), SERVICE**: when the diff touches the API surface, run the
  breaking-change diff and raise breaks as `[R<n>]` comments.

## Prerequisites / install

- `oasdiff` CLI. `/init-workspace` installs it when SERVICE is present; manual:
  ```bash
  brew install oasdiff            # macOS ; Linux/Windows: release binary or `go install github.com/oasdiff/oasdiff@latest`
  oasdiff --version
  ```
- A way to emit the OpenAPI spec for a given checkout. Options, in order of preference:
  - A build-time generated `swagger.json` (e.g. Swashbuckle CLI: `dotnet swagger tofile --output swagger.json <Api.dll> v1`).
  - The running app's `/swagger/v1/swagger.json` endpoint.

## Running

```bash
# 1. Emit the BASE spec (from the base branch checkout) → base.json
# 2. Emit the HEAD spec (from the PR branch checkout)   → head.json
# 3. Diff for breaking changes only:
oasdiff breaking base.json head.json
oasdiff breaking base.json head.json --format json     # machine-readable
# Full changelog (non-breaking too):
oasdiff changelog base.json head.json
```

In holistic review the Reviewer already has both branches available
(`git diff <base>...<head>`); generate each spec from the respective checkout (or
from two app runs) and diff.

## What counts as breaking (raise these)

- Removed endpoint / path / HTTP method.
- Removed or renamed response field a consumer may read.
- New **required** request parameter or body field (old clients omit it).
- Narrowed type / enum (removed allowed value), tightened validation.
- Changed status codes a consumer branches on.

Non-breaking (informational): new optional fields, new endpoints, new optional
params, relaxed validation.

## How to interpret (harness policy — advisory)

- **Intended breaks must be versioned**: a real breaking change belongs behind a
  new API version (`/v2/…`) or a coordinated consumer update — not a silent edit.
  If breaking is intended, the PR description must say so and name the consumer
  update plan.
- **Developer**: avoid accidental breaks; additive-first.
- **Reviewer**: raise each breaking change as `[R<n>] WARNING` (or CRITICAL if a
  shipped consumer depends on it) with the consumer impact; read-only — no edits.
- Advisory — never hard-blocks; a confirmed break to a live consumer is gate-worthy.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) — SERVICE API/controller conventions.
- [`migration-safety`](../migration-safety/SKILL.md) — the database-schema equivalent.
- [`react-turbo-conventions`](../react-turbo-conventions/SKILL.md) / [`expo-mobile-conventions`](../expo-mobile-conventions/SKILL.md) — the consumers a contract break would hit.
- Upstream: `github.com/oasdiff/oasdiff`.
