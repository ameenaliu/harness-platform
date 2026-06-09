#!/bin/bash
# ---
# name: sensitive-file-guard
# event: PreToolUse
# matcher: "Write|Edit"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Blocks writes/edits to potentially sensitive files: .env / .env.* / .secret /
#   .key / .pfx / .pem / serviceAccount*.json / appsettings.{Production,Local}.json.
#   Catches catastrophic failure modes where the model would accidentally commit
#   credentials to this repo.
# ---
#
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)

# ─── Workspace scope guard ───────────────────────────────────────────────────
# Only run inside an initialised platform-sdlc workspace. Anchor to
# $CLAUDE_PROJECT_DIR (pinned at session launch by Claude Code to the project
# root) rather than CWD — CWD can drift when a subagent cd-s into a worktree
# and would otherwise cause this guard to silently skip. If the sentinel is
# absent the plugin is not active here — exit silently so this hook does not
# interfere with unrelated Claude Code sessions.
if [ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ]; then
    exit 0
fi

INPUT=$(cat)

# Parse JSON without jq — use python3 or python, whichever is available.
# Require Python — guardrails must not silently degrade.
PYTHON=""
for candidate in python3 python; do
    p=$(command -v "$candidate" 2>/dev/null)
    if [ -n "$p" ] && "$p" --version >/dev/null 2>&1; then
        PYTHON="$p"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "BLOCKED: Python is required for sensitive file protection but was not found." >&2
    echo "Install Python 3 or ensure it is on PATH." >&2
    exit 2
fi

FILE_PATH=$(echo "$INPUT" | "$PYTHON" -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Filename-only check (lowercase basename for case-insensitive match)
BASENAME=$(basename "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

# Extension-style matches
if echo "$BASENAME" | grep -qE '\.(env|env\.[a-z0-9_-]+|secret|key|pfx|pem)$'; then
    REASON=".env/.secret/.key/.pfx/.pem file"
elif echo "$BASENAME" | grep -qE '^serviceaccount.*\.json$'; then
    REASON="Firebase / GCP service-account JSON (contains private key)"
elif echo "$BASENAME" | grep -qE '^appsettings\.(production|local)\.json$'; then
    REASON=".NET appsettings with environment-specific secrets (Production/Local)"
else
    exit 0
fi

echo "BLOCKED: Refusing to write a potentially sensitive file: $FILE_PATH ($REASON)" >&2
echo "Credentials, keys, and secrets must never be committed to this repo." >&2
echo "Use Azure Key Vault / EAS secrets / .env (gitignored) / dotnet user-secrets instead." >&2
exit 2
