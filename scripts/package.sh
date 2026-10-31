#!/usr/bin/env bash
set -euo pipefail

version=${1:?Usage: scripts/package.sh vX.Y.Z [output-directory]}
output_dir=${2:-dist}
if [[ ! "$version" =~ ^v[0-9]+([.][0-9]+)*([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Invalid release version: $version (expected vX.Y.Z)" >&2
    exit 2
fi

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
mkdir -p "$output_dir"
output_dir=$(cd "$output_dir" && pwd)
work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

mkdir -p "$work_dir/scripts/adwisp" "$work_dir/script-opts"
cp "$repo_root/adwisp.lua" "$work_dir/scripts/adwisp/"
cp -R "$repo_root/core" "$work_dir/scripts/adwisp/"
cp "$repo_root/script-opts/adwisp.conf" "$work_dir/script-opts/"

archive="$output_dir/adwisp-$version.zip"
(
    cd "$work_dir"
    zip -qr "$archive" scripts script-opts
)
echo "Created $archive"
