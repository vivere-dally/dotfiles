#!/usr/bin/env bash
# Installs the tools that the dotfiles need, links the configuration, and
# completes the first Neovim installation. Safe to run again.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
NPM="$(command -v npm || true)"
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

PLATFORM="$(uname -s)"
case "$PLATFORM" in
    Darwin) DOTFILES_BOOTSTRAP_PLATFORM_HELPER=1 "$DOTFILES/scripts/init.darwin.sh" ;;
    Linux) DOTFILES_BOOTSTRAP_PLATFORM_HELPER=1 "$DOTFILES/scripts/init.linux.sh" ;;
    *)
        echo "bootstrap: only macOS and Linux are supported" >&2
        exit 1
        ;;
esac

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

formulae=(
    stow neovim tree-sitter-cli jq pyenv uv zsh fzf git
    ripgrep fd lazygit tmux
    go gopls delve golangci-lint goimports templ
)
[[ $PLATFORM == Linux ]] && formulae+=(rust)
command -v tic >/dev/null 2>&1 || formulae+=(ncurses)

"$BREW" install "${formulae[@]}"
"$BREW" upgrade "${formulae[@]}"

case "$PLATFORM" in
    Darwin) "$DOTFILES/scripts/install-alacritty.darwin.sh" ;;
    Linux) "$DOTFILES/scripts/install-alacritty.linux.sh" ;;
esac
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

NVM_INSTALLER_VERSION=v0.40.7
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
installer=$(mktemp)
trap 'rm -f "$installer"' EXIT
curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_INSTALLER_VERSION/install.sh" -o "$installer"
PROFILE=/dev/null /bin/bash "$installer"
rm -f "$installer"
trap - EXIT

if [[ ! -s $NVM_DIR/nvm.sh ]]; then
    echo "bootstrap: nvm was installed, but its initialization script was not found" >&2
    exit 1
fi

# nvm reads this file while it installs a Node release. Link it before the
# first Node installation; the later Stow run then keeps the same link.
mkdir -p "$NVM_DIR"
nvm_packages="$NVM_DIR/default-packages"
repo_nvm_packages="$DOTFILES/.nvm/default-packages"
if [[ ! -e $nvm_packages ]] || [[ ! $nvm_packages -ef $repo_nvm_packages ]]; then
    if [[ -e $nvm_packages || -L $nvm_packages ]]; then
        mv "$nvm_packages" "$nvm_packages.bootstrap-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    ln -s "$repo_nvm_packages" "$nvm_packages"
fi

set +u
# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
set -u
nvm install --lts --latest-npm
node_version=$(nvm current)
nvm alias default "$node_version"
nvm use "$node_version"
npm install --global --allow-scripts=bun bun@latest
npm install --global --ignore-scripts @earendil-works/pi-coding-agent@latest

export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
python_version=$(pyenv latest --known 3)
pyenv install -s "$python_version"
pyenv global "$python_version"
uv pip install --python "$(pyenv which python)" --upgrade libtmux

"$DOTFILES/scripts/stow.sh"

TPM_ROOT="$HOME/.tmux/plugins"
TPM_DIR="$TPM_ROOT/tpm"
if [[ -d $TPM_DIR/.git ]]; then
    git -C "$TPM_DIR" pull --ff-only
elif [[ ! -e $TPM_DIR ]]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
else
    echo "bootstrap: $TPM_DIR exists but is not a TPM checkout" >&2
    exit 1
fi
if tmux list-sessions >/dev/null 2>&1; then
    tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$TPM_ROOT/"
fi
"$TPM_DIR/bin/install_plugins"

for tmux_plugin in \
    tmux-sensible \
    tmux-window-name \
    tmux-fzf \
    tmux-resurrect \
    tmux-continuum; do
    if [[ ! -d $TPM_ROOT/$tmux_plugin ]]; then
        echo "bootstrap: tmux plugin installation did not create $tmux_plugin" >&2
        exit 1
    fi
done

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
if [[ ! -r $ZSH/oh-my-zsh.sh ]]; then
    omz_installer=$(mktemp)
    trap 'rm -f "$omz_installer"' EXIT
    curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -o "$omz_installer"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes /bin/sh "$omz_installer" --unattended
    rm -f "$omz_installer"
    trap - EXIT
elif [[ -d $ZSH/.git ]]; then
    git -C "$ZSH" pull --ff-only
fi

install_zsh_plugin() {
    local repository=$1 destination=$2
    if [[ -d $destination/.git ]]; then
        git -C "$destination" pull --ff-only
    elif [[ ! -e $destination ]]; then
        git clone --depth=1 "$repository" "$destination"
    fi
}

ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH/custom}"
mkdir -p "$ZSH_CUSTOM/plugins"
install_zsh_plugin \
    https://github.com/zsh-users/zsh-autosuggestions.git \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_zsh_plugin \
    https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

for plugin_file in \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"; do
    if [[ ! -r $plugin_file ]]; then
        echo "bootstrap: Zsh plugin installation did not create $plugin_file" >&2
        exit 1
    fi
done

TIC="$(command -v tic || true)"
if [[ -z $TIC ]]; then TIC="$("$BREW" --prefix ncurses)/bin/tic"; fi
TIC="$TIC" "$DOTFILES/scripts/install-terminfo.sh"

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

if ! NVIM_BOOTSTRAP=1 nvim --headless \
    -c "lua local ok, err = pcall(require('core.bootstrap').run); if not ok then vim.api.nvim_err_writeln(err); vim.cmd.cquit() end" \
    -c 'qa!'; then
    echo "bootstrap: Neovim setup failed" >&2
    exit 1
fi

echo "bootstrap: installation complete"
