# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# ============================================================================
# XDG Base Directory Specification
# ============================================================================
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

export CARGO_HOME="$XDG_DATA_HOME/cargo"
export GNUPGHOME="$XDG_DATA_HOME/gnupg"
export LESSHISTFILE="$XDG_STATE_HOME/less/history"
export NPM_CONFIG_CACHE="$XDG_CACHE_HOME/npm"
export DOCKER_CONFIG="$XDG_CONFIG_HOME/docker"
export RUSTUP_HOME="$XDG_DATA_HOME/rustup"
export USQL_HISTORY="$XDG_STATE_HOME/usql/history"

# ============================================================================
# Environment
# ============================================================================
export EDITOR=hx
export TERMINAL=kitty
export MANPAGER="bat -l man -p"
export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
ssh-add -l &>/dev/null
[ $? -eq 1 ] && ssh-add 2>/dev/null
export XCURSOR_THEME=phinger-cursors-gruvbox-material
export XCURSOR_SIZE=24
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
export PATH="$XDG_DATA_HOME/cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

# History
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
shopt -s histappend

# ============================================================================
# Tool activation
# ============================================================================
eval "$(mise activate bash)"
eval "$(fzf --bash)"
export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
eval "$(zoxide init --cmd cd bash)"
eval "$(starship init bash)"

# ============================================================================
# Aliases
# ============================================================================

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias .rc='. ~/.bashrc'

# Modern replacements
alias l='eza -la'
alias ls='eza -la'
alias ll='eza -la'
alias la='eza -la'
alias tree='eza --tree'

# Git shortcuts
alias gst='git status'
alias ga='git add'
alias gc='git commit'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log'
alias gcob='git for-each-ref --format="%(refname:lstrip=2)" refs/heads/ refs/remotes/ | sed "s#^origin/##" | sort -u | fzf | xargs git switch'
alias glf='git log --oneline | fzf --preview "git show {1}"'
alias gp='git push'

# mise shortcuts
alias mi='mise'
alias mii='mise install'
alias miu='mise upgrade'
alias mis='mise use'
alias mil='mise list'
alias mio='mise outdated'
alias mt='mise task'

# Utilities
alias grep='grep --color=auto'
alias sudop='sudo env PATH="$PATH"'
alias rc='$EDITOR ~/.bashrc'
alias myip='curl -s ifconfig.me'
alias ports='lsof -i -P -n | grep LISTEN'
alias claude='claude --dangerously-skip-permissions'
alias suspend='systemctl suspend'
alias shutdown='systemctl poweroff'
alias reboot='systemctl reboot'
alias logout='swaymsg exit'

# ============================================================================
# User specific aliases and functions
# ============================================================================
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
