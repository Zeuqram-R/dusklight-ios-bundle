#!/usr/bin/env bash
# Runs inside the unpacked mod. iOS file names are case-sensitive (macOS's are not):
# the mod loads "res/sounds/silence.wav" but ships "res/sounds/Silence.wav".
set -euo pipefail
if [ -f res/sounds/Silence.wav ] && [ ! -f res/sounds/silence.wav ]; then
    mv res/sounds/Silence.wav res/sounds/silence.wav
    echo "fairy_companion: renamed Silence.wav -> silence.wav"
fi
