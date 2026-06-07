# platform-backlog-workflow — refine & enrich a GitHub Story

Improve the quality of a GitHub Story issue before it enters development. Read-mostly against GitHub; the only writes are Story-quality artefacts (issue body / acceptance-criteria edits + change-log comments) posted back after human confirmation. All GitHub access uses the `gh` CLI (`gh issue view`, `gh issue edit`, `gh issue comment`) — there is no MCP server.

**Usage**: `<command> <story-issue-number>` where command ∈:

- **analyze** — produce a readiness report scoring the Story against its acceptance criteria; list gaps and risks. No writes.
- **refine** — section-by-section structured refinement (title with `[<surface>]` prefix + `S<e>.<f>.<s>` numbering, story body, ACs, NFRs, dependencies, parent Feature). Propose the rewrite; apply it via `gh issue edit` + a change-log comment only after the human confirms.
- **improve** — conversational gap-filling: ask the human targeted questions, assemble the refined Story, post it back via `gh issue edit` + `gh issue comment`.
- **enrich** — codebase-aware technical notes (affected services/apps in the monorepo, integration points across SERVICE/WEB/MOBILE, references to `.claude/architecture/*` + `.claude/rules/*`). Reads the repo; appends to the body's Technical Notes section + posts a comment.

## Rules
- Never assume requirements — ask the human when a section is ambiguous.
- Never overwrite a Story's body silently; propose, then write after confirmation.
- Body and acceptance criteria are Markdown (GitHub-native) per `.agents/skills/github-rendering/SKILL.md`; acceptance criteria render as a `- [ ]` checklist.
- Express dependencies as GitHub **native issue dependencies** (the typed "Blocked by" relationship via the REST `dependencies/blocked_by` endpoint), not a `blocked` label or body link. Body line + `blocked` label is a GitHub-Enterprise-only fallback. See `.agents/skills/github-rendering/SKILL.md` § Dependency convention.
- Every generated artefact (readiness report, refined Story, technical notes) ends with the attribution footer.
- Match the conventions for any Surface you reference while enriching (`dotnet-conventions`, `react-turbo-conventions`, `expo-mobile-conventions`).
- Refined titles MUST carry the `[<surface>]` prefix matching the Story's affected surfaces and the `S<e>.<f>.<s>:` numbering prefix.
