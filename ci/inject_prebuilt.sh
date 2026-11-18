#!/usr/bin/env bash
# Hooks ci/prebuilt_mods.cmake into Dusklight's CMakeLists right before install_bundled_mods().
set -euo pipefail
REPO="$1"
DUSK="$2"
cp "$REPO/ci/prebuilt_mods.cmake" "$DUSK/cmake/PrebuiltMods.cmake"
cp "$REPO/ci/engine_patchable.cmake" "$DUSK/cmake/EnginePatchable.cmake"
python3 - "$DUSK/CMakeLists.txt" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
anchor = "\ninstall_bundled_mods()\n"
if "PrebuiltMods.cmake" not in s:
    if anchor not in s:
        sys.exit("inject_prebuilt.sh: install_bundled_mods() not found")
    s = s.replace(anchor, "\ninclude(cmake/EnginePatchable.cmake)\ninclude(cmake/PrebuiltMods.cmake)" + anchor, 1)
    open(p, "w").write(s)
PY
grep -n "PrebuiltMods.cmake" "$DUSK/CMakeLists.txt"
