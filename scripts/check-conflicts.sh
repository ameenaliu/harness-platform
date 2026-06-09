#!/usr/bin/env bash
# Detects naming conflicts (commands, agents, skills) across all installed plugins.
# Claude Code loads all plugins simultaneously — duplicate names silently overwrite.
#
# In a PR build (GITHUB_BASE_REF set), only conflicts involving
# a changed plugin fail the build. Pre-existing conflicts between unchanged
# plugins are warnings.
#
# Usage: check-conflicts.sh -r <RepoRoot>
#
# Requires: bash, git, find, grep.

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

# ── Detect changed plugins via git (PR builds only) ──────────────────────────
declare -a CHANGED_PLUGINS=()
TARGET_BRANCH=${GITHUB_BASE_REF:-}

if [ -n "$TARGET_BRANCH" ]; then
    TARGET_BRANCH=${TARGET_BRANCH#refs/heads/}
    git -C "$REPO_ROOT" fetch origin "$TARGET_BRANCH" >/dev/null 2>&1 || true

    while IFS= read -r p; do
        [ -n "$p" ] && CHANGED_PLUGINS+=("$p")
    done < <(
        git -C "$REPO_ROOT" diff --name-only "origin/$TARGET_BRANCH...HEAD" -- plugins/ 2>/dev/null \
            | sed -nE 's|^plugins/([^/]+)/.*|\1|p' \
            | sort -u
    )

    if [ ${#CHANGED_PLUGINS[@]} -eq 0 ]; then
        echo "[conflicts] No plugin changes in this PR — skipping conflict check."
        exit 0
    fi
    echo "[conflicts] PR build — will fail only on conflicts involving: ${CHANGED_PLUGINS[*]}"
else
    echo "[conflicts] Not a PR build — all conflicts will be reported."
fi

involves_changed() {
    # Returns 0 (true) if conflict involves a changed plugin OR no PR scope set
    [ ${#CHANGED_PLUGINS[@]} -eq 0 ] && return 0
    local p1=$1 p2=$2 item
    for item in "${CHANGED_PLUGINS[@]}"; do
        [ "$item" = "$p1" ] && return 0
        [ "$item" = "$p2" ] && return 0
    done
    return 1
}

# ── Build full registry: "type/name" -> first plugin that defines it ──────────
declare -A REGISTRY=()
declare -a CONFLICT_TYPES=()
declare -a CONFLICT_NAMES=()
declare -a CONFLICT_FIRST=()
declare -a CONFLICT_SECOND=()
declare -a CONFLICT_FILES=()

PLUGINS_ROOT="$REPO_ROOT/plugins"

for plugin_dir in "$PLUGINS_ROOT"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name=$(basename "$plugin_dir")

    for type in commands agents skills; do
        type_dir="$plugin_dir/$type"
        [ -d "$type_dir" ] || continue

        # Recurse into subfolders (matches the PS1's -Recurse)
        while IFS= read -r -d '' md; do
            base=$(basename "$md" .md)
            # Frontmatter "name:" wins over filename
            name=$(awk '
                /^---/ {fm = !fm; next}
                fm && /^name:[[:space:]]/ {
                    sub(/^name:[[:space:]]*/, "")
                    sub(/[[:space:]]+$/, "")
                    print
                    exit
                }
            ' "$md")
            [ -z "$name" ] && name=$base

            key="$type/$name"
            if [ -n "${REGISTRY[$key]:-}" ]; then
                CONFLICT_TYPES+=("$type")
                CONFLICT_NAMES+=("$name")
                CONFLICT_FIRST+=("${REGISTRY[$key]}")
                CONFLICT_SECOND+=("$plugin_name")
                CONFLICT_FILES+=("${md#$REPO_ROOT/}")
            else
                REGISTRY[$key]="$plugin_name"
            fi
        done < <(find "$type_dir" -type f -name '*.md' -print0)
    done
done

# ── Print registry ────────────────────────────────────────────────────────────
echo "=== Plugin Resource Registry (${#REGISTRY[@]} resources across all plugins) ==="
# Sort keys for stable output
for key in $(printf '%s\n' "${!REGISTRY[@]}" | sort); do
    printf '  %-50s <- %s\n' "$key" "${REGISTRY[$key]}"
done
echo ""

# ── Report conflicts ──────────────────────────────────────────────────────────
if [ ${#CONFLICT_TYPES[@]} -eq 0 ]; then
    echo "No naming conflicts — all ${#REGISTRY[@]} resources are unique across plugins."
    exit 0
fi

declare -a BLOCKING_IDX=()
declare -a PREEXIST_IDX=()

for i in "${!CONFLICT_TYPES[@]}"; do
    if involves_changed "${CONFLICT_FIRST[$i]}" "${CONFLICT_SECOND[$i]}"; then
        BLOCKING_IDX+=("$i")
    else
        PREEXIST_IDX+=("$i")
    fi
done

if [ ${#PREEXIST_IDX[@]} -gt 0 ]; then
    echo "PRE-EXISTING conflicts (between unchanged plugins — not blocking this PR):"
    for i in "${PREEXIST_IDX[@]}"; do
        echo "  ~ [${CONFLICT_TYPES[$i]}] '${CONFLICT_NAMES[$i]}' — '${CONFLICT_FIRST[$i]}' vs '${CONFLICT_SECOND[$i]}'"
    done
    echo ""
fi

if [ ${#BLOCKING_IDX[@]} -gt 0 ]; then
    echo "NAMING CONFLICTS DETECTED involving changed plugins (${#BLOCKING_IDX[@]}):"
    for i in "${BLOCKING_IDX[@]}"; do
        echo "  ✗ [${CONFLICT_TYPES[$i]}] '${CONFLICT_NAMES[$i]}'"
        echo "      defined in '${CONFLICT_FIRST[$i]}' AND '${CONFLICT_SECOND[$i]}'"
        echo "      conflicting file: ${CONFLICT_FILES[$i]}"
    done
    echo ""
    echo "Fix: rename to disambiguate (this marketplace ships two plugins; any cross-plugin duplicate must be renamed)."
    exit 1
fi

echo "No conflicts involving changed plugins — OK."
exit 0
