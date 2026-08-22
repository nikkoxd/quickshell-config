#!/usr/bin/env bash
# Installer for the island Quickshell config.
#
# Installs the dependencies listed in the README, puts the config where
# Quickshell looks for it, and prints the Hyprland snippet needed to start it.
#
#   Can be run from a clone, or piped straight from the web:
#     curl -fsSL https://raw.githubusercontent.com/nikkoxd/quickshell-config/main/install.sh | bash
#
#   ./install.sh                       # interactive, installs to ~/.config/quickshell/island
#   ./install.sh --name mybar          # run alongside other configs as `qs -c mybar`
#   ./install.sh --skip-deps           # only place the config
#   ./install.sh --skip-localsend      # do not build localsend-cli from source
#   ./install.sh --dry-run             # print what would happen, change nothing

set -euo pipefail

REPO_URL="https://github.com/nikkoxd/quickshell-config.git"
LOCALSEND_REPO="https://codeberg.org/nikkoxd/localsend-cli.git"
LOCALSEND_SRC="${XDG_CACHE_HOME:-$HOME/.cache}/island-install/localsend-cli"
CONFIG_NAME="island"
SKIP_DEPS=0
SKIP_LOCALSEND=0
DRY_RUN=0
ASSUME_YES=0

# Official repos.
PACMAN_PKGS=(
    hyprland
    ffmpeg
    qt6-multimedia-ffmpeg
    python
    libnotify
    bluez-utils
    keepassxc
    cava
    cliphist
    wl-clipboard
    matugen
    git
    go
)

# AUR.
AUR_PKGS=(
    quickshell
    gpu-screen-recorder
    iris-colors
    ttf-phosphor-icons
)

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# Empty when piped into bash (`curl ... | bash`): there is no script file on
# disk, and no repo next to it to install from.
SCRIPT_FILE=""
if [ -f "${BASH_SOURCE[0]:-}" ]; then
    SCRIPT_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
fi

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '\033[2m   would run:\033[0m %s\n' "$*"
        return 0
    fi
    "$@"
}

# Piped into bash, stdin is the script itself, so prompts have to come from the
# terminal. With no terminal at all (a pipe in a script), take the default.
confirm() {
    [ "$ASSUME_YES" -eq 1 ] && return 0
    [ -e /dev/tty ] || return 0
    local reply
    read -r -p "$1 [Y/n] " reply </dev/tty || return 0
    [[ -z "$reply" || "$reply" =~ ^[Yy] ]]
}

usage() {
    if [ -n "$SCRIPT_FILE" ]; then
        # The header comment, minus the shebang, up to the first blank line.
        sed -n '2,/^$/p' "$SCRIPT_FILE" | sed 's/^# \{0,1\}//'
    else
        echo "Options: --name NAME, --skip-deps, --skip-localsend, --dry-run, -y"
    fi
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --name) CONFIG_NAME="${2:?--name needs a value}"; shift 2 ;;
        --skip-deps) SKIP_DEPS=1; shift ;;
        --skip-localsend) SKIP_LOCALSEND=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        -y|--yes) ASSUME_YES=1; shift ;;
        -h|--help) usage ;;
        *) die "unknown option: $1 (try --help)" ;;
    esac
done

[ "$(id -u)" -eq 0 ] && die "do not run this as root; it installs into your home directory"

# The repo this script came with, if it came with one.
SRC_DIR=""
if [ -n "$SCRIPT_FILE" ] && [ -f "$(dirname "$SCRIPT_FILE")/shell.qml" ]; then
    SRC_DIR="$(dirname "$SCRIPT_FILE")"
fi

DEST_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/$CONFIG_NAME"

bold "Quickshell config installer"
echo "  source:      ${SRC_DIR:-$REPO_URL}"
echo "  destination: $DEST_DIR"
echo "  run with:    qs -c $CONFIG_NAME"
[ "$DRY_RUN" -eq 1 ] && warn "dry run: nothing will be changed"
echo

# --- dependencies ---------------------------------------------------------

install_deps() {
    command -v pacman >/dev/null 2>&1 || {
        warn "pacman not found — this installer only knows how to install packages on Arch."
        warn "Install these manually, then re-run with --skip-deps:"
        warn "  ${PACMAN_PKGS[*]} ${AUR_PKGS[*]}"
        return 0
    }

    local helper=""
    for candidate in paru yay; do
        if command -v "$candidate" >/dev/null 2>&1; then
            helper="$candidate"
            break
        fi
    done

    info "Installing packages from the official repos"
    run sudo pacman -S --needed "${PACMAN_PKGS[@]}"

    if [ -z "$helper" ]; then
        warn "No AUR helper (paru/yay) found. Install these from the AUR yourself:"
        warn "  ${AUR_PKGS[*]}"
    else
        info "Installing AUR packages with $helper"
        run "$helper" -S --needed "${AUR_PKGS[@]}"
    fi
}

if [ "$SKIP_DEPS" -eq 1 ]; then
    info "Skipping dependency installation (--skip-deps)"
else
    install_deps
fi

