#!/usr/bin/env bash
# Runs inside the unpacked mod. iOS file names are case-sensitive (macOS's are not):
# the mod loads "res/sounds/silence.wav" but ships "res/sounds/Silence.wav".
# The build machine is macOS too (case-insensitive), so compare the exact listed name and
# rename through a temporary name.
set -euo pipefail
if ls res/sounds | grep -qx 'Silence.wav'; then
    mv res/sounds/Silence.wav res/sounds/silence.wav.tmp
    mv res/sounds/silence.wav.tmp res/sounds/silence.wav
    echo "fairy_companion: renamed Silence.wav -> silence.wav"
fi
ls res/sounds | grep -qx 'silence.wav' || { echo "::error::fairy_companion: silence.wav missing"; exit 1; }
