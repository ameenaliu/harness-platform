---
name: generate
description: >
  The single user-invocable workflow of platform-product-video-harness.
  Orchestrates 5 sequential phases (Analyze → Script → Build → Narrate →
  Review) with 3 human approval gates to produce 3 final MP4s (9:16 + 1:1
  + 16:9) from a project folder. Phase 0 (Brief Drafting) walks the user
  through a Q&A to author brief.md if missing — assets/ is still
  user-provided. Each phase delegates to its specialised agent (analyzer,
  scriptwriter, compositor, narrator, reviewer); the orchestrator (you)
  coordinates and gates.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent, AskUserQuestion
argument-hint: "<project-folder>"
user-invocable: true
---

# /platform-product-video-harness:generate

End-to-end product-video generation. One command, 5 phases (+ optional Phase 0 for brief drafting), 3 human gates, 3 final MP4s ready to post.

## Usage

```
/platform-product-video-harness:generate <project-folder>
```

Where `<project-folder>` is a path under `<ProductVideos>/projects/`, e.g. `projects/2026-05-25_inventory-launch`.

The folder must contain:

- `assets/` (required, ≥1 file) — PNG / JPG / SVG / MP4 assets
- `brief.md` (optional — if absent, **Phase 0 will draft it with you**)
- `sample.mp4` (optional) — reference video for the analyzer

You no longer need to author `brief.md` before invoking `/generate`. If it's missing, Phase 0 walks you through 4 questions and writes the file for you. If it exists, Phase 0 is skipped and the workflow goes straight to Phase 1.

## Orchestrator Rules

**Before executing**, read `context/video-orchestrator-rules.md`. These apply to all phases (including Phase 0).

## Pre-flight

1. Verify `<ProductVideos>/.claude/context/platform-video-context.md` exists. If missing → halt with `"Run /platform-product-video-harness:init-video-workspace first."`
2. Verify `<project-folder>` exists and contains `assets/` with ≥1 file. If `assets/` is missing or empty → halt with `"Drop ≥1 PNG/JPG/SVG/MP4 into <project-folder>/assets/ then re-run."`
3. Check whether `<project-folder>/brief.md` exists. **If missing, mark Phase 0 = ⏳ Pending** (the workflow will draft it). If present, mark Phase 0 = ⏭ Skipped (already exists).
4. Verify `<ProductVideos>/.env` contains `ELEVENLABS_API_KEY=…` (non-empty). If missing → halt with the standardised remediation block from `skills/env-credential-recipes/SKILL.md` (verbatim).
5. Create `<ProductVideos>/ai/video-runs/<slug>.md` runtime tracker (gitignored). Record start time + project path + Phase 0 status from step 3.

## The Phases

| Phase | Hosted by | Output | Gate |
|---|---|---|---|
| 0. Brief (if missing) | orchestrator (inline) | `brief.md` | — (collaborative drafting; no separate APPROVED) |
| 1. Analyze | `@platform-video-analyzer` | `_cache/analysis.json` | — |
| 2. Script | `@platform-video-scriptwriter` | `script.md` | **GATE #1** (hosted by agent) |
| 3. Build | `@platform-video-compositor` | `compositions/<slug>.tsx` + `_preview/*.mp4` | **GATE #2** (hosted by agent) |
| 4. Narrate | `@platform-video-narrator` | `out/{9-16,1-1,16-9}.mp4` | — |
| 5. Review | `@platform-video-reviewer` (read-only) | Verification report | **GATE #3** (hosted by agent) |

Phases 1–5 each delegate to a thin agent pointer that reads its `portable/roles/<name>.md` body + `portable/mechanics/claude.md` at startup. The orchestrator (you, the main `generate` thread) coordinates — never does an agent's work for Phases 1–5. Phase 0 is the **one** exception — drafting `brief.md` is gathering user input, not agent work, so the orchestrator hosts it inline.

For the full phase-by-phase narrative, the Phase 0 Q&A script, the orchestrator's responsibilities at each phase transition, gate handling, and the tracker update transition table, see `context/video-orchestrator-rules.md`. For the workflow narrative shared with Codex, see `../../portable/workflow/generate.md`.

## Phase 0 — Brief Drafting (skipped if `brief.md` exists)

If pre-flight step 3 flagged `brief.md` as missing, run this sequence **inline** before spawning the analyzer.

### Step 0.1 — Show the user what a brief looks like

Print this example verbatim so they know the target:

```markdown
# <Project Slug> — <One-line working title>

**Audience**: primary end users of the product who currently solve this
problem manually or with a workaround.

**Goal**: show that the core action takes < 10 seconds, and that results
sync across all the user's devices in real time.

**Tone**: warm and credible — confident without hype. No "revolutionary" /
"AI-powered" language.

**CTA**: "Try <feature> in <brand> — open the app and tap the action button."

**Notes** (optional): highlight the offline-sync indicator in any demo
scene; avoid showing real user names or transaction IDs in screenshots.
```

