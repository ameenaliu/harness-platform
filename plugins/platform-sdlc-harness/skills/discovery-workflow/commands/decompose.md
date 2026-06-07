# Phase D2: Decompose & Propose Tree

**Phase**: D2
**Actor**: Planner agent in `discovery` mode
**Gate**: explicit human `APPROVED` before D3

## Prerequisites

- `ai/discoveries/<slug>.md` exists with `## Idea` + `## Shape` sections populated (from D1).

## Steps

1. **Read the tracker stub** at `ai/discoveries/<slug>.md`. Extract Idea + Shape. Read `Org` / `Repo` from `.claude/context/platform-context.md` for the sampling step.
2. **Sample existing work-item style** — list 5-10 recent Epics / Features / Stories from the repo via `gh` (read-only) to learn typical title patterns, AC style, and body length, then mirror that style so the new tree looks native:
   ```bash
   gh issue list --repo "<org>/<repo>" --label type:epic    --limit 10 --json number,title,body
   gh issue list --repo "<org>/<repo>" --label type:feature --limit 10 --json number,title
   gh issue list --repo "<org>/<repo>" --label type:story   --limit 10 --json number,title
   # or, fuzzy: gh search issues --repo "<org>/<repo>" "<keyword>" --limit 10
   ```
   Best-effort — if the repo is brand-new and returns nothing, fall back to the canonical structures in `skills/github-rendering/SKILL.md`.
