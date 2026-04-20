#!/usr/bin/env bash

set -euo pipefail

if command -v python3 >/dev/null 2>&1; then
  python_cmd="python3"
elif command -v python >/dev/null 2>&1; then
  python_cmd="python"
else
  echo "python is required to read .fvmrc" >&2
  exit 1
fi

flutter_version="${FLUTTER_VERSION:-$("$python_cmd" -c 'import json; print(json.load(open(".fvmrc", encoding="utf-8"))["flutter"])')}"
flutter_root="${FLUTTER_ROOT:-$HOME/flutter/$flutter_version}"
flutter_bin_dir="$flutter_root/bin"

uname_s="$(uname -s)"
case "$uname_s" in
  Linux|Darwin)
    platform="unix"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    platform="windows"
    ;;
  *)
    echo "unsupported operating system: $uname_s" >&2
    exit 1
    ;;
esac

add_to_github_path() {
  local path_value="$1"
  if [[ -z "${GITHUB_PATH:-}" ]]; then
    return
  fi

  if [[ "$platform" == "windows" ]]; then
    cygpath -w "$path_value" >> "$GITHUB_PATH"
  else
    echo "$path_value" >> "$GITHUB_PATH"
  fi
}

add_to_github_env() {
  local name="$1"
  local value="$2"
  if [[ -z "${GITHUB_ENV:-}" ]]; then
    return
  fi

  if [[ "$platform" == "windows" ]]; then
    value="$(cygpath -w "$value")"
  fi
  echo "${name}=${value}" >> "$GITHUB_ENV"
}

rm -rf "$flutter_root"
mkdir -p "$(dirname "$flutter_root")"
git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git "$flutter_root"

export PATH="$flutter_bin_dir:$PATH"
add_to_github_path "$flutter_bin_dir"
add_to_github_env "FLUTTER_ROOT" "$flutter_root"

flutter --version
