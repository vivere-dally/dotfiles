#!/usr/bin/env bash
# Sets up what pi needs beyond the links that scripts/llm-capabilities.sh makes:
# the pinned packages, and the secret that the local SearXNG container reads.
# Safe to run again. scripts/bootstrap.sh calls this, and it also runs alone,
# which matters because a new pin must not wait for a full bootstrap.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

for tool in pi jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "pi setup: $tool is not on PATH. Run scripts/bootstrap.sh first." >&2
        exit 1
    fi
done

# Offline mode blocks installation of missing packages. Install only a missing or
# changed pin, because `pi update --extensions` intentionally skips exact versions.
while IFS= read -r pi_package; do
    package_spec=${pi_package#npm:}
    package_name=${package_spec%@*}
    package_version=${package_spec##*@}
    package_file="$HOME/.pi/agent/npm/node_modules/$package_name/package.json"
    installed_version=$(jq -r '.version // empty' "$package_file" 2>/dev/null || true)
    if [[ $installed_version != "$package_version" ]]; then
        env -u PI_OFFLINE pi install "$pi_package"
    fi
done < <(jq -r '.packages[] | if type == "string" then . else .source end' \
    "$DOTFILES/llm-capabilities/settings/pi/settings.json")

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