3. **Propose the tree**. Apply these rules:
   - **One Epic per cohesive capability surface.** Multiple Epics ONLY when the idea genuinely spans separate user journeys / business capabilities (e.g., "Disease detection workflow" + "Disease detection partner billing" = two Epics; "Disease detection v1 features" = one Epic with several Features).
   - **Feature granularity**: one Feature per discrete user-facing or system-facing slice that can be released independently. Aim for 2-5 Features per Epic.
   - **Story granularity**: one Story per outcome a developer can complete in 1-5 days. Aim for 2-6 Stories per Feature.
   - **Hierarchical numbering prefix is mandatory** on every title — `E<e>` for Epic, `F<e>.<f>` for Feature, `S<e>.<f>.<s>` for Story (1-based). Per `skills/github-rendering/SKILL.md` § Title numbering scheme. The full Story title format is `S<e>.<f>.<s>: [<Surface>] <title>`.
   - **`[Surface]` prefix is mandatory on every Story title**, immediately after the `S`-prefix `: `. Multi-surface: `[mobile][service] …`. Surface ∈ `service` / `web` / `mobile` / `cross-cutting`. Use the Shape's "Affected surfaces" to decide.
   - **Bugs are NOT discovery output**. If the idea includes a defect-fix component, flag it but leave Bug creation to the user post-discovery (Bugs don't decompose the same way).
4. **Compose rich, structured content per item**. Read `skills/github-rendering/SKILL.md` and produce per-item bodies matching its canonical Epic / Feature / Story Markdown structures (these align with the repo's issue-form templates). Do NOT collapse to one-liners; the human approves what will be posted to GitHub almost verbatim.

   For each **Epic** (§Epic structure): Value (1–2 sentences), Success criteria (measurable checklist), Features in this Epic (checklist of child Features), Out of scope.

   For each **Feature** (§Feature structure): Intent (2–3 sentences), Stories in this Feature (checklist of child Stories with `[surface]` + one-line context), Acceptance / done (feature-level checklist), Notes / links (incl. Implementation dependencies — predecessor sibling Features, by slug — see step 4.5).

   For each **Story** (§Story structure, matches `story.yml`): Story (`As a … I want … so that …`), Acceptance criteria (AC hints as a checklist — one-line hook per anticipated AC; full Given/When/Then is `/backlog-workflow refine`'s job), Surface (`service | web | mobile | cross-cutting`), Notes / links (incl. Implementation dependencies — predecessor sibling Stories, by slug — and open questions).

   Skip Technical Notes — that's `/backlog-workflow enrich`.

5. **Capture implementation dependencies between siblings** (Step 4.5). After items are composed, walk:
   - For each **Feature** under each Epic — does it depend on a sibling Feature being implemented first? Ask via `AskUserQuestion` if not obvious from the items themselves. Capture as `blocked by <other-feature-slug>` in the Feature's dependencies notes.
   - For each **Story** — does it depend on a sibling Story (same Feature or any Story in a blocking Feature) being implemented first? Same prompt. Capture as `blocked by <other-story-slug>`.
   - **Cross-Epic dependencies are allowed but flagged** — surface them so the human can confirm. Most discoveries are single-Epic; cross-Epic deps usually mean the Epic boundary is wrong.

   The slug is a temporary identifier — at create time (D3) it gets resolved to the real GitHub issue `#N` and written as a `Blocked by: #<n>` body line (mirror `Blocks: #<m>`) plus the `blocked` label, per `skills/github-rendering/SKILL.md` § Dependency convention.

6. **Assign hierarchical numbering IDs** (1-based) per `skills/github-rendering/SKILL.md` § Title numbering scheme. **Allocate every E/F/S number across the whole proposed tree up-front, before composing content**, so they are stable before any `gh issue create` runs in D3:
   - Number Epics top-down: E1, E2, … (almost always just E1).
   - For each Epic, number its Features top-down: F<e>.1, F<e>.2, …
   - For each Feature, number its Stories top-down: S<e>.<f>.1, S<e>.<f>.2, …
   - Record each assigned human-id alongside its slug + planned title in the stub so `create` can wire sub-issues after each issue gets its `#N`.

7. **Render the tree** in Markdown for the human review (uses both human-id + slug; human-ids are the final E/F/S names, slugs are temporary discovery handles):
   ```markdown
   ## Proposed Tree

   ### E1: <Epic title>   slug=epic-<slug>

   **Value**: <1–2 sentences>
   **Success criteria**: <checklist>
   **Out of scope**: <bullets>

   ---

   #### F1.1: <Feature title>   slug=feat-<slug>

   **Intent**: <2–3 sentences>
   **Acceptance / done**: <checklist>
   **Dependencies**: Blocked by=<"none" | F<e>.<f>>
   **Notes / links**: <bullets>

   ##### S1.1.1: [surface] <Story title>   slug=story-<slug>

   **Story**: As a <role>, I want <capability>, so that <benefit>.
   **AC hints**: <checklist — one-line hook per anticipated AC; full Given/When/Then later via /backlog-workflow refine>
   **Surface**: <service | web | mobile | cross-cutting>
   **Dependencies**: Blocked by=<"none" | S<e>.<f>.<s>>

   ##### S1.1.2: [surface] <Story title>   slug=story-<slug>
   …

   #### F1.2: <Feature title>   slug=feat-<slug>
   …

   ### E2 (if multiple): <Epic title>   slug=epic-<slug>
   …
   ```

   **Important**: GitHub Issues are Markdown-native — no HTML conversion is needed. The body composed here is posted to GitHub almost verbatim at D3 (per `skills/github-rendering/SKILL.md`). The issue **title** posted to GitHub is the prefixed form (`E1: …`, `F1.1: …`, `S1.1.1: [surface] …`).

8. **Present to the human** via `AskUserQuestion` with 4 options:
   - `APPROVED` — write to GitHub in D3.
   - `EDIT — I'll dictate changes` — relay text edits to the planner; planner re-proposes the affected sub-tree; loop.
   - `SPLIT — too big, more Epics needed` — planner identifies natural cut lines; re-proposes with N+1 Epics.
   - `MERGE — too granular, collapse some items` — planner identifies merge candidates; re-proposes with fewer Features/Stories.
9. **On EDIT / SPLIT / MERGE**: re-propose the affected sub-tree and re-present. Don't restart from scratch. Loop until `APPROVED`. If items get added/removed during EDIT, **do not renumber existing IDs** — assigned IDs are sticky (gaps from deletions are intentional, like JIRA issue keys); new items get `max(existing) + 1`.
10. **On APPROVED**: write the approved tree into `ai/discoveries/<slug>.md` under an `## Approved Tree (D2 gate)` section. Preserve every per-item body, the human-id → slug map, AND the slug → dependency map. Set `Phase: D2-APPROVED`, `Status: awaiting-create`.
11. Hand off to D3 (create). If invoked from the full pipeline, automatically continue. If standalone, tell the human to run `/discovery-workflow create <slug>` when ready.

## Output

- Updated `ai/discoveries/<slug>.md` with `## Proposed Tree` (iterations) + `## Approved Tree (D2 gate)` (final).
- Verbal hand-off summary listing slug + Epic/Feature/Story counts.

## Rules

- **No GitHub writes** in D2. The tree lives only in the tracker stub until D3.
- **Functional only.** No data-model decisions (entity shapes, table designs, API contracts), no architecture decisions (which service owns what), no implementation hints. If you find yourself proposing a source-file change in a Story body, stop — that belongs to `/backlog-workflow enrich` or `/dev-workflow plan`.
- **Title prefix rule is non-negotiable.** Every Story title starts with `S<e>.<f>.<s>: [<Surface>]`.
- **Full AC are NOT drafted at the discovery stage** — Stories get **AC hints** (one-line hooks per anticipated AC) so the team has a starting point; full Given/When/Then drafting happens in `/backlog-workflow refine` (or `improve`).
- **Rich bodies are mandatory.** Discovery output isn't a placeholder for backlog-workflow to fill in later — the body posted to GitHub at D3 must already be substantive (per `skills/github-rendering/SKILL.md`). The PO and stakeholders see this immediately on the Project board.
- **Implementation dependencies are part of discovery.** If two Features must be implemented in order, that's a discovery-time decision (it affects scope and Epic boundaries), not a dev-workflow afterthought. Capture per Step 5 and write them as `Blocked by:` / `Blocks:` body lines at D3.
- **Status block** the planner ends with:
  ```
  📋 AGENT STATUS
  - Agent: planner
  - Mode: discovery
  - Phase: D2-decompose
  - Slug: <slug>
  - Tree: <N Epics, M Features, K Stories>
  - Outcome: <SUCCESS (APPROVED, ready for D3) | IN-PROGRESS (iterating) | BLOCKED>
  - Next action: <"run create" | "iterate on edits" | "human input needed">
  ```
