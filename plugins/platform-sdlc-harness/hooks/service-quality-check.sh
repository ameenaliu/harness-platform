#!/bin/bash
# ---
# name: service-quality-check
# event: PreToolUse
# matcher: "Bash"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Pre-commit gate for SERVICE changes. Fires before any `git commit` call. If
#   the staged + working diff touches `service/,
#   runs `dotnet build` (zero warnings enforced) and `dotnet test` against the
#   the repo solution. Exits 2 to block the commit on failure. Otherwise silent.
# ---
set -euo pipefail
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
case "$CMD" in git\ commit*|git\ -C*\ commit*) : ;; *) exit 0 ;; esac

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
SLN=$( find "$ROOT/service" -maxdepth 3 -name "*.sln" 2>/dev/null | head -1 )
[ -z "$SLN" ] && exit 0

CHANGED=$( ( git -C "$ROOT" diff --name-only HEAD 2>/dev/null
             git -C "$ROOT" diff --name-only --cached 2>/dev/null
             git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null ) \
           | grep -E '^service/' | sort -u || true )
[ -z "$CHANGED" ] && exit 0

run() { echo "[service-quality-check] $*" >&2; "$@" 2>&1 || { echo "[service-quality-check] BLOCKED: $* failed. Fix and retry." >&2; exit 2; } ; }

# dotnet build with warnings-as-errors-equivalent: fail if any warning lines appear
echo "[service-quality-check] dotnet build (zero warnings enforced)" >&2
BUILD_OUTPUT=$( dotnet build "$SLN" --nologo 2>&1 )
echo "$BUILD_OUTPUT" >&2
if echo "$BUILD_OUTPUT" | grep -qE 'error\s+\w+\d+:|FAILED'; then
  echo "[service-quality-check] BLOCKED: dotnet build had errors." >&2
  exit 2
fi
if echo "$BUILD_OUTPUT" | grep -qE 'Warning\(s\)\s+[1-9]'; then
  echo "[service-quality-check] BLOCKED: dotnet build had warnings (zero warnings required)." >&2
  exit 2
fi

# Tests — scope by changed test projects when feasible; otherwise full suite
echo "[service-quality-check] dotnet test" >&2
if ! dotnet test "$SLN" --nologo --no-build 2>&1; then
  echo "[service-quality-check] BLOCKED: tests failed." >&2
  exit 2
fi

echo "[service-quality-check] OK" >&2
exit 0
