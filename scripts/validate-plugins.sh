#!/usr/bin/env bash
# Validates all plugin manifests and markdown frontmatter in the marketplace.
#
# Usage: validate-plugins.sh -r <RepoRoot> [-p <plugin1,plugin2>]
#   -r RepoRoot       Path to marketplace repo root (required)
#   -p PluginFilter   Comma-separated plugin names to validate (default: all)
#
# Requires: bash, jq, find.

set -euo pipefail

REPO_ROOT=""
PLUGIN_FILTER=""

while getopts ":r:p:" opt; do
    case $opt in
        r) REPO_ROOT=$OPTARG ;;
        p) PLUGIN_FILTER=$OPTARG ;;
        *) echo "Usage: $0 -r <RepoRoot> [-p <plugin1,plugin2>]" >&2; exit 2 ;;
    esac
done

if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: -r RepoRoot is required" >&2
    exit 2
fi

# shellcheck source=lib/ensure-tool.sh
. "$(dirname "$0")/lib/ensure-tool.sh"
ensure_tool jq jqlang.jq jq jq --required || exit 2

# Build filter set (comma-separated -> array)
declare -a FILTER_SET=()
if [ -n "$PLUGIN_FILTER" ]; then
    IFS=',' read -r -a FILTER_SET <<< "$PLUGIN_FILTER"
    echo "[validate] Scoped to changed plugins: ${FILTER_SET[*]}"
else
    echo "[validate] Checking all plugins"
fi

# Returns 0 if $1 is in filter set OR filter set is empty
in_filter() {
    [ ${#FILTER_SET[@]} -eq 0 ] && return 0
    local needle=$1
    local item
    for item in "${FILTER_SET[@]}"; do
        [ "$(echo "$item" | tr -d '[:space:]')" = "$needle" ] && return 0
    done
    return 1
}

ERRORS=()

# ── marketplace.json ──────────────────────────────────────────────────────────
echo "=== Marketplace Manifest ==="
MARKETPLACE_PATH="$REPO_ROOT/.claude-plugin/marketplace.json"

if [ ! -f "$MARKETPLACE_PATH" ]; then
    ERRORS+=("Missing .claude-plugin/marketplace.json")
elif ! jq empty "$MARKETPLACE_PATH" 2>/dev/null; then
    ERRORS+=("marketplace.json: invalid JSON")
    echo "  ✗ marketplace.json"
else
    echo "  ✓ marketplace.json"

    # Required top-level fields
    for field in name plugins; do
        if [ "$(jq -r --arg f "$field" 'has($f)' "$MARKETPLACE_PATH")" != "true" ]; then
            ERRORS+=("marketplace.json: missing required field '$field'")
        fi
    done

    echo ""
    echo "=== Plugin Source Paths ==="
    # For each plugin, extract source. Can be a string OR an object.
    while IFS= read -r entry; do
        plugin_name=$(echo "$entry" | jq -r '.name')
        source_type=$(echo "$entry" | jq -r '.source | type')

        local_path=""
        if [ "$source_type" = "string" ]; then
            raw=$(echo "$entry" | jq -r '.source')
            local_path=${raw#./}
        elif [ "$source_type" = "object" ]; then
            disc=$(echo "$entry" | jq -r '.source.source // ""')
            if [ "$disc" = "git-subdir" ]; then
                raw=$(echo "$entry" | jq -r '.source.path // ""')
                local_path=${raw#./}
            fi
        fi

        if [ -z "$local_path" ]; then
            disc_label=$(echo "$entry" | jq -r '.source.source // "unknown"')
            echo "  ⚠ $plugin_name: non-local source ($disc_label) — skipping local existence check"
            continue
        fi

        if [ -d "$REPO_ROOT/$local_path" ]; then
            echo "  ✓ $plugin_name -> $local_path"
        else
            ERRORS+=("marketplace.json: plugin '$plugin_name' source path '$local_path' does not exist")
            echo "  ✗ $plugin_name -> $local_path (NOT FOUND)"
        fi
    done < <(jq -c '.plugins[]' "$MARKETPLACE_PATH")
fi

# ── plugin.json per plugin ────────────────────────────────────────────────────
echo ""
echo "=== Plugin Manifests ==="
PLUGINS_ROOT="$REPO_ROOT/plugins"

if [ -d "$PLUGINS_ROOT" ]; then
    for plugin_dir in "$PLUGINS_ROOT"/*/; do
        [ -d "$plugin_dir" ] || continue
        plugin_name=$(basename "$plugin_dir")
        in_filter "$plugin_name" || continue

        plugin_json="$plugin_dir/.claude-plugin/plugin.json"
        if [ ! -f "$plugin_json" ]; then
            ERRORS+=("$plugin_name: missing .claude-plugin/plugin.json")
            echo "  ✗ $plugin_name: missing .claude-plugin/plugin.json"
            continue
        fi

        if ! jq empty "$plugin_json" 2>/dev/null; then
            ERRORS+=("$plugin_name/plugin.json: invalid JSON")
            echo "  ✗ $plugin_name/plugin.json"
            continue
        fi

        echo "  ✓ $plugin_name/plugin.json"

        for field in name version description; do
            if [ "$(jq -r --arg f "$field" 'has($f)' "$plugin_json")" != "true" ]; then
                ERRORS+=("$plugin_name/plugin.json: missing required field '$field'")
            fi
        done

        version=$(jq -r '.version // empty' "$plugin_json")
        if [ -n "$version" ] && [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+ ]]; then
            ERRORS+=("$plugin_name/plugin.json: version '$version' does not match semver x.y.z")
        fi
    done
fi

# ── Frontmatter in commands / agents / skills ─────────────────────────────────
echo ""
echo "=== Markdown Frontmatter ==="
has_any_md=false

for plugin_dir in "$PLUGINS_ROOT"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name=$(basename "$plugin_dir")
    in_filter "$plugin_name" || continue

    for type in commands agents skills; do
        type_dir="$plugin_dir/$type"
        [ -d "$type_dir" ] || continue

        # Top-level .md files only (consistent with the original PS1)
        for md in "$type_dir"/*.md; do
            [ -f "$md" ] || continue
            has_any_md=true
            md_name=$(basename "$md")
            rel="$plugin_name/$type/$md_name"

            first_line=$(head -1 "$md")
            if [ "$first_line" != "---" ]; then
                ERRORS+=("$rel: missing YAML frontmatter (--- block)")
                echo "  ✗ $rel: missing frontmatter"
            elif [ "$type" = "commands" ] && ! grep -qE '^description:' "$md"; then
                ERRORS+=("$rel: commands must have 'description:' in frontmatter")
                echo "  ✗ $rel: missing description in frontmatter"
            else
                echo "  ✓ $rel"
            fi
        done
    done
done

[ "$has_any_md" = false ] && echo "  (no markdown resources found)"

# ── Result ────────────────────────────────────────────────────────────────────
echo ""
if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "VALIDATION FAILED — ${#ERRORS[@]} error(s):"
    printf '  ✗ %s\n' "${ERRORS[@]}"
    exit 1
fi

echo "All manifest validations passed."
exit 0
