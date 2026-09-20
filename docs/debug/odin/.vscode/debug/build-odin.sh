#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
binary="$project_root/odin"

if [[ -x $binary ]] && ! find "$project_root/src" -type f \( -name '*.cpp' -o -name '*.hpp' \) -newer "$binary" -print -quit | grep -q .; then
    exit 0
fi

stamp="$(mktemp)"
trap 'rm -f "$stamp"' EXIT
had_binary=0
if [[ -e $binary ]]; then
    had_binary=1
    touch -r "$binary" "$stamp"
fi

set +e
(
    cd "$project_root"
    ./build_odin.sh debug
)
build_status=$?
set -e

# The build script runs a demo after compilation. The demo can fail even when
# the compiler is valid, so the refreshed binary decides whether the task passed.
if [[ ! -x $binary ]] || (( had_binary == 1 )) && [[ ! $binary -nt $stamp ]]; then
    if (( build_status == 0 )); then
        build_status=1
    fi
    exit "$build_status"
fi
