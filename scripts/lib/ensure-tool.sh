# Source this file from a bash script to get the `ensure_tool` function.
#
#   ensure_tool <command> <winget-id> <brew-formula> <linux-pkg> [--required]
#
# Detects the host OS, checks `command -v <command>`, and if missing:
#   1. Prints a one-line miss notice.
#   2. If running interactively (TTY on stdin AND no CI=1 env), asks the user
#      with `read -p` for "[Y/n] Install <command> automatically?".
#   3. On approval, runs the per-OS install command and re-verifies.
#   4. If non-interactive (CI, no TTY), exits 2 immediately with a clear
#      message — never hangs on a prompt.
#   5. With --required and a final miss, exits 2. Without, returns 1 and lets
#      the caller decide.
#
# Usage from another script:
#   . "$(dirname "$0")/lib/ensure-tool.sh"
#   ensure_tool jq jqlang.jq jq jq --required
#
# Supported OSes: Linux (apt/dnf/pacman), macOS (brew), Windows Git Bash
# (winget).

# shellcheck shell=bash

_ensure_tool_detect_os() {
    case "$(uname -s 2>/dev/null)" in
        Linux*)                       echo linux ;;
        Darwin*)                      echo macos ;;
        MINGW*|MSYS*|CYGWIN*|Windows_NT) echo windows ;;
        *)                            echo unknown ;;
    esac
}

_ensure_tool_is_interactive() {
    # CI=1 or non-TTY stdin → non-interactive
    [ -n "${CI:-}" ] && return 1
    [ -t 0 ] || return 1
    return 0
}

_ensure_tool_install() {
    local cmd=$1 winget_id=$2 brew_formula=$3 linux_pkg=$4 os
    os=$(_ensure_tool_detect_os)

    case "$os" in
        windows)
            if ! command -v winget >/dev/null 2>&1; then
                echo "ERROR: winget not found. Install App Installer from Microsoft Store, then retry." >&2
                return 2
            fi
            echo "→ winget install --silent --accept-source-agreements --accept-package-agreements $winget_id"
            winget install --silent --accept-source-agreements --accept-package-agreements "$winget_id"
            ;;
        macos)
            if ! command -v brew >/dev/null 2>&1; then
                echo "ERROR: Homebrew not found. Install from https://brew.sh, then retry." >&2
                return 2
            fi
            echo "→ brew install $brew_formula"
            brew install "$brew_formula"
            ;;
        linux)
            if command -v apt-get >/dev/null 2>&1; then
                echo "→ sudo apt-get update && sudo apt-get install -y $linux_pkg"
                sudo apt-get update && sudo apt-get install -y "$linux_pkg"
            elif command -v dnf >/dev/null 2>&1; then
                echo "→ sudo dnf install -y $linux_pkg"
                sudo dnf install -y "$linux_pkg"
            elif command -v pacman >/dev/null 2>&1; then
                echo "→ sudo pacman -S --noconfirm $linux_pkg"
                sudo pacman -S --noconfirm "$linux_pkg"
            else
                echo "ERROR: No supported package manager found (apt-get/dnf/pacman)." >&2
                return 2
            fi
            ;;
        *)
            echo "ERROR: Unsupported OS for auto-install ($(uname -s))." >&2
            return 2
            ;;
    esac
}

ensure_tool() {
    local cmd=$1 winget_id=$2 brew_formula=$3 linux_pkg=$4 required=${5:-}

    if command -v "$cmd" >/dev/null 2>&1; then
        return 0
    fi

    echo "⚙ '$cmd' not found on PATH."

    if ! _ensure_tool_is_interactive; then
        echo "ERROR: '$cmd' is required and the session is non-interactive (CI or no TTY)." >&2
        echo "       Install it once and retry (Windows: winget install $winget_id ; macOS: brew install $brew_formula ; Linux: sudo apt-get install -y $linux_pkg)." >&2
        [ "$required" = "--required" ] && return 2 || return 1
    fi

    local reply
    read -r -p "Install '$cmd' automatically? [Y/n] " reply
    case "${reply:-Y}" in
        [Yy]|[Yy][Ee][Ss]|"")
            if ! _ensure_tool_install "$cmd" "$winget_id" "$brew_formula" "$linux_pkg"; then
                echo "ERROR: install command exited non-zero. '$cmd' is still missing." >&2
                [ "$required" = "--required" ] && return 2 || return 1
            fi
            # Re-verify
            if ! command -v "$cmd" >/dev/null 2>&1; then
                echo "ERROR: install command succeeded but '$cmd' is still not on PATH (may require shell restart)." >&2
                [ "$required" = "--required" ] && return 2 || return 1
            fi
            echo "✓ '$cmd' installed and on PATH."
            return 0
            ;;
        *)
            echo "Skipped install of '$cmd'." >&2
            [ "$required" = "--required" ] && return 2 || return 1
            ;;
    esac
}
