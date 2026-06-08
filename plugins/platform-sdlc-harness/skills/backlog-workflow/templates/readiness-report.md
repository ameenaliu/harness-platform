# Readiness Report Template

This is the output format for `/backlog-analyze`. It provides a qualitative assessment of Story readiness with both standard dimensions and harness-specific dimensions. Posted as a comment on the Story issue; never edits the body or any field.

```markdown
## Story Readiness Report (`/backlog-analyze`)

**Issue**: #[N] — [Title]
**Type**: [Story | Bug]
**Project Status**: [Backlog | Ready | In Progress | In Review | Done | No Status]
**Parent Feature**: #[N] (F<e>.<f> [Title]) | none
**Affected Surfaces** (from `[<surface>]` prefix + `surface:*` label): [service | web | mobile | cross-cutting | combinations | NONE]
**Labels**: [`type:story`, `surface:…`, `blocked`?]
**Assessed**: [UTC timestamp]

### Summary verdict

[Pick one]:
- 🟢 **Ready for `/dev-workflow`** — all dimensions pass, item is implementable as-is.
- 🟡 **Needs refinement** — recommend running `/backlog-improve` to address the flagged dimensions before development.
- 🔴 **Needs split or rework** — item is too large, missing critical context, or has blocking gaps. Suggest `/discovery-workflow extend <feature-#>` to split, or `/backlog-refine` for slow restructuring.

### Standard dimensions

| Dimension | Flag | Explanation + Concrete Suggestion |
|---|---|---|
| Title clarity | 🟢/🟡/🔴 | … |
| Story / body completeness | 🟢/🟡/🔴 | … |
| Acceptance criteria quality | 🟢/🟡/🔴 | … |
| Scope (1-5 day developer outcome?) | 🟢/🟡/🔴 | … |
| Dependencies (other Stories, services, infra) | 🟢/🟡/🔴 | … |
| Risks & open questions | 🟢/🟡/🔴 | … |
| Assumptions | 🟢/🟡/🔴 | … |

### Harness-specific dimensions (mandatory)

| Dimension | Pass criteria | Flag | Explanation |
|---|---|---|---|
| E/F/S numbering prefix | Title starts with `S<e>.<f>.<s>:` | 🟢/🟡 | … |
| Surface label + prefix | Title carries `[<surface>]` AND a matching `surface:<surface>` label | 🟢/🔴 | … |
| Parent Feature | Linked as a sub-issue of a Feature (mandatory unless Bug) | 🟢/🔴 | … |
| Status posture | Project Status `Ready` or `In Progress` | 🟢/🟡 | … |
| AC granularity | AC count ≤ 8 AND Story/scope sentences ≤ 15 | 🟢/🟡 | … |
| Surface-architecture coverage | AC mentions match components in `.claude/architecture/<area>/<surface>.md` | 🟢/🟡 | … |

### Suggested improvements

[Concrete actionable suggestions. Draft replacement text where possible (titles, AC, body sections). NOT generic advice — specific to this Story with the repo's real vocabulary.]

**Title**: <if redraft needed, show the proposed new title here with S-prefix + [surface]>

**Story / body**: <if redraft, show proposed>

**Acceptance criteria additions / rewrites**:
- (redraft of AC#2) Given a logged-in user with an active subscription, When they submit a payment via the payment-provider webhook, Then the transaction is persisted via the service Outbox and a push confirmation is sent within 5 seconds.
- (new AC) Given an invalid provider signature on the webhook, When the request reaches the service, Then a 401 is returned with code `PROVIDER_INVALID_SIGNATURE` and no DB write occurs.

### Open questions for the PO

[Specific things this analysis can't decide. Tagged `[PO]` / `[Tech]` / `[Team]`.]

- `[PO]` <question>
- `[Tech]` <question>

### Footer — references consulted

- `.claude/rules/<surface>/code-style.md` — <list which read>
- `.claude/rules/<surface>/testing.md` — <list which read>
- `.claude/architecture/<area>/<surface>.md` — <list which read>
- `.claude/CLAUDE.md`
```

## Flag Catalog

These are the readiness dimensions to evaluate. Not every flag applies to every Story — use judgment.

### Context & Motivation
- 🔴 **Missing Context** — No explanation of why this Story exists.
- 🟡 **Vague Context** — Context present but doesn't clearly connect to a business need / user value.
- 🟢 **Clear Context** — Business motivation well articulated, references the parent Feature or product area.

### Story / Description Quality
- 🔴 **No Story Format** — `## Story` doesn't identify persona, capability, or outcome.
- 🟡 **Generic Persona** — "As a user" is too generic; should specify a real persona from the repo's `.claude/architecture/*`.
- 🟢 **Well-Formed Story** — Clear persona, capability, outcome.

### Acceptance criteria
- 🔴 **Missing ACs** — No acceptance criteria at all.
- 🔴 **Untestable ACs** — ACs are vague ("system should work well") or not verifiable.
- 🟡 **Incomplete ACs** — Some ACs exist but obvious scenarios are missing (error cases, edge cases).
- 🟡 **Too Many ACs** — More than 8 ACs suggests the Story is too large; split via `/discovery-workflow extend`.
- 🟡 **Generic component references** — AC mentions "the auth module" instead of a concrete class/method named in the architecture doc.
- 🟢 **Solid ACs** — Testable, specific, covering main scenarios + at least one error path; references real components.

### Scope
- 🔴 **Unbounded Scope** — No clear boundaries; could expand indefinitely.
- 🟡 **Implicit Assumptions** — Story assumes context not written down.
- 🟡 **No Out of Scope** — Nothing explicitly excluded; scope creep risk.
- 🟢 **Well-Bounded** — Clear what's in and what's out; out-of-scope items listed.

### Dependencies & Risks
- 🟡 **Implicit Dependencies** — Item depends on another Story / service / infra but doesn't say so (`Blocked by:` line missing).
- 🟡 **Cross-Team Dependency** — Requires work from another team; coordination needed.
- 🟢 **Self-Contained** — No external dependencies identified.

### Harness-Specific
- 🔴 **Missing Surface** — Title doesn't carry a `[<surface>]` segment and no `surface:*` label; dev-workflow planner can't route this.
- 🔴 **Missing Parent Feature** (non-Bug only) — Not a sub-issue of a Feature; dev-workflow branch routing falls back to `develop`. If a Feature should exist, run `/discovery-workflow extend <epic-#>` first.
- 🟡 **Missing E/F/S prefix** — Title lacks the `S<e>.<f>.<s>:` numbering prefix; the parent–child structure isn't visible on the board. Suggest the prefix inferred from the parent Feature; never renumber an existing one.
- 🟡 **Status `Backlog`/`No Status`** — Recommend `/backlog-improve` to reach `Ready` before `/dev-workflow`.
- 🟡 **Components not in architecture doc** — Story mentions a component/pattern that doesn't appear in `.claude/architecture/<area>/<surface>.md`. Either a Phase 8 reconciliation candidate (new component needs documenting) or a likely architectural gap.

## Tone

The readiness report appears as a GitHub issue comment seen by the PO + team. Constructive and specific. Every 🔴 or 🟡 flag MUST include a concrete suggestion for how to fix it — draft replacement text where possible. 🟢 flags are valuable too — they reinforce what the PO and team are doing well. *"This Story is in good shape — clear context, testable ACs, parent Feature linked, `[mobile][service]` surface present. Ready for /dev-workflow."* is a valid and valuable output.
