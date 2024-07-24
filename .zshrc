export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Mac OSX
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi

export EDITOR=nvim
export GIT_EDITOR=nvim
# export TERM=screen-256color

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

source $ZSH/oh-my-zsh.sh

#--------------------------------------------------------------------------
# Aliases
#--------------------------------------------------------------------------

alias ll="ls -alF"
alias la="ls -A"
alias l="ls -CF"
alias vim="nvim"
alias copy="xclip -selection clipboard"
alias paste="xclip -o -selection clipboard"

## PHP
alias sail='[ -f sail ] && sail || vendor/bin/sail'
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
. "$HOME/.cargo/env"

source <(fzf --zsh)
