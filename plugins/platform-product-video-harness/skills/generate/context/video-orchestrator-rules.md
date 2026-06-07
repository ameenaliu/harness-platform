# Orchestrator Rules (generate workflow)

These rules apply to all 5 phases of `/platform-product-video-harness:generate`. Individual command files must not override them.

## Role & Boundaries

**The orchestrator (you, the main `generate` thread) is a COORDINATOR, not an implementer.** Follow these rules without exception:

### NEVER do agent work yourself

The orchestrator MUST NOT:
- Extract frames or call ffmpeg (analyzer's job)
- Read PNG frames via vision (analyzer's job)
- Draft or edit `script.md` (scriptwriter's job)
- Write or edit `compositions/*.tsx` (compositor's job)
- Run `npx remotion render` (compositor's job)
- Call ElevenLabs APIs or mux audio (narrator's job)
- Run `ffprobe` to verify outputs (reviewer's job)
- Touch `<ProductVideos>/.env` (no agent does; user-maintained)

### ALWAYS delegate to the correct agent

| Phase | Agent | Tool to spawn |
|---|---|---|
| 1 | analyzer | `@platform-video-analyzer` |
| 2 | scriptwriter | `@platform-video-scriptwriter` (hosts GATE #1) |
| 3 | compositor | `@platform-video-compositor` (hosts GATE #2) |
| 4 | narrator | `@platform-video-narrator` |
| 5 | reviewer | `@platform-video-reviewer` (read-only, hosts GATE #3) |

### The orchestrator MAY only

- Read `brief.md`, `sample.mp4` (existence checks), `script.md` (to pass excerpts to next agent), `_cache/analysis.json` (to verify Phase 1 SUCCESS)
- Read `<ProductVideos>/.claude/context/platform-video-context.md` for workspace config
- Cache-check `_cache/analysis.json` against `sample.mp4`'s git hash to decide whether Phase 1 can be skipped
- Update the runtime tracker at `<ProductVideos>/ai/video-runs/<slug>.md`
- Delegate to role agents via the Agent tool (sequential — no background lanes)
- Pass the human's gate responses to the next agent invocation as context
- Verify `.env` contains `ELEVENLABS_API_KEY=…` (presence check only — never read the value, never write the file)
- **Phase 0 only**: host the brief-drafting Q&A inline and `Write` / `Edit` `<project-folder>/brief.md` (see §Phase 0 below). This is the single exception to "never do agent work" — drafting `brief.md` is gathering user input, not transforming pipeline state.

**If you catch yourself about to call `ffmpeg`, `Read` a PNG frame, write to `script.md`, or `Edit` a composition — STOP and delegate.**

## Phase 0 — Brief Drafting (orchestrator-hosted, conditional)

Phase 0 runs **only** if `<project-folder>/brief.md` does not exist at pre-flight time. If it exists, Phase 0 is skipped entirely and the orchestrator jumps to Phase 1.

When Phase 0 runs:

- The orchestrator (you) hosts it directly — no agent spawned.
- Steps: show sample brief → ask Q1–Q3 (1 batch, 3 questions) → ask Q4 (free text) → optional Q5 (notes) → `Write` `brief.md` → present + confirm → loop on `EDIT IT` or `START OVER` → record outcome.
- The full Q&A script lives in `skills/generate/SKILL.md` → "Phase 0 — Brief Drafting". Follow it verbatim; do not improvise the questions.
- Allowed file operations during Phase 0: `Write` and `Edit` on `<project-folder>/brief.md` ONLY. Any other write is a violation.
- No GATE number for Phase 0 — the confirm-loop at Step 0.6 IS the human checkpoint, but `brief.md` is user input, not approved pipeline output, so it doesn't get a numbered gate.
- On `CANCEL` at Step 0.6: record `Cancelled at Phase 0` in the tracker, halt the workflow, leave any partial `brief.md` on disk for the user to edit / discard.

## Constraints (non-negotiable)

1. **Orchestrator does NOT do agent work.** Violation = workflow failure.
2. **Three mandatory human gates** (hosted by the respective agents, not by the orchestrator directly):
   - GATE #1 — after Phase 2 (scriptwriter presents `script.md`)
   - GATE #2 — after Phase 3 (compositor presents 3 silent previews)
   - GATE #3 — after Phase 5 (reviewer presents verification report)
3. **`.env` is the user's territory.** No agent writes it. If `ELEVENLABS_API_KEY` missing, halt with the standardised remediation block from `skills/env-credential-recipes/SKILL.md` (verbatim).
4. **Agent isolation**: each agent runs in its own context window. The orchestrator passes only the necessary outputs between them.
5. **Sequential phases.** Never start phase N+1 before phase N reports `Outcome: SUCCESS`.
6. **Cache discipline.** Phase 1 is idempotent against `sample.mp4`'s git hash. If `_cache/analysis.json` exists and `source.hash` matches, the analyzer reports `SUCCESS (cached)` and proceeds directly to Phase 2.
7. **Tracker is persistent runtime state.** Update at every phase transition. Tracker is **never committed** (gitignored under `ai/video-runs/`).
8. **Output is always 3 MP4s.** Never 1 or 2 — the compositor must register all 3 aspect ratios in `Root.tsx`.
9. **Output is files, not posts.** Posting to social media is manual in v0.1.0.
10. **Brand tokens always.** Reviewer rejects compositions with hardcoded hex / fonts.
11. **Captions burned in.** Reviewer rejects voiceover-without-CaptionStrip.
12. **Audio levels.** -16 LUFS voiceover, -28 LUFS BGM; reviewer halts on overshoot.

## Phase transition table

Update the tracker at every transition.

| When | Tracker update |
|---|---|
| Pre-flight passes | Create tracker, record `Started` timestamp, Phase 0 `⏳ Pending` (if `brief.md` missing) or `⏭ Skipped` (if present), Phases 1–5 `⏳ Pending` |
| Phase 0 starts (brief.md missing) | Phase 0 → `🔧 In Progress`, record `Drafting brief via Q&A` |
| Phase 0 confirm = LOOKS GOOD | Phase 0 → `✅ Done`, record approval rounds (re-drafts) + persona / tone / CTA selected |
| Phase 0 confirm = EDIT IT (in loop) | Phase 0 stays `🔧 In Progress`, increment edit-round counter |
| Phase 0 confirm = START OVER | Phase 0 stays `🔧 In Progress`, reset edit-round counter, re-run Q&A |
| Phase 0 confirm = CANCEL | Phase 0 → `❌ Cancelled`, record `Cancelled at Phase 0`; halt workflow |
| Before launching analyzer | Phase 1 → `🔧 In Progress`, set `Phase 1 started` |
| Analyzer returns SUCCESS | Phase 1 → `✅ Done`, record cache status (cached/fresh), scene count, suggested template |
| Before launching scriptwriter | Phase 2 → `🔧 In Progress`, pass `analysis.json` summary as context |
| Scriptwriter returns SUCCESS (APPROVED at GATE #1) | Phase 2 → `✅ Done`, GATE #1 ✅, record template used, voice ID, target duration, approval rounds |
| Scriptwriter returns BLOCKED (NEEDS CHANGES — go back) | Phase 2 stays `🔧 In Progress`, increment round counter, re-spawn scriptwriter with notes |
| Before launching compositor | Phase 3 → `🔧 In Progress`, pass `script.md` excerpt as context |
| Compositor returns SUCCESS (APPROVED at GATE #2) | Phase 3 → `✅ Done`, GATE #2 ✅, record composition line count, render time, approval rounds |
| Compositor returns BLOCKED (NEEDS CHANGES — script edit) | Phase 2 → `🔧 In Progress` (rollback), Phase 3 → `⏳ Pending` again, re-spawn scriptwriter with compositor's notes |
| Compositor returns BLOCKED (NEEDS CHANGES — visual) | Phase 3 stays `🔧 In Progress`, re-spawn compositor with notes |
| Before launching narrator | Phase 4 → `🔧 In Progress`. Verify `.env` has `ELEVENLABS_API_KEY=…` (presence only). If missing → halt with remediation block. |
| Narrator returns SUCCESS | Phase 4 → `✅ Done`, record approx char usage, BGM prompt, output file sizes |
| Narrator returns BLOCKED (missing API key) | Phase 4 stays `🔧 In Progress`, surface remediation block to human, wait for them to set up `.env`, then re-spawn |
| Before launching reviewer | Phase 5 → `🔧 In Progress`, pass output file paths + composition path as context |
| Reviewer returns INFORMATIONAL + human APPROVED at GATE #3 | Phase 5 → `✅ Done`, GATE #3 ✅, record finding counts, workflow complete |
| Reviewer returns INFORMATIONAL + human NEEDS CHANGES — re-narrate | Phase 4 → `🔧 In Progress`, re-spawn narrator with notes |
| Reviewer returns INFORMATIONAL + human NEEDS CHANGES — re-build | Phase 3 → `🔧 In Progress`, re-spawn compositor with notes |
| Reviewer returns INFORMATIONAL + human NEEDS CHANGES — re-script | Phase 2 → `🔧 In Progress`, re-spawn scriptwriter with notes |
| Any phase returns CANCEL | Workflow aborted; tracker records `Cancelled at <phase>` |

## Agent response contract

Every agent ends with a `📋 AGENT STATUS` block. Parse it after every invocation.

| Outcome | Action |
|---|---|
| `SUCCESS` | Record + proceed to next phase |
| `SUCCESS (APPROVED)` (gate-hosting agents at Phases 2, 3, 5) | Record GATE crossed + proceed |
| `SUCCESS (cached)` (analyzer Phase 1 only) | Record cache hit + proceed |
| `BLOCKED (NEEDS CHANGES — <which>)` (gate-hosting agents) | Loop back per the table above |
| `BLOCKED (missing API key)` (narrator only) | Surface remediation block, pause workflow, wait, re-spawn |
| `BLOCKED (CANCEL)` (any gate-hosting agent) | Abort workflow, record in tracker |
| `INFORMATIONAL` (reviewer always) | Proceed to GATE #3 handling per the table above |
| `FAILED` | Halt the entire workflow, surface error to human |

## Tracker file format

`<ProductVideos>/ai/video-runs/<YYYY-MM-DD>_<slug>.md`:

```markdown
# Video run: <slug>

- Started: <UTC>
- Project folder: projects/<slug>
- Voice ID: <id> (<tone>)
- Target duration: <N>s

## Phase status

| Phase | Status | Notes |
|---|---|---|
| 1 Analyze | ✅ Done | Cached / 8 scenes, suggested feature-demo, 2.3s analyzer time |
| 2 Script | ✅ Done | GATE #1 ✅ after 2 rounds. Template: feature-demo. Final duration target: 30s. |
| 3 Build | ✅ Done | GATE #2 ✅ after 1 round. 142 lines. Render: 4.1 min (3 ratios). |
| 4 Narrate | ✅ Done | ~1,240 chars. BGM prompt: "calm ambient pad". |
| 5 Review | ✅ Done | GATE #3 ✅. 0 CRITICAL, 0 WARNING. |

## Round trips

- Phase 2: 2 (human edited Scene 3 voiceover)
- Phase 3: 1
- Phase 5: 0

## Outputs

- projects/<slug>/out/9-16.mp4  (8.2 MB, 30.1s, -16.1 LUFS)
- projects/<slug>/out/1-1.mp4   (6.1 MB, 30.1s, -16.1 LUFS)
- projects/<slug>/out/16-9.mp4  (9.4 MB, 30.1s, -16.1 LUFS)

## Completed: <UTC>
```

## Error recovery

- **Mid-workflow API errors** (ElevenLabs 401/402/429): narrator halts with the API's error; orchestrator surfaces to human, does not auto-retry on auth/billing/rate errors.
- **ffmpeg / Remotion render failures**: relevant agent retries once with verbose logging; on second failure surfaces to human.
- **Session restart**: next session reads tracker, resumes from the last `✅ Done` phase.
- **Cache invalidation**: if user replaces `sample.mp4`, the hash mismatch invalidates Phase 1's cache automatically (analyzer re-runs).
