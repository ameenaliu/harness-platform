#!/bin/bash
# ---
# name: pii-pattern-guard
# event: UserPromptSubmit
# scope: global (plugin-level)
# blocking: true
# description: >
#   Scans user prompts for PII / credential / customer-data shapes before they
#   reach the model. Hard-blocks and logs to .claude/logs/policy-violations.log.
#   Cannot be silenced by prompt-injection because it runs before the model
#   sees the input. Catches: large UUID clusters (farmer/transaction batches),
#   email clusters, IBAN/PAN patterns, Bearer JWT tokens, .env payload shapes,
#   Nigerian BVN/NIN, Nigerian phone clusters (+234), Paystack secret shapes.
# ---
#
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)

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
    echo "BLOCKED: Python is required for PII pattern detection but was not found." >&2
    exit 2
fi

# All detection happens in Python — easier to write maintainable regex.
RESULT=$(HOOK_INPUT="$INPUT" "$PYTHON" <<'PY'
import os, sys, json, re

# Input arrives via the HOOK_INPUT env var, NOT stdin: a `<<'PY'` heredoc already
# occupies this process's stdin (it is the program source), so sys.stdin is empty
# here. Reading from the env var is what makes detection actually run.
raw = os.environ.get("HOOK_INPUT", "")
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    # Malformed input — let it through; the model will see the raw input.
    print("ALLOW")
    sys.exit(0)

prompt = data.get("prompt", "") or data.get("message", "") or ""

if not prompt:
    print("ALLOW")
    sys.exit(0)

# Patterns to detect (returns the first match's reason)
checks = [
    # 10+ UUIDs in a single prompt — looks like a farmer/transaction batch
    (
        len(re.findall(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b", prompt)) >= 10,
        "10+ UUIDs detected — looks like a farmer or transaction batch",
    ),
    # 5+ distinct email addresses
    (
        len(set(re.findall(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", prompt))) >= 5,
        "5+ distinct email addresses detected — looks like a contact list",
    ),
    # IBAN: starts with 2 letters + 2 digits, then up to 30 alphanumeric
    (
        bool(re.search(r"\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b", prompt)),
        "looks like an IBAN",
    ),
    # PAN: 13–19 digit number with optional spaces/dashes, adjacent to a card-related keyword
    (
        bool(re.search(r"\b(?:\d[ -]?){13,19}\b", prompt))
        and bool(re.search(r"\b(?:visa|mastercard|verve|card|pan|cvv|cvc|exp(?:iry)?)\b", prompt, re.IGNORECASE)),
        "card-number-shaped digits adjacent to a card-related keyword",
    ),
    # Bearer JWT tokens
    (
        bool(re.search(r"\bBearer\s+ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b", prompt)),
        "Bearer JWT token detected",
    ),
    # .env payload — multi-line KEY=VALUE shape with at least 3 keys
    (
        len(re.findall(r"^[A-Z][A-Z0-9_]{2,}=\S+", prompt, re.MULTILINE)) >= 3,
        "looks like a .env file payload (3+ KEY=VALUE lines)",
    ),
    # Connection strings (SQL / Postgres / Azure)
    (
        bool(re.search(r"(?:Server|Data Source|Host)=[^;]+;(?:[^;]*;)*(?:Password|Pwd)=", prompt, re.IGNORECASE))
        or bool(re.search(r"DefaultEndpointsProtocol=https;AccountName=[a-z0-9]+;AccountKey=", prompt)),
        "looks like a connection string with embedded credentials",
    ),
    # Paystack secret/public key shapes (also caught by secret-scan-guard but worth blocking here too)
    (
        bool(re.search(r"\b(?:sk|pk)_(?:live|test)_[A-Za-z0-9]{20,}\b", prompt)),
        "looks like a Paystack key",
    ),
    # SendGrid API key shape
    (
        bool(re.search(r"\bSG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}\b", prompt)),
        "looks like a SendGrid API key",
    ),
    # 5+ distinct Nigerian phone numbers (+234 or 0[789]XX format)
    (
        len(set(re.findall(r"\+?234[789]\d{9}\b|\b0[789]\d{9}\b", prompt))) >= 5,
        "5+ distinct Nigerian phone numbers detected — looks like a contact list",
    ),
    # 3+ Nigerian BVN-shaped numbers (11 digits, often labelled). Conservative: require keyword nearby.
    (
        len(re.findall(r"\b\d{11}\b", prompt)) >= 3
        and bool(re.search(r"\b(BVN|NIN|bank verification number|national identification)\b", prompt, re.IGNORECASE)),
        "3+ 11-digit numbers adjacent to BVN/NIN keyword — looks like a BVN/NIN batch",
    ),
]

for matched, reason in checks:
    if matched:
        print(f"BLOCK::{reason}")
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
        REASON="${VERDICT#BLOCK::}"
        LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/logs"
        mkdir -p "$LOG_DIR" 2>/dev/null
        TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "$TS pii-pattern-guard blocked: $REASON" >> "$LOG_DIR/policy-violations.log"

        echo "BLOCKED by pii-pattern-guard: $REASON." >&2
        echo "Remove the sensitive content from your prompt and rephrase. Reference data structurally (\"a farmer record\") rather than pasting values." >&2
        exit 2
        ;;
    *)
        # Unrecognised verdict — fail closed for safety.
        echo "BLOCKED by pii-pattern-guard: unexpected internal verdict. Re-run after checking your prompt." >&2
        exit 2
        ;;
esac
