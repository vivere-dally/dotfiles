#/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi

#--------------------------------------------------------------------------
# brew & stow
#--------------------------------------------------------------------------
mkdir ~/homebrew && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C ~/homebrew
echo 'eval "$($HOME/homebrew/bin/brew shellenv)"' >> ~/.zprofile
source ~/.zprofile
brew update -y
brew install stow -y
cd ~/dotfiles/ && stow . && cd

#--------------------------------------------------------------------------
# utilities
#--------------------------------------------------------------------------
brew install ripgrep -y # https://github.com/BurntSushi/ripgrep
brew install fd -y # https://github.com/sharkdp/fd
brew install fzf -y # https://github.com/junegunn/fzf
# brew install openjdk-21-jdk -y # tbd

#--------------------------------------------------------------------------
# zsh https://github.com/ohmyzsh/ohmyzsh
#--------------------------------------------------------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
source ~/.zshrc

#--------------------------------------------------------------------------
# nvm https://github.com/nvm-sh/nvm
#--------------------------------------------------------------------------
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
zsh
nvm install --lts

#--------------------------------------------------------------------------
# pyenv https://github.com/pyenv/pyenv
#--------------------------------------------------------------------------
brew install pyenv -y 
zsh
pyenv install 3.12
pyenv global 3.12

#--------------------------------------------------------------------------
# tmux https://github.com/tmux/tmux
#--------------------------------------------------------------------------
brew install -y tmux
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
# Go
#--------------------------------------------------------------------------
echo "To install Golang goto https://go.dev/doc/install"
