#!/bin/bash
# ---
# name: attribution-guard
# event: PreToolUse
# matcher: "Write|Edit|Bash"
# scope: global (plugin-level)
# blocking: true
# description: >
#   HARD, CRITICAL RULE. Never let AI/Claude attribution enter the repo — not in
#   commit messages, code, comments, or documents. Blocks a `git commit` whose
#   message carries a Claude/Anthropic "Co-Authored-By" trailer, a
#   noreply@anthropic.com co-author, or a "Generated with Claude Code" / 🤖 line,
#   and blocks any Write/Edit whose content carries the same. Exit 2 blocks
#   (stderr fed back to the agent as an error).
# ---
#
# Exit 0 = allow, Exit 2 = block.

# ─── Workspace scope guard ───────────────────────────────────────────────────
# Only run inside an initialised platform-sdlc workspace (sentinel anchored to
# $CLAUDE_PROJECT_DIR). Absent → plugin not active here → exit silently.
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ] && exit 0

PYTHON=""
for candidate in python3 python; do
    p=$(command -v "$candidate" 2>/dev/null)
    if [ -n "$p" ] && "$p" --version >/dev/null 2>&1; then PYTHON="$p"; break; fi
done
if [ -z "$PYTHON" ]; then
    echo "BLOCKED: Python is required for attribution-guard but was not found." >&2
    exit 2
fi

INPUT=$(cat)

# Build the haystack from the relevant tool fields:
#   - Bash: the command, but ONLY when it is a `git commit` (so we don't block a
#     grep/log that merely searches for these strings).
#   - Write/Edit: the file content / replacement text.
HAYSTACK=$(printf '%s' "$INPUT" | "$PYTHON" -c "
import sys, json, re
d = json.load(sys.stdin)
t = d.get('tool_input', {})
parts = []
cmd = t.get('command', '') or ''
if cmd and re.search(r'\\bgit\\b.*\\bcommit\\b', cmd):
    parts.append(cmd)
parts.append(t.get('content', '') or '')
parts.append(t.get('new_string', '') or '')
print('\n'.join(p for p in parts if p))
" 2>/dev/null || echo "")

[ -z "$HAYSTACK" ] && exit 0

# Banned attribution patterns. Targets Claude / Claude Code / Anthropic
# specifically — a legitimate human "Co-Authored-By:" is NOT blocked.
if printf '%s' "$HAYSTACK" | grep -iqE 'co-authored-by:[[:space:]]*.*(claude|anthropic)' \
   || printf '%s' "$HAYSTACK" | grep -iqE 'noreply@anthropic\.com' \
   || printf '%s' "$HAYSTACK" | grep -iqE 'generated with[[:space:]]+\[?claude' \
   || printf '%s' "$HAYSTACK" | grep -iqE 'generated with claude code' \
   || printf '%s' "$HAYSTACK" | grep -qF '🤖 Generated with'; then
    echo "BLOCKED: AI/Claude attribution is forbidden in this repo (commits, code, comments, docs)." >&2
    echo "Remove any 'Co-Authored-By: Claude/Anthropic' trailer, any 'noreply@anthropic.com' co-author," >&2
    echo "and any 'Generated with Claude Code' / 🤖 line, then re-run without the attribution." >&2
    exit 2
fi

exit 0
