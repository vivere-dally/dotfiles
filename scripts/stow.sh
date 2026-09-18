#!/usr/bin/env bash
# Links the dotfiles into $HOME. Safe to re-run: --restow also prunes links to
# files that were removed from the repo.
#
# Two stow packages:
#   .       the repo root: shell, nvim, tmux, ... (claude/ excluded via .stow-local-ignore)
#   claude  ~/.claude settings, rules and skills; a package of its own so the
#           repo root never has a .claude/ that Claude Code would load as this
#           repo's project settings
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# Stow folds a target dir that doesn't exist yet into one symlink. For these
# that would route Claude Code's runtime state (sessions, history, the
# claude.ai-synced skills under skills/synced) into the repo, so they must be
# real dirs before stow runs; each skill inside skills/ is then linked whole.
mkdir -p "$HOME/.claude/skills"

# Stow refuses to overwrite files it doesn't own, which is the normal state of
# a machine whose ~/.claude predates this repo. Move whatever is in the way
# into $BACKUP for diffing. Only ~/.claude and its direct subdirs are walked
# into, since those also hold machine-owned entries (projects/, history,
# skills/synced) that must stay; anything deeper, like an existing copy of a
# skill, is replaced whole so the skill dir itself becomes the link.
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

stow --dir="$DOTFILES" --target="$HOME" --restow . claude
