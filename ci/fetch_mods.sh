#!/usr/bin/env bash
# Downloads every mod in mods.txt and unpacks its iOS build into <dusklight>/prebuilt_mods/<id>.
# Usage: fetch_mods.sh <bundle_repo_dir> <dusklight_dir>
set -euo pipefail
REPO="$1"
DUSK="$2"
OUT="$DUSK/prebuilt_mods"
DL="$REPO/.downloads"
rm -rf "$OUT" "$DL"
mkdir -p "$OUT" "$DL"

while read -r id version _; do
    [[ -z "${id:-}" || "$id" == \#* ]] && continue
    pkg="$DL/$id.dusk"
    if [ -f "$REPO/mods/$id.dusk" ]; then
        echo "::notice::$id: using mods/$id.dusk from the repo"
        cp "$REPO/mods/$id.dusk" "$pkg"
    else
        url="https://twilitrealm.dev/download/dusklight/$id/$version"
        echo "$id: downloading $url"
        if ! curl -fsSL --retry 3 -o "$pkg" "$url"; then
            echo "::error::$id: download failed ($url). Put the file at mods/$id.dusk instead."
            exit 1
        fi
    fi
    if ! unzip -tq "$pkg" >/dev/null 2>&1; then
        echo "::error::$id: downloaded file is not a valid .dusk package"
        exit 1
    fi
    dest="$OUT/$id"
    mkdir -p "$dest"
    unzip -q "$pkg" -d "$dest"
    real_id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['id'])" "$dest/mod.json")
    if [ "$real_id" != "$id" ]; then
        echo "::error::$id: package id is $real_id"
        exit 1
    fi
    if [ ! -f "$dest/lib/ios-arm64/mod.so" ]; then
        echo "::error::$id has no iOS build (lib/ios-arm64/mod.so). Assets-only mods don't need bundling."
        exit 1
    fi
    # Keep only the iOS library; the other platforms would just bloat the app.
    find "$dest/lib" -mindepth 1 -maxdepth 1 -type d ! -name ios-arm64 -exec rm -rf {} +
    echo "$id $version: OK ($(du -sh "$dest" | cut -f1))"
done < "$REPO/mods.txt"
