#!/usr/bin/env bash
# Builds the latest stable Alacritty release and installs its desktop files.
set -euo pipefail

if [[ $(uname -s) != Linux ]]; then
    echo "install-alacritty.linux.sh: this helper requires Linux" >&2
    exit 1
fi

for command_name in cargo curl jq sha256sum; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "install-alacritty.linux.sh: $command_name is required" >&2
        exit 1
    fi
done

RELEASE_API=https://api.github.com/repos/alacritty/alacritty/releases/latest
release_json=$(curl -fsSL "$RELEASE_API")
release_tag=$(jq -er '.tag_name | select(startswith("v"))' <<<"$release_json")
release_version=${release_tag#v}

binary="$HOME/.local/bin/alacritty"
installed_version=""
if [[ -x $binary ]]; then
    installed_version=$("$binary" --version | awk '{print $2}')
fi
if [[ $installed_version != "$release_version" ]]; then
    cargo install --force --locked --root "$HOME/.local" --version "$release_version" alacritty
fi

work_dir=$(mktemp -d)
cleanup() {
    if ! rm -rf "$work_dir"; then
        echo "install-alacritty.linux.sh: could not remove temporary files in $work_dir" >&2
    fi
}
trap cleanup EXIT

fetch_asset() {
    local name=$1
    local url digest destination="$work_dir/$name"
    url=$(jq -er --arg name "$name" \
        '.assets[] | select(.name == $name) | .browser_download_url' \
        <<<"$release_json")
    digest=$(jq -er --arg name "$name" \
        '.assets[] | select(.name == $name) | .digest | select(startswith("sha256:")) | sub("^sha256:"; "")' \
        <<<"$release_json")
    curl -fsSL "$url" -o "$destination"
    printf '%s  %s\n' "$digest" "$destination" | sha256sum --check --status
    echo "$destination"
}

desktop_source=$(fetch_asset Alacritty.desktop)
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
desktop_dir="$data_home/applications"
mkdir -p "$desktop_dir"
awk -v binary="$binary" '
    $0 == "TryExec=alacritty" { $0 = "TryExec=" binary }
    $0 == "Exec=alacritty" { $0 = "Exec=" binary }
    { print }
' "$desktop_source" >"$desktop_dir/Alacritty.desktop"

icon_source=$(fetch_asset Alacritty.svg)
icon_dir="$data_home/icons/hicolor/scalable/apps"
mkdir -p "$icon_dir"
install -m 0644 "$icon_source" "$icon_dir/Alacritty.svg"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$desktop_dir"
fi

installed_version=$("$binary" --version | awk '{print $2}')
if [[ $installed_version != "$release_version" ]]; then
    echo "install-alacritty.linux.sh: installed Alacritty $installed_version, expected $release_version" >&2
    exit 1
fi

echo "Alacritty $release_version is installed"
