# /backlog-analyze Command

> **Note:** For most workflows, `/backlog-improve` is the recommended alternative — it combines readiness analysis with refinement in a single adaptive flow. `/backlog-analyze` remains available when you need a standalone readiness report (e.g., to share with the PO before a refinement session, or to triage a backlog of items).

Pre-refinement readiness check. Evaluates a Story against quality criteria + harness-specific conventions and produces a readiness report posted as a comment on the Story issue.

## Invocation

The user types `/backlog-analyze [issue-number]`. This command is always human-invoked.

## Prerequisites

- `.claude/context/platform-context.md` must exist (provides **Org** + **Repo**).
- `gh` CLI available and authenticated (`gh auth status`).
- The configured repo cloned locally — needed to read `.claude/rules/` + `.claude/architecture/` for context.

## Behavior

### Step 1 — Read the Story

Read the Story issue with `gh issue view <n> --json title,body,labels,comments` (add `--repo <org>/<repo>` when not inside the clone). Extract:
- Title (and **parse the E/F/S numbering prefix** `S<e>.<f>.<s>` and the `[<Surface>]` segment — `[service]`, `[web]`, `[mobile]`, `[cross-cutting]`, or combos like `[mobile][service]`; record what's there or `none`)
- Body — the Markdown **Story**, **Acceptance criteria**, **Surface**, and **Notes / links** sections (matching the `story.yml` issue-form template — see `skills/github-rendering/SKILL.md` § Story structure), plus any optional **In Scope**, **Out of Scope**, **Implementation dependencies**, **Open Questions**, **Technical notes** sections
- Labels — `type:story` / `type:bug`, `surface:<surface>`, `blocked`, Project Status (read separately, below)
- **Surface** — from the `surface:*` label and the body's `## Surface` section
- **Project Status** — read the Story's Project (v2) **Status** field (`Backlog` / `Ready` / `In Progress` / `In Review` / `Done`) via `gh project item-list` / `gh api graphql` against the project number in `platform-context.md`
- Issue type — `type:story` vs `type:bug` label
- **Parent Feature** — the Story's parent via the native sub-issue link (`gh api graphql` reading `parent { number title }`), falling back to a `Parent: #<n>` line in the body; record `#<n> (F<e>.<f> <title>)` or `none`
- **Blocked by / Blocks** — read native dependencies: `gh api "repos/<org>/<repo>/issues/<n>/dependencies/blocked_by"` and `.../dependencies/blocking` (fallback for older GitHub Enterprise: the body's `## Implementation dependencies` lines + `blocked` label)

If the issue is not found or not accessible, inform the user clearly and stop.

### Step 2 — Load Context

Read the following in this order:
1. `.claude/context/platform-context.md` — workspace config, GitHub Org/Repo/Project, conventions index.
2. For each Surface detected in the title prefix:
   - `.claude/rules/<surface>/code-style.md` (where surface = `backend` for service, `web`, `mobile`)
   - `.claude/rules/<surface>/testing.md`
3. For the affected area (inferred from the title or the parent Feature title):
   - `.claude/architecture/<area>/<surface>.md` for each detected surface
4. `.claude/CLAUDE.md` — the index of rules + architecture.

If no Surface is present, skip the surface-specific reads and flag this in the report.

### Step 3 — Evaluate Readiness

Score the Story across the dimensions below. For each, assign a flag (🔴 critical / 🟡 needs attention / 🟢 good) and a specific one-paragraph explanation. Where possible, draft a concrete fix.

**Standard quality dimensions** (from `templates/readiness-report.md`):
- Title clarity
- Story / body completeness
- Acceptance criteria quality (testable, Given/When/Then where applicable, count reasonable)
- Scope (is this a 1-5 day developer outcome? Or does it look like a Feature disguised as a Story?)
- Dependencies (other Stories, external services, infra)
- Risks & open questions
- Assumptions

**Harness-specific dimensions** (mandatory additions for every analysis):

| Dimension | Pass criteria | Flag if missing |
|---|---|---|
| **E/F/S numbering prefix** | Title starts with `S<e>.<f>.<s>:` (e.g. `S1.2.3:`) — see `skills/github-rendering/SKILL.md` § Title numbering scheme | 🟡 Needs attention — without it the parent–child structure isn't visible on the board; suggest the prefix inferred from the parent Feature. **Never renumber an existing prefix.** |
| **Surface label + prefix** | Title carries `[<surface>]` after the numbering prefix AND a matching `surface:<surface>` label exists | 🔴 Critical — dev-workflow planner can't route this; suggest the exact Surface based on the body, and the `surface:*` label to add |
| **Parent Feature** | Linked as a sub-issue of a Feature (or `Parent: #<n>` in the body) — mandatory unless `type:bug` | 🔴 Critical for non-Bugs — sets the backlog hierarchy + board Parent grouping (it does **not** affect git branching — every Story branches off `develop`); suggest checking with `/discovery-workflow extend` if the Feature exists |
| **Status posture** | Project Status `Ready` or `In Progress` (team agrees it's well-formed enough to work) | 🟡 If `Backlog`/`No Status` — flag *"should run /backlog-improve first to reach Ready"*; if `Done` — flag *"refinement of completed items is unusual; confirm intent"* |
| **AC granularity** | Story ≈ 1-5 day developer outcome. Heuristic: AC count ≤ 8 AND Story/scope sentences ≤ 15 | 🟡 If exceeds — likely too large; suggest splitting via `/discovery-workflow extend <feature-#>` to add sibling Stories |
| **Surface-architecture coverage** | For each affected surface, AC references match components / services / patterns that appear in `.claude/architecture/<area>/<surface>.md` | 🟡 If AC mentions components NOT in the architecture doc, surface as either *"new component — Phase 8 will reconcile"* or *"likely architectural gap"* with the doc path the human can verify |

### Evaluation rules

**Be specific, not generic.** "Acceptance criteria could be improved" is useless. Instead: *"AC #2 says 'transactions are saved' — not testable. Suggest: 'Given a logged-in user with an active subscription, When they submit a payment via the payment-provider webhook, Then the transaction is persisted via the service Outbox and a confirmation push notification is sent.'"*

**Suggest, don't just critique.** Every 🔴 or 🟡 flag must include a concrete improvement suggestion. Draft replacement text where possible (titles, AC, body sections).

**Use the repo's real vocabulary in suggestions.** Reference the real services, integrations, and conventions named in `.claude/architecture/*` + `.claude/rules/*` for this repo. A generic suggestion is a missed opportunity. Do not assume a specific product's services exist — read them from the architecture docs.

**Consider the audience.** The readiness report appears as a GitHub issue comment seen by the PO + team. Keep the tone constructive and collaborative.

**Use architecture knowledge.** If the Surface is `[mobile]` and the body mentions a concept like "batch sync" — read `.claude/architecture/<area>/mobile.md` to confirm it's a known concept; if it's not in the doc, that's worth flagging.

### Step 4 — Generate the Report

Produce the readiness report following the format in `templates/readiness-report.md`. The report includes:
1. **Header**: Story issue number, title, Project Status, parent Feature, affected surfaces, labels.
2. **Summary verdict**: one of `🟢 Ready for /dev-workflow`, `🟡 Needs refinement (recommend /backlog-improve)`, `🔴 Needs split or rework`.
3. **Standard dimensions table**: flag + explanation per dimension.
4. **Harness dimensions table**: flag + explanation per dimension (above).
5. **Suggested improvements** section: concrete redrafts (titles, AC, body) the human can copy into the Story.
6. **Open questions for the PO**: specific things this analysis can't decide.
7. **Footer**: which `.claude/rules/*` and `.claude/architecture/*` files were consulted. Do NOT add any AI/Claude attribution (no `🤖 Generated with Claude Code`, no `Co-Authored-By: Claude/Anthropic`) — hard rule, enforced by `attribution-guard`.

### Step 5 — Present and Confirm

Show the full report to the user in the conversation. Then ask:

> "Would you like me to post this as a comment on Story #[N]?"

If the user confirms, post the readiness report as a comment with `gh issue comment <n> --body-file <file>` (write the Markdown to a temp file and pass `--body-file` to preserve formatting; GitHub renders Markdown natively — no HTML conversion).

If the user wants changes, iterate on the report before posting.

## Important

- **Never** edit the Story's body, Acceptance criteria, labels, Project Status, or any field. Only add a comment. Refinement is the job of `/backlog-improve` and `/backlog-refine`.
- If the Story is already well-formed and Ready, say so: *"This Story looks ready for /dev-workflow. Nothing to flag."* A clean report is a valid and valuable output.
- **Do not invent business requirements.** If something seems missing from AC or the body, surface it as a question to the PO, NOT as an assertion of what should be there.
- **Do not invent architecture.** If the body mentions a component you can't locate in `.claude/architecture/<area>/<surface>.md`, flag the gap — don't assume the component exists or propose its design.
- **Do not skip harness dimensions** even when standard quality looks fine. Many otherwise-clean Stories lack the Surface label or parent Feature — these are 🔴 blockers for dev-workflow downstream.
