# FarmManagement/Farmilik/Azure-DevOps coupling audit — 2026-06-09

238 files. Legend: C1 domain · C2 other-repo-path · C3 .NET-arch-default · C4 Azure-DevOps · C5 NG-identifiers · C6 grammar · C7 video-theme.

| # | File | Fix? | Cats | Note |
|--|------|------|------|------|
| 1 | `.claude-plugin/marketplace.json` | — |  | Generic stack-agnostic marketplace manifest; no FarmManagement/ADO coupling. |
| 2 | `.gitattributes` | — |  | Line-ending/EOL rules only; no project-specific content. |
| 3 | `.github/workflows/ci.yml` | — |  | Generic GitHub Actions validation; uses main branch, no ADO/Farm refs. |
| 4 | `.gitignore` | — |  | Standard ignore patterns; nothing project-specific. |
| 5 | `AGENTS.md` | ⚠️ REVIEW | C5 | BVN/NIN/Nigerian phone cited as PII examples in data-policy rules — defensible default, but Farmilik-flavored. |
| 6 | `LICENSE` | — |  | MIT license + upstream skill attributions; no project coupling. |
| 7 | `README.md` | — |  | Generic GitHub-native harness README; main branch, stack-flexible, no Farm/ADO refs. |
| 8 | `video/.claude-plugin/plugin.json` | ⚠️ REVIEW | C5 | 9jaLingo + Yoruba/Hausa/Igbo/Pidgin TTS routing as defaults; presented as routed-provider example with generic fallback. |
| 9 | `video/CHANGELOG.md` | ⚠️ REVIEW | C5 | 9jaLingo + Yoruba/Hausa/Igbo/Nigerian Pidgin as localisation defaults; borderline Farmilik-flavored but framed as provid |
| 10 | `video/CLAUDE.md` | ⚠️ REVIEW | C5 | 9jaLingo + Yoruba/Hausa/Igbo/Nigerian Pidgin translate examples; provider-routing flavor, generic fallback present. |
| 11 | `video/README.md` | ⚠️ REVIEW | C7 | Brand-agnostic harness doc; only flag is the example project folder name 'inventory-launch', a taxonomy-listed product-v |
| 12 | `video/agents/platform-video-analyzer.md` | — |  | Generic Phase 1 analyzer pointer; no project-specific coupling. |
| 13 | `video/agents/platform-video-compositor.md` | — |  | Generic Phase 3 compositor pointer; Remotion-neutral, no Farmilik coupling. |
| 14 | `video/agents/platform-video-narrator.md` | — |  | Generic Phase 4 narrator pointer; ElevenLabs is the plugin's tool, not Farmilik coupling. |
| 15 | `video/agents/platform-video-reviewer.md` | — |  | Generic Phase 5 reviewer pointer; no project-specific coupling. |
| 16 | `video/agents/platform-video-scriptwriter.md` | — |  | File listed in slice plan but not present in rows 11-20 git order; not part of assigned slice — see note. Actual slice f |
| 17 | `video/agents/shared/video-production-principles.md` | — |  | Generic video-production rules (brand tokens, captions, LUFS, aspect ratios); no Farmilik domain or stack coupling. |
| 18 | `video/hooks/hooks.json` | — |  | Generic hook wiring; references plugin's own guard scripts only. |
| 19 | `video/hooks/large-media-guard.sh` | — |  | Generic 10MB media-size guard gated on the video-context sentinel; no project-specific coupling. |
| 20 | `video/hooks/pii-pattern-guard.sh` | ✅ FIX | C5 C7 | PII guard; Nigerian BVN/NIN/phone are defensible defaults but '9jaLingo' is a Farmilik-only product and 'farmer'/'farmer |
| 21 | `video/hooks/render-quality-check.sh` | — |  | Generic Remotion pre-commit lint + 1-frame dry-render gate; no project coupling. |
| 22 | `video/hooks/secrets-guard.sh` | ⚠️ REVIEW | C5 | Generic secret-scan guard; one Farmilik-specific 9jaLingo key pattern (defensible default, flagged). |
| 23 | `video/portable/AGENTS.md.tmpl` | — |  | Tool-agnostic ProductVideos AGENTS hub; neutral personas (end_user/prospect/partner), no coupling. |
| 24 | `video/portable/README.md` | — |  | Describes cross-tool portable layer; generic, no project-specific vocab. |
| 25 | `video/portable/codex/agents/analyzer.toml` | — |  | Codex analyzer subagent definition; generic video-pipeline role. |
| 26 | `video/portable/codex/agents/compositor.toml` | — |  | Codex compositor subagent; generic Remotion composition role. |
| 27 | `video/portable/codex/agents/narrator.toml` | — |  | Codex narrator subagent; ElevenLabs TTS role, no project coupling. |
| 28 | `video/portable/codex/agents/orchestrator.toml` | — |  | Codex orchestrator subagent; generic 5-phase pipeline coordinator. |
| 29 | `video/portable/codex/agents/reviewer.toml` | — |  | Codex reviewer subagent; read-only ffprobe verifier, generic. |
| 30 | `video/portable/codex/agents/scriptwriter.toml` | — |  | Codex scriptwriter subagent; generic template-fill role. |
| 31 | `video/portable/codex/skills/platform-video-generate/SKILL.md` | — |  | Generic Codex orchestration skill for the video pipeline; no origin-project coupling. |
| 32 | `video/portable/guards/github-actions-secret-scan.yml` | ✅ FIX | C4 C5 | 9jaLingo is a Farmilik-only provider key shape (not a generic provider); also a 'master' push-trigger leftover. |
| 33 | `video/portable/guards/pre-commit` | — |  | Generic secrets/large-media pre-commit guard; ElevenLabs/Figma/Slack/JWT shapes only, no 9jaLingo. |
| 34 | `video/portable/mechanics/claude.md` | — |  | Claude Code per-role mechanics for the video harness; no origin-project coupling. |
| 35 | `video/portable/mechanics/codex.md` | — |  | Codex per-role mechanics for the video harness; no origin-project coupling. |
| 36 | `video/portable/roles/analyzer.md` | — |  | Frame-extraction/vision analyzer role; generic, no Farmilik vocab. |
| 37 | `video/portable/roles/compositor.md` | ⚠️ REVIEW | C7 | Uses 'inventory-launch'/'InventoryLaunch' as the example composition — product-video Farmilik theming (expected demo, bu |
| 38 | `video/portable/roles/narrator.md` | — |  | ElevenLabs TTS+ffmpeg mux role; ElevenLabs is the legit video stack, no Farmilik coupling. |
| 39 | `video/portable/roles/orchestrator.md` | — |  | Generic 5-phase generate orchestrator; placeholder <slug> examples, no origin coupling. |
| 40 | `video/portable/roles/reviewer.md` | — |  | Read-only output-verification reviewer role; generic ffprobe/grep checks, no Farmilik vocab. |
| 41 | `video/portable/roles/scriptwriter.md` | ⚠️ REVIEW | C7 | Product-video demo theming: farmer testimonial + inventory asset examples — expected for this plugin but Farmilik-flavor |
| 42 | `video/portable/templates/.env.example` | ✅ FIX | C5 | 9jaLingo + NAIJALINGO_API_KEY + Yoruba/Hausa/Igbo/Pidgin baked as a default credential in a generic video harness — Farm |
| 43 | `video/portable/templates/.gitattributes` | — |  | Generic git line-ending / binary normalization rules — nothing project-specific. |
| 44 | `video/portable/templates/.gitignore` | — |  | Generic Node/Remotion ignore patterns — no Farmilik coupling. |
| 45 | `video/portable/templates/README.md` | — |  | Generic ProductVideos Remotion scaffold README; brand-neutral, references generic plugin + marketplace. |
| 46 | `video/portable/templates/brand/brand.json` | — |  | Neutral placeholder brand kit ("Your Brand", generic personas/tone) — intentionally project-agnostic. |
| 47 | `video/portable/templates/brand/logo.svg` | — |  | Neutral placeholder logo SVG (letter 'B') — no project coupling. |
| 48 | `video/portable/templates/compositions/Root.tsx` | — |  | Generic Remotion root with example-hello compositions per aspect ratio — stack-agnostic scaffold. |
| 49 | `video/portable/templates/compositions/_components/BrandIntro.tsx` | — |  | Generic reusable BrandIntro component reading brand.json tokens — no Farmilik vocab. |
| 50 | `video/portable/templates/compositions/_components/CaptionStrip.tsx` | — |  | Generic caption-strip component driven by brand.json — no project-specific content. |
| 51 | `video/portable/templates/compositions/_components/EndCard.tsx` | — |  | Generic brand-token-driven end card (logo/tagline/CTA/store badges); no Farmilik theming. |
| 52 | `video/portable/templates/compositions/_components/FeatureCallout.tsx` | — |  | Generic callout component driven by brand tokens; no project-specific content. |
| 53 | `video/portable/templates/compositions/_components/LogoStinger.tsx` | — |  | Generic logo stinger animation reading brand.json; nothing project-specific. |
| 54 | `video/portable/templates/compositions/_components/LowerThird.tsx` | — |  | Generic lower-third name/role component from brand tokens; clean. |
| 55 | `video/portable/templates/compositions/_components/SafeArea.tsx` | — |  | Generic aspect-ratio safe-zone padding component; no coupling. |
| 56 | `video/portable/templates/compositions/example-hello.tsx` | — |  | Generic smoke-test composition using brand.name/tagline tokens; no Farmilik content. |
| 57 | `video/portable/templates/package.json` | — |  | Neutral Remotion project manifest named platform-product-videos; clean. |
| 58 | `video/portable/templates/remotion.config.ts` | — |  | Generic Remotion render config; no project coupling. |
| 59 | `video/portable/templates/tsconfig.json` | — |  | Standard TS config for Remotion; clean. |
| 60 | `video/portable/workflow/generate.md` | ⚠️ REVIEW | C7 | Example project path uses 'inventory-launch' — expected product-video demo theming, flaggable. |
| 61 | `video/settings.json` | — |  | Generic permissions allowlist (ffmpeg, remotion, elevenlabs curl); nothing project-specific. |
| 62 | `video/skills/9jalingo-voices/SKILL.md` | ⚠️ REVIEW | C5 | Entire skill is a Nigerian-language TTS provider (9jaLingo, yo/ha/ig/pcm, NAIJALINGO_API_KEY, nl- keys) — Farmilik-flavo |
| 63 | `video/skills/aspect-ratio-rendering/SKILL.md` | ✅ FIX | C7 | Uses 'inventory-launch' / 'InventoryLaunch' as the running composition example — the Farmilik product-video theming toke |
| 64 | `video/skills/brand-collection/SKILL.md` | — |  | Neutral brand-collection protocol; uses generic example folders (kawee-kids/nafuu_app) and neutral starter palette/perso |
| 65 | `video/skills/brand-kit/SKILL.md` | — |  | Neutral brand-kit pointer with generic starter template (Your Brand, generic personas/tone); no Farmilik coupling. |
| 66 | `video/skills/caption-generation/SKILL.md` | ✅ FIX | C1 | Caption examples use farm-sales testimonial vocab ('tallying my farm sales') — FarmManagement domain leakage. |
| 67 | `video/skills/elevenlabs-voices/SKILL.md` | ⚠️ REVIEW | C5 | Otherwise-generic ElevenLabs skill but explicitly routes yo/ha/ig/pcm to 9jaLingo and names NAIJALINGO_API_KEY — Nigeria |
| 68 | `video/skills/env-credential-recipes/SKILL.md` | ⚠️ REVIEW | C5 | Credential recipe; defensible ElevenLabs default but also bakes in NAIJALINGO_API_KEY / nl- keys for the four Nigerian l |
| 69 | `video/skills/ffmpeg-recipes/SKILL.md` | — |  | Generic ffmpeg/ffprobe recipe collection; no domain or project coupling. |
| 70 | `video/skills/frame-analysis-patterns/SKILL.md` | — |  | Generic frame-analysis checklist and template heuristics; no Farmilik/Nigeria coupling. |
| 71 | `video/skills/generate/SKILL.md` | — |  | Generic product-video orchestrator; 'inventory-launch' folder name is a neutral example slug. |
| 72 | `video/skills/generate/context/video-orchestrator-rules.md` | — |  | Stack-agnostic orchestrator rules; no Farmilik coupling. |
| 73 | `video/skills/init-video-workspace/SKILL.md` | — |  | Generic Remotion workspace setup; org/repo always user-supplied, neutral starter brand. |
| 74 | `video/skills/remotion-component-library/SKILL.md` | ⚠️ REVIEW | C7 C1 | Product-video demo copy carries Farmilik farm theming in usage examples (expected for this plugin but flagged). |
| 75 | `video/skills/remotion-conventions/SKILL.md` | ⚠️ REVIEW | C7 C1 | Example composition named InventoryLaunch with Farmilik product-launch copy; product-video demo theming, flagged. |
| 76 | `video/skills/script-templates/SKILL.md` | ⚠️ REVIEW | C1 | Farm domain example in template-selection signal; product-video demo theming, flagged. |
| 77 | `video/skills/script-templates/app-walkthrough.md` | ⚠️ REVIEW | C1 C7 | Farm-specific demo voiceover examples (Farming, finally simple); product-video theming, flagged. |
| 78 | `video/skills/script-templates/before-after.md` | ✅ FIX | C6 | Doubled article 'the actual the product UI' — templating grammar artifact. |
| 79 | `video/skills/script-templates/feature-demo.md` | ✅ FIX | C1 C7 | Farmilik-only farm/smallholder demo examples baked into template ('Meet Inventory', 'on the farm'). |
| 80 | `video/skills/script-templates/launch-announcement.md` | — |  | Example voiceover lines are generic (offline support, audit trail, live sync); no Farmilik vocab. |
| 81 | `video/skills/script-templates/problem-solution-cta.md` | — |  | Generic problem-solution-CTA video script template; placeholders only, no farm/Nigeria vocab. |
| 82 | `video/skills/script-templates/testimonial-style.md` | ⚠️ REVIEW | C7 | Product-video plugin demo theming: testimonial examples use 'smallholder farmer' and farm-sales quotes. |
| 83 | `video/skills/social-platform-specs/SKILL.md` | — |  | Generic per-platform video spec table (IG/TikTok/YouTube/LinkedIn); no project-specific coupling. |
| 84 | `video/skills/translate/SKILL.md` | ✅ FIX | C5 C7 | 9jaLingo TTS + NAIJALINGO_API_KEY + Yoruba/Hausa/Igbo/Pidgin routing baked as core workflow; Farmilik-specific, plus 'sm |
| 85 | `video/skills/update-brand-kit/SKILL.md` | — |  | Generic brand-kit update flow (colors/logo/tagline/fonts/personas); no project-specific coupling. |
| 86 | `sdlc/.claude-plugin/plugin.json` | — |  | Plugin manifest; stack-agnostic GitHub harness description, pluggable packs, no Farmilik/farm/ADO coupling. |
| 87 | `sdlc/CHANGELOG.md` | ⚠️ REVIEW | C4 C5 | Intentional ADO contrasts ('replaces ADO work items / ADO's [Stack]') and defensible BVN data-policy default; both REVIE |
| 88 | `sdlc/CLAUDE.md` | ⚠️ REVIEW | C5 | Data-policy section lists Paystack/SendGrid/BVN/NIN/+234 as guard defaults — defensible-but-Farmilik-flavored → REVIEW. |
| 89 | `sdlc/README.md` | ⚠️ REVIEW | C4 | Intentional ADO contrasts ('replaces ADO's [Stack]', 'GitHub-native port of the Azure DevOps pipeline'); REVIEW not FIX. |
| 90 | `sdlc/agents/platform-sdlc-developer.md` | — |  | Developer agent pointer file; stack-agnostic via packs/registry.json, no farm/Nigeria/ADO coupling. |
| 91 | `sdlc/agents/platform-sdlc-planner.md` | — |  | Generic GitHub multi-surface planner agent pointer; no FarmManagement coupling. |
| 92 | `sdlc/agents/platform-sdlc-reviewer.md` | — |  | Generic reviewer agent pointer; GitHub/gh CLI, surface/stack-pack neutral. |
| 93 | `sdlc/agents/platform-sdlc-tester.md` | — |  | Generic tester agent; stack-agnostic via packs, neutral framework mentions. |
| 94 | `sdlc/agents/shared/engineering-principles.md` | — |  | Universal SOLID/DRY/YAGNI reference; no project-specific content. |
| 95 | `sdlc/hooks/attribution-guard.sh` | — |  | Generic AI-attribution guard; Claude/Anthropic mentions are intentional target, not coupling. |
| 96 | `sdlc/hooks/hooks.json` | — |  | Hook wiring manifest; neutral surface-named quality checks, no project coupling. |
| 97 | `sdlc/hooks/mobile-quality-check.sh` | — |  | Generic Expo/yarn pre-commit gate scoped to mobile/; stack-agnostic. |
| 98 | `sdlc/hooks/pii-pattern-guard.sh` | ⚠️ REVIEW | C5 C1 | Nigerian/Paystack/SendGrid PII shapes are defensible data-policy defaults, but farmer-batch framing is Farmilik-flavored |
| 99 | `sdlc/hooks/prompt-injection-guard.sh` | — |  | Generic prompt-injection warn-only scanner; no project-specific content. |
| 100 | `sdlc/hooks/secret-scan-guard.sh` | ⚠️ REVIEW | C5 C1 | Mostly generic secret shapes, but Paystack-as-'primary payment provider (70+ hits)' bakes Farmilik provider as the defau |
| 101 | `sdlc/hooks/sensitive-file-guard.sh` | ✅ FIX | C6 | Templating grammar artifact 'the this repo' appears twice; otherwise stack-neutral secret guard. |
| 102 | `sdlc/hooks/service-quality-check.sh` | — |  | Stack-agnostic service build/test gate (go + dotnet, registry-driven); no project coupling. |
| 103 | `sdlc/hooks/web-quality-check.sh` | — |  | Generic web pre-commit lint/test gate; no Farmilik/ADO coupling. |
| 104 | `sdlc/packs/README.md` | — |  | Stack-pack model doc; .NET/React/Expo mentioned only as neutral pluggable examples, explicitly de-hardcoded. |
| 105 | `sdlc/packs/dotnet/pack.json` | — |  | .NET stack pack manifest; standard tooling (Refit/Moq) as test frameworks, not baked as THE arch. |
| 106 | `sdlc/packs/expo/pack.json` | — |  | Expo mobile stack pack manifest; generic RN tooling, no domain/project coupling. |
| 107 | `sdlc/packs/go/pack.json` | — |  | Go stack pack manifest; generic Go tooling, no project coupling. |
| 108 | `sdlc/packs/react-turbo/pack.json` | — |  | React+Turbo web stack pack manifest; generic tooling, no coupling. |
| 109 | `sdlc/packs/registry.json` | — |  | Surface->stack registry; .NET/React/Expo are neutral defaults, explicitly described as de-hardcoded. |
| 110 | `sdlc/portable/AGENTS.md.tmpl` | ⚠️ REVIEW | C1 C5 | GitHub-native template (good); 'disease detection' domain example + Nigerian BVN/NIN/Paystack/+234 in data-policy defaul |
| 111 | `sdlc/portable/README.md` | — |  | Generic cross-tool layer doc; GitHub-native, surface-agnostic (SERVICE/WEB/MOBILE), no Farmilik/ADO/farm coupling. |
| 112 | `sdlc/portable/codex/agents/developer.toml` | — |  | Generic Codex developer subagent across SERVICE/WEB/MOBILE; no project-specific coupling. |
| 113 | `sdlc/portable/codex/agents/orchestrator.toml` | — |  | Generic orchestrator; GitHub Issues/Project/PRs via gh CLI; no farm/ADO/Farmilik coupling. |
| 114 | `sdlc/portable/codex/agents/planner.toml` | — |  | Generic planner across 4 workflows; GitHub Issues/sub-issues; no project-specific coupling. |
| 115 | `sdlc/portable/codex/agents/reviewer.toml` | — |  | Generic reviewer; gh PR comments; read-only source; no farm/ADO/Farmilik coupling. |
| 116 | `sdlc/portable/codex/agents/tester.toml` | — |  | Generic tester with neutral per-surface coverage targets; no project-specific coupling. |
| 117 | `sdlc/portable/codex/skills/platform-backlog-workflow/SKILL.md` | — |  | Generic Story refinement skill; [surface] prefix, gh CLI; no farm/ADO/Farmilik coupling. |
| 118 | `sdlc/portable/codex/skills/platform-dev-workflow/SKILL.md` | — |  | Generic 10-phase/3-gate dev workflow; GitHub-native via gh CLI; no project-specific coupling. |
| 119 | `sdlc/portable/codex/skills/platform-discovery-workflow/SKILL.md` | — |  | Generic Epic→Feature→Story discovery on GitHub; no farm/ADO/Farmilik coupling. |
| 120 | `sdlc/portable/codex/skills/platform-pr-review/SKILL.md` | — |  | Generic GitHub PR review skill; gh CLI inline/summary comments; no project-specific coupling. |
| 121 | `sdlc/portable/guards/github-actions-secret-scan.yml` | ⚠️ REVIEW | C5 | Paystack/SendGrid named as provider key-shapes in a data-policy CI guard — defensible defaults. |
| 122 | `sdlc/portable/guards/pre-commit` | ⚠️ REVIEW | C5 | Paystack/SendGrid/Azure provider key-shapes in a pre-commit data-policy guard — defensible defaults. |
| 123 | `sdlc/portable/mechanics/claude.md` | — |  | Generic Claude Code mechanics; gh CLI, worktrees, packs — no project coupling. |
| 124 | `sdlc/portable/mechanics/codex.md` | — |  | Generic Codex mechanics; gh CLI, subagents, gates — no project coupling. |
| 125 | `sdlc/portable/roles/developer.md` | ✅ FIX | C1 | FarmManagement domain example baked into the commit-message sample. |
| 126 | `sdlc/portable/roles/orchestrator.md` | — |  | Generic orchestration; phases, gates, gh sync — no project-specific vocab or paths. |
| 127 | `sdlc/portable/roles/planner.md` | ✅ FIX | C1 C2 | Farm/inventory domain task examples + marketplace/web-apps architecture paths from origin repo. |
| 128 | `sdlc/portable/roles/reviewer.md` | ⚠️ REVIEW | C5 | Paystack/SendGrid/Firebase named in the security checklist — defensible key-handling defaults. |
| 129 | `sdlc/portable/roles/tester.md` | ✅ FIX | C1 | FarmManagement 'disease detection' domain example in the test commit-message sample. |
| 130 | `sdlc/portable/workflow/backlog-workflow.md` | — |  | Generic Story refinement workflow; surface-agnostic conventions references only. |
| 131 | `sdlc/portable/workflow/dev-workflow.md` | — |  | Generic GitHub gh-CLI SDLC orchestrator; neutral service/web/mobile surfaces; no FarmManagement coupling. |
| 132 | `sdlc/portable/workflow/discovery-workflow.md` | — |  | Generic GitHub Epic/Feature/Story discovery flow; native sub-issues + blocked_by; no origin coupling. |
| 133 | `sdlc/portable/workflow/pr-review.md` | — |  | Generic gh-CLI holistic PR review; .NET/web/mobile build commands are neutral surface checks. |
| 134 | `sdlc/scripts/setup-labels.sh` | — |  | Generic GitHub label-creation script; example repo kawee-kids/platform; neutral surface labels. |
| 135 | `sdlc/settings.json` | — |  | Generic pre-approved tool permissions (dotnet/go/yarn/gh/expo/etc.); no project-specific coupling. |
| 136 | `sdlc/skills/agent-device/SKILL.md` | ✅ FIX | C1 | FarmManagement domain leaks in examples: 'kano farm' fill input and 'disease-detection screen' verification example. |
| 137 | `sdlc/skills/api-contract-check/SKILL.md` | — |  | Generic oasdiff OpenAPI breaking-change detection; neutral service/web/mobile consumer framing. |
| 138 | `sdlc/skills/backlog-workflow/SKILL.md` | — |  | Generic backlog-refinement skill router over gh CLI; resolves org/repo from context, no hardcoded project. |
| 139 | `sdlc/skills/backlog-workflow/commands/analyze.md` | ⚠️ REVIEW | C1 C3 | Borderline: AC example uses payment-provider webhook + Outbox + push notification, but framed generically with explicit  |
| 140 | `sdlc/skills/backlog-workflow/commands/enrich.md` | ✅ FIX | C1 C3 | Bakes Farmilik .NET architecture (MediatR CQRS, AutoMapper, Outbox, Refit typed clients, notification worker) as THE ser |
| 141 | `sdlc/skills/backlog-workflow/commands/improve.md` | ✅ FIX | C1 C3 | Farm-management domain personas + Farmilik .NET patterns (Outbox, payment-provider) baked into examples. |
| 142 | `sdlc/skills/backlog-workflow/commands/refine.md` | ✅ FIX | C1 C3 | Payment-provider webhook + service Outbox used as the canonical AC example. |
| 143 | `sdlc/skills/backlog-workflow/templates/backlog-template.md` | ⚠️ REVIEW | C3 | Mostly generic template; EF Core named as a repo-convention placeholder, borderline. |
| 144 | `sdlc/skills/backlog-workflow/templates/readiness-report.md` | ✅ FIX | C1 C3 | Payment-provider webhook + service Outbox + transaction persistence used as the AC redraft example. |
| 145 | `sdlc/skills/backlog-workflow/templates/technical-notes.md` | ✅ FIX | C1 C3 | Farmilik .NET stack (MediatR, Outbox, AutoMapper) + payment/email/push provider clients presented as the canonical servi |
| 146 | `sdlc/skills/brainstorming/SKILL.md` | — |  | Generic Superpowers brainstorming skill; no FarmManagement/Farmilik coupling. |
| 147 | `sdlc/skills/brainstorming/scripts/frame-template.html` | — |  | Generic Superpowers companion HTML/CSS frame; no project-specific coupling. |
| 148 | `sdlc/skills/brainstorming/scripts/helper.js` | — |  | Generic WebSocket client helper; no project-specific coupling. |
| 149 | `sdlc/skills/brainstorming/scripts/server.cjs` | — |  | Generic WebSocket/HTTP companion server; no project-specific coupling. |
| 150 | `sdlc/skills/brainstorming/scripts/start-server.sh` | — |  | Generic server-launch bash script; no project-specific coupling. |
| 151 | `sdlc/skills/brainstorming/scripts/stop-server.sh` | — |  | Generic server-stop shell script; no project-specific coupling. |
| 152 | `sdlc/skills/brainstorming/spec-document-reviewer-prompt.md` | — |  | Generic spec-reviewer prompt template; stack-agnostic. |
| 153 | `sdlc/skills/brainstorming/visual-companion.md` | — |  | Generic browser visual-brainstorming companion guide; no Farmilik coupling. |
| 154 | `sdlc/skills/building-native-ui/SKILL.md` | — |  | Generic Expo Router UI guidelines; no domain or origin-project coupling. |
| 155 | `sdlc/skills/building-native-ui/references/animations.md` | — |  | Generic Reanimated animations reference. |
| 156 | `sdlc/skills/building-native-ui/references/controls.md` | — |  | Generic native iOS controls reference. |
| 157 | `sdlc/skills/building-native-ui/references/form-sheet.md` | — |  | Generic Expo Router form-sheet reference. |
| 158 | `sdlc/skills/building-native-ui/references/gradients.md` | — |  | Generic CSS gradients reference. |
| 159 | `sdlc/skills/building-native-ui/references/icons.md` | — |  | Generic SF Symbols icons reference. |
| 160 | `sdlc/skills/building-native-ui/references/media.md` | — |  | Generic Expo camera/audio/video media reference. |
| 161 | `sdlc/skills/building-native-ui/references/route-structure.md` | — |  | Generic Expo Router route-structure docs; no project-specific coupling. |
| 162 | `sdlc/skills/building-native-ui/references/search.md` | — |  | Generic Expo/RN search-bar and filtering patterns; nothing project-specific. |
| 163 | `sdlc/skills/building-native-ui/references/storage.md` | — |  | Generic Expo storage (localStorage/sqlite) docs; example data is neutral. |
| 164 | `sdlc/skills/building-native-ui/references/tabs.md` | — |  | Generic NativeTabs docs; no FarmManagement vocab or ADO leftovers. |
| 165 | `sdlc/skills/building-native-ui/references/toolbar-and-headers.md` | — |  | Generic Expo toolbar/header docs using Notes/Mail examples; neutral. |
| 166 | `sdlc/skills/building-native-ui/references/visual-effects.md` | — |  | Generic expo-blur/glass effect docs; nothing project-specific. |
| 167 | `sdlc/skills/building-native-ui/references/webgpu-three.md` | — |  | Generic WebGPU/Three.js Expo guide; neutral examples only. |
| 168 | `sdlc/skills/building-native-ui/references/zoom-transitions.md` | — |  | Generic Expo Router Apple zoom-transition docs; neutral. |
| 169 | `sdlc/skills/bundle-budget/SKILL.md` | — |  | Stack-agnostic bundle-budget skill (size-limit); WEB/MOBILE generic, no coupling. |
| 170 | `sdlc/skills/dead-code-analysis/SKILL.md` | — |  | Stack-agnostic dead-code skill (Knip/madge); generic WEB/MOBILE, no coupling. |
| 171 | `sdlc/skills/dev-workflow/SKILL.md` | — |  | Generic GitHub-native dev-workflow orchestrator; .NET stack listed as one pluggable pack option among go, not baked as T |
| 172 | `sdlc/skills/dev-workflow/commands/architecture-reconciliation.md` | — |  | Stack-agnostic Phase 8 doc-reconciliation; neutral surfaces and .claude/architecture paths, no Farmilik vocab. |
| 173 | `sdlc/skills/dev-workflow/commands/create-pr.md` | — |  | Phase 9 PR creation via gh CLI; main/develop branches, no ADO or domain coupling. |
| 174 | `sdlc/skills/dev-workflow/commands/develop.md` | — |  | Phase 3 dev loop; generic surfaces, GitHub Projects sync, no project-specific content. |
| 175 | `sdlc/skills/dev-workflow/commands/plan.md` | — |  | Phase 2 planning; GitHub-native sub-issues, develop/main defaults, no Area/Iteration Path or domain vocab. |
| 176 | `sdlc/skills/dev-workflow/commands/post-pr-review.md` | — |  | Phase 10 GitHub PR comment posting via gh; comment-only, no project coupling. |
| 177 | `sdlc/skills/dev-workflow/commands/pre-pr-review.md` | — |  | Phase 7 holistic pre-PR review; generic surfaces and thresholds, no Farmilik content. |
| 178 | `sdlc/skills/dev-workflow/commands/pre-test-review.md` | — |  | Phase 4 holistic pre-test review; neutral SERVICE/WEB/MOBILE, no domain or ADO coupling. |
| 179 | `sdlc/skills/dev-workflow/commands/requirements.md` | — |  | Phase 1 requirements; gh issue/project commands, main/develop defaults, no project-specific vocab. |
| 180 | `sdlc/skills/dev-workflow/commands/test.md` | — |  | Phase 6 test loop; generic coverage targets per surface, no Farmilik/ADO artifacts. |
| 181 | `sdlc/skills/dev-workflow/context/orchestrator-rules.md` | ✅ FIX | C1 | Generic orchestrator rules but uses FarmManagement domain file as the sample review comment. |
| 182 | `sdlc/skills/discovery-workflow/SKILL.md` | ✅ FIX | C1 | Uses Farmilik 'Disease detection' as the Epic-boundary example. |
| 183 | `sdlc/skills/discovery-workflow/commands/create.md` | ✅ FIX | C1 | Title-validation examples use FarmManagement disease-detection domain. |
| 184 | `sdlc/skills/discovery-workflow/commands/decompose.md` | ✅ FIX | C1 | Epic-granularity rules illustrated with disease-detection domain examples. |
| 185 | `sdlc/skills/discovery-workflow/commands/explore.md` | ✅ FIX | C1 | Idea-capture example is a farm-health alerts feature. |
| 186 | `sdlc/skills/discovery-workflow/commands/extend.md` | — |  | Generic extend command; attribution footer already genericized. |
| 187 | `sdlc/skills/dotnet-code-quality/SKILL.md` | — |  | Generic .NET Roslynator/Sonar tooling; no FarmManagement coupling. |
| 188 | `sdlc/skills/dotnet-conventions/SKILL.md` | ✅ FIX | C1 C2 C3 C4 C5 C6 | Heavily Farmilik-coupled: doubled 'the', farm-management/marketplace paths, Wolverine/Hangfire, ADO Work Items + /master |
| 189 | `sdlc/skills/expo-dev-client/SKILL.md` | — |  | Generic Expo EAS dev-client build instructions; no project coupling. |
| 190 | `sdlc/skills/expo-doctor/SKILL.md` | — |  | Generic expo-doctor health-check skill; no project coupling. |
| 191 | `sdlc/skills/expo-mobile-conventions/SKILL.md` | ✅ FIX | C1 C2 C6 | Doubled-the grammar artifacts plus FarmManagement domain (persistedFarm/farm switch) and other-repo paths baked in as th |
| 192 | `sdlc/skills/expo-module/SKILL.md` | — |  | Generic stack-agnostic Expo Modules API reference; no project coupling. |
| 193 | `sdlc/skills/expo-module/references/config-plugin.md` | — |  | Generic Expo config-plugin reference; no project coupling. |
| 194 | `sdlc/skills/expo-module/references/create-expo-module.md` | — |  | Generic create-expo-module CLI reference; no project coupling. |
| 195 | `sdlc/skills/expo-module/references/lifecycle.md` | — |  | Generic Expo lifecycle-hooks reference; no project coupling. |
| 196 | `sdlc/skills/expo-module/references/module-config.md` | — |  | Generic expo-module.config.json reference; no project coupling. |
| 197 | `sdlc/skills/expo-module/references/native-module.md` | — |  | Generic native-module DSL reference; no project coupling. |
| 198 | `sdlc/skills/expo-module/references/native-view.md` | — |  | Generic native-view reference; no project coupling. |
| 199 | `sdlc/skills/github-rendering/SKILL.md` | ⚠️ REVIEW | C4 | Only ADO mention is an intentional GitHub-vs-ADO contrast; rest is generic GitHub Issues/Projects rendering. REVIEW per  |
| 200 | `sdlc/skills/go-code-quality/SKILL.md` | — |  | Generic Go SERVICE quality-tooling skill (golangci-lint/staticcheck); no project coupling. |
| 201 | `sdlc/skills/go-conventions/SKILL.md` | — |  | Go conventions; kawee-kids is the new generic org, Wolverine/Hangfire only listed as the .NET stack option in a neutral  |
| 202 | `sdlc/skills/grill-me/SKILL.md` | — |  | Generic plan-interview skill; no project coupling |
| 203 | `sdlc/skills/grill-with-docs/ADR-FORMAT.md` | — |  | Generic ADR format; Ordering/Billing examples are neutral |
| 204 | `sdlc/skills/grill-with-docs/CONTEXT-FORMAT.md` | — |  | Generic glossary format; Order/Invoice/Customer examples are neutral |
| 205 | `sdlc/skills/grill-with-docs/SKILL.md` | — |  | Generic grilling-against-docs skill; no project coupling |
| 206 | `sdlc/skills/init-workspace/SKILL.md` | ⚠️ REVIEW | C1 | Generic GitHub init; uses new kawee-kids org & develop/main. Convention-extraction examples mention tenant scoping + pay |
| 207 | `sdlc/skills/maestro-e2e/SKILL.md` | ✅ FIX | C1 | E2E examples are FarmManagement domain: select farm, Kano Demo Farm, inventory movement, bag balances |
| 208 | `sdlc/skills/migration-safety/SKILL.md` | — |  | Generic EF Core migration-safety review; customer-data references are neutral |
| 209 | `sdlc/skills/native-data-fetching/SKILL.md` | — |  | Generic Expo networking skill; api.example.com placeholders only |
| 210 | `sdlc/skills/native-data-fetching/references/expo-router-loaders.md` | — |  | Generic Expo Router loaders reference; Stripe/api.example.com placeholders only |
| 211 | `sdlc/skills/observability/SKILL.md` | ⚠️ REVIEW | C5 | BVN/NIN cited in a PII-never-log guardrail — defensible default, not Farmilik-only |
| 212 | `sdlc/skills/pr-review/SKILL.md` | ✅ FIX | C1 C2 C3 C5 | Farmilik .NET arch (Wolverine/outbox), persistedFarm, farm-globe, Marketplace area, Paystack/SendGrid baked into the PR  |
| 213 | `sdlc/skills/react-doctor/SKILL.md` | — |  | Generic React Doctor scan skill; no project-specific coupling |
| 214 | `sdlc/skills/react-turbo-conventions/SKILL.md` | ✅ FIX | C1 C2 C6 | Doubled-the grammar artifacts plus Farmilik repo paths: /Web/, farm-management, marketplace, Farm Globe app |
| 215 | `sdlc/skills/requesting-code-review/SKILL.md` | — |  | Generic code-review request skill; no project-specific coupling |
| 216 | `sdlc/skills/requesting-code-review/code-reviewer.md` | — |  | Generic reviewer prompt template; no project-specific coupling |
| 217 | `sdlc/skills/security-scan/SKILL.md` | — |  | Generic Semgrep/Gitleaks/OSV security-scan skill; stack-neutral |
| 218 | `sdlc/skills/tdd/SKILL.md` | — |  | Generic TDD red-green-refactor skill; no project coupling |
| 219 | `sdlc/skills/tdd/deep-modules.md` | — |  | Generic deep-modules design note; no project coupling |
| 220 | `sdlc/skills/tdd/interface-design.md` | — |  | Generic interface-design-for-testability note; no project coupling |
| 221 | `sdlc/skills/tdd/mocking.md` | — |  | Generic TDD mocking guide; payment/email are neutral system-boundary examples. |
| 222 | `sdlc/skills/tdd/refactoring.md` | — |  | Generic refactor-candidates checklist; no project-specific content. |
| 223 | `sdlc/skills/tdd/tests.md` | — |  | Generic good/bad test guidance with neutral cart/checkout/user examples. |
| 224 | `sdlc/skills/upgrading-expo/SKILL.md` | — |  | Generic Expo SDK upgrade process; stack-agnostic, no Farmilik coupling. |
| 225 | `sdlc/skills/upgrading-expo/references/expo-av-to-audio.md` | — |  | Generic expo-av to expo-audio migration reference. |
| 226 | `sdlc/skills/upgrading-expo/references/expo-av-to-video.md` | — |  | Generic expo-av to expo-video migration reference. |
| 227 | `sdlc/skills/upgrading-expo/references/native-tabs.md` | — |  | Generic Expo SDK 55 native tabs migration reference. |
| 228 | `sdlc/skills/upgrading-expo/references/new-architecture.md` | — |  | Generic Expo New Architecture migration reference. |
| 229 | `sdlc/skills/upgrading-expo/references/react-19.md` | — |  | Generic React 19 upgrade reference; no project-specific content. |
| 230 | `sdlc/skills/upgrading-expo/references/react-compiler.md` | — |  | Generic React Compiler setup reference; no project-specific content. |
| 231 | `sdlc/skills/upgrading-expo/references/react-navigation-to-expo-router.md` | — |  | Generic Expo Router / react-navigation migration guide; no project coupling. |
| 232 | `sdlc/tests/run-tests.sh` | ⚠️ REVIEW | C5 | Paystack + BVN/NIN appear only as test fixtures exercising the secret-scan/pii guards — defensible defaults, Farmilik-fl |
| 233 | `sdlc/tests/validate-skills.py` | — |  | Generic plugin structure validator; no project-specific content. |
| 234 | `scripts/check-conflicts.sh` | ⚠️ REVIEW | C4 | Gates on SYSTEM_PULLREQUEST_TARGETBRANCH — an Azure DevOps Pipelines variable in a repo described as a GitHub harness. |
| 235 | `scripts/check-context-bloat.sh` | — |  | Generic per-plugin context-token bloat reporter; no project coupling. |
| 236 | `scripts/install-and-test.sh` | ⚠️ REVIEW | C4 | Uses SYSTEM_PULLREQUEST_TARGETBRANCH (ADO Pipelines var) for PR-scope detection in a GitHub-oriented harness. |
| 237 | `scripts/lib/ensure-tool.sh` | — |  | Generic cross-OS tool-install helper; no project-specific content. |
| 238 | `scripts/validate-plugins.sh` | — |  | Generic marketplace/plugin manifest + frontmatter validator; no project coupling. |
