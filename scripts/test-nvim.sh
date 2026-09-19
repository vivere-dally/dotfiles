#!/usr/bin/env bash

set -euo pipefail

readonly REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly NVIM_BIN="${NVIM_BIN:-nvim}"
readonly TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nvim-smoke.XXXXXX")"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

env \
  NVIM_TEST_ROOT="$REPO_ROOT" \
  XDG_CACHE_HOME="$TEST_ROOT/cache" \
  XDG_CONFIG_HOME="$TEST_ROOT/config" \
  XDG_DATA_HOME="$TEST_ROOT/data" \
  XDG_STATE_HOME="$TEST_ROOT/state" \
  "$NVIM_BIN" --clean --headless \
  -l "$REPO_ROOT/.config/nvim/tests/smoke.lua"
