#!/usr/bin/env bash
# Links the dotfiles into $HOME. Safe to re-run: --restow also prunes links to
# files that were removed from the repo.
#
# Two stow packages, then the agent capabilities:
#   .       the repo root: shell, nvim, tmux, ... (claude/, llm-capabilities/ and
#           docs/ excluded via .stow-local-ignore)
#   claude  Claude-only settings, agents, skills, and the status line; a package
#           of its own so the repo root never has a .claude/ that Claude Code
#           would load as this repo's project settings
#   llm-capabilities.sh  skills, rules, and the STE gate for Claude Code, Codex,
#           opencode, and pi
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Stow folds a target dir that doesn't exist yet into one symlink. For ~/.claude
# that would route Claude Code's runtime state (sessions, history, the
# claude.ai-synced skills under skills/synced) into the repo, so it must be a
# real dir before stow runs.
mkdir -p "$HOME/.claude/agents" "$HOME/.claude/skills"

# Stow refuses to overwrite files it doesn't own, which is the normal state of
# a machine whose ~/.claude predates this repo. Move whatever is in the way
# into $BACKUP for diffing. Only ~/.claude and its direct subdirs are walked
# into, since those also hold machine-owned entries (projects/, history,
# skills/synced) that must stay; anything deeper is replaced whole.
make_way() {
    local rel=$1
    local src="$DOTFILES/claude/$rel" dst="$HOME/$rel"
    local depth=${rel//[^\/]/}

    if [[ -d $src && -d $dst && ! -L $dst && ${#depth} -le 1 ]]; then
        local child
        for child in "$src"/*; do
            [[ -e $child ]] && make_way "$rel/${child##*/}"
        done
        return
    fi

    [[ -e $dst || -L $dst ]] || return 0
    [[ -L $dst && $(readlink -f "$dst") == "$DOTFILES/claude/"* ]] && return 0

    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$dst" "$BACKUP/$rel"
    echo "moved aside: ~/$rel -> $BACKUP/$rel"
}
make_way .claude

# Karabiner saves karabiner.json as a new file, which replaces a link to the
# file. Only a link to the whole directory survives, and stow makes one only
# when ~/.config/karabiner does not exist.
karabiner="$HOME/.config/karabiner"
if [[ -d $karabiner && ! -L $karabiner ]]; then
    mkdir -p "$BACKUP/.config"
    mv "$karabiner" "$BACKUP/.config/karabiner"
    echo "moved aside: ~/.config/karabiner -> $BACKUP/.config/karabiner"
    restart_karabiner=1
fi

stow --dir="$DOTFILES" --target="$HOME" --restow . claude

# The running Karabiner watches the directory that was moved aside.
if [[ -n ${restart_karabiner:-} ]] && command -v launchctl >/dev/null; then
    launchctl kickstart -k "gui/$(id -u)/org.pqrs.service.agent.karabiner_console_user_server" ||
        echo "restart Karabiner-Elements to load ~/.config/karabiner"
fi

"$DOTFILES/scripts/llm-capabilities.sh"
