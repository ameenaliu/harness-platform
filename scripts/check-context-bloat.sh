#!/usr/bin/env bash
# Estimates Claude context contribution per plugin and reports bloat by bucket.
#
# Buckets:
#   MAIN SESSION         commands/*.md + skills/**/*.md (except on-demand subfolders)
#   ISOLATED AGENT       agents/*.md
#   CONDITIONAL          README.md + text/config assets + references/rules/documentation
#   IGNORED              binaries, hooks, scripts, etc.
#
# Heuristic: 1 token ≈ 4 characters.
#
# Usage: check-context-bloat.sh -r <RepoRoot> [-w WARN] [-f FAIL] [-p plugins] [-o outfile]
#                               [-c] [-x outlier-tokens]
#   -r RepoRoot               Path to marketplace repo root (required)
#   -w WarnTokensPerPlugin    Warn threshold (default: 10000)
#   -f FailTokensPerPlugin    Fail threshold (default: 100000)
#   -p PluginFilter           Comma-separated plugin names (default: all)
#   -o OutFile                Optional markdown report path
#   -c                        Include conditional tokens in threshold evaluation
#   -x PerFileOutlierTokens   Outlier threshold (default: 2000)
#
# Requires: bash, find, awk.

set -euo pipefail

REPO_ROOT=""
WARN_TOKENS=10000
FAIL_TOKENS=100000
PLUGIN_FILTER=""
OUT_FILE=""
INCLUDE_CONDITIONAL_IN_THRESHOLD=false
PER_FILE_OUTLIER_TOKENS=2000

while getopts ":r:w:f:p:o:cx:" opt; do
    case $opt in
        r) REPO_ROOT=$OPTARG ;;
        w) WARN_TOKENS=$OPTARG ;;
        f) FAIL_TOKENS=$OPTARG ;;
        p) PLUGIN_FILTER=$OPTARG ;;
        o) OUT_FILE=$OPTARG ;;
        c) INCLUDE_CONDITIONAL_IN_THRESHOLD=true ;;
        x) PER_FILE_OUTLIER_TOKENS=$OPTARG ;;
        *) echo "Usage: $0 -r <RepoRoot> [-w WARN] [-f FAIL] [-p plugins] [-o outfile] [-c] [-x outlier]" >&2; exit 2 ;;
    esac
done

if [ -z "$REPO_ROOT" ]; then
    echo "ERROR: -r RepoRoot is required" >&2
    exit 2
fi

PLUGINS_ROOT="$REPO_ROOT/plugins"
if [ ! -d "$PLUGINS_ROOT" ]; then
    echo "ERROR: Plugins root not found: $PLUGINS_ROOT" >&2
    exit 2
fi

declare -a FILTER_SET=()
if [ -n "$PLUGIN_FILTER" ]; then
    IFS=',' read -r -a FILTER_SET <<< "$PLUGIN_FILTER"
    echo "[bloat] Scoped to plugins: ${FILTER_SET[*]}"
else
    echo "[bloat] Checking all plugins"
fi

