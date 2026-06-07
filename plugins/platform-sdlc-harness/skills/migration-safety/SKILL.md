---
name: migration-safety
description: >
  Review EF Core database migrations on the SERVICE surface for destructive or
  locking operations before they ship — dropped columns/tables, non-nullable
  columns without a default, narrowing type changes, renames that lose data, and
  index creation that locks a hot table. For a product handling real customer
  data, an unsafe migration is a top production-incident source. Load this in the
  Developer self-review and Reviewer Phase B whenever a change adds or edits a
  file under a `Migrations/` folder. Advisory — surfaces risks; never auto-blocks.
user-invocable: true
---

# migration-safety — EF Core migration review (service)

A clean build and green tests say nothing about whether a migration will drop a
column of live data or lock a table for minutes on deploy. This skill is the
review lens for any change that touches `**/Migrations/*.cs`.

## When to use it

- **Developer (Phase 3), SERVICE**: any task that adds/edits an EF Core migration
  — review your own migration against the checklist before committing.
- **Reviewer (Phase B), SERVICE**: when the diff includes a `Migrations/` file,
  run this review and raise risky operations as `[R<n>]` comments.

## How to inspect

1. **Read the migration's `Up()` and `Down()`** (`**/Migrations/*.cs`).
2. **Generate the SQL** to see what actually runs (idempotent, no DB needed):
   ```bash
   dotnet ef migrations script --idempotent --project <Infra.csproj> --startup-project <Api.csproj> --output migration.sql
   # or diff a range: dotnet ef migrations script <FromMigration> <ToMigration> ...
   ```
3. Read `migration.sql` and check it against the risk table below.

## Risk checklist (flag = raise as a finding)

| Operation | Risk | Safer pattern |
|---|---|---|
| `DropColumn` / `DropTable` | **Permanent data loss**; also breaks running old app instances mid-deploy | Expand→contract: stop writing → deploy → backfill → drop in a *later* migration after the old code is gone |
| `AddColumn` non-nullable, no `defaultValue` | Fails on any existing row | Add nullable (or with a default), backfill, then tighten in a later migration |
| `RenameColumn` / `RenameTable` | Data-loss-shaped to old code; breaks zero-downtime deploys | Add new + copy + drop old across releases |
| `AlterColumn` narrowing (e.g. `nvarchar(max)`→`nvarchar(50)`, `bigint`→`int`) | Truncation / overflow failures | Validate data first; widen-only when possible |
| `CreateIndex` on a large/hot table (non-concurrent) | Table lock → request timeouts on deploy | Postgres: `CREATE INDEX CONCURRENTLY` (`migrationBuilder.Sql` outside a txn); SQL Server: `ONLINE = ON` |
| Adding a `unique` constraint/index | Fails if existing data violates it | Dedupe first; add in a controlled step |
| Empty or auto-`throw` `Down()` | No rollback path | Provide a real `Down()`, or document why irreversible |
| Data migration mixed with schema change in one migration | Long lock + hard rollback | Separate schema (fast) from data backfill (batched, online) |

## How to interpret (harness policy — advisory)

- **Scoped to the diff's migration(s)** — review what this change introduces.
- **Developer**: restructure unsafe ops (expand→contract) before committing, or
  document an explicit, justified exception in the PR description.
- **Reviewer**: raise destructive/locking ops as `[R<n>] CRITICAL` (data loss) or
  `WARNING` (locking/rollback) with the safer pattern; read-only — never edits.
- This is **advisory** — it never hard-blocks, but a `CRITICAL` data-loss finding
  on customer data is the kind of thing a human gate (GATE #2 / GATE #3) should
  take seriously.

## See also

- [`dotnet-conventions`](../dotnet-conventions/SKILL.md) — SERVICE rules incl. EF Core patterns.
- [`api-contract-check`](../api-contract-check/SKILL.md) — the API-surface equivalent (breaking changes for consumers).
- [`security-scan`](../security-scan/SKILL.md) / [`dotnet-code-quality`](../dotnet-code-quality/SKILL.md) — the other service review lenses.
- EF Core docs: "Managing Migrations" and "Applying Migrations" (idempotent scripts, zero-downtime).
