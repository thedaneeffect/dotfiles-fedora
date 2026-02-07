#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Files/dirs to symlink, relative to $HOME
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
    .local/bin/fzf-launcher
    .local/bin/fzf-launcher-preview
    .local/bin/dmenu-new-workspace
    .local/bin/random-wallpaper
    .local/bin/set-wallpaper
    .local/bin/save-wallpaper
    .local/bin/recover-lightdm
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

echo
echo "Done. Backed-up files have a .bak extension."
echo "Run 'mise install' to install all tools."
