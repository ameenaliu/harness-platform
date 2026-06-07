#!/usr/bin/env bash
# Idempotently create the platform-sdlc-harness label set on a GitHub repo.
# Safe to re-run: existing labels are updated (colour/description), missing ones created.
#
# Usage:  setup-labels.sh <owner/repo>
#   e.g.  setup-labels.sh kawee-kids/platform
#
# Requires: gh (authed with `repo` scope).

set -euo pipefail

REPO="${1:-}"
if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)"
fi
[ -z "$REPO" ] && { echo "usage: setup-labels.sh <owner/repo>" >&2; exit 1; }

echo "[setup-labels] target repo: $REPO" >&2

# name|color|description  — type:* (work-item kind), surface:* (work axis), status:* (lightweight fallback to Project Status), plus harness/blocked.
LABELS=(
  "type:epic|6F42C1|Epic — top-level initiative"
  "type:feature|0E8A16|Feature — capability within an Epic"
  "type:story|1D76DB|User Story — user-facing increment"
  "type:task|0052CC|Task — technical unit of work"
  "type:bug|D73A4A|Bug — something not working"
  "surface:service|5319E7|Backend / .NET service surface"
  "surface:web|0366D6|Web / React surface"
  "surface:mobile|FBCA04|Mobile / Expo surface"
  "surface:cross-cutting|BFD4F2|Spans multiple surfaces"
  "status:ready|C2E0C6|Refined and ready for development"
  "status:in-dev|FEF2C0|In development"
  "status:in-review|D4C5F9|In code review"
  "status:blocked|B60205|Blocked by an open dependency"
  "platform-sdlc-harness|EDEDED|Managed by the SDLC harness"
)

for entry in "${LABELS[@]}"; do
  IFS='|' read -r name color desc <<< "$entry"
  if gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" >/dev/null 2>&1; then
    echo "[setup-labels] created  $name" >&2
  else
    gh label edit "$name" --repo "$REPO" --color "$color" --description "$desc" >/dev/null 2>&1 \
      && echo "[setup-labels] updated  $name" >&2 \
      || echo "[setup-labels] skipped  $name (could not create or edit)" >&2
  fi
done

echo "[setup-labels] done" >&2
