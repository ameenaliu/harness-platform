# /backlog-refine Command

> **Note:** For most workflows, `/backlog-improve` is the recommended alternative — it combines readiness analysis with refinement in a single adaptive flow. `/backlog-refine` remains available when you specifically want the slower, **section-by-section interactive refinement** for complex, contentious, or tangled-scope Stories.

Interactive Story structuring. Walks 10 sections one-at-a-time with per-section human approval, then **writes the Title / body / Acceptance criteria directly to the GitHub issue** plus a change-log comment.

## Invocation

The user types `/backlog-refine [issue-number]`. Optionally followed by session notes (pasted text, bullet points, or a rough description of what was discussed).

This command is always human-invoked.

## Prerequisites

- `.claude/context/platform-context.md` exists (provides **Org** + **Repo** + **Project** number).
- `gh` CLI available and authenticated (`gh auth status`).
- The configured repo cloned locally — needed for `.claude/rules/*` + `.claude/architecture/*` reads.

## Behavior

### Step 1 — Read the Story

Read the Story with `gh issue view <n> --json title,body,labels,comments` (add `--repo <org>/<repo>` when not inside the clone). Extract:
- Title (parse the `S<e>.<f>.<s>:` numbering prefix + `[<surface>]` segment — record what's there or `none`)
- Body — **Story**, **Acceptance criteria**, **Surface**, **Notes / links** sections + optional **In Scope**, **Out of Scope**, **Implementation dependencies**, **Open Questions**, **Technical notes** sections
- Labels (`type:story` / `type:bug`, `surface:<surface>`, `blocked`) + Project **Status**
- Issue type (`type:story` / `type:bug` label)
- Parent Feature — via the native sub-issue link (`gh api graphql` reading `parent { number title }`), fallback `Parent: #<n>` body line — `#<n> (F<e>.<f> <title>)` or `none`
- **Blocked-by links** — parse the body's `## Implementation dependencies` → `Blocked by: #<n> (...)` lines. Fetch each blocker's title with `gh issue view <n> --json title` for display.
- **Blocks links** — parse `Blocks: #<m> (...)` lines. Same extraction.

Halt with a clear message if not found.

### Step 2 — Gather Session Notes

If session notes provided with the command, capture them. Otherwise ask once:

> "Do you have notes from a refinement session? Bullet points, rough notes, decisions reached, rejected approaches — anything helps. If not, I'll work from the Story content plus the repo conventions."

### Step 3 — Load Context

1. `templates/backlog-template.md` — target format (canonical Markdown Story body).
2. `.claude/context/platform-context.md` — workspace + GitHub config.
3. For each detected surface: `.claude/rules/<backend|web|mobile>/{code-style,testing}.md`.
4. For the affected area: `.claude/architecture/<area>/<surface>.md`.
5. `.claude/CLAUDE.md` — top-level index.

If the Surface is missing, defer surface-specific reads until Section 1 (Title) resolves it.

### Step 4 — Section-by-Section Interactive Refinement

Walk each section in order. **Propose content → ask for approval → iterate → confirm → next section.** Don't rush. Don't bundle.

**Section 1 — Title** (HARD BLOCK if Surface missing):
- Title format: `S<e>.<f>.<s>: [<surface>][<surface>...] <title>` (e.g. `S1.2.3: [mobile][service] Upload pipeline`). The `[<surface>]` segment is mandatory; the `S`-numbering prefix is required for new items and **preserved byte-for-byte** for existing ones. See `skills/github-rendering/SKILL.md` § Title numbering scheme.
- **Preserve the existing `S<e>.<f>.<s>` prefix** byte-for-byte when refining. Never re-number.
- If the title is missing the `S<e>.<f>.<s>` prefix entirely (legacy item): ask the user *"This Story predates the hierarchical numbering convention. What's its position in the discovery tree? (e.g. S1.2.3 = Epic 1 / Feature 2 / Story 3.)"* — infer from the parent Feature title via `gh issue view <feature-#> --json title` if the Feature is linked.
- If the title is missing the `[<surface>]` segment: ask which surfaces the work touches (multi-select via `AskUserQuestion`) and insert the `[<surface>]` segment(s) immediately after the `S<e>.<f>.<s>: `.
- Do NOT proceed to Section 2 until the title matches `^S\d+\.\d+\.\d+:\s+\[(service|web|mobile|cross-cutting)\](\[(service|web|mobile|cross-cutting)\])*\s+\S`.

**Section 2 — Parent Feature link** (warn for non-Bugs, allow proceed):
- If the issue type is `type:bug`: skip (Bugs don't require parent Features).
- If `type:story` and parent Feature exists: confirm — *"Currently a sub-issue of Feature #45 'Batch sync v2' — keep, change, or detach?"*
- If `type:story` and no parent Feature: surface the gap — *"No parent Feature linked. Either: (a) which existing Feature should this belong to? give #/title; (b) skip and proceed (dev-workflow will route to `develop`); (c) pause refinement and run `/discovery-workflow extend <epic-#>` to create the missing Feature first."*

**Section 3 — Surface label**:
- Confirm the `surface:*` label(s) match the title's `[<surface>]` segment(s). If a surface segment was added/changed in Section 1, queue the matching `surface:*` label add/remove for Step 6's Write 1.

**Section 4 — Affected Surfaces**:
- Confirm the surfaces implied by the title segment match the actual work. *"Title says `[mobile][service]` — does this work touch both? Is there a Web component you'd expect?"*

**Section 5 — Context** (the why):
- Draft 2-4 sentences on the business motivation based on existing body + session notes + parent Feature (if loaded). This feeds the `## Story` narrative and `## Notes / links`.
- Ask: *"Does this capture the why correctly?"* Iterate.

**Section 6 — Story** (As a … I want … so that …):
- Use the repo's real personas from `.claude/architecture/*`.
- Formulate the `## Story` statement. If the body hints at multiple capabilities, flag: *"This looks like it might cover X + Y. Split into siblings via `/discovery-workflow extend <feature-#>`, or keep as one coherent unit?"*
- Confirm.

**Section 7 — Acceptance criteria**:
- Draft Given/When/Then AC (`- [ ]` checklist) based on session notes, existing AC, and `.claude/architecture/` understanding.
- Reference real components / integrations where applicable — e.g. *"Given a user pays via the payment provider, When the webhook fires, Then the service Outbox persists the transaction within the same DB transaction AND a push notification fires within 5s"*.
- Happy path first; then error / edge cases; then NFR-style AC where relevant (performance, accessibility, offline behaviour).
- Present all AC together: *"Are these complete? Any scenarios missing?"* Iterate. User can add/remove/modify.

**Section 7.5 — Implementation dependencies**:
- Surface existing links fetched in Step 1: *"Currently — Blocked by: #420 'Camera permission', #421 'Upload pipeline'. Blocks: #430 'Result display'."*
- Ask: *"Keep these as-is? Or add / remove / change?"*
- If add: take the `#<n>` + title from the user, validate via `gh issue view <n> --json title`, queue for Step 6's Write 1.5.
- If remove: queue the line removal + label/mirror updates for Write 1.5.
- If no dependencies known and the Story is non-trivial: ask *"Are there any sibling Stories (in the same Feature, or in a Feature that must finish first) that this depends on? If unsure, skip — we can revisit via `/backlog-workflow improve <n>` later."*
- See `skills/github-rendering/SKILL.md` § Dependency convention for the `Blocked by:` / `Blocks:` body lines + `blocked` label.

**Section 8 — Out of Scope**:
- Propose explicit exclusions inferred from session notes ("we decided X is for next sprint") + parent Feature scope.
- Ask: *"Anything else that should be explicitly excluded? Cross-reference sibling Stories / Features by `#<n>` where the excluded work lives."*

**Section 9 — Open Questions**:
- Collect unresolved items from session notes.
- Flag anything noticed during this refinement that seems ambiguous.
- Tag each `[PO]` (business decisions), `[Tech]` (technical decisions), `[Team]` (process/coordination).
- Ask: *"Any other open questions from the session?"*

**Section 10 — Technical notes** (placeholder only):
- Leave empty in the draft.
- If user volunteers technical context during refinement, capture it in scratchpad and offer: *"I'll note this for now; the full technical analysis happens in `/backlog-enrich` — want me to run that next after we persist this?"*

### Step 5 — Assemble and Review

Once all 10 sections are confirmed, assemble and present the complete Story:

> "Here's the complete refined Story. Please review the full picture before I persist."

Show the entire item in template format including the field summary at top: *Title, Type, Parent Feature, Surface, Project Status*.

### Step 6 — Persist to GitHub

After approval, ask:
> "Ready to apply? Same 3-write model as `/backlog-improve`: (1) update the Title + body (incl. Acceptance criteria) + `surface:*` labels directly, (2) post a change-log comment with the section-by-section audit history, (3) optionally bump Project Status `Backlog → Ready` if currently in `Backlog`/`No Status`. Modes: ALL / EDITS+COMMENT / COMMENT-ONLY. Pick?"

#### Write 1 — Issue edits (unless COMMENT-ONLY)

Write the full Markdown body to a temp file, then:

```bash
gh issue edit <n> \
  --title "<new title with S-prefix + [surface]>" \
  --body-file <body.md>
# Surface labels — sync to match the title segment(s) (idempotent):
gh issue edit <n> --add-label "surface:<surface>"
gh issue edit <n> --remove-label "surface:<old-surface>"   # only if a surface was dropped
```

GitHub renders Markdown natively — no MD→HTML conversion. The Acceptance criteria are a `## Acceptance criteria` checklist **inside the body**.

If the Parent Feature link was changed in Section 2: re-parent the sub-issue via `gh api graphql` — `removeSubIssue` on the old parent, then `addSubIssue` on the new one (resolve node IDs with `gh issue view <#> --json id`). See `skills/github-rendering/SKILL.md` § Sub-issue linking protocol.

#### Write 1.5 — Dependency link sync (only if Section 7.5 captured changes)

Dependencies are body lines + the `blocked` label (no typed GitHub link). To **add** a `Blocked by: #<p>`:
1. Ensure the body's `## Implementation dependencies` section contains `Blocked by: #<p> (<human-id> <title>)` (included in the Write 1 body payload).
2. (Optional mirror) On the blocking issue `#<p>`, add a `Blocks: #<n> (...)` line via `gh issue edit <p> --body-file <p-body.md>` after reading its current body.
3. If `#<p>` is still **open**, add the `blocked` label to `#<n>`: `gh issue edit <n> --add-label blocked`.

To **remove** a `Blocked by: #<p>`:
1. Drop the `Blocked by: #<p>` line from the body and remove the mirrored `Blocks:` line on `#<p>`.
2. If `#<n>` now has no remaining open blockers, remove the `blocked` label: `gh issue edit <n> --remove-label blocked`.

Never delete a dependency line without updating both sides. See `skills/github-rendering/SKILL.md` § Dependency convention.

Failure policy: log + continue per link. Surface failures in the change-log comment under a `### Link sync warnings` subsection.

#### Write 2 — Change-log comment (always)

Write to a temp file and post with `gh issue comment <n> --body-file <file>`:

```markdown
## Refined via `/backlog-refine` at <UTC timestamp>

**Sections reviewed**: Title, Parent Feature, Surface, Affected Surfaces, Context, Story, Acceptance criteria, Out of Scope, Open Questions, Technical notes

### Changes by section
- Title: <was → now>
- Parent Feature: <was → now>
- Surface: <was → now>
- Affected Surfaces: <was → now>
- Story: <summary of changes>
- Acceptance criteria: <N added, M removed, K modified — list>
- Out of Scope: <new explicit exclusions>
- Open Questions: <new questions tagged>

### Final content (audit trail, Markdown)
<full Title / body / AC of the new version>

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

#### Write 3 — Optional Status bump (only if Status was `Backlog`/`No Status` and human picked ALL)

Set the Story's Project (v2) **Status** field to `Ready` via `gh project item-edit`. See `skills/github-rendering/SKILL.md` § Project (v2) board fields.

Report URLs of the updated issue + comment + any link changes.

## Important

- **Section-by-section discipline is the value here.** Don't rush. Give the user space to think between sections.
- **Surface (title segment + `surface:*` label) is a HARD BLOCK at Section 1.** Don't proceed without it.
- **Parent Feature for non-Bug is a soft warn**, not a block — user can defer.
- **Adapt the write set.** Some Stories are sensitive — let the human downgrade to COMMENT-ONLY for PO sign-off first.
- **Mirror the repo's vocabulary.** Real personas, real services, real integrations from `.claude/architecture/`.
- **Don't invent requirements or architecture.** If something seems missing, flag as `[PO]` / `[Tech]` open question.
- **Sparse session notes — be transparent**: *"I'm inferring X from the existing body — is that correct?"*
- **Suggest splitting** when too large (>7 ACs, multiple capabilities) — point to `/discovery-workflow extend <feature-#>` for adding siblings.
- **Idempotent re-runs.** Re-invoking on an already-refined item is fine; the change-log comment thread tracks iterations.
