# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/Users/s-ved/.oh-my-zsh/custom/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

    bindkey -e
    bindkey '\e\e[C' forward-word
    bindkey '\e\e[D' backward-word
fi

export EDITOR=nvim
export GIT_EDITOR=nvim
export TERM=alacritty

#--------------------------------------------------------------------------
# oh-my-zsh
#--------------------------------------------------------------------------

export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="robbyrussell"
COMPLETION_WAITING_DOTS="true"
HIST_STAMPS="yyyy-mm-dd"
VI_MODE_SET_CURSOR=true
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true

zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format %d
zstyle ':completion:*:descriptions' format %B%d%b
zstyle ':completion:*:complete:(cd|pushd):*' tag-order \
    'local-directories named-directories'

plugins=(git fzf poetry zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias copy="xclip -selection clipboard"
alias paste="xclip -o -selection clipboard"

#--------------------------------------------------------------------------
# Tools
#--------------------------------------------------------------------------

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
# eval "$(goenv init -)"

export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:/usr/local/android-studio/bin
export PATH=$PATH:~/go/bin
export PATH=$PATH:~/.composer/vendor/bin

source <(fzf --zsh)

# Poetry https://python-poetry.org/docs/#installing-manually
export POETRY_VENV_PATH="$HOME/.local/lib/poetry-home"
export PATH=$PATH:~/.local/lib/bin
export POETRY_VIRTUALENVS_IN_PROJECT=true

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk"

. "$HOME/.local/bin/env"
export PATH=$PATH:$HOME/.local/bin

# bun completions
[ -s "/Users/s-ved/.bun/_bun" ] && source "/Users/s-ved/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

my-oc() {
    ANTHROPIC_API_KEY=x ANTHROPIC_BASE_URL=http://localhost:8182/anthropic/v1 opencode "$@"
}

export OLLAMA_CONTEXT_LENGTH=32768
export OPENSPEC_TELEMETRY=0

# Added by MTPLX.app — terminal command
export PATH="$HOME/.mtplx/bin:$PATH"

# The Homebrew prefix differs per machine (~/homebrew from init.darwin.sh vs
# the stock /opt/homebrew), so never hardcode it. ~/.zprofile's
# `brew shellenv` exports it; asking brew covers shells that skipped that.
: ${HOMEBREW_PREFIX:=$(brew --prefix 2>/dev/null)}

export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/icu4c/lib/pkgconfig:$PKG_CONFIG_PATH"

# LLVM: machines carry either the pinned llvm@22 or the floating `llvm`
# formula. Use the first one installed, pinned first, so compilers and cmake
# agree on a single toolchain.
for _llvm in "$HOMEBREW_PREFIX/opt/llvm@22" "$HOMEBREW_PREFIX/opt/llvm"; do
    [[ -d $_llvm ]] || continue
    export PATH="$_llvm/bin:$PATH"
    export LDFLAGS="-L$_llvm/lib"
    export CPPFLAGS="-I$_llvm/include"
    export CMAKE_PREFIX_PATH="$_llvm"
    break
done
unset _llvm
