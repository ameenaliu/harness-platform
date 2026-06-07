# Story Template

Canonical Markdown format for a Story issue body. Commands in `backlog-workflow` (`improve`, `refine`, `enrich`) produce output that follows this structure and write it to the Story's Title + body (incl. the Acceptance criteria checklist) + a change-log comment. Discovery (`/discovery-workflow create`) initially writes Story / Acceptance criteria / Surface / Notes (+ optional In Scope / Out of Scope / Implementation dependencies); Open Questions + Technical notes are added by backlog-workflow afterwards.

**Rendering**: GitHub issue bodies are **Markdown-native** — there is **no HTML conversion**. This template *is* the body. The Acceptance criteria are a `## Acceptance criteria` checklist **inside the body** (matching the `story.yml` issue-form template — see `skills/github-rendering/SKILL.md` § Story structure) — there is no separate Acceptance Criteria field. The required sections are **Story / Acceptance criteria / Surface / Notes**; **In Scope / Out of Scope / Implementation dependencies / Open Questions / Technical notes** are optional sections added during refinement and enrichment.

```markdown
## Story

As a <role>, I want <capability>, so that <benefit>.

[1–2 paragraphs of context where useful. Why does this Story exist within its parent Feature? Use the repo's real vocabulary (personas + concrete components named in `.claude/architecture/*`) so the dev reading this knows the technical neighbourhood.]

## In Scope

[Optional. Bulleted list of what's covered. Lead with the entity / domain model, then the mechanism / pipeline, then heuristics, then plumbing.]

- [The entity (reference, fields, EF Core configuration following the repo conventions).]
- [The mechanism (pipeline / handler / endpoint).]
- [Edge-case heuristic (if any).]
- [Cache invalidation / hook readiness for follow-up items.]

## Out of Scope

[Optional. Explicit exclusions for this Story — keep the developer focused. Cross-reference sibling Stories + sibling Features where excluded work lives, using `#<n> (<human-id> <title>)`.]

- [Specific category definitions (covered by #<n> (F1.2 …) / #<n> (F1.3 …)).]
- [The aggregation layer that feeds metric data (next Story).]
- [The query API exposing computed insights (#<n> (S1.1.4 …)).]

> If nothing is ambiguous, write *"No explicit exclusions identified."*

## Acceptance criteria

> A `## Acceptance criteria` checklist **inside the body** (matches `story.yml`). GitHub renders the `- [ ]` checkboxes natively. Each AC independently testable; reference real components / integrations from `.claude/architecture/*` where applicable.

- [ ] [Given precondition], When [action], Then [expected result + verifiable signal]
- [ ] [Given precondition], When [action], Then [expected result + verifiable signal]
- [ ] (error case) [Given error precondition], When [action], Then [error handling behaviour]
- [ ] (edge case) [Given edge precondition], When [action], Then [edge behaviour]

## Surface

<service | web | mobile | cross-cutting>

> Matches the `surface:*` label and the `[<surface>]` segment in the title. Multi-surface is allowed (e.g. `service, mobile`).

## Implementation dependencies

[Optional. Both directions, as body lines + the `blocked` label (GitHub has no typed Predecessor/Successor link). Backlog-workflow commands READ these lines via `gh issue view --json body` and offer to add/change/remove. See `skills/github-rendering/SKILL.md` § Dependency convention.]

Blocked by: none (foundation work) | #<n> (<human-id> <title>)
Blocks: none | #<m> (<human-id> <title>)

## Open Questions

[Optional. Unresolved items tagged with the role who should answer. Populated by `/backlog-workflow refine` — usually empty at discovery time.]

- `[PO]` <business / scope question>
- `[Tech]` <technical / architecture question>
- `[Team]` <process / coordination question>

> Remove items as they get answered. Don't leave stale questions.

## Technical notes

[Optional. Populated by `/backlog-workflow enrich`. Per-surface analysis of affected components, references to `.claude/architecture/<area>/<surface>.md` for canonical patterns. See `technical-notes.md` for the format. Left empty or absent until enriched.]

## Notes / links

<design-doc references, dependencies, open questions, parent-Feature context>

---

🤖 Generated with [Claude Code](https://claude.ai/claude-code)
```

## Section Guidelines

**Title** — `S<e>.<f>.<s>: [<surface>][<surface>...] <title>` (Surface segment mandatory; `S`-prefix required for new items and preserved byte-for-byte for existing ones — **never renumber**). The `S`-prefix encodes Epic / Feature / Story position so the parent–child structure is visible on the board without expanding the sub-issue panel; GitHub also assigns a native `#N`. The `[<surface>]` segment(s) identify which surface(s) the work touches. Keep the rest of the title concise (≤ 80 chars excluding prefixes recommended). Multi-surface is normal — `[mobile][service]` indicates this work touches both. See `skills/github-rendering/SKILL.md` § Title numbering scheme.

**Story** — the `As a … I want … so that …` statement plus 1–2 paragraphs of context combining the "why" (parent-Feature link, motivation) with the "what" (capability + outcome). If a developer reads only this section, they should understand both the business motivation AND the technical neighbourhood. Use the repo's real vocabulary — personas and concrete components from `.claude/architecture/*` — so the dev knows where they are.

**In Scope** — Bulleted list of what's covered. Sequence matters: lead with the foundational entity / domain model, then the mechanism / pipeline that operates on it, then heuristics + edge cases, then plumbing.

**Out of Scope** — 1–3 explicit exclusions someone might reasonably assume are included. Cross-reference sibling Stories + sibling Features where excluded work lives, using `#<n> (<human-id> <title>)`. Prevents mid-sprint scope discussions.

**Acceptance criteria** — Each AC independently testable. Given/When/Then format. **3–7 ACs** per Story is the sweet spot. Fewer than 3 = missing edge cases. More than 7 = item is too large; split via `/discovery-workflow extend <feature-#>`. Reference concrete components / integrations so the test plan is unambiguous.

**Surface** — single value or comma-separated combo; must match the `surface:*` label(s) and the title `[<surface>]` segment(s).

**Implementation dependencies** — `Blocked by:` + `Blocks:` lines. Usually 0–1 blockers per Story. Complex dependency webs at the Story level are a smell — the Feature decomposition is probably wrong; consider re-decomposing via `/discovery-workflow extend`.

**Open Questions** — Prefix each with who answers: `[PO]` (business), `[Tech]` (architecture / implementation), `[Team]` (process / coordination). Example: `[Tech] Should the new TransactionService use the existing transaction wrapper or its own?`.

**Technical notes** — Only populated during enrichment. Left empty before enrichment. See `technical-notes.md`.

## What does NOT go in a Story

- **Implementation hints** (which class to modify, which method to add) — those go in `Technical notes` (added by `/backlog-enrich`) or in the dev-workflow Phase 2 execution plan.
- **Tasks** — Tasks are created by `/dev-workflow` Phase 2 from the approved plan, as sub-issues of the Story. A Story is a unit of outcome, not a list of dev steps.
- **Discovery-phase brainstorming** — if multiple competing approaches need to be discussed, that happens at `/discovery-workflow` D1 / D2, not in the Story itself.
- **Code samples** — Test plan code samples are fine in `Technical notes`; production code samples don't belong here at all.
