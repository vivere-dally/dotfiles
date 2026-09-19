#!/usr/bin/env bash
# Compiles the Alacritty terminfo entries and repairs stale, unwritable output.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TIC=${TIC:-$(command -v tic || true)}
TERMINFO_DIR=${TERMINFO_DIR:-$HOME/.terminfo}
TERMINFO_SOURCE=${TERMINFO_SOURCE:-$DOTFILES/.config/alacritty/extra/alacritty.info}

if [[ -z $TIC || ! -x $TIC ]]; then
    echo "install-terminfo: tic was not found" >&2
    exit 1
fi

staging_dir=$(mktemp -d "${TMPDIR:-/tmp}/alacritty-terminfo.XXXXXX")
trap 'rm -rf "$staging_dir"' EXIT
TERMINFO="$staging_dir" "$TIC" -x -o "$staging_dir" "$TERMINFO_SOURCE"

terminfo_is_writable() {
    [[ -d $TERMINFO_DIR && -w $TERMINFO_DIR ]] || return 1

    local compiled_path relative_path destination_path
    while IFS= read -r compiled_path; do
        relative_path=${compiled_path#"$staging_dir"/}
        destination_path="$TERMINFO_DIR/$relative_path"
        if [[ -e $destination_path ]] && [[ ! -w $destination_path ]]; then
            return 1
        fi
    done < <(find "$staging_dir" -mindepth 1)
}

if [[ -e $TERMINFO_DIR || -L $TERMINFO_DIR ]]; then
    if [[ -L $TERMINFO_DIR || ! -d $TERMINFO_DIR ]]; then
        echo "install-terminfo: $TERMINFO_DIR exists but is not a directory" >&2
        exit 1
    fi

    if ! terminfo_is_writable; then
        echo "install-terminfo: repairing permissions in $TERMINFO_DIR"
        chmod -R u+rwX "$TERMINFO_DIR" 2>/dev/null || true
        if ! terminfo_is_writable; then
            if [[ $(id -u) == 0 ]]; then
                chown -R "$(id -u):$(id -g)" "$TERMINFO_DIR"
            elif command -v sudo >/dev/null 2>&1; then
                sudo chown -R "$(id -u):$(id -g)" "$TERMINFO_DIR"
            else
                echo "install-terminfo: sudo is required to repair $TERMINFO_DIR" >&2
                exit 1
            fi
            chmod -R u+rwX "$TERMINFO_DIR"
        fi
    fi
fi

mkdir -p "$TERMINFO_DIR"
while IFS= read -r compiled_dir; do
    relative_dir=${compiled_dir#"$staging_dir"/}
    mkdir -p "$TERMINFO_DIR/$relative_dir"
done < <(find "$staging_dir" -mindepth 1 -type d)

while IFS= read -r compiled_file; do
    relative_file=${compiled_file#"$staging_dir"/}
    install -m 0644 "$compiled_file" "$TERMINFO_DIR/$relative_file"
done < <(find "$staging_dir" -type f)
