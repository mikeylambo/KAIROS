#!/usr/bin/env bash
# Builds macOS (universal, ad-hoc signed .zip) and Windows (x86_64 .exe, embedded pck) into build/.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
mkdir -p build/macos build/windows
"$GODOT" --headless --import >/dev/null 2>&1
"$GODOT" --headless --export-release "macOS" build/macos/KAIROS.zip
"$GODOT" --headless --export-release "Windows" build/windows/KAIROS.exe
ls -la build/macos build/windows
