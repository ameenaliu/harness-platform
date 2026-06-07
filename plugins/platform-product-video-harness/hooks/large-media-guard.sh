#!/bin/bash
# ---
# name: large-media-guard
# event: PreToolUse Write + Bash on git
# scope: video plugin (gated on platform-video-context.md sentinel)
# blocking: true
# description: >
#   Blocks files larger than MAX_BYTES (default 10 MB) from being written
#   to disk via Write tool OR staged for git commit. Media output (renders,
#   audio) belongs in gitignored directories (out/, _preview/, _cache/,
#   audio/). If a media file genuinely needs to be tracked, the user
#   commits it manually with --no-verify and the team decides separately.
# ---
#
# Exit 0 = allow, Exit 2 = block

if [ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-video-context.md" ]; then
    exit 0
fi

MAX_BYTES="${PRODUCT_VIDEO_MAX_BYTES:-10485760}"  # 10 MB default

INPUT=$(cat)

PYTHON=""
for candidate in python3 python; do
    p=$(command -v "$candidate" 2>/dev/null)
    if [ -n "$p" ] && "$p" --version >/dev/null 2>&1; then
        PYTHON="$p"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    # No Python — fail open; secrets-guard already requires Python and would have caught this.
    exit 0
fi

RESULT=$(echo "$INPUT" | "$PYTHON" <<PY
import sys, json, re, os, subprocess

MAX = $MAX_BYTES

raw = sys.stdin.read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("ALLOW")
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {})

# === Case 1: Write a large content blob ===
if tool_name == "Write":
    content = tool_input.get("content", "")
    file_path = tool_input.get("file_path", "")
    size = len(content.encode("utf-8", errors="ignore"))
    if size > MAX:
        print(f"BLOCK_WRITE::{file_path}::{size}::{MAX}")
        sys.exit(0)

# === Case 2: git add / git commit of a large file ===
if tool_name == "Bash":
    cmd = tool_input.get("command", "")
    if cmd and re.search(r'\bgit\s+(add|commit)\b', cmd):
        try:
            root = os.environ.get("CLAUDE_PROJECT_DIR", ".")
            staged = subprocess.run(
                ["git", "-C", root, "diff", "--cached", "--name-only"],
                capture_output=True, text=True, timeout=3
            )
            if staged.returncode == 0:
                for line in staged.stdout.splitlines():
                    full = os.path.join(root, line)
                    if os.path.exists(full):
                        size = os.path.getsize(full)
                        if size > MAX:
                            print(f"BLOCK_COMMIT::{line}::{size}::{MAX}")
                            sys.exit(0)
        except Exception:
            pass

print("ALLOW")
PY
)

VERDICT=$(echo "$RESULT" | head -1)
HUMAN_SIZE() { python3 -c "n=int('$1'); print(f'{n/1024/1024:.1f} MB')" 2>/dev/null || echo "$1 bytes"; }

case "$VERDICT" in
    ALLOW)
        exit 0
        ;;
    BLOCK_WRITE::*)
        BODY="${VERDICT#BLOCK_WRITE::}"
        FILE="${BODY%%::*}"
        rest="${BODY#*::}"
        SIZE="${rest%%::*}"
        LIMIT="${rest#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS large-media-guard blocked Write: $FILE ($SIZE bytes > $LIMIT)" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by large-media-guard: refusing to Write $FILE ($(HUMAN_SIZE $SIZE) > $(HUMAN_SIZE $LIMIT) limit)." >&2
        echo "Action: rendered media belongs in out/ or _preview/ (gitignored). If you need to write a large file deliberately, raise the limit via PRODUCT_VIDEO_MAX_BYTES env var." >&2
        exit 2
        ;;
    BLOCK_COMMIT::*)
        BODY="${VERDICT#BLOCK_COMMIT::}"
        FILE="${BODY%%::*}"
        rest="${BODY#*::}"
        SIZE="${rest%%::*}"
        LIMIT="${rest#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS large-media-guard blocked git commit: $FILE ($SIZE bytes > $LIMIT)" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by large-media-guard: $FILE is staged for commit but $(HUMAN_SIZE $SIZE) exceeds $(HUMAN_SIZE $LIMIT) limit." >&2
        echo "Action: 'git restore --staged $FILE'. Move large media to a blob store or shared drive and reference by URL." >&2
        exit 2
        ;;
    *)
        # Unknown verdict — fail open to avoid breaking unrelated workflows
        exit 0
        ;;
esac
