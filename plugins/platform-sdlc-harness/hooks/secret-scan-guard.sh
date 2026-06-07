#!/bin/bash
# ---
# name: secret-scan-guard
# event: PreToolUse
# matcher: "Write|Edit"
# scope: global (plugin-level)
# blocking: true
# description: >
#   Scans the content being written/edited for the project provider secret-key shapes
#   (Paystack, SendGrid, Firebase, Sentry, OpenAI, Azure storage / SAS, generic JWT,
#   credential assignment with a literal value). Complements sensitive-file-guard
#   (which checks filename only). Logs to .claude/logs/policy-violations.log.
# ---
#
# Exit 0 = allow, Exit 2 = block

if [ ! -f "${CLAUDE_PROJECT_DIR:-.}/.claude/context/platform-context.md" ]; then
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
    echo "BLOCKED: Python is required for secret scanning but was not found." >&2
    exit 2
fi

RESULT=$(echo "$INPUT" | "$PYTHON" <<'PY'
import sys, json, re

raw = sys.stdin.read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("ALLOW")
    sys.exit(0)

tool_input = data.get("tool_input", {})
file_path = tool_input.get("file_path", "")

# Write tool has "content"; Edit has "new_string"
content = tool_input.get("content") or tool_input.get("new_string") or ""

if not content:
    print("ALLOW")
    sys.exit(0)

# the project provider patterns + generic high-confidence secret shapes.
# Pattern, label.
patterns = [
    # Paystack — primary payment provider (70+ hits in the monorepo code)
    (r"\bsk_(?:live|test)_[A-Za-z0-9]{24,}\b",                  "Paystack secret key (sk_live_/sk_test_)"),
    (r"\bpk_(?:live|test)_[A-Za-z0-9]{24,}\b",                  "Paystack public key (pk_live_/pk_test_)"),
    # SendGrid
    (r"\bSG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}\b",           "SendGrid API key"),
    # Firebase / Google API
    (r"\bAIza[0-9A-Za-z_-]{35}\b",                              "Firebase / Google API key (AIza prefix)"),
    # Firebase / GCP service-account private key block
    (r"-----BEGIN (?:RSA |EC |OPENSSH |)PRIVATE KEY-----",      "PEM private key block (service account or SSH)"),
    # Sentry DSN with secret token in the URL
    (r"https://[a-f0-9]{32}@[a-z0-9.-]+\.ingest\.sentry\.io/\d+",
                                                                "Sentry DSN with embedded secret"),
    # OpenAI API key (both sk- and sk-proj- shapes)
    (r"\bsk-(?:proj-)?[A-Za-z0-9_-]{32,}\b",                    "OpenAI API key"),
    # Azure Storage account key
    (r"AccountKey=[A-Za-z0-9+/=]{60,}",                         "Azure Storage AccountKey in connection string"),
    # Azure Storage connection string (full)
    (r"DefaultEndpointsProtocol=https;AccountName=[a-z0-9]+;AccountKey=",
                                                                "Azure Storage connection string"),
    # Azure SAS signature
    (r"[?&]sig=[A-Za-z0-9%+/=]{40,}",                           "Azure SAS signature"),
    # Generic JWT
    (r"\bey[A-Za-z0-9_-]{20,}\.ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b",
                                                                "JWT-shaped token"),
    # Credential assignment with a literal value
    (r"(?im)^[ \t]*(?:password|passwd|pwd|secret|api[_-]?key|client[_-]?secret)\s*[:=]\s*['\"]?[A-Za-z0-9+/=_-]{12,}['\"]?",
                                                                "credential assignment with a literal value"),
]

for pat, label in patterns:
    if re.search(pat, content):
        print(f"BLOCK::{label}::{file_path}")
        sys.exit(0)

print("ALLOW")
PY
)

VERDICT=$(echo "$RESULT" | head -1)

case "$VERDICT" in
    ALLOW)
        exit 0
        ;;
    BLOCK::*)
        # Strip BLOCK::, then split label::file_path
        BODY="${VERDICT#BLOCK::}"
        LABEL="${BODY%%::*}"
        FILE="${BODY#*::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS secret-scan-guard blocked ($LABEL): $FILE" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by secret-scan-guard: $LABEL detected in $FILE." >&2
        echo "Secrets must never be committed. Move the value to Azure Key Vault / EAS secrets / .env (gitignored) / dotnet user-secrets and reference via env var or binding." >&2
        exit 2
        ;;
    *)
        echo "BLOCKED by secret-scan-guard: unexpected internal verdict." >&2
        exit 2
        ;;
esac
