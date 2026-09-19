#!/usr/bin/env bash
# Linux prerequisites for Homebrew and CPython builds through pyenv.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Keep the old entry point useful while all installation logic stays in one
# place. bootstrap.sh sets the marker when it calls this helper.
if [[ ${DOTFILES_BOOTSTRAP_PLATFORM_HELPER:-0} != 1 ]]; then
    exec "$SCRIPT_DIR/bootstrap.sh"
fi

if [[ $(uname -s) != Linux ]]; then
    echo "init.linux.sh: this helper requires Linux" >&2
    exit 1
fi

run_as_root() {
    if [[ $(id -u) == 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        echo "init.linux.sh: sudo is required to install system packages" >&2
        exit 1
    fi
}

if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y \
        build-essential cmake curl file g++ git pkg-config procps wl-clipboard zsh \
        libbz2-dev libffi-dev libgdbm-dev liblzma-dev libncursesw5-dev \
        libfontconfig1-dev libreadline-dev libsqlite3-dev libssl-dev \
        libxcb-xfixes0-dev libxkbcommon-dev libxml2-dev libxmlsec1-dev \
        tk-dev uuid-dev xz-utils zlib1g-dev
elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y \
        '@Development Tools' cmake curl file gcc-c++ git procps-ng wl-clipboard zsh \
        bzip2-devel libffi-devel gdbm-devel libuuid-devel ncurses-devel \
        fontconfig-devel freetype-devel libxcb-devel libxkbcommon-devel \
        openssl-devel pkgconf-pkg-config readline-devel sqlite-devel \
        tk-devel xz-devel zlib-devel
elif command -v yum >/dev/null 2>&1; then
    run_as_root yum groupinstall -y 'Development Tools'
    run_as_root yum install -y \
        cmake curl file gcc-c++ git procps-ng wl-clipboard zsh \
        bzip2-devel fontconfig-devel freetype-devel libffi-devel gdbm-devel \
        libuuid-devel libxcb-devel libxkbcommon-devel ncurses-devel \
        openssl-devel pkgconfig readline-devel sqlite-devel tk-devel \
        xcb-util-devel xz-devel zlib-devel
elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install -t pattern devel_basis
    run_as_root zypper --non-interactive install \
        cmake curl file gcc-c++ git make pkg-config procps wl-clipboard zsh \
        fontconfig-devel freetype-devel libbz2-devel libffi-devel gdbm-devel \
        libopenssl-devel libreadline-devel libsqlite3-devel libuuid-devel \
        libxcb-devel libxkbcommon-devel ncurses-devel tk-devel xz-devel zlib-devel
elif command -v pacman >/dev/null 2>&1; then
    run_as_root pacman -Syu --needed --noconfirm \
        base-devel cmake curl fontconfig freetype2 git libxcb libxkbcommon \
        procps-ng python wl-clipboard zsh bzip2 libffi gdbm libxcrypt ncurses \
        openssl readline sqlite tk util-linux xz zlib
else
    echo "init.linux.sh: unsupported package manager; install the pyenv build dependencies first" >&2
    exit 1
fi
