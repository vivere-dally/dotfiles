#!/usr/bin/env bash
# Installs the latest stable Alacritty app from its official GitHub release.
set -euo pipefail

if [[ $(uname -s) != Darwin ]]; then
    echo "install-alacritty.darwin.sh: this helper requires macOS" >&2
    exit 1
fi

for command_name in curl ditto hdiutil jq shasum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "install-alacritty.darwin.sh: $command_name is required" >&2
        exit 1
    fi
done

APPLICATIONS_DIR="${ALACRITTY_APPLICATIONS_DIR:-/Applications}"
RELEASE_API=https://api.github.com/repos/alacritty/alacritty/releases/latest
release_json=$(curl -fsSL "$RELEASE_API")
release_tag=$(jq -er '.tag_name | select(startswith("v"))' <<<"$release_json")
release_version=${release_tag#v}
asset_name="Alacritty-$release_tag.dmg"
asset_url=$(jq -er --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url' \
    <<<"$release_json")
asset_digest=$(jq -er --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .digest | select(startswith("sha256:")) | sub("^sha256:"; "")' \
    <<<"$release_json")

destination="$APPLICATIONS_DIR/Alacritty.app"
installed_binary="$destination/Contents/MacOS/alacritty"
if [[ -x $installed_binary ]]; then
    installed_version=$("$installed_binary" --version | awk '{print $2}')
    if [[ $installed_version == "$release_version" ]]; then
        echo "Alacritty $release_version is already installed"
        exit 0
    fi
fi

work_dir=$(mktemp -d)
mount_dir="$work_dir/mount"
mounted=0
cleanup() {
    if [[ $mounted == 1 ]]; then
        hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
    fi
    if ! rm -rf "$work_dir"; then
        echo "install-alacritty.darwin.sh: could not remove temporary files in $work_dir" >&2
    fi
}
trap cleanup EXIT

dmg="$work_dir/$asset_name"
mkdir -p "$mount_dir" "$APPLICATIONS_DIR"
curl -fL "$asset_url" -o "$dmg"
printf '%s  %s\n' "$asset_digest" "$dmg" | shasum -a 256 -c -

hdiutil attach -nobrowse -readonly -mountpoint "$mount_dir" "$dmg" >/dev/null
mounted=1
candidate="$work_dir/Alacritty.app"
ditto "$mount_dir/Alacritty.app" "$candidate"
hdiutil detach "$mount_dir" >/dev/null
mounted=0

candidate_version=$("$candidate/Contents/MacOS/alacritty" --version | awk '{print $2}')
if [[ $candidate_version != "$release_version" ]]; then
    echo "install-alacritty.darwin.sh: release contains Alacritty $candidate_version, expected $release_version" >&2
    exit 1
fi

backup_dir="$HOME/.dotfiles-backup/alacritty/$(date +%Y%m%d-%H%M%S)"
previous="$backup_dir/Alacritty.app"
if [[ -e $destination ]]; then
    mkdir -p "$backup_dir"
    mv "$destination" "$previous"
    echo "Backed up the previous app to $previous"
fi
if ! ditto "$candidate" "$destination"; then
    [[ ! -e $destination ]] || mv "$destination" "$work_dir/failed.app"
    [[ ! -e $previous ]] || mv "$previous" "$destination"
    echo "install-alacritty.darwin.sh: failed to install $destination" >&2
    exit 1
fi

installed_version=$("$installed_binary" --version | awk '{print $2}')
if [[ $installed_version != "$release_version" ]]; then
    mv "$destination" "$work_dir/failed.app"
    [[ ! -e $previous ]] || mv "$previous" "$destination"
    echo "install-alacritty.darwin.sh: installed Alacritty $installed_version, expected $release_version" >&2
    exit 1
fi

echo "Installed Alacritty $release_version"
