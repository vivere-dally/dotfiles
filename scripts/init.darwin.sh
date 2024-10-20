#/bin/bash

#if [ "$(id -u)" -ne 0 ]; then
#    echo 'This script must be run by root' >&2
#    exit 1
#fi

#--------------------------------------------------------------------------
# brew & stow
#--------------------------------------------------------------------------
mkdir ~/homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C ~/homebrew
echo 'eval "$($HOME/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
brew update
brew install stow
cd ~/dotfiles/ && stow . && cd

#--------------------------------------------------------------------------
# utilities
#--------------------------------------------------------------------------
brew install ripgrep # https://github.com/BurntSushi/ripgrep
brew install fd # https://github.com/sharkdp/fd
brew install fzf # https://github.com/junegunn/fzf
# brew install openjdk-21-jdk # tbd

#--------------------------------------------------------------------------
# zsh https://github.com/ohmyzsh/ohmyzsh
#--------------------------------------------------------------------------
RUNZSH='no' KEEP_ZSHRC='yes' sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
source ~/.zshrc

#--------------------------------------------------------------------------
# nvm https://github.com/nvm-sh/nvm
#--------------------------------------------------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.zshrc
nvm install --lts

#--------------------------------------------------------------------------
# pyenv https://github.com/pyenv/pyenv
#--------------------------------------------------------------------------
brew install pyenv
pyenv install 3.12
pyenv global 3.12

#--------------------------------------------------------------------------
# tmux https://github.com/tmux/tmux
#--------------------------------------------------------------------------
brew install tmux
python3 -m pip install --user libtmux

#--------------------------------------------------------------------------
# rust
#--------------------------------------------------------------------------
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup override set stable
rustup update stable

#--------------------------------------------------------------------------
# alacritty https://github.com/alacritty/alacritty
#--------------------------------------------------------------------------
echo "To install Alacritty goto https://alacritty.org/ and download the dmg file"

#--------------------------------------------------------------------------
# neovim https://github.com/neovim/neovim
#--------------------------------------------------------------------------
brew install neovim

#--------------------------------------------------------------------------
# php
#--------------------------------------------------------------------------
brew install php
read -p "Make sure to follow brew's php installation instructions"
brew install composer


#--------------------------------------------------------------------------
# go
#--------------------------------------------------------------------------
echo "To install Golang goto https://go.dev/doc/install"

#--------------------------------------------------------------------------
# karabiner, skhd, yabai
#--------------------------------------------------------------------------

brew install --cask karabiner-elements
brew install koekeishiya/formulae/yabai && yabai --start-service
brew install koekeishiya/formulae/skhd && skhd --start-service
