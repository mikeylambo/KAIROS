#!/usr/bin/env bash
# KAIROS check: import, parse, tests, headless boot. Extended per BUILD_BRIEF §1/§5.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LOG="$(mktemp)"

echo "== import"; "$GODOT" --headless --import >"$LOG" 2>&1 || { cat "$LOG"; exit 1; }

echo "== boot (300 frames)"
"$GODOT" --headless --quit-after 300 res://scenes/main.tscn >"$LOG" 2>&1 || { cat "$LOG"; exit 1; }
if grep -E "SCRIPT ERROR|ERROR:|WARNING:" "$LOG"; then echo "boot produced errors/warnings"; exit 1; fi

if [ -d addons/gut ]; then
  echo "== tests"
  "$GODOT" --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
fi

if [ -f tools/bot.gd ]; then
  echo "== bot playthrough"
  "$GODOT" --headless -s tools/bot.gd
fi
echo "check: OK"
