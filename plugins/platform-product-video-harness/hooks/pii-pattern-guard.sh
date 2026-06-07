#!/bin/bash
# ---
# name: pii-pattern-guard
# event: UserPromptSubmit
# scope: video plugin (gated on platform-video-context.md sentinel)
# blocking: true
# description: >
#   Scans user prompts for PII / credential / customer-data shapes before
#   they reach the model. Copy of the SDLC harness's pii-pattern-guard,
#   retuned to gate on the video workspace sentinel (platform-video-context.md)
#   so it fires inside the ProductVideos workspace (the SDLC harness's copy
#   gates on platform-context.md and won't fire here).
# ---
#
# Exit 0 = allow, Exit 2 = block (stderr fed back to Claude as error)

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
    echo "BLOCKED: Python is required for PII pattern detection but was not found." >&2
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

prompt = data.get("prompt", "") or data.get("message", "") or ""

if not prompt:
    print("ALLOW")
    sys.exit(0)

checks = [
    (
        len(re.findall(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b", prompt)) >= 10,
        "10+ UUIDs detected — looks like a farmer or transaction batch",
    ),
    (
        len(set(re.findall(r"[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}", prompt))) >= 5,
        "5+ distinct email addresses detected — looks like a contact list",
    ),
    (
        bool(re.search(r"\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b", prompt)),
        "looks like an IBAN",
    ),
    (
        bool(re.search(r"\b(?:\d[ -]?){13,19}\b", prompt))
        and bool(re.search(r"\b(?:visa|mastercard|verve|card|pan|cvv|cvc|exp(?:iry)?)\b", prompt, re.IGNORECASE)),
        "card-number-shaped digits adjacent to a card-related keyword",
    ),
    (
        bool(re.search(r"\bBearer\s+ey[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\b", prompt)),
        "Bearer JWT token detected",
    ),
    (
        len(re.findall(r"^[A-Z][A-Z0-9_]{2,}=\S+", prompt, re.MULTILINE)) >= 3,
        "looks like a .env file payload (3+ KEY=VALUE lines)",
    ),
    (
        bool(re.search(r"\bsk_[a-fA-F0-9]{40,}\b", prompt)),
        "looks like an ElevenLabs API key — paste into <ProductVideos>/.env via your editor instead",
    ),
    (
        bool(re.search(r"\bnl-[A-Za-z0-9_-]{20,}\b", prompt)),
        "looks like a 9jaLingo API key — paste into <ProductVideos>/.env via your editor instead",
    ),
    (
        bool(re.search(r"\bfigd_[A-Za-z0-9_-]{30,}\b", prompt)),
        "looks like a Figma personal access token — paste into .env via your editor",
    ),
    (
        len(set(re.findall(r"\+?234[789]\d{9}\b|\b0[789]\d{9}\b", prompt))) >= 5,
        "5+ distinct Nigerian phone numbers detected — looks like a contact list",
    ),
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
        echo "BLOCKED by pii-pattern-guard: unexpected internal verdict. Re-run after checking your prompt." >&2
        exit 2
        ;;
esac
