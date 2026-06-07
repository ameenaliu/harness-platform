#!/bin/bash
# ---
# name: secrets-guard
# event: PreToolUse Read/Write/Edit + Bash
# scope: video plugin (gated on platform-video-context.md sentinel)
# blocking: true
# description: >
#   Combined secret-scan + sensitive-file guard for the video pipeline.
#   FOUR jobs:
#   (1) On Read: refuse to load .env / .env.* / .secret / .key / .pfx / .pem
#       (keeps secrets out of Claude's prompt context — narrator sources
#       them via bash `set -a; . .env; set +a` into the subshell instead).
#   (2) On Write/Edit: block API-key patterns in content (ElevenLabs sk_,
#       Figma figd_, Cloudflare R2 keys, generic JWT, credential assignments).
#   (3) On Write/Edit: refuse direct writes to .env, .env.*, .secret, .key,
#       .pfx, .pem, serviceAccount*.json (forces user to maintain .env in
#       their text editor).
#   (4) On Bash: detect `git add` / `git commit` of any .env* file in the
#       staged paths and reject.
# ---
#
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)

# Workspace scope guard — only fire inside an initialised video workspace
if [ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-video-context.md" ]; then
    exit 0
fi

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
    echo "BLOCKED by secrets-guard: Python is required but not found." >&2
    exit 2
fi

RESULT=$(echo "$INPUT" | "$PYTHON" <<'PY'
import sys, json, re, os

raw = sys.stdin.read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("ALLOW")
    sys.exit(0)

tool_name = data.get("tool_name", "")
tool_input = data.get("tool_input", {})

# === Case 0: Read of a sensitive file (keeps secret out of prompt context) ===
if tool_name == "Read":
    file_path = tool_input.get("file_path", "")
    if file_path:
        basename = os.path.basename(file_path).lower()
        if (re.match(r'^\.env(\..+)?$', basename) and basename != '.env.example') \
                or re.match(r'.*\.(secret|key|pfx|pem)$', basename) \
                or re.match(r'^serviceaccount.*\.json$', basename):
            print(f"BLOCK_FILE::{file_path}::secrets-protected file — never read its contents into the prompt. Use `set -a; . .env; set +a` in Bash to source the key into the subshell instead, or `grep -q '^ELEVENLABS_API_KEY=.\\+' .env` to check presence without exposing the value")
            sys.exit(0)

# === Case 1: Write/Edit on a sensitive file path ===
if tool_name in ("Write", "Edit"):
    file_path = tool_input.get("file_path", "")
    if file_path:
        basename = os.path.basename(file_path).lower()
        # .env / .env.* / .secret / .key / .pfx / .pem (but allow .env.example)
        if (re.match(r'^\.env(\..+)?$', basename) and basename != '.env.example') \
                or re.match(r'.*\.(secret|key|pfx|pem)$', basename):
            print(f"BLOCK_FILE::{file_path}::secrets-protected file (.env/.secret/.key/.pfx/.pem) — the user maintains these in their text editor; the harness never writes them")
            sys.exit(0)
        if re.match(r'^serviceaccount.*\.json$', basename):
            print(f"BLOCK_FILE::{file_path}::service-account JSON (contains private key)")
            sys.exit(0)

    # === Case 2: Write/Edit content contains an API-key pattern ===
    content = tool_input.get("content") or tool_input.get("new_string") or ""
    if content:
        patterns = [
            (r"\bsk_[a-fA-F0-9]{40,}\b", "ElevenLabs API key shape (sk_…40+ hex)"),
            (r"\bnl-[A-Za-z0-9_-]{20,}\b", "9jaLingo API key shape (nl-…)"),
            (r"\bfigd_[A-Za-z0-9_-]{30,}\b", "Figma personal access token (figd_…)"),
            (r"\bxoxb-[0-9]+-[0-9]+-[A-Za-z0-9]+\b", "Slack bot token"),
            (r"\b[Aa][Ii][Zz][Aa][0-9A-Za-z_-]{35}\b", "Google / Firebase API key (AIza…)"),
            (r"\bey[A-Za-z0-9_-]{20,}\.ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b", "JWT-shaped token"),
            (r"(?im)^[ \t]*(?:password|passwd|pwd|secret|api[_-]?key|client[_-]?secret)\s*[:=]\s*['\"]?[A-Za-z0-9+/=_-]{16,}['\"]?", "credential assignment with literal value"),
            # Cloudflare R2 access key
            (r"\b[A-Za-z0-9]{32}\b\s*[:=]\s*['\"]?[A-Za-z0-9+/=_-]{40,}", "possible R2 access key + secret"),
        ]
        for pat, label in patterns:
            if re.search(pat, content):
                print(f"BLOCK_CONTENT::{label}::{file_path}")
                sys.exit(0)

# === Case 3: Bash command stages or commits .env* ===
if tool_name == "Bash":
    cmd = tool_input.get("command", "")
    if cmd:
        # git add <something .env-ish>
        if re.search(r'\bgit\s+add\s+.*\.env\b', cmd):
            print(f"BLOCK_BASH::git add .env detected::Move .env out of staging — never commit it")
            sys.exit(0)
        # git commit -a (would stage tracked .env if it ever was tracked)
        # git commit with no -m (would open editor; safe enough)
        # For safety, also block git commit -am if .env*  shows in `git status --porcelain | grep '^[AM].*\.env'`
        if re.match(r'^\s*git\s+commit\b', cmd):
            # Best-effort: check if .env* is staged via subprocess
            try:
                import subprocess
                root = os.environ.get("CLAUDE_PROJECT_DIR", ".")
                staged = subprocess.run(
                    ["git", "-C", root, "diff", "--cached", "--name-only"],
                    capture_output=True, text=True, timeout=3
                )
                if staged.returncode == 0:
                    for line in staged.stdout.splitlines():
                        bn = os.path.basename(line).lower()
                        if re.match(r'^\.env(\..+)?$', bn) and bn != '.env.example':
                            print(f"BLOCK_BASH::.env file staged for commit ({line})::Run 'git restore --staged {line}' first, then retry")
                            sys.exit(0)
            except Exception:
                pass

print("ALLOW")
PY
)

VERDICT=$(echo "$RESULT" | head -1)

case "$VERDICT" in
    ALLOW)
        exit 0
        ;;
    BLOCK_FILE::*)
        BODY="${VERDICT#BLOCK_FILE::}"
        FILE_PATH="${BODY%%::*}"
        REASON="${BODY#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS secrets-guard blocked write to $FILE_PATH: $REASON" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by secrets-guard: refusing to Write/Edit $FILE_PATH." >&2
        echo "Reason: $REASON" >&2
        echo "Action: create or edit this file in your text editor; the harness never auto-writes it." >&2
        exit 2
        ;;
    BLOCK_CONTENT::*)
        BODY="${VERDICT#BLOCK_CONTENT::}"
        LABEL="${BODY%%::*}"
        FILE_PATH="${BODY#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS secrets-guard blocked content ($LABEL): $FILE_PATH" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by secrets-guard: $LABEL detected in content being written to $FILE_PATH." >&2
        echo "Action: API keys live in <ProductVideos>/.env (gitignored). Never paste them into source files." >&2
        exit 2
        ;;
    BLOCK_BASH::*)
        BODY="${VERDICT#BLOCK_BASH::}"
        DETAIL="${BODY%%::*}"
        REMEDY="${BODY#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS secrets-guard blocked bash: $DETAIL" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by secrets-guard: $DETAIL." >&2
        echo "Action: $REMEDY" >&2
        exit 2
        ;;
    *)
        echo "BLOCKED by secrets-guard: unexpected internal verdict — failing closed for safety." >&2
        exit 2
        ;;
esac
