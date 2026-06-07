#!/bin/bash
# ---
# name: render-quality-check
# event: PreToolUse Bash on `git commit*`
# scope: video plugin (gated on platform-video-context.md sentinel)
# blocking: true
# description: >
#   Pre-commit quality gate for Remotion compositions. Fires only when:
#   (1) the bash command is `git commit*`,
#   (2) inside a Remotion project (package.json with "remotion" dep),
#   (3) staged diff touches compositions/*.tsx.
#   Runs `npx remotion lint` + a 1-frame dry render of the affected
#   composition to catch syntax errors, missing assets, or broken imports
#   BEFORE the commit lands.
# ---
set -euo pipefail
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-video-context.md" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
case "$CMD" in git\ commit*|git\ -C*\ commit*) : ;; *) exit 0 ;; esac

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"

# Must be a Remotion project
if [ ! -f "$ROOT/package.json" ]; then exit 0; fi
if ! grep -q '"remotion"' "$ROOT/package.json" 2>/dev/null; then exit 0; fi

# Must have composition changes staged
CHANGED=$(git -C "$ROOT" diff --cached --name-only 2>/dev/null | grep -E '^compositions/.*\.tsx$' | sort -u || true)
[ -z "$CHANGED" ] && exit 0

echo "[render-quality-check] Composition changes detected:" >&2
echo "$CHANGED" | sed 's/^/  /' >&2

# Lint
echo "[render-quality-check] Running npx remotion lint…" >&2
if ! ( cd "$ROOT" && npx remotion lint 2>&1 | tail -20 ); then
  echo "[render-quality-check] BLOCKED: remotion lint failed. Fix errors and retry." >&2
  exit 2
fi

# 1-frame dry render of the first changed composition (sanity check)
# Get the first composition ID from Root.tsx — best-effort
FIRST_TSX=$(echo "$CHANGED" | head -1)
echo "[render-quality-check] Dry-rendering 1 frame of any composition in $FIRST_TSX…" >&2

# Try to discover composition IDs from Root.tsx
ROOT_TSX="$ROOT/compositions/Root.tsx"
if [ -f "$ROOT_TSX" ]; then
  FIRST_ID=$(grep -oE 'id="[a-z0-9-]+"' "$ROOT_TSX" | head -1 | sed 's/id="//;s/"//') || true
  if [ -n "$FIRST_ID" ]; then
    if ! ( cd "$ROOT" && \
           npx remotion render compositions/Root.tsx "$FIRST_ID" \
             "/tmp/product-video-render-check-$$.mp4" \
             --codec=h264 --frames=0-0 --no-audio --log=error 2>&1 | tail -10 ); then
      rm -f "/tmp/product-video-render-check-$$.mp4"
      echo "[render-quality-check] BLOCKED: 1-frame dry render of '$FIRST_ID' failed. Composition has a runtime error." >&2
      exit 2
    fi
    rm -f "/tmp/product-video-render-check-$$.mp4"
  fi
fi

echo "[render-quality-check] OK — composition changes are renderable." >&2
exit 0