# --- fonts ----------------------------------------------------------------

# --- localsend-cli --------------------------------------------------------

# Not packaged anywhere, so the drag-a-file-onto-the-island feature needs it
# built from source. `make install-user` drops it in ~/.local/bin, no root.
install_localsend() {
    if command -v localsend-cli >/dev/null 2>&1; then
        info "localsend-cli is already installed ($(command -v localsend-cli))"
        return 0
    fi

    for tool in git go make; do
        command -v "$tool" >/dev/null 2>&1 || {
            warn "$tool is not installed — skipping the localsend-cli build."
            warn "Install it and re-run, or build by hand: $LOCALSEND_REPO"
            return 0
        }
    done

    confirm "Build localsend-cli from source? (needed for LocalSend integration)" || {
        info "Skipping localsend-cli."
        return 0
    }

    if [ -d "$LOCALSEND_SRC/.git" ]; then
        info "Updating the localsend-cli clone in $LOCALSEND_SRC"
        run git -C "$LOCALSEND_SRC" pull --ff-only
    else
        info "Cloning localsend-cli into $LOCALSEND_SRC"
        run mkdir -p "$(dirname "$LOCALSEND_SRC")"
        run git clone "$LOCALSEND_REPO" "$LOCALSEND_SRC"
    fi

    info "Building and installing localsend-cli to ~/.local/bin"
    run make -C "$LOCALSEND_SRC" install-user

    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) warn "~/.local/bin is not in your PATH — the shell will not find localsend-cli." ;;
    esac
}

if [ "$SKIP_LOCALSEND" -eq 1 ]; then
    info "Skipping the localsend-cli build (--skip-localsend)"
else
    install_localsend
fi

# --- place the config -----------------------------------------------------

place_config() {
    if [ "$SRC_DIR" = "$DEST_DIR" ]; then
        info "Config is already at $DEST_DIR"
        return 0
    fi

    if [ -e "$DEST_DIR" ] || [ -L "$DEST_DIR" ]; then
        warn "$DEST_DIR already exists."
        confirm "Replace it? (the existing directory will be removed)" || {
            info "Leaving it alone."
            return 0
        }
        run rm -rf "$DEST_DIR"
    fi

    run mkdir -p "$(dirname "$DEST_DIR")"

    # Running from a clone: symlink it, so `git pull` in the clone updates the
    # live config. Piped into bash: clone the repo straight into place, so the
    # repo is only ever fetched once.
    if [ -n "$SRC_DIR" ]; then
        info "Linking $SRC_DIR to $DEST_DIR"
        run ln -s "$SRC_DIR" "$DEST_DIR"
    else
        command -v git >/dev/null 2>&1 || die "git is not installed, and it is needed to fetch the config"
        info "Cloning $REPO_URL into $DEST_DIR"
        run git clone "$REPO_URL" "$DEST_DIR"
    fi
}

place_config

# Config/ is gitignored: every JSON file there is recreated from the defaults in
# Core/Config.qml on first run, so there is nothing to copy.

# --- fonts ----------------------------------------------------------------

# Checked after the config is in place: the font name comes out of the defaults
# in Core/Config.qml, since Config/theme.json only exists after the first run.
check_fonts() {
    # Captured rather than piped into grep -q: under `set -o pipefail`, grep
    # exiting early kills fc-list with SIGPIPE and the check reads as a failure.
    local fonts
    fonts="$(fc-list 2>/dev/null || true)"

    if ! grep -qi phosphor <<<"$fonts"; then
        warn "The Phosphor icon font is not installed — every icon in the shell will render as text."
        warn "Install ttf-phosphor-icons, or grab the .ttf files from https://phosphoricons.com/,"
        warn "drop them into ~/.local/share/fonts and run: fc-cache -f"
    fi

    local family
    family="$(grep -oP 'property string fontFamily:\s*"\K[^"]+' "$DEST_DIR/Core/Config.qml" 2>/dev/null || true)"
    if [ -n "$family" ] && ! grep -qiF "$family" <<<"$fonts"; then
        warn "The default UI font \"$family\" is not installed; text will fall back to another font."
        warn "Install it, or change the font in Settings > Theme."
    fi
}

check_fonts

# --- done -----------------------------------------------------------------

echo
bold "Done."
echo
echo "Start it with:"
echo "  qs -c $CONFIG_NAME"
echo
echo "To start it with Hyprland, add to ~/.config/hypr/hyprland.conf:"
echo "  exec-once = qs -c $CONFIG_NAME"
echo
echo "Suggested binds:"
echo "  bind = SUPER, SPACE, exec, qs -c $CONFIG_NAME ipc call bar toggle launcher"
echo "  bind = SUPER, C, exec, qs -c $CONFIG_NAME ipc call bar toggle controlCenter"
echo "  bind = SUPER, W, exec, qs -c $CONFIG_NAME ipc call bar toggle wallpaperSelector"
echo "  bind = SUPER, R, exec, qs -c $CONFIG_NAME ipc call bar toggle recorder"
echo
echo "Logs: qs log -c $CONFIG_NAME"