in_filter() {
    [ ${#FILTER_SET[@]} -eq 0 ] && return 0
    local needle=$1 item
    for item in "${FILTER_SET[@]}"; do
        [ "$(echo "$item" | tr -d '[:space:]')" = "$needle" ] && return 0
    done
    return 1
}

# Returns bucket name for a file: Main | Agent | Conditional | Ignored
bucket_for_file() {
    local rel=$1 ext=$2
    # rel is plugin-root-relative path; lowercase for matching
    local rel_lc
    rel_lc=$(echo "$rel" | tr '[:upper:]' '[:lower:]')

    # plugin-root README.md -> Conditional
    if [ "$rel_lc" = "readme.md" ]; then
        echo Conditional; return
    fi

    # First path segment
    local first_seg=${rel_lc%%/*}

    # On-demand folder anywhere in the path
    local is_on_demand=false
    case "/$rel_lc/" in
        */references/*|*/rules/*|*/documentation/*) is_on_demand=true ;;
    esac

    # agents/*.md -> Agent
    if [ "$first_seg" = "agents" ] && [ "$ext" = "md" ]; then
        echo Agent; return
    fi

    # commands/*.md or skills/**/*.md
    if { [ "$first_seg" = "commands" ] || [ "$first_seg" = "skills" ]; } && [ "$ext" = "md" ]; then
        if [ "$is_on_demand" = true ]; then
            echo Conditional; return
        fi
        echo Main; return
    fi

    # On-demand .md anywhere else -> Conditional
    if [ "$is_on_demand" = true ] && [ "$ext" = "md" ]; then
        echo Conditional; return
    fi

    # assets/<text>: md/txt/json/yaml/yml/config -> Conditional
    if [ "$first_seg" = "assets" ]; then
        case "$ext" in
            md|txt|json|yaml|yml|config) echo Conditional; return ;;
        esac
    fi

    echo Ignored
}

# tokens = ceil(chars / 4)
tokens_from_chars() {
    local chars=$1
    echo $(( (chars + 3) / 4 ))
}

declare -a STAT_PLUGINS=()
declare -A STAT_MAIN_FILES STAT_MAIN_CHARS STAT_AGENT_FILES STAT_AGENT_CHARS STAT_COND_FILES STAT_COND_CHARS

declare -a FB_PLUGIN FB_BUCKET FB_PATH FB_TOKENS FB_CHARS

HAS_WARNINGS=false
HAS_FAILS=false

for plugin_dir in "$PLUGINS_ROOT"/*/; do
    [ -d "$plugin_dir" ] || continue
    plugin_name=$(basename "$plugin_dir")
    in_filter "$plugin_name" || continue
    STAT_PLUGINS+=("$plugin_name")
    STAT_MAIN_FILES[$plugin_name]=0; STAT_MAIN_CHARS[$plugin_name]=0
    STAT_AGENT_FILES[$plugin_name]=0; STAT_AGENT_CHARS[$plugin_name]=0
    STAT_COND_FILES[$plugin_name]=0; STAT_COND_CHARS[$plugin_name]=0

    while IFS= read -r -d '' file; do
        rel_to_plugin=${file#"$plugin_dir"}
        ext=${file##*.}
        ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')

        bucket=$(bucket_for_file "$rel_to_plugin" "$ext")
        [ "$bucket" = "Ignored" ] && continue

        # File size in bytes ≈ chars for ASCII/UTF-8; use wc -c
        chars=$(wc -c < "$file" | tr -d ' ')
        [ "$chars" -gt 0 ] || continue

        case "$bucket" in
            Main)
                STAT_MAIN_FILES[$plugin_name]=$(( STAT_MAIN_FILES[$plugin_name] + 1 ))
                STAT_MAIN_CHARS[$plugin_name]=$(( STAT_MAIN_CHARS[$plugin_name] + chars ))
                ;;
            Agent)
                STAT_AGENT_FILES[$plugin_name]=$(( STAT_AGENT_FILES[$plugin_name] + 1 ))
                STAT_AGENT_CHARS[$plugin_name]=$(( STAT_AGENT_CHARS[$plugin_name] + chars ))
                ;;
            Conditional)
                STAT_COND_FILES[$plugin_name]=$(( STAT_COND_FILES[$plugin_name] + 1 ))
                STAT_COND_CHARS[$plugin_name]=$(( STAT_COND_CHARS[$plugin_name] + chars ))
                ;;
        esac

        tokens=$(tokens_from_chars "$chars")
        rel_to_repo=${file#"$REPO_ROOT/"}
        FB_PLUGIN+=("$plugin_name")
        FB_BUCKET+=("$bucket")
        FB_PATH+=("$rel_to_repo")
        FB_TOKENS+=("$tokens")
        FB_CHARS+=("$chars")
    done < <(find "$plugin_dir" -type f -print0)
done

# Compute totals + thresholds
declare -A STAT_MAIN_TOKENS STAT_AGENT_TOKENS STAT_COND_TOKENS STAT_THRESHOLD STAT_STATUS
TOTAL_MAIN=0; TOTAL_COND=0; TOTAL_AGENT=0; TOTAL_THRESHOLD=0

for p in "${STAT_PLUGINS[@]}"; do
    STAT_MAIN_TOKENS[$p]=$(tokens_from_chars "${STAT_MAIN_CHARS[$p]}")
    STAT_AGENT_TOKENS[$p]=$(tokens_from_chars "${STAT_AGENT_CHARS[$p]}")
    STAT_COND_TOKENS[$p]=$(tokens_from_chars "${STAT_COND_CHARS[$p]}")

    t=${STAT_MAIN_TOKENS[$p]}
    [ "$INCLUDE_CONDITIONAL_IN_THRESHOLD" = true ] && t=$(( t + STAT_COND_TOKENS[$p] ))
    STAT_THRESHOLD[$p]=$t

    if [ "$t" -ge "$FAIL_TOKENS" ]; then
        STAT_STATUS[$p]=FAIL; HAS_FAILS=true
    elif [ "$t" -ge "$WARN_TOKENS" ]; then
        STAT_STATUS[$p]=WARN; HAS_WARNINGS=true
    else
        STAT_STATUS[$p]=OK
    fi

    TOTAL_MAIN=$(( TOTAL_MAIN + STAT_MAIN_TOKENS[$p] ))
    TOTAL_COND=$(( TOTAL_COND + STAT_COND_TOKENS[$p] ))
    TOTAL_AGENT=$(( TOTAL_AGENT + STAT_AGENT_TOKENS[$p] ))
    TOTAL_THRESHOLD=$(( TOTAL_THRESHOLD + t ))
done

# ── Summary table ─────────────────────────────────────────────────────────────
echo ""
echo "=== Context Bloat Report ==="
echo "Threshold mode:"
if [ "$INCLUDE_CONDITIONAL_IN_THRESHOLD" = true ]; then
    echo "  MAIN + CONDITIONAL are evaluated against thresholds"
else
    echo "  MAIN only is evaluated against thresholds"
fi
echo ""
echo "Buckets:"
echo "  MAIN        = commands/ + skills/ (excluding references/, rules/, documentation/)"
echo "  AGENT       = agents/ (isolated context)"
echo "  CONDITIONAL = README.md + assets text/config + on-demand docs"
echo ""
echo "Thresholds: WARN >= $WARN_TOKENS tokens   FAIL >= $FAIL_TOKENS tokens"
echo ""

# Sort plugins by threshold desc
SORTED_PLUGINS=$(
    for p in "${STAT_PLUGINS[@]}"; do
        echo "${STAT_THRESHOLD[$p]} $p"
    done | sort -rn | awk '{print $2}'
)

printf '%-35s %10s %12s %12s %12s %10s %12s %14s %s\n' \
    'Plugin' 'Main.Files' 'Main.Tokens' 'Cond.Files' 'Cond.Tokens' 'Agent.Files' 'Agent.Tokens' 'Thresh.Tokens' 'Status'

while IFS= read -r p; do
    [ -z "$p" ] && continue
    printf '%-35s %10s %12s %12s %12s %10s %12s %14s %s\n' \
        "$p" \
        "${STAT_MAIN_FILES[$p]}" "${STAT_MAIN_TOKENS[$p]}" \
        "${STAT_COND_FILES[$p]}" "${STAT_COND_TOKENS[$p]}" \
        "${STAT_AGENT_FILES[$p]}" "${STAT_AGENT_TOKENS[$p]}" \
        "${STAT_THRESHOLD[$p]}" "${STAT_STATUS[$p]}"
done <<< "$SORTED_PLUGINS"

echo ""
echo "Combined MAIN tokens:        $TOTAL_MAIN"
echo "Combined CONDITIONAL tokens: $TOTAL_COND"
echo "Combined AGENT tokens:       $TOTAL_AGENT"
echo "Combined threshold tokens:   $TOTAL_THRESHOLD"

# ── Per-file outliers ─────────────────────────────────────────────────────────
echo ""
echo "=== Per-File Outliers (> $PER_FILE_OUTLIER_TOKENS tokens) ==="

# Build list of "<tokens>\t<bucket>\t<path>" lines for outlier sort
OUTLIERS=$(
    for i in "${!FB_PLUGIN[@]}"; do
        t=${FB_TOKENS[$i]}
        if [ "$t" -gt "$PER_FILE_OUTLIER_TOKENS" ]; then
            printf '%d\t%s\t%s\n' "$t" "${FB_BUCKET[$i]}" "${FB_PATH[$i]}"
        fi
    done | sort -rn
)

if [ -z "$OUTLIERS" ]; then
    echo "  None — all counted files are within threshold."
else
    while IFS=$'\t' read -r tokens bucket path; do
        b_upper=$(echo "$bucket" | tr '[:lower:]' '[:upper:]')
        printf '  [%s] %s  (~%s tokens)\n' "$b_upper" "$path" "$tokens"
    done <<< "$OUTLIERS"
fi

# ── Top 10 per bucket ─────────────────────────────────────────────────────────
print_top() {
    local bucket_label=$1
    echo ""
    echo "=== Top 10 Largest $bucket_label Files ==="
    local top
    top=$(
        for i in "${!FB_PLUGIN[@]}"; do
            if [ "${FB_BUCKET[$i]}" = "$bucket_label" ]; then
                printf '%d\t%s\n' "${FB_TOKENS[$i]}" "${FB_PATH[$i]}"
            fi
        done | sort -rn | head -10
    )
    if [ -z "$top" ]; then
        echo "  None"
    else
        printf '%-90s %s\n' 'Path' 'Tokens'
        while IFS=$'\t' read -r tokens path; do
            printf '%-90s %s\n' "$path" "$tokens"
        done <<< "$top"
    fi
}

print_top Main
print_top Conditional
print_top Agent

# ── Markdown artifact ─────────────────────────────────────────────────────────
if [ -n "$OUT_FILE" ]; then
    out_dir=$(dirname "$OUT_FILE")
    [ -d "$out_dir" ] || mkdir -p "$out_dir"

    {
        echo "# Context Bloat Report"
        echo ""
        echo "## Threshold mode"
        if [ "$INCLUDE_CONDITIONAL_IN_THRESHOLD" = true ]; then
            echo "- MAIN + CONDITIONAL are included in threshold evaluation"
        else
            echo "- MAIN only is included in threshold evaluation"
        fi
        echo ""
        echo "## Buckets"
        echo '- **MAIN** = `commands/` + `skills/` excluding `references/`, `rules/`, `documentation/`'
        echo '- **AGENT** = `agents/` isolated context'
        echo '- **CONDITIONAL** = `README.md`, text/config files in `assets/`, and on-demand docs'
        echo ""
        echo "| Plugin | Main Files | Main Tokens | Conditional Files | Conditional Tokens | Agent Files | Agent Tokens | Threshold Tokens | Status |"
        echo "|--------|------------|-------------|-------------------|--------------------|-------------|--------------|------------------|--------|"
        while IFS= read -r p; do
            [ -z "$p" ] && continue
            echo "| $p | ${STAT_MAIN_FILES[$p]} | ${STAT_MAIN_TOKENS[$p]} | ${STAT_COND_FILES[$p]} | ${STAT_COND_TOKENS[$p]} | ${STAT_AGENT_FILES[$p]} | ${STAT_AGENT_TOKENS[$p]} | ${STAT_THRESHOLD[$p]} | ${STAT_STATUS[$p]} |"
        done <<< "$SORTED_PLUGINS"
        echo ""
        echo "**Combined MAIN tokens:** $TOTAL_MAIN  "
        echo "**Combined CONDITIONAL tokens:** $TOTAL_COND  "
        echo "**Combined AGENT tokens:** $TOTAL_AGENT  "
        echo "**Combined threshold tokens:** $TOTAL_THRESHOLD"

        if [ -n "$OUTLIERS" ]; then
            echo ""
            echo "## Per-File Outliers"
            while IFS=$'\t' read -r tokens bucket path; do
                echo "- [$bucket] $path (~$tokens tokens)"
            done <<< "$OUTLIERS"
        fi
    } > "$OUT_FILE"

    echo ""
    echo "Report written to: $OUT_FILE"
fi

# ── Exit code ─────────────────────────────────────────────────────────────────
echo ""
if [ "$HAS_FAILS" = true ]; then
    echo "FAIL: one or more plugins exceed the $FAIL_TOKENS token limit."
    exit 1
fi
if [ "$HAS_WARNINGS" = true ]; then
    echo "WARN: one or more plugins exceed $WARN_TOKENS tokens."
    exit 0
fi
echo "OK: all plugins within acceptable context limits."
exit 0
