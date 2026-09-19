#!/usr/bin/env bash
# macOS prerequisites for scripts/bootstrap.sh.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# Keep the old entry point useful while all installation logic stays in one
# place. bootstrap.sh sets the marker when it calls this helper.
if [[ ${DOTFILES_BOOTSTRAP_PLATFORM_HELPER:-0} != 1 ]]; then
    exec "$SCRIPT_DIR/bootstrap.sh"
fi

if [[ $(uname -s) != Darwin ]]; then
    echo "init.darwin.sh: this helper requires macOS" >&2
    exit 1
fi

# Homebrew installs the libraries that pyenv uses on macOS. Its installer also
# checks for the Xcode command line tools, so no separate package step is needed.