Then say: *"I'll ask you 4 quick questions to draft your equivalent. You can edit before we continue."*

### Step 0.2 — Gather inputs (one AskUserQuestion batch — 3 questions)

```
Q1: Audience — Who is this video for?
  - end user (primary user of the product)
  - prospect (evaluating the product)
  - partner / stakeholder
  - Other  ← user types a custom persona

(Populate from brand.personas[].label when a brand kit is present.)

Q2: Tone — How should it feel?
  - warm and friendly (default brand voice)
  - energetic and upbeat (high-energy launches)
  - calm and authoritative (serious announcements)
  - Other  ← user types

Q3: CTA — What action should the viewer take?
  - Download <brand> on iOS and Android
  - Open the app and try the feature
  - Sign up at <your-domain>
  - Other  ← user types a custom CTA
```

(Map answers to `brand.personas[].key` for Q1 where possible; the scriptwriter will use it. For Q3 "Other", let them type the exact CTA line they want delivered.)

### Step 0.3 — One free-text question (the goal/key message)

A second AskUserQuestion call, single question, with a "Continue with my answer" option that just unblocks after the user types via the "Other" path:

```
Q4: What's the ONE thing the viewer should walk away knowing or doing?
    (One or two sentences — what problem does this solve, what's the wow moment?)
  - I'll type my answer  ← user types via "Other"
```

### Step 0.4 — Optional context (single AskUserQuestion, skippable)

```
Q5: Any extra notes? (Optional — banned topics, key assets to highlight,
    specific persona language, etc.)
  - Skip — nothing extra
  - I'll type my notes  ← user types via "Other"
```

### Step 0.5 — Draft brief.md

Using the answers from Q1–Q5, write `<project-folder>/brief.md`:

```markdown
# {{slug}} — {{working_title_or_inferred_from_goal}}

**Audience**: {{Q1_answer_expanded_to_full_sentence}}

**Goal**: {{Q4_answer}}

**Tone**: {{Q2_answer}}. {{auto_appended_no_banned_phrases}}

**CTA**: "{{Q3_answer}}"

{{if Q5_provided}}
**Notes**: {{Q5_answer}}
{{endif}}

---
🤖 Generated with platform-product-video-harness Phase 0 (Brief Drafting)
```

Auto-append `"No revolutionary / game-changing / AI-powered / next-generation / world-class / 10x language."` to the Tone line — these are the brand's banned phrases per `brand.tone.banned_phrases` (the neutral starter set; the user's brand kit may add more) and pre-empting them in the brief avoids a Phase 2 round-trip.

For `{{slug}}`, derive from the project folder name (strip the date prefix, replace dashes with spaces, title-case).

### Step 0.6 — Present + confirm

Show the user the rendered brief in the conversation, then ask via `AskUserQuestion`:

```
This brief looks like:
[show the full file]

How does it look?
  - LOOKS GOOD — proceed to Phase 1
  - EDIT IT — I'll dictate changes  ← Other; user types edits, you Edit the file, then re-confirm
  - START OVER — re-run the questions  ← restart Step 0.2
  - CANCEL — abort the workflow
```

On `LOOKS GOOD`: record `Phase 0: ✅ Done — drafted via Q&A` in the tracker; proceed to Phase 1.
On `EDIT IT`: Edit `brief.md` per the user's notes; loop back to Step 0.6.
On `START OVER`: restart Step 0.2.
On `CANCEL`: record `Cancelled at Phase 0` in tracker; halt.

## Full pipeline mode (default)

When called with a project folder, run sequentially:

0. **(if `brief.md` missing)** Run Phase 0 inline → record in tracker
1. Spawn `@platform-video-analyzer` → record `Phase 1` in tracker
2. Spawn `@platform-video-scriptwriter` → GATE #1 → record
3. Spawn `@platform-video-compositor` → GATE #2 → record
4. Spawn `@platform-video-narrator` → record
5. Spawn `@platform-video-reviewer` → GATE #3 → record + completion summary

After each phase completes successfully, proceed automatically to the next (unless a human gate blocks).

## Resume mode

If the runtime tracker shows partial completion (e.g. Phase 1 + 2 done, Phase 3 partial), resume from the last completed phase. The orchestrator infers from the tracker — no special flag needed.

## Output

3 final MP4s at:

```
<ProductVideos>/projects/<slug>/out/9-16.mp4    # Reels, TikTok, YouTube Shorts (1080×1920)
<ProductVideos>/projects/<slug>/out/1-1.mp4     # Instagram Feed (1080×1080)
<ProductVideos>/projects/<slug>/out/16-9.mp4    # YouTube long-form, LinkedIn (1920×1080)
```

All gitignored. Posting is **manual** — open each platform's uploader.

## Critical rules (delegated to video-orchestrator-rules.md)

- 3 human gates, no auto-advance
- `.env` is user-maintained; agents never write it
- Cache discipline: Phase 1 idempotent against `sample.mp4` hash
- Tracker is local-only (`ai/video-runs/*.md`) — never committed
- Agents are sequential — no parallel spawning
