#!/usr/bin/env bash
# Installs the tools that the dotfiles need, links the configuration, and
# completes the first Neovim installation. Safe to run again.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
NPM="$(command -v npm || true)"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

find_brew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return
    fi

    local candidate
    for candidate in \
        "$HOME/homebrew/bin/brew" \
        /opt/homebrew/bin/brew \
        /usr/local/bin/brew \
        /home/linuxbrew/.linuxbrew/bin/brew; do
        if [[ -x $candidate ]]; then
            echo "$candidate"
            return
        fi
    done
    return 1
}

BREW="$(find_brew || true)"
if [[ -z $BREW ]]; then
    command -v curl >/dev/null 2>&1 || {
        echo "bootstrap: curl is required to install Homebrew" >&2
        exit 1
    }
    installer=$(mktemp)
    trap 'rm -f "$installer"' EXIT
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o "$installer"
    NONINTERACTIVE=1 /bin/bash "$installer"
    rm -f "$installer"
    trap - EXIT
    BREW="$(find_brew || true)"
    if [[ -z $BREW ]]; then
        echo "bootstrap: Homebrew was installed, but its brew command was not found" >&2
        exit 1
    fi
fi

eval "$("$BREW" shellenv)"

formulae=(stow neovim tree-sitter-cli jq pyenv uv)
command -v tic >/dev/null 2>&1 || formulae+=(ncurses)

"$BREW" install "${formulae[@]}"
"$BREW" upgrade "${formulae[@]}"
hash -r

if [[ -z $NPM ]]; then NPM="$(command -v npm || true)"; fi
if [[ -n $NPM ]] && "$NPM" list --global --depth=0 tree-sitter-cli >/dev/null 2>&1; then
    "$NPM" uninstall --global tree-sitter-cli
    hash -r
fi

command -v curl >/dev/null 2>&1 || {
    echo "bootstrap: curl is required to install nvm" >&2
    exit 1
}

readonly NVM_VERSION=v0.40.7
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
installer=$(mktemp)
trap 'rm -f "$installer"' EXIT
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" -o "$installer"
PROFILE=/dev/null /bin/bash "$installer"
rm -f "$installer"
trap - EXIT

if [[ ! -s $NVM_DIR/nvm.sh ]]; then
    echo "bootstrap: nvm was installed, but its initialization script was not found" >&2
    exit 1
fi

set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
set -u
nvm install --lts --latest-npm
node_version=$(nvm current)
nvm alias default "$node_version"
nvm use "$node_version"
npm install --global bun@latest

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
python_version=$(pyenv latest --known 3)
pyenv install -s "$python_version"
pyenv global "$python_version"

TIC="$(command -v tic || true)"
if [[ -z $TIC ]]; then TIC="$("$BREW" --prefix ncurses)/bin/tic"; fi
mkdir -p "$HOME/.terminfo"
"$TIC" -x -o "$HOME/.terminfo" "$DOTFILES/.config/alacritty/extra/alacritty.info"

"$DOTFILES/scripts/stow.sh"

if ! nvim --clean --headless -u NONE -i NONE -n \
    -c "lua if vim.fn.has('nvim-0.12') == 0 then vim.cmd.cquit() end" \
    -c 'qa!' >/dev/null 2>&1; then
    echo "bootstrap: Neovim 0.12 or later is required" >&2
    exit 1
fi

if ! tree-sitter --version | awk '
    {
        split($2, version, ".")
        ok = version[1] > 0 || version[2] > 26 || (version[2] == 26 && version[3] >= 1)
        exit !ok
    }
'; then
    echo "bootstrap: tree-sitter-cli 0.26.1 or later is required" >&2
    exit 1
fi

NVIM_BOOTSTRAP=1 nvim --headless \
    -c "lua local failed = require('pack').failed; if #failed > 0 then print('Plugin groups failed: ' .. table.concat(failed, ', ')); vim.cmd('cquit 1') end" \
    -c "lua local ok, err = pcall(vim.cmd, 'MasonToolsInstallSync'); if not ok then print(err); vim.cmd('cquit 1') end" \
    -c 'qa!'

echo "bootstrap: installation complete"
