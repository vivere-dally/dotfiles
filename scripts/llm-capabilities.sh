#!/usr/bin/env bash
# Installs llm-capabilities/ (skills, rules, and the STE gate) into each agent
# harness: Claude Code, Codex, opencode, and pi. Safe to run again. The research
# behind each path is in docs/research/harness-agnostic-capabilities.md.
#
#   build     llm-capabilities/render.ts writes one copy of the skills and rules
#             for each harness into ~/.local/share/llm-capabilities/<harness>/,
#             with the tool names of that harness in place of each placeholder
#   skills    one link for each skill, from the skills directory of each harness
#             to its build: ~/.claude/skills, ~/.codex/skills,
#             ~/.config/opencode/skills, ~/.pi/agent/skills
#   rules     Claude Code reads the rules directory. The other harnesses read
#             one user file each, thus they get AGENTS.md, which joins the rules.
#   STE gate  Claude Code: settings.json of the claude stow package. Codex:
#             hooks.json. opencode: a plugin. pi: an extension. All four call
#             ste/core.ts, which holds each rule.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SRC="$DOTFILES/llm-capabilities"
# The build, and one link to the sources as `src`. Each harness link and each hook
# command goes through this directory, so a move of the repository needs only the
# `src` link again.
STABLE="$HOME/.local/share/llm-capabilities"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

# harness name : its user skills directory
HARNESSES=(
    "claude:$HOME/.claude/skills"
    "codex:$HOME/.codex/skills"
    "opencode:$HOME/.config/opencode/skills"
    "pi:$HOME/.pi/agent/skills"
)

# Links go on single entries, never on these directories: Claude Code writes
# skills/synced, Codex writes skills/.system and config.toml, and opencode writes
# package.json and node_modules into its config directory.
mkdir -p "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.config/opencode/skills" \
    "$HOME/.config/opencode/plugins" "$HOME/.pi/agent/skills" "$HOME/.pi/agent/extensions"

