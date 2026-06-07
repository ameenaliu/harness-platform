#!/bin/bash
# ---
# name: web-quality-check
# event: PreToolUse
# matcher: "Bash"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Pre-commit gate for WEB changes. Fires before any `git commit` call. If
#   the staged + working diff touches `web/`, runs `yarn lint`
#   (max-warnings=0) and `yarn test` (or filtered Vitest runs). Exits 2 to
#   block the commit on failure. Otherwise silent.
# ---
set -euo pipefail
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
case "$CMD" in git\ commit*|git\ -C*\ commit*) : ;; *) exit 0 ;; esac

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
WEB_DIR="$ROOT/web"
[ ! -d "$WEB_DIR" ] && exit 0

CHANGED=$( ( git -C "$ROOT" diff --name-only HEAD 2>/dev/null
             git -C "$ROOT" diff --name-only --cached 2>/dev/null
             git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null ) \
           | grep -E '^web/' | sort -u || true )
[ -z "$CHANGED" ] && exit 0

YARN=$( command -v corepack >/dev/null 2>&1 && echo "corepack yarn" || echo "yarn" )

run() { echo "[web-quality-check] $*" >&2; $YARN --cwd "$WEB_DIR" "$@" 2>&1 || { echo "[web-quality-check] BLOCKED: $* failed. Fix and retry." >&2; exit 2; } ; }

# Lint with zero warnings (per .claude/CLAUDE.md: `yarn lint` runs with --max-warnings=0)
run lint

# Tests — full suite; Vitest is fast enough and isolating per-app is brittle pre-commit
# (test suite is not yet established per .claude/rules/web/testing.md — this is a no-op until tests exist)
if $YARN --cwd "$WEB_DIR" run --silent test --help >/dev/null 2>&1; then
  $YARN --cwd "$WEB_DIR" test --run 2>&1 \
    || { echo "[web-quality-check] BLOCKED: tests failed." >&2; exit 2; }
fi

echo "[web-quality-check] OK" >&2
exit 0
