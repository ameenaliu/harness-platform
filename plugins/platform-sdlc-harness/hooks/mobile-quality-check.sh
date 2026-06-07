#!/bin/bash
# ---
# name: mobile-quality-check
# event: PreToolUse
# matcher: "Bash"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Pre-commit gate for MOBILE changes. Fires before any `git commit` call. If
#   the staged + working diff touches `/mobile/{src,__tests__}`,
#   runs `yarn tsc:build`, `yarn lint:fix`, then `yarn test:coverage:check`
#   (full suite if source changed) or the changed tests only. Exits 2 to block
#   the commit on failure. Otherwise silent.
# ---
set -euo pipefail
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ] && exit 0

# Only fire on `git commit`. Parse JSON tool_input.command via python; bail out on anything else.
INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
case "$CMD" in git\ commit*|git\ -C*\ commit*) : ;; *) exit 0 ;; esac

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
MOBILE_DIR="$ROOT/mobile"
[ ! -d "$MOBILE_DIR" ] && exit 0

# Stack-detection: union of staged + working + untracked under mobile/{src,__tests__}/
CHANGED=$( ( git -C "$ROOT" diff --name-only HEAD 2>/dev/null
             git -C "$ROOT" diff --name-only --cached 2>/dev/null
             git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null ) \
           | grep -E '^mobile/(src|__tests__|app)/' | sort -u || true )
[ -z "$CHANGED" ] && exit 0

YARN=$( command -v corepack >/dev/null 2>&1 && echo "corepack yarn" || echo "yarn" )

run() { echo "[mobile-quality-check] $*" >&2; $YARN --cwd "$MOBILE_DIR" "$@" 2>&1 || { echo "[mobile-quality-check] BLOCKED: $* failed. Fix and retry." >&2; exit 2; } ; }

run tsc:build
run lint:fix

# Source changed → full coverage; tests-only changed → run just those
if echo "$CHANGED" | grep -qE '^mobile/'; then
  run test:coverage:check
else
  TESTS=$( echo "$CHANGED" | sed 's|^mobile/||' )
  $YARN --cwd "$MOBILE_DIR" test --coverage=false --runTestsByPath $TESTS 2>&1 \
    || { echo "[mobile-quality-check] BLOCKED: changed tests failed." >&2; exit 2; }
fi

echo "[mobile-quality-check] OK" >&2
exit 0