# A link that points into the repository or into the build belongs to this script,
# and it is replaced without a backup. Stow writes relative links, such as
# `../../dotfiles/claude/.claude/skills/<skill>` from the old claude package, thus
# the last two patterns match on the path of the target, not on its prefix.
ours() {
    [[ -L $1 ]] || return 1
    case $(readlink "$1") in
        "$DOTFILES"/* | "$STABLE" | "$STABLE"/* | *dotfiles/claude/* | *llm-capabilities*) return 0 ;;
    esac
    return 1
}

# Moves a real file, or a link that points somewhere else, out of the way. The
# backup keeps it for a diff.
move_aside() {
    local path=$1
    local rel=${path#"$HOME"/}
    mkdir -p "$(dirname "$BACKUP/$rel")"
    mv "$path" "$BACKUP/$rel"
    echo "moved aside: ~/$rel -> $BACKUP/$rel"
}

link() {
    local target=$1 path=$2
    [[ -L $path && $(readlink "$path") == "$target" ]] && return 0
    if ours "$path"; then
        rm "$path"
    elif [[ -e $path || -L $path ]]; then
        move_aside "$path"
    fi
    ln -s "$target" "$path"
}

# An earlier layout made STABLE itself a link to the repository. The build now
# lives there, so it must be a real directory.
[[ -L $STABLE ]] && rm "$STABLE"
mkdir -p "$STABLE"
link "$SRC" "$STABLE/src"

PATH="$HOME/.bun/bin:$PATH" bun "$SRC/render.ts" "$STABLE"

for entry in "${HARNESSES[@]}"; do
    harness=${entry%%:*}
    skills_dir=${entry#*:}
    for skill in "$STABLE/$harness/skills"/*/; do
        name=$(basename "$skill")
        link "$STABLE/$harness/skills/$name" "$skills_dir/$name"
    done
done

link "$STABLE/claude/rules" "$HOME/.claude/rules"
link "$STABLE/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link "$STABLE/opencode/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
link "$STABLE/pi/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"

link "$STABLE/src/adapters/codex/hooks.json" "$HOME/.codex/hooks.json"
link "$STABLE/src/adapters/opencode/ste-gate.ts" "$HOME/.config/opencode/plugins/ste-gate.ts"
link "$STABLE/src/adapters/pi/ste-gate.ts" "$HOME/.pi/agent/extensions/ste-gate.ts"

# Privacy settings. Claude Code gets them from settings.json of the claude stow
# package. Each other harness writes into its own settings file, thus the dotfiles
# never own that file. The research behind each key and each method is in
# docs/research/privacy-<harness>.md, and the environment half is in .zshrc.

# opencode loads config.json before opencode.json and opencode.jsonc. It writes only
# into the first of opencode.jsonc, opencode.json, and config.json that exists, thus
# an opencode.json keeps those writes out of the linked config.json.
OPENCODE_DIR="$HOME/.config/opencode"
if [[ ! -e $OPENCODE_DIR/opencode.json && ! -e $OPENCODE_DIR/opencode.jsonc ]]; then
    printf '{\n  "$schema": "https://opencode.ai/config.json"\n}\n' >"$OPENCODE_DIR/opencode.json"
fi
link "$STABLE/src/settings/opencode/config.json" "$OPENCODE_DIR/config.json"

# pi writes settings.json through a symlink and reformats it, so the managed keys go
# in by a merge. Objects merge key by key and the managed value wins. pi keeps the
# other keys at its next write, and the next run of this script restores a managed
# key that pi changed.
PI_SETTINGS="$HOME/.pi/agent/settings.json"
if [[ -d $PI_SETTINGS.lock ]]; then
    echo "pi holds $PI_SETTINGS.lock. Stop pi, then run this script again." >&2
    exit 1
fi
if ours "$PI_SETTINGS"; then
    rm "$PI_SETTINGS"
elif [[ -L $PI_SETTINGS ]]; then
    move_aside "$PI_SETTINGS"
fi
if [[ -f $PI_SETTINGS ]]; then
    tmp=$(mktemp "$PI_SETTINGS.XXXXXX")
    if jq --indent 2 -s '.[0] * .[1]' "$PI_SETTINGS" "$SRC/settings/pi/settings.json" >"$tmp"; then
        chmod 644 "$tmp"
        mv "$tmp" "$PI_SETTINGS"
    else
        rm -f "$tmp"
        echo "pi: $PI_SETTINGS is not valid JSON, thus it stays as it is." >&2
    fi
else
    install -m 644 "$SRC/settings/pi/settings.json" "$PI_SETTINGS"
fi

# Codex reads /etc/codex/config.toml as its system layer and never writes it. The
# link needs root one time, thus the script only prints the command.
CODEX_SYSTEM=/etc/codex/config.toml
if [[ $(readlink "$CODEX_SYSTEM" 2>/dev/null) != "$STABLE/src/settings/codex/config.toml" ]]; then
    if [[ -e $CODEX_SYSTEM && ! -L $CODEX_SYSTEM ]]; then
        echo "Codex: $CODEX_SYSTEM is a real file. Merge llm-capabilities/settings/codex/config.toml into it by hand."
    else
        echo "Codex: run one time: sudo mkdir -p /etc/codex && sudo ln -sfn \"$STABLE/src/settings/codex/config.toml\" $CODEX_SYSTEM"
    fi
fi

# Last, because a link only goes stale once the build above has replaced what it
# pointed at: a deleted or renamed skill, a link from an earlier layout (the shared
# ~/.agents/skills, the old claude stow package), and so on.
for dir in "$HOME/.claude" "$HOME/.claude/skills" "$HOME/.claude/hooks" "$HOME/.agents/skills" \
    "$HOME/.codex" "$HOME/.codex/skills" "$HOME/.config/opencode" "$HOME/.config/opencode/skills" \
    "$HOME/.config/opencode/plugins" "$HOME/.pi/agent" "$HOME/.pi/agent/skills" "$HOME/.pi/agent/extensions"; do
    [[ -d $dir ]] || continue
    for entry in "$dir"/* "$dir"/.[!.]*; do
        [[ -L $entry && ! -e $entry ]] || continue
        case $(readlink "$entry") in
            "$DOTFILES"/* | "$STABLE"/* | *dotfiles/claude/* | *llm-capabilities*)
                rm "$entry"
                echo "removed stale link: ~/${entry#"$HOME"/}"
                ;;
        esac
    done
done

# Codex runs a user hook only after the user trusts it, and it asks again after
# each change of the hook definition.
echo "Codex: open /hooks one time and trust the STE gate hooks, if Codex does not run them yet."
