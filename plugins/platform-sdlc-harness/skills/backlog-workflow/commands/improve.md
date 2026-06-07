# /backlog-improve Command

Single-pass Story improvement. Assesses readiness internally, fills gaps conversationally, drafts the entire Story, then **writes the improved Title + body + Acceptance criteria directly to the GitHub issue** along with a change-log comment. Replaces the separate analyze-then-refine workflow with a single adaptive command.

## Invocation

The user types `/backlog-improve [issue-number]`. Optionally followed by session notes (pasted text, bullet points, or a rough description of what was discussed in refinement).

This command is always human-invoked.

## Prerequisites

- `.claude/context/platform-context.md` must exist (provides **Org** + **Repo** + **Project** number).
- `gh` CLI available and authenticated (`gh auth status`).
- The configured repo cloned locally — needed to read `.claude/rules/` + `.claude/architecture/` for context.

## Behavior

### Step 1 — Fetch the Story

Read the Story with `gh issue view <n> --json title,body,labels,comments` (add `--repo <org>/<repo>` when not inside the clone). Extract:
- Title (parse the `S<e>.<f>.<s>:` numbering prefix and the `[<surface>]` segment — record what's there or `none`)
- Body — **Story**, **Acceptance criteria**, **Surface**, **Notes / links** sections (per `story.yml`), plus any optional **In Scope**, **Out of Scope**, **Implementation dependencies**, **Open Questions**, **Technical notes** sections
- Labels (`type:story` / `type:bug`, `surface:<surface>`, `blocked`) + Project **Status** (via `gh project item-list` / `gh api graphql` against the project number in `platform-context.md`)
- Issue type (`type:story` / `type:bug` label)
- **Parent Feature** — via the native sub-issue link (`gh api graphql` reading `parent { number title }`), fallback to a `Parent: #<n>` body line
- **Blocked-by links** — parse the body's `## Implementation dependencies` → `Blocked by: #<n> (...)` lines. For each `#<n>`, fetch its title with `gh issue view <n> --json title` for display.
- **Blocks links** — parse the body's `Blocks: #<m> (...)` lines. Same extraction.

Halt with a clear message if not found / not accessible.

### Step 2 — Load Context

1. `.claude/context/platform-context.md` — workspace + GitHub config.
2. `templates/backlog-template.md` — target output format (the canonical Markdown Story body).
3. `templates/readiness-report.md` — flag catalog (internal rubric only).
4. For each detected surface: `.claude/rules/<backend|web|mobile>/{code-style,testing}.md`.
5. For the affected area: `.claude/architecture/<area>/<surface>.md`.
6. `.claude/CLAUDE.md` — top-level index.

If the Surface is missing, defer the surface-specific reads to Step 4 (after the human supplies the surface).

### Step 3 — Assess Readiness (Internal)

Use the same dimensions as `/backlog-analyze` (see `commands/analyze.md → Step 3`). Internal rubric only — do NOT present a standalone readiness report. The score drives:
1. **Tier classification**:
   - **Tier 1 — Solid.** ≤ 2 yellow flags, no red. Draft immediately with minimal questions.
   - **Tier 2 — Some gaps.** 1-3 issues (mix of red/yellow). Specific areas need clarification.
   - **Tier 3 — Rough.** 4+ issues OR any critical section missing. Substantial input needed.
2. **Gap list** — specifically which harness dimensions failed (missing Surface, missing parent Feature, AC count too low, etc.).
3. **Question set** for Step 4.

### Step 4 — Conversational Gap-Filling

Adapt to tier:

**Tier 1:** Skip questions. Briefly acknowledge:
> "This Story is in good shape — `[mobile][service]` surface present, parent Feature #45 linked, 5 testable ACs. I'll draft a clean version in the template format."

**Tier 2:** Ask 2-5 targeted questions. Each question: references the specific gap, suggests an answer where possible, answerable in 1-2 sentences. Example:
> "AC #3 says 'transactions are saved' — not testable. Should it be: 'Given a logged-in user with an active subscription, When they submit a payment via the payment-provider webhook, Then the transaction is persisted via the service Outbox and a push confirmation is sent'? Or did the team have a different acceptance shape in mind?"

Present all questions at once via `AskUserQuestion` (max 5).

**Tier 3:** Acknowledge state honestly, then ask up to 5 questions. After answers, ask a 2nd round (up to 3 more) if critical gaps remain. Then draft.

**Harness-specific question patterns** (mandatory if the relevant gap exists):

| Gap | Question pattern |
|---|---|
| Missing `S<e>.<f>.<s>` numbering prefix | *"This Story's title has no hierarchical numbering prefix (e.g. `S1.2.3`). What's its position in the discovery tree? — I'll infer from the parent Feature title if you've linked one. Title becomes `S<e>.<f>.<s>: [<surface>] <title>`."* (Never renumber an existing prefix.) |
| Missing Surface | *"This Story's title has no `[<surface>]` segment and no `surface:*` label — which surfaces does this touch? (multi-select: service, web, mobile, cross-cutting — pick all that apply)"* |
| Missing parent Feature (non-Bug) | *"This Story isn't linked to a parent Feature. Either: (a) which existing Feature does this belong under? (give #/title), or (b) if there's no matching Feature, run `/discovery-workflow extend <epic-#>` first to create one, then re-invoke me — OK?"* |
| AC scope too large | *"This Story has {N} ACs spanning {M} distinct capabilities — likely larger than a 1-5 day developer outcome. Split via `/discovery-workflow extend <feature-#>` into sibling Stories? Or keep as one for now?"* |

**Using session notes:** mine thoroughly before asking. Acknowledge what was learned: *"From your refinement notes, I see the team scoped to mobile-only and deferred web for next iteration. I'll incorporate that. A couple of remaining questions..."*

If no session notes provided and tier is 2 or 3: ask *"Do you have notes from a refinement session? Even rough bullets help. If not, I'll work from what's in the Story plus the repo conventions."*

### Step 5 — Draft the Complete Story

Using Step 4 answers (or existing content for Tier 1), draft the ENTIRE Story at once following `templates/backlog-template.md`. Sections:
- **Title** = `S<e>.<f>.<s>: [<surface>][<surface>...] <title>` — refuse to proceed if the Surface is missing. **Preserve** the existing `S`-prefix byte-for-byte; never re-number. See `skills/github-rendering/SKILL.md` § Title numbering scheme.
- **Story** — `As a <role>, I want <capability>, so that <benefit>.` Use the repo's real personas naturally and concrete components from `.claude/architecture/*`.
- **In Scope** *(optional section)* — bulleted list. Entity / domain model first, then mechanism, then heuristics, then plumbing.
- **Out of Scope** *(optional section)* — explicit exclusions; cross-reference sibling Stories / Features by `#<n> (<human-id> <title>)`.
- **Acceptance criteria** — Given/When/Then checklist (`- [ ]` items). Happy path first, then error/edge cases. Reference real components / integrations from `.claude/architecture/*` where applicable.
- **Implementation dependencies** *(optional section)* — `Blocked by:` / `Blocks:` lines. Use the existing links fetched in Step 1 as the starting point. Surface them to the user during Step 4 (*"Blocked by: #420 'Camera permission', #421 'Upload pipeline'. Blocks: #430 'Result display'. Keep, change, or add more?"*). On change, capture the diff (add list + remove list) for Step 7's Write 1.5. See `skills/github-rendering/SKILL.md` § Dependency convention.
- **Surface** — the `## Surface` section value (matches the `surface:*` label).
- **Open Questions** *(optional section)* — unresolved items tagged `[PO]` / `[Tech]` / `[Team]`.
- **Technical notes** — leave empty. Populated by `/backlog-enrich`.

**Body rendering**: GitHub issue bodies are **Markdown-native** — no HTML conversion. The human reviews the Markdown body directly. At Step 7 the whole body (Story + In/Out of Scope + Acceptance criteria + Surface + Implementation dependencies + Open Questions + Technical notes placeholder + Notes/links) is written to the issue body as a single Markdown payload via `gh issue edit --body-file`. The Acceptance criteria live as a `## Acceptance criteria` checklist section **inside the body** (matching the `story.yml` template) — there is no separate field.

**"What was improved" header** (Tier 2 or 3 only) — used in the change-log comment (Step 7 Write 2):
```
### What was improved
- Added 3 missing error-case ACs (webhook idempotency, notification failure, batch sync conflict)
- Clarified persona from "user" to "farm member"
- Added explicit out-of-scope: deferred B2B partner notifications
- Added `[mobile][service]` surface (title segment + `surface:mobile` + `surface:service` labels)
- Linked to parent Feature #45 "Batch sync v2"

---
```

Skip for Tier 1 where content is largely unchanged.

### Step 6 — Review and Iterate

Present the complete draft:
> "Here's the improved Story. Review the whole thing — I can adjust any section."

The user may approve, request section changes, add/remove/modify ACs, or adjust scope. Iterate until satisfied. After minor edits, confirm the change briefly without re-presenting the entire item.

If during review you notice the item is too large (>7 ACs, multiple capabilities), gently suggest splitting:
> "This Story has 9 ACs spanning two distinct capabilities ('disease detection capture' + 'disease detection notification'). Cleaner as two sibling Stories under Feature #X? Run `/discovery-workflow extend <feature-#>` to add the sibling and split the ACs between them."

### Step 7 — Persist to GitHub

After the user approves the final version, ask:
> "Ready to apply? I'll: (1) update the Story's Title + body (incl. Acceptance criteria) directly, (2) post a change-log comment with the audit history, (3) optionally bump the Project Status `Backlog → Ready` if currently in `Backlog`/`No Status`. OK to proceed?"

The user can answer:
- **`YES — all three`** → do all three writes.
- **`YES — edits + comment only`** → skip the status bump.
- **`COMMENT ONLY`** → skip the issue edits; post only the change-log comment (useful for sensitive items the PO wants to sign off on first).

#### Write 1 — Issue edits (unless COMMENT ONLY)

Write the full Markdown body to a temp file, then:

```bash
gh issue edit <n> \
  --title "<new title with S-prefix + [surface]>" \
  --body-file <body.md>
# Surface labels — add any newly-applicable surface labels (idempotent):
gh issue edit <n> --add-label "surface:<surface>"
```

GitHub renders Markdown natively — no MD→HTML conversion. The Acceptance criteria are a `## Acceptance criteria` checklist **inside the body** (not a separate field). Preserve the `## Surface` body section + `surface:*` label in sync.

#### Write 1.5 — Dependency link sync (only if Step 5 captured changes)

Dependencies are body lines + a label (no typed GitHub link). To **add** a `Blocked by: #<p>`:
1. Ensure the body's `## Implementation dependencies` section contains `Blocked by: #<p> (<human-id> <title>)` (included in the Write 1 body payload).
2. (Optional mirror) On the blocking issue `#<p>`, add a `Blocks: #<n> (...)` line via `gh issue edit <p> --body-file <p-body.md>` after reading its current body.
3. If `#<p>` is still **open**, add the `blocked` label to `#<n>`: `gh issue edit <n> --add-label blocked`.

To **remove** a `Blocked by: #<p>`:
1. Drop the `Blocked by: #<p>` line from the body (in the Write 1 payload) and remove the mirrored `Blocks:` line on `#<p>`.
2. If `#<n>` now has no remaining open blockers, remove the `blocked` label: `gh issue edit <n> --remove-label blocked`.

Never delete a dependency line without updating both sides. See `skills/github-rendering/SKILL.md` § Dependency convention.

**Failure policy**: log + continue per link. Surface failures in the change-log comment under a `### Link sync warnings` subsection so the human can fix in the GitHub UI.

#### Write 2 — Change-log comment (always)

Write to a temp file and post with `gh issue comment <n> --body-file <file>`:

```markdown
## What was improved (`/backlog-improve` at <UTC timestamp>)
<the "What was improved" block from Step 5>

## Improved content (for audit trail)
<full Title / body / AC of the new version, in Markdown for human readability>

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

#### Write 3 — Optional Status bump (only if Status was `Backlog`/`No Status` and human confirmed YES — all three)

Set the Story's Project (v2) **Status** field to `Ready` via `gh project item-edit` (resolve the project number, item id, Status field id, and the `Ready` option id from `platform-context.md` / `gh api graphql`). See `skills/github-rendering/SKILL.md` § Project (v2) board fields.

Report back the URL of the updated issue + the comment URL(s).

## Important

- **Surface (title segment + `surface:*` label) is non-negotiable.** Refuse to draft a final version without one. If the human refuses to supply, halt with a clear message ("can't reach Ready without surface identification — re-invoke with the surface clarified").
- **Parent Feature for non-Bug items is strongly recommended.** Flag missing as 🟡 in the draft preamble; offer to defer to `/discovery-workflow extend` if no matching Feature exists.
- **Adapt the write set.** Some Stories are sensitive — let the human downgrade to COMMENT ONLY without losing the change-log audit.
- **Adapt, don't interrogate.** If the Story is good, say so and draft fast. Don't ask unnecessary questions.
- **Suggest answers.** When asking, propose an answer the user can confirm or correct. The user validates; never asks them to draft from scratch.
- **Mirror the repo's vocabulary.** If the user calls something "farm member" don't rename to "tenant user". Use real service / integration names from `.claude/architecture/`.
- **Session notes are gold.** If provided, mine thoroughly before asking questions the notes might already answer.
- **Don't invent requirements or architecture.** If something seems missing, flag as a question (`[PO]` / `[Tech]`) not an assertion.
- **One drafting pass per invocation.** No multiple-comment artifact spreads. The change-log comment + the issue edit history is the audit trail.
- **Idempotent re-runs.** Running `/backlog-improve` again on a Story already improved is fine — the change-log comment thread tracks iterations; body edits just overwrite.
