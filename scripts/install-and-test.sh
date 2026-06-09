#!/usr/bin/env bash
# Installs plugins from the local marketplace via Claude Code CLI,
# verifies they resolve without conflicts, then cleans up.
#
# In a PR build (GITHUB_BASE_REF set), only plugins whose
# files changed under plugins/ are installed. If no plugin folders changed,
# the install step is skipped entirely.
#
# Usage: install-and-test.sh -r <RepoRoot>
#
# Requires: bash, git, jq, claude CLI. On Linux/macOS also requires `script`
# (util-linux) to allocate a pseudo-TTY for Claude's Ink UI.

set -euo pipefail

REPO_ROOT=""
while getopts ":r:" opt; do
    case $opt in
        r) REPO_ROOT=$OPTARG ;;
        *) echo "Usage: $0 -r <RepoRoot>" >&2; exit 2 ;;
    esac
done

if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: -r RepoRoot is required" >&2
    exit 2
fi

# shellcheck source=lib/ensure-tool.sh
. "$(dirname "$0")/lib/ensure-tool.sh"

# claude CLI is special — npm-distributed, can't be installed via winget/brew/apt
# the same way. Detect + tell the user the canonical install commands, but don't
# auto-run npm install -g without their consent in this script (CI variants may
# not have npm).
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI is not on PATH." >&2
    echo "       Install with: npm install -g @anthropic-ai/claude-code" >&2
    echo "       (Or: curl -fsSL https://claude.ai/install.sh | bash)" >&2
    exit 2
fi

ensure_tool jq jqlang.jq jq jq --required || exit 2

# Claude Code's CLI uses Ink (React terminal UI) which calls process.stdin.setRawMode().
# Without a TTY (e.g. CI), Ink throws "Raw mode is not supported".
# On Linux/macOS: wrap with `script -qec` to allocate a PTY.
# On Git Bash for Windows: run claude directly (mintty has a TTY).
LAST_EXIT=0
invoke_claude() {
    # Run claude with args; capture exit code
    local os_name
    os_name=$(uname -s 2>/dev/null || echo Windows)

    if [ "$os_name" = "Linux" ] || [ "$os_name" = "Darwin" ]; then
        local quoted=""
        local arg
        for arg in "$@"; do
            quoted+=" '$(printf '%s' "$arg" | sed "s/'/'\\\\''/g")'"
        done
        if script --version 2>&1 | grep -qi util-linux; then
            script --quiet --return -c "claude$quoted" /dev/null
        else
            # macOS BSD script syntax
            script -q /dev/null bash -c "claude$quoted"
        fi
    else
        claude "$@"
    fi
    LAST_EXIT=$?
}

# ── Detect changed plugins via git (PR builds only) ──────────────────────────
MARKETPLACE_NAME='harness-platform'
MARKETPLACE_JSON="$REPO_ROOT/.claude-plugin/marketplace.json"

mapfile -t ALL_PLUGINS < <(jq -r '.plugins[].name' "$MARKETPLACE_JSON")

declare -a PLUGINS
PLUGINS=("${ALL_PLUGINS[@]}")

TARGET_BRANCH=${GITHUB_BASE_REF:-}
if [ -n "$TARGET_BRANCH" ]; then
    TARGET_BRANCH=${TARGET_BRANCH#refs/heads/}
    BASE="origin/$TARGET_BRANCH"
    echo "[scope] PR build detected — target branch: $TARGET_BRANCH"
    git -C "$REPO_ROOT" fetch origin "$TARGET_BRANCH" >/dev/null 2>&1 || true

    mapfile -t CHANGED < <(
        git -C "$REPO_ROOT" diff --name-only "$BASE...HEAD" -- plugins/ 2>/dev/null \
            | sed -nE 's|^plugins/([^/]+)/.*|\1|p' \
            | sort -u
    )

    declare -a CHANGED_VALID=()
    for p in "${CHANGED[@]}"; do
        for known in "${ALL_PLUGINS[@]}"; do
            [ "$p" = "$known" ] && CHANGED_VALID+=("$p")
        done
    done

    if [ ${#CHANGED_VALID[@]} -eq 0 ]; then
        echo "[scope] No plugin changes in this PR — skipping install."
        exit 0
    fi

    PLUGINS=("${CHANGED_VALID[@]}")
    echo "[scope] Changed plugins: ${PLUGINS[*]} (of ${#ALL_PLUGINS[@]} total)"
else
    echo "[scope] Not a PR build — installing all plugins."
fi

ERRORS=()

echo ""
echo "=== Plugin Install Test ==="
echo "Plugins to install: ${PLUGINS[*]}"
echo ""

# ── Register local marketplace ────────────────────────────────────────────────
echo "Registering local marketplace: $REPO_ROOT"
invoke_claude plugin marketplace remove "$MARKETPLACE_NAME" >/dev/null 2>&1 || true
invoke_claude plugin marketplace add "$REPO_ROOT"
if [ $LAST_EXIT -ne 0 ]; then
    echo "ERROR: Failed to add marketplace — aborting install test." >&2
    exit 1
fi
echo "✓ Marketplace registered as '$MARKETPLACE_NAME'"
echo ""

# ── Install plugins ───────────────────────────────────────────────────────────
echo "Installing ${#PLUGINS[@]} plugin(s)..."
for plugin in "${PLUGINS[@]}"; do
    echo "  Installing $plugin@$MARKETPLACE_NAME ..."
    invoke_claude plugin install "$plugin@$MARKETPLACE_NAME"
    if [ $LAST_EXIT -ne 0 ]; then
        ERRORS+=("Install failed for '$plugin' (exit $LAST_EXIT)")
        echo "  ✗ $plugin FAILED"
    else
        echo "  ✓ $plugin OK"
    fi
done

# ── Verify presence in plugin list ────────────────────────────────────────────
echo ""
echo "=== Installed Plugin List ==="
INSTALLED_OUTPUT=$(invoke_claude plugin list 2>&1 || true)
echo "$INSTALLED_OUTPUT"

for plugin in "${PLUGINS[@]}"; do
    if printf '%s' "$INSTALLED_OUTPUT" | grep -q -F -- "$plugin"; then
        echo "  ✓ $plugin found in plugin list"
    else
        echo "  ~ $plugin not found in list output (install exit code was the authoritative check)"
    fi
done

# ── Cleanup ───────────────────────────────────────────────────────────────────
echo ""
echo "Cleaning up test installation..."
for plugin in "${PLUGINS[@]}"; do
    invoke_claude plugin uninstall "$plugin@$MARKETPLACE_NAME" >/dev/null 2>&1 || true
done
invoke_claude plugin marketplace remove "$MARKETPLACE_NAME" >/dev/null 2>&1 || true
echo "✓ Cleanup complete"

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "INSTALL TEST FAILED — ${#ERRORS[@]} error(s):"
    printf '  ✗ %s\n' "${ERRORS[@]}"
    exit 1
fi
echo "All ${#PLUGINS[@]} plugin(s) installed and verified successfully."
exit 0
