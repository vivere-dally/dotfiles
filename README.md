# dotfiles

- (mac) `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- install stow

  - (linux) `sudo apt install stow`
  - (mac) `sudo brew install stow`

- alacritty:
  - some [terminal issues](https://unix.stackexchange.com/questions/597445/why-would-i-set-term-to-xterm-256color-when-using-alacritty)
  - TLDR:
    - download the alacritty/extra/ folder and copy it into the alacritty/ you just create, then:
    - `sudo tic -xe alacritty,alacritty-direct extra/alacritty.info`
