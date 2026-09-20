#!/usr/bin/env bash
set -euo pipefail

project_root="${1:?project root is required}"
current_file="${2:?current Zig file is required}"

if [[ $current_file != *.zig ]]; then
    echo "The current file is not a Zig file: $current_file" >&2
    exit 1
fi

root_source=''
for candidate in src/root.zig src/main.zig root.zig main.zig; do
    if [[ -f $project_root/$candidate ]]; then
        root_source="$project_root/$candidate"
        break
    fi
done

if [[ -z $root_source ]]; then
    echo 'No Zig root source file exists in the project.' >&2
    exit 1
fi

# A leaf file cannot import outside its module root. Build the package root and
# derive the test namespace from the leaf path instead.
root_directory="$(dirname "$root_source")"
test_filter=''
if [[ $current_file != "$root_source" && $current_file == "$root_directory/"* ]]; then
    relative_file="${current_file#"$root_directory/"}"
    test_filter="${relative_file%.zig}"
    test_filter="${test_filter//\//.}"
fi

command=(zig test --test-no-exec "-femit-bin=$project_root/zig-test-debug")
if [[ -n $test_filter ]]; then
    command+=(--test-filter "$test_filter")
fi
command+=("$root_source")

cd "$project_root"
"${command[@]}"
