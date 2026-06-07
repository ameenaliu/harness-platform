---
name: env-credential-recipes
description: >
  The .env credential-loading pattern used by platform-product-video-harness.
  Format, presence-check protocol, bash source pattern, and the canonical
  "key not found" remediation block that init-video-workspace and narrator
  print verbatim. Single source of truth so both agents print the same
  thing.
disable-model-invocation: true
user-invocable: true
---

# `.env` credential recipes

The plugin uses a `.env` file at `<ProductVideos>/.env` to hold two API keys: `ELEVENLABS_API_KEY` (required for `/generate` Phase 4 + most `/translate` languages) and `NAIJALINGO_API_KEY` (optional — required only when `/translate` is called with the Nigerian languages `yo` / `ha` / `ig` / `pcm`). **The harness never writes `.env`** — the `secrets-guard.sh` hook blocks it. The user creates / maintains it in their text editor.

## `.env` format

```bash
# ProductVideos credentials — keep this file out of git.

# ── ElevenLabs (Phase 4 narrator + /translate en + 31 other langs) ──
# Get at https://elevenlabs.io/app/settings/api-keys
# Starter tier ($5/mo) required for commercial use (posting to social media).
ELEVENLABS_API_KEY=sk_your_real_key_here

# ── 9jaLingo (only required by /translate for yo / ha / ig / pcm) ──
# Get at https://www.9jalingo.org/dashboard
# Optional — when unset, /translate downgrades those 4 languages to captions-only.
NAIJALINGO_API_KEY=nl-your_real_key_here

# Optional future keys:
# FIGMA_PAT=figd_...
# CLOUDFLARE_R2_KEY=...
```

A template `.env.example` is committed to ProductVideos with placeholder values. The user copies it to `.env` and edits the real keys.

### Per-key purpose

| Key | Required for | Optional for |
|---|---|---|
| `ELEVENLABS_API_KEY` | `/generate` Phase 4 narrator (English baseline); `/translate` for `en` + 31 other ElevenLabs-supported languages | — |
| `NAIJALINGO_API_KEY` | `/translate` when ISO codes include `yo` / `ha` / `ig` / `pcm` | All other workflows. Without it, the four Nigerian languages downgrade to captions-only. |

The harness checks each key only when that workflow actually needs it. Missing `ELEVENLABS_API_KEY` halts `/generate` Phase 4 immediately. Missing `NAIJALINGO_API_KEY` halts the affected language(s) in `/translate` Phase T2 only — other languages continue normally.

## Presence check (used by init-video-workspace + narrator)

```bash
if [ ! -f "<ProductVideos>/.env" ] || ! grep -q "^ELEVENLABS_API_KEY=.\+" "<ProductVideos>/.env"; then
  # Print the standardised remediation block below and halt
  exit 2
fi
```

Note `.\+` (escaped `+`) requires at least one character after the `=`. An empty `ELEVENLABS_API_KEY=` fails the check, as it should.

## Bash source pattern (used by narrator at runtime)

```bash
set -a
. "<ProductVideos>/.env"
set +a
```

- `set -a` causes all subsequent variable assignments to be exported.
- `. file` (or `source file`) reads the file in the current shell.
- `set +a` turns off auto-export.

After these 3 lines, `$ELEVENLABS_API_KEY` (and any other vars in `.env`) is exported and available to child processes spawned by this shell (including `curl`).

Use inside the narrator's bash invocations:

```bash
set -a; . "<ProductVideos>/.env"; set +a; \
  curl -s -X POST "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" \
    ...
```

**NEVER `echo $ELEVENLABS_API_KEY`** — not for debugging, not in any file, not in any agent output / status block.

## Canonical "key not found" remediation block (verbatim — print this when key is missing)

```text
⚠ ElevenLabs API key not found.

1. Get your API key at https://elevenlabs.io/app/settings/api-keys
   (Starter tier $5/mo required for commercial use — posting to social media counts.)
2. Create or edit <ProductVideos>/.env in your text editor and add this line:
     ELEVENLABS_API_KEY=sk_your_real_key_here
3. Save the file. Re-run the workflow:
     /platform-product-video-harness:generate <project-folder>
   (or /platform-product-video-harness:init-video-workspace if you're setting up)

Your .env is gitignored AND the secrets-guard hook will refuse any
attempt to commit it. The harness will never auto-write your .env —
you stay in control.
```

The actual `<ProductVideos>` path in step 2 should be substituted with the user's resolved local path (e.g., `/path/to/ProductVideos/.env`).

## What the harness explicitly will NOT do

- **Will NOT** call `Write` or `Edit` on `.env` (blocked by `secrets-guard.sh`)
- **Will NOT** print the key value (not in logs, not in agent status blocks, not in conversation)
- **Will NOT** read the key into Claude's prompt context (`Read` on `.env` is also blocked by `secrets-guard.sh`)
- **Will NOT** silently fall back to environment variables if `.env` is missing — halts with the remediation block instead, so the user knows the canonical location

## `.gitignore` setup

`init-video-workspace` verifies `<ProductVideos>/.gitignore` contains:

```
.env
.env.*
!.env.example
```

If not, halts with `"Add '.env' + '.env.*' (and '!.env.example' to preserve the template) to .gitignore then re-run."`

The `!.env.example` negation keeps the committed template visible.

## Rotating a leaked key

If a key ever lands in git history (despite the hook):

1. Immediately revoke the key at https://elevenlabs.io/app/settings/api-keys
2. Generate a new key, paste into `.env` (replacing the old line)
3. Scrub from git history: `git filter-repo --path .env --invert-paths --force`
4. Force-push (coordinate with anyone else who has cloned)
5. File an incident note in your team's security log

## Multi-developer setup

Each developer maintains their own `.env` locally — the key is per-developer (so usage tracks who generated what).

If a single shared key is preferred (small team, one budget), agree on a shared secret manager (1Password, Bitwarden) and document the retrieval path in `<ProductVideos>/README.md`. The harness doesn't manage that; it only reads `.env`.
