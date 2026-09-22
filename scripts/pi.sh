#!/usr/bin/env bash
# Sets up what pi needs beyond the links that scripts/llm-capabilities.sh makes:
# the pinned packages, and the secret that the local SearXNG container reads.
# Safe to run again. scripts/bootstrap.sh calls this, and it also runs alone,
# which matters because a new pin must not wait for a full bootstrap.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

for tool in pi jq npm; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "pi setup: $tool is not on PATH. Run scripts/bootstrap.sh first." >&2
        exit 1
    fi
done

# The capabilities installer owns Pi's package declarations. Install their code
# directly into Pi's npm store, then make sure that each exact pin is present.
pi_npm_root="$HOME/.pi/agent/npm"
packages_to_install=()
while IFS= read -r pi_package; do
    package_spec=${pi_package#npm:}
    package_name=${package_spec%@*}
    package_version=${package_spec##*@}
    package_file="$pi_npm_root/node_modules/$package_name/package.json"
    installed_version=$(jq -r '.version // empty' "$package_file" 2>/dev/null || true)
    if [[ $installed_version != "$package_version" ]]; then
        packages_to_install+=("$package_spec")
    fi
done < <(jq -r '.packages[] | if type == "string" then . else .source end' \
    "$DOTFILES/llm-capabilities/settings/pi/settings.json")

if ((${#packages_to_install[@]} > 0)); then
    mkdir -p "$pi_npm_root"
    if [[ ! -f $pi_npm_root/package.json ]]; then
        printf '{\n  "name": "pi-extensions",\n  "private": true\n}\n' >"$pi_npm_root/package.json"
    fi
    npm install "${packages_to_install[@]}" --prefix "$pi_npm_root" --legacy-peer-deps
fi

while IFS= read -r pi_package; do
    package_spec=${pi_package#npm:}
    package_name=${package_spec%@*}
    package_version=${package_spec##*@}
    package_file="$pi_npm_root/node_modules/$package_name/package.json"
    installed_version=$(jq -r '.version // empty' "$package_file" 2>/dev/null || true)
    if [[ $installed_version != "$package_version" ]]; then
        echo "pi setup: expected $package_name $package_version, found ${installed_version:-nothing}" >&2
        exit 1
    fi
done < <(jq -r '.packages[] | if type == "string" then . else .source end' \
    "$DOTFILES/llm-capabilities/settings/pi/settings.json")

# npm cannot find Pi's optional peer packages from this separate package store.
# Links keep each extension on the same Pi runtime that starts it.
global_pi_root="$(npm root -g)/@earendil-works/pi-coding-agent"
if [[ ! -f $global_pi_root/package.json ]]; then
    echo "pi setup: cannot find the Pi package under $(npm root -g)" >&2
    exit 1
fi
pi_subagents_peer_root="$pi_npm_root/node_modules/pi-subagents/node_modules/@earendil-works"

link_pi_peer() {
    local name=$1 target=$2 path="$pi_subagents_peer_root/$1"
    if [[ ! -f $target/package.json ]]; then
        echo "pi setup: cannot find the $name peer at $target" >&2
        exit 1
    fi
    if [[ -L $path ]]; then
        [[ $(readlink "$path") == "$target" ]] || ln -sfn "$target" "$path"
    elif [[ ! -e $path ]]; then
        ln -s "$target" "$path"
    fi
}

mkdir -p "$pi_subagents_peer_root"
link_pi_peer pi-coding-agent "$global_pi_root"
for pi_peer in pi-agent-core pi-ai pi-tui; do
    link_pi_peer "$pi_peer" "$global_pi_root/node_modules/@earendil-works/$pi_peer"
done

# pi-web-access searches through the SearXNG container in compose.yaml, and
# SearXNG refuses to start while its secret key is the default `ultrasecretkey`.
# The container entrypoint replaces that value with `sed -i`, but compose mounts
# containers/searxng/settings.yml read-only, thus the rewrite never happens.
# SearXNG also reads the key from SEARXNG_SECRET (searx/settings_defaults.py),
# and docker compose reads this file, so the environment is the path that works.
# The key is a secret, thus .env stays out of Git and gets mode 600.
ENV_FILE="$DOTFILES/.env"
if ! grep -q '^SEARXNG_SECRET=' "$ENV_FILE" 2>/dev/null; then
    umask 077
    printf 'SEARXNG_SECRET=%s\n' \
        "$(head -c 32 /dev/urandom | base64 | tr -dc 'a-zA-Z0-9')" >>"$ENV_FILE"
    echo "pi setup: wrote SEARXNG_SECRET to $ENV_FILE."
    printf 'pi setup: run: podman compose -f %q up -d searxng\n' "$DOTFILES/compose.yaml"
fi
