#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# ============================================================================
# System packages
# ============================================================================
echo "==> Updating dnf and installing packages..."
sudo dnf upgrade -y --refresh
sudo dnf install -y \
    sway swayidle swaylock swaybg \
    kitty \
    mako \
    i3status \
    grim slurp wtype wl-clipboard wf-recorder ffmpeg \
    distrobox git procs trash-cli clang kanshi \
    https://proton.me/download/mail/linux/ProtonMail-desktop-beta.rpm \
    https://proton.me/download/PassDesktop/linux/x64/ProtonPass.rpm

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
if ! command -v mise &>/dev/null; then
    echo "==> Installing mise..."
    curl https://mise.run | sh
fi
echo "==> Installing mise tools..."
mise trust "$DOTFILES/.config/mise/config.toml"
mise install

# ============================================================================
# autotiling-rs
# ============================================================================
if [ ! -f "$HOME/.local/share/cargo/bin/autotiling-rs" ]; then
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

echo
echo "Done. Backed-up files have a .bak extension."
echo "Log out and back in (or 'source ~/.bashrc') to apply."
