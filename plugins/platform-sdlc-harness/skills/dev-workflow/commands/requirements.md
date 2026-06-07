# Phase 1: Requirements

**Phase**: 1
**Actor**: Orchestrator (preflight) + Planner agent (requirements + parent Feature lookup)

## Prerequisites

None — this is the first step in the pipeline.

## Preflight

1. Read `.claude/context/platform-context.md`. Confirm `Repo`, `Org`, `Project Number`, branch names (`ProdBranch` default `main`, `IntegrationBranch` default `develop`), `Worktree` flag, `UserSlug`, and the GitHub configuration are present. If `platform-context.md` is missing, halt with: *"Workspace not initialized — run `/init-workspace` first."*
2. Sync the working tree to the integration branch:
   ```bash
   git -C <repo-path> fetch origin
   git -C <repo-path> checkout <IntegrationBranch>     # default: develop
   git -C <repo-path> pull --ff-only origin <IntegrationBranch>
   ```
   On conflict / divergence, halt and report to the human.

## GitHub Pre-State Sync

Ensure the Story's Project **Status** is at least `Ready`. Read the Story's current board status, and if it is `Backlog` / `No Status`, set it to `Ready`:
```bash
# Resolve the Project item for the Story (idempotent — returns existing item if present):
item_id=$(gh project item-add <project-number> --owner <owner> --url \
  "$(gh issue view <story-number> --json url -q .url)" --format json -q .id)
# Set Status → Ready (field/option IDs resolved once from gh project field-list):
gh project item-edit --project-id <project-id> --id "$item_id" \
  --field-id <status-field-id> --single-select-option-id <ready-option-id>
```
This is the only GitHub write in Phase 1. Best-effort — on failure, warn and continue.

## Delegate to the Planner

Spawn `@platform-sdlc-planner` with:

- Story issue number (`#<n>`)
- Repo / Org / Project from `platform-context.md`
- Direction: pull the Story issue (`gh issue view <n> --json title,body,labels,url`), identify the **parent Feature** via the native sub-issue link (`gh api graphql` on `issue.parent`, or the `Parent: #<n>` body line / `Feature` reference — drives branch routing), identify affected **Surfaces** from the title prefix (`[service]` / `[web]` / `[mobile]` / `[cross-cutting]`; ask via `AskUserQuestion` if missing), parse the acceptance-criteria checklist from the body, surface ambiguities via `AskUserQuestion`. Confirm requirements with the human before returning.
- (Optional) Ask whether to draft 4 initiative MD files (`README.md`, `spec.md`, `test-plan.md`, `work-units.md`) under `docs/initiatives/<slug>/`. The planner writes these but doesn't commit yet — orchestrator commits at GATE #1 in Phase 2.

## Parse Planner Status Block

After the planner returns, extract from `📋 AGENT STATUS`:
- `Story`, `Parent Feature` (`#<n>` or `none`), `Affected Surfaces` (`service | web | mobile | combinations`)
- `Outcome` (`SUCCESS` / `BLOCKED`)
- `Files written` (initiative docs, if produced)
- `Blockers` (if any)

Save these to a tracker stub or to your working memory. They drive Phase 2 (branch strategy comes from Parent Feature).

## Next

If Outcome = `SUCCESS`, proceed to Phase 2 (`plan`). If `BLOCKED`, present blockers to the human and wait for resolution before continuing.
