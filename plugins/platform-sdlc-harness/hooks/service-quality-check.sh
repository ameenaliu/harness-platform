#!/bin/bash
# ---
# name: service-quality-check
# event: PreToolUse
# matcher: "Bash"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Pre-commit gate for SERVICE changes. Fires before any `git commit` call. If
#   the staged + working diff touches `service/`, detects the SERVICE stack
#   (dotnet via *.sln, or go via go.mod — see packs/registry.json) and runs that
#   stack's build + test gate: dotnet → `dotnet build` (zero warnings) +
#   `dotnet test`; go → `go build ./...` + `golangci-lint run` + `go test ./...`.
#   Exits 2 to block the commit on failure. Otherwise silent.
# ---
set -euo pipefail
[ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ] && exit 0

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || echo "")
case "$CMD" in git\ commit*|git\ -C*\ commit*) : ;; *) exit 0 ;; esac

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -d "$ROOT/service" ] || exit 0

CHANGED=$( ( git -C "$ROOT" diff --name-only HEAD 2>/dev/null
             git -C "$ROOT" diff --name-only --cached 2>/dev/null
             git -C "$ROOT" ls-files --others --exclude-standard 2>/dev/null ) \
           | grep -E '^service/' | sort -u || true )
[ -z "$CHANGED" ] && exit 0

# --- Detect the SERVICE stack from files present under service/ (pack detect globs) ---
GOMOD=$( find "$ROOT/service" -maxdepth 3 -name "go.mod" 2>/dev/null | head -1 )
SLN=$( find "$ROOT/service" -maxdepth 3 -name "*.sln" 2>/dev/null | head -1 )

# --- Go stack ---
if [ -n "$GOMOD" ]; then
  GODIR=$( dirname "$GOMOD" )
  echo "[service-quality-check] Go stack detected ($GODIR)" >&2
  echo "[service-quality-check] go build ./..." >&2
  if ! ( cd "$GODIR" && go build ./... ) >&2 2>&1; then
    echo "[service-quality-check] BLOCKED: go build failed. Fix and retry." >&2
    exit 2
  fi
  if command -v golangci-lint >/dev/null 2>&1; then
    echo "[service-quality-check] golangci-lint run" >&2
    if ! ( cd "$GODIR" && golangci-lint run ) >&2 2>&1; then
      echo "[service-quality-check] BLOCKED: golangci-lint found issues. Fix and retry." >&2
      exit 2
    fi
  else
    echo "[service-quality-check] golangci-lint not installed — skipping lint gate (advisory)." >&2
  fi
  echo "[service-quality-check] go test ./..." >&2
  if ! ( cd "$GODIR" && go test ./... ) >&2 2>&1; then
    echo "[service-quality-check] BLOCKED: go test failed. Fix and retry." >&2
    exit 2
  fi
  echo "[service-quality-check] OK (go)" >&2
  exit 0
fi

# --- .NET stack ---
if [ -n "$SLN" ]; then
  echo "[service-quality-check] .NET stack detected ($SLN)" >&2
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
  echo "[service-quality-check] dotnet test" >&2
  if ! dotnet test "$SLN" --nologo --no-build 2>&1; then
    echo "[service-quality-check] BLOCKED: tests failed." >&2
    exit 2
  fi
  echo "[service-quality-check] OK (dotnet)" >&2
  exit 0
fi

# No recognised SERVICE stack files yet (empty scaffold) — nothing to gate.
exit 0
