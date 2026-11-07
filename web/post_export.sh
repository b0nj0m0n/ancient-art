#!/usr/bin/env bash
# Runs after the Web export so phones always get the latest build.
#   web/post_export.sh build/web
#
# - The game data (index.pck) is fetched fresh on every launch. It is small,
#   and it is the only file that changes between builds; the engine files only
#   change when the Godot version does.
# - Earlier builds installed an offline cache (a service worker) that kept
#   serving old builds. A replacement service worker removes it.
set -euo pipefail
dir="$1"

# Guard: the game data is downloaded on every launch, so it must stay small.
# If this fails, something large (such as art/reference) is being packed into
# the build. Raise the limit only on purpose.
max_mb=20
pck_bytes=$(stat -c %s "$dir/index.pck")
if [ "$pck_bytes" -gt $((max_mb * 1024 * 1024)) ]; then
	echo "index.pck is $((pck_bytes / 1024 / 1024)) MB, over the ${max_mb} MB limit." >&2
	exit 1
fi
sed -i 's/"executable":"index",/"executable":"index","mainPack":"index.pck?t="+Date.now(),/' "$dir/index.html"
grep -q 'index.pck?t=' "$dir/index.html"
cp "$(dirname "$0")/remove_old_cache.service.worker.js" "$dir/index.service.worker.js"
