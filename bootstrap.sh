#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ============================================================================
# System packages
# ============================================================================
# Upgrade before installing: fresh Fedora media is months stale, and installing onto an
# un-upgraded base is how you end up with new packages pulling new deps against old core
# libraries. update-all runs a second upgrade at the end, which is then a near-free no-op
# -- `dnf upgrade` is idempotent, so this is not the kind of duplication that rots.
#
# The sideloaded Proton RPMs did used to live here, and those genuinely were: a URL is
# data, and a stale copy in the file nobody runs fails silently. They are update-all's
# job now, and it installs them on a fresh box too.
echo "==> Updating dnf and installing packages..."
sudo dnf upgrade -y --refresh
sudo dnf install -y \
    sway swayidle swaylock swaybg \
    kitty \
    mako \
    i3status \
    grim slurp wtype wl-clipboard wf-recorder ffmpeg \
    xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr \
    distrobox git procs trash-cli clang kanshi

# ============================================================================
# Fonts
# ============================================================================
echo "==> Installing fonts..."
mkdir -p "$HOME/.local/share/fonts"
for font in "$DOTFILES"/fonts/*; do
    dest="$HOME/.local/share/fonts/$(basename "$font")"
    if [ -f "$dest" ]; then
        echo "OK    fonts/$(basename "$font")"
    else
        cp "$font" "$dest"
        echo "COPY  fonts/$(basename "$font")"
    fi
done
fc-cache -f

# ============================================================================
# Symlinks
# ============================================================================
echo "==> Linking config files..."

files=(
    .bashrc
    .bash_profile
    .gitignore_global
    .config/git/config
    .config/sway/config
    .config/kitty/kitty.conf
    .config/kitty/current-theme.conf
    .config/helix/config.toml
    .config/mako/config
    .config/i3status/config
    .config/mise/config.toml
    .config/gh/config.yml
    .config/glow/glow.yml
    .config/btop/btop.conf
    .config/gtk-3.0/settings.ini
    .config/gtk-4.0/settings.ini
    .config/kanshi/config
    .config/swaylock/config
    .config/mpv/mpv.conf
    .local/bin/fzf-launcher
    .local/bin/fzf-launcher-preview
    .local/bin/dmenu-new-workspace
    .local/bin/random-wallpaper
    .local/bin/set-wallpaper
    .local/bin/save-wallpaper
    .local/bin/capture-menu
    .local/bin/cliphist-fzf
    .local/bin/toggle-terminal
    .local/bin/new-terminal
    .local/bin/update-all
    .ssh/config
    .config/systemd/user/ssh-agent.service
    .config/systemd/user/trash-purge.service
    .config/systemd/user/trash-purge.timer
    .claude/CLAUDE.md
    .claude/skills/fedora/SKILL.md
)

for f in "${files[@]}"; do
    src="$DOTFILES/$f"
    dest="$HOME/$f"

    if [ ! -f "$src" ]; then
        echo "SKIP  $f (not in repo)"
        continue
    fi

    mkdir -p "$(dirname "$dest")"

    if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
        echo "OK    $f"
        continue
    fi

    if [ -e "$dest" ]; then
        mv "$dest" "$dest.bak"
        echo "BACK  $f -> $dest.bak"
    fi

    ln -sf "$src" "$dest"
    echo "LINK  $f"
done

# ============================================================================
# SSH agent (systemd user service)
# ============================================================================
echo "==> Enabling SSH agent..."
systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service
systemctl --user enable --now trash-purge.timer

# ============================================================================
# mise
# ============================================================================
# From the official mise RPM repo rather than `curl https://mise.run | sh`: packages are
# GPG-signed, and dnf then keeps mise itself current. The curl installer has no
# self-update path wired into anything, so mise silently rotted five months behind --
# which broke tool installs, since a stale mise carries a stale aqua registry.
if [ ! -f /etc/yum.repos.d/mise.repo ]; then
    echo "==> Adding mise repo..."
    sudo cp "$DOTFILES/system/mise.repo" /etc/yum.repos.d/mise.repo
fi
sudo dnf install -y mise

echo "==> Installing mise tools..."
mise trust "$DOTFILES/.config/mise/config.toml"
mise install

# ============================================================================
# Rust
# ============================================================================
# Nothing here installed rustup before, so `cargo install` below would abort a fresh
# bootstrap under `set -e`. It only ever worked because rustup had been installed by
# hand, off the books.
#
# bootstrap does not source .bashrc, so the XDG paths it exports are not in scope here.
# They have to be set explicitly or rustup drops the toolchain in ~/.cargo and ~/.rustup,
# which is not where anything else on this system looks for it.
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export CARGO_HOME="$XDG_DATA_HOME/cargo"
export PATH="$CARGO_HOME/bin:$PATH"

# Fedora's `rustup` package ships /usr/bin/rustup-init -- the installer, not the tool.
# Running it puts the real rustup/cargo/rustc under CARGO_HOME, which is the same end
# state as upstream's `curl https://sh.rustup.rs | sh`, minus piping an unsigned script
# to a shell. rustup then self-updates from there, as usual.
echo "==> Installing rustup..."
sudo dnf install -y rustup
if ! command -v rustup &>/dev/null; then
    rustup-init -y --no-modify-path   # .bashrc already owns PATH
fi

# ============================================================================
# autotiling-rs
# ============================================================================
if [ ! -f "$CARGO_HOME/bin/autotiling-rs" ]; then
    echo "==> Installing autotiling-rs..."
    cargo install --git https://github.com/ammgws/autotiling-rs
fi

# ============================================================================
# cliphist (clipboard history)
# ============================================================================
if ! command -v cliphist &>/dev/null; then
    echo "==> Installing cliphist..."
    go install go.senan.xyz/cliphist@latest
    mise reshim
fi

# ============================================================================
# Fedora docs (for /fedora skill)
# ============================================================================
if [ ! -d "$HOME/.local/share/fedora-docs/quick-docs" ]; then
    echo "==> Cloning Fedora quick-docs..."
    git clone --depth 1 https://pagure.io/fedora-docs/quick-docs.git \
        "$HOME/.local/share/fedora-docs/quick-docs"
fi

# ============================================================================
# Cursor theme
# ============================================================================
if [ ! -d "$HOME/.icons/phinger-cursors-gruvbox-material" ]; then
    echo "==> Installing cursor theme..."
    mkdir -p "$HOME/.icons"
    curl -sL https://github.com/rehanzo/phinger-cursors-gruvbox-material/releases/latest/download/phinger-cursors-variants.tar.bz2 \
        | tar xfj - -C "$HOME/.icons"
fi

# ============================================================================
# Proton Pass CLI
# ============================================================================
if ! command -v proton-pass &>/dev/null; then
    echo "==> Installing Proton Pass CLI..."
    curl -fsSL https://proton.me/download/pass-cli/install.sh | bash
fi

# ============================================================================
# Optional: greetd + tuigreet login greeter
# ============================================================================
if gum confirm "Install greetd + tuigreet login greeter?"; then
    sudo dnf install -y greetd greetd-tuigreet
    sudo cp "$DOTFILES/system/greetd-config.toml" /etc/greetd/config.toml
    sudo systemctl enable greetd.service
    echo "DONE  greetd configured"
fi

# ============================================================================
# Bring everything current
# ============================================================================
# Deliberately last: update-all is symlinked onto PATH by the symlink step above, and it
# expects mise and rustup to exist. It owns the dnf upgrade, the Proton RPMs, and the
# toolchain updates, so this is also what installs Proton on a fresh box.
#
# `|| true` because this script is `set -e` while update-all exits non-zero if any single
# stage failed. Without it a transient mise hiccup would abort the whole bootstrap at the
# finish line; update-all prints its own summary of what failed.
echo "==> Bringing everything up to date..."
update-all || true

echo
echo "Done. Backed-up files have a .bak extension."
echo "Log out and back in (or 'source ~/.bashrc') to apply."
