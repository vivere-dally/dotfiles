#/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run by root' >&2
    exit 1
fi

apt update -y && apt upgrade -y
apt install stow -y
cd ~/dotfiles/ && stow . && cd

#--------------------------------------------------------------------------
# utilities
#--------------------------------------------------------------------------
apt install wl-clipboard -y
apt install ripgrep -y # https://github.com/BurntSushi/ripgrep
apt install fd-find -y # https://github.com/sharkdp/fd
apt install fzf -y # https://github.com/junegunn/fzf
# apt install openjdk-21-jdk -y # tbd

#--------------------------------------------------------------------------
# zsh https://github.com/ohmyzsh/ohmyzsh
#--------------------------------------------------------------------------
apt install zsh
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
apt install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev llvm gcc openssl
curl https://pyenv.run | bash
zsh
pyenv install 3.12
pyenv global 3.12

#--------------------------------------------------------------------------
# tmux https://github.com/tmux/tmux
#--------------------------------------------------------------------------
apt install -y tmux
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

# alacritty required build packages
apt install cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev libegl1-mesa-dev python3 -y

git clone --depth=1 https://github.com/alacritty/alacritty.git ~/alacritty && cd ~/alacritty
cargo build --release --no-default-features --features=wayland

# post build
tic -xe alacritty,alacritty-direct extra/alacritty.info
cp target/release/alacritty /usr/local/bin
cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
desktop-file-install extra/linux/Alacritty.desktop
update-desktop-database
cd

#--------------------------------------------------------------------------
# neovim https://github.com/neovim/neovim
#--------------------------------------------------------------------------
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
chmod u+x nvim.appimage
./nvim.appimage --appimage-extract
mv ./squashfs-root /usr/local/share/
ln -s /usr/local/share/squashfs-root/AppRun /usr/bin/nvim
rm ./nvim.appimage

# TODO - not sure about these
# CUSTOM_NVIM_PATH=/usr/local/bin/nvim.appimage
# Set the above with the correct path, then run the rest of the commands:
# set -u
# update-alternatives --install /usr/bin/ex ex "${CUSTOM_NVIM_PATH}" 110
# update-alternatives --install /usr/bin/vi vi "${CUSTOM_NVIM_PATH}" 110
# update-alternatives --install /usr/bin/view view "${CUSTOM_NVIM_PATH}" 110
# update-alternatives --install /usr/bin/vim vim "${CUSTOM_NVIM_PATH}" 110
# update-alternatives --install /usr/bin/vimdiff vimdiff "${CUSTOM_NVIM_PATH}" 110

#--------------------------------------------------------------------------
# php
#--------------------------------------------------------------------------
PHP_WV="php8.3" # PHP with version
add-apt-repository ppa:ondrej/php
apt update
apt install $PHP_WV libapache2-mod-$PHP_WV
systemctl restart apache2
apt install $PHP_WV-fpm libapache2-mod-fcgid
a2enmod proxy_fcgi setenvif
a2enconf $PHP_WV-fpm
systemctl restart apache2
apt install $PHP_WV-mysql $PHP_WV-gd $PHP_WV-curl $PHP_WV-xml

# Composer
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]
then
    >&2 echo 'ERROR: Invalid composer installer checksum'
    rm composer-setup.php
else
    php composer-setup.php --quiet
    rm composer-setup.php

    mv composer.phar /usr/local/bin/composer
fi

#--------------------------------------------------------------------------
# Go
#--------------------------------------------------------------------------
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
