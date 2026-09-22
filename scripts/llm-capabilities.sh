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

# Print the absolute, lexically normalized target of a link. This also works for
# a broken link, where realpath cannot resolve the target.
link_target() {
    local path=$1 target remainder part index
    local -a parts=()
    target=$(readlink "$path") || return 1
    if [[ $target == /* ]]; then
        remainder=${target#/}
    else
        remainder="$(cd "$(dirname "$path")" && pwd -P)/$target"
        remainder=${remainder#/}
    fi

    while [[ -n $remainder ]]; do
        if [[ $remainder == */* ]]; then
            part=${remainder%%/*}
            remainder=${remainder#*/}
        else
            part=$remainder
            remainder=
        fi
        case $part in
            '' | .) ;;
            ..)
                index=$((${#parts[@]} - 1))
                (( index >= 0 )) && unset 'parts[index]'
                ;;
            *) parts[${#parts[@]}]=$part ;;
        esac
    done

    printf '/'
    local separator=
    for part in "${parts[@]}"; do
        printf '%s%s' "$separator" "$part"
        separator=/
    done
    printf '\n'
}

# A link that points into the repository or into the build belongs to this script,
# and it is replaced without a backup. Normalize old relative Stow links before
# comparing them so similarly named paths elsewhere are never treated as ours.
ours() {
    [[ -L $1 ]] || return 1
    case $(link_target "$1") in
        "$DOTFILES"/* | "$STABLE" | "$STABLE"/*) return 0 ;;
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

"$HOME/.local/bin/bun" "$SRC/render.ts" "$STABLE"

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
link "$STABLE/src/adapters/pi/ask-user.ts" "$HOME/.pi/agent/extensions/ask-user.ts"
link "$STABLE/src/adapters/pi/cliproxy-provider.ts" "$HOME/.pi/agent/extensions/cliproxy-provider.ts"
link "$STABLE/src/adapters/pi/permission-gate.ts" "$HOME/.pi/agent/extensions/permission-gate.ts"
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

# Pi rewrites its JSON files, so managed keys go in by a merge instead of a link.
# Objects merge key by key and the managed value wins. Pi keeps each other key.
merge_json_file() {
    local live=$1 managed=$2 label=$3 tmp
    if ours "$live"; then
        rm "$live"
    elif [[ -L $live ]]; then
        move_aside "$live"
    fi
    if [[ -f $live ]]; then
        tmp=$(mktemp "$live.XXXXXX")
        if jq --indent 2 -s '.[0] * .[1]' "$live" "$managed" >"$tmp"; then
            chmod 644 "$tmp"
            mv "$tmp" "$live"
        else
            rm -f "$tmp"
            echo "$label: $live is not valid JSON, thus it stays as it is." >&2
        fi
    else
        install -m 644 "$managed" "$live"
    fi
}

PI_SETTINGS="$HOME/.pi/agent/settings.json"
if [[ -d $PI_SETTINGS.lock ]]; then
    echo "pi holds $PI_SETTINGS.lock. Stop pi, then run this script again." >&2
    exit 1
fi
merge_json_file "$PI_SETTINGS" "$SRC/settings/pi/settings.json" pi
merge_json_file "$HOME/.pi/agent/web-search.json" "$SRC/settings/pi/web-search.json" pi-web-access

# The endpoint and the key of CLIProxyAPI, for adapters/pi/cliproxy-provider.ts.
# The key is a secret, thus this repository never holds it and the file gets mode
# 600. The environment writes the file, and the extension also reads the same two
# variables directly, so an export alone is enough for one session.
CLIPROXY_CONFIG="$HOME/.pi/agent/cliproxy.json"
if [[ -n ${CLIPROXY_API_KEY:-} ]]; then
    cliproxy_tmp=$(mktemp "$CLIPROXY_CONFIG.XXXXXX")
    chmod 600 "$cliproxy_tmp"
    jq -n --arg baseUrl "${CLIPROXY_BASE_URL:-http://127.0.0.1:8317}" \
        --arg apiKey "$CLIPROXY_API_KEY" \
        '{baseUrl: $baseUrl, apiKey: $apiKey}' >"$cliproxy_tmp"
    mv "$cliproxy_tmp" "$CLIPROXY_CONFIG"
elif [[ ! -e $CLIPROXY_CONFIG ]]; then
    echo "pi: to use CLIProxyAPI, set CLIPROXY_API_KEY and CLIPROXY_BASE_URL, then run this script again."
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
        case $(link_target "$entry") in
            "$DOTFILES"/* | "$STABLE"/*)
                rm "$entry"
                echo "removed stale link: ~/${entry#"$HOME"/}"
                ;;
        esac
    done
done

# Codex runs a user hook only after the user trusts it, and it asks again after
# each change of the hook definition.
echo "Codex: open /hooks one time and trust the STE gate hooks, if Codex does not run them yet."
