#!/usr/bin/env bash
# KAIROS check (BUILD_BRIEF §1): import → parse every script → GUT → headless boot
# of main.tscn for 300 frames → bot playthrough. Non-zero exit on any failure.
set -uo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
LOG="$(mktemp)"
fail() { echo "check: FAIL ($1)"; cat "$LOG" | tail -60; exit 1; }
noisy() { grep -E "SCRIPT ERROR|^ERROR:|^WARNING:|Parse Error" "$LOG" | grep -v "ObjectDB instances leaked\|resources still in use" ; }

echo "== 1/5 import"
"$GODOT" --headless --import >"$LOG" 2>&1 || fail import
noisy && fail "import errors"

echo "== 2/5 parse all scripts"
"$GODOT" --headless res://tools/runner.tscn -- --tool=res://tools/parse_all.gd >"$LOG" 2>&1 || fail parse
noisy && fail "parse errors/warnings"
grep "parse_all" "$LOG"

echo "== 3/5 GUT tests"
"$GODOT" --headless -s addons/gut/gut_cmdln.gd -gexit >"$LOG" 2>&1 || fail tests
grep -E "Passing Tests|Failing Tests|Asserts" "$LOG"

echo "== 4/5 headless boot (300 frames)"
"$GODOT" --headless --quit-after 300 res://scenes/main.tscn >"$LOG" 2>&1 || fail boot
noisy && fail "boot produced errors/warnings"
echo "boot: clean"

if [ -f tools/bot.gd ] && [ "${SKIP_BOT:-0}" != "1" ]; then
  echo "== 5/5 bot playthrough"
  "$GODOT" --headless --fixed-fps 60 res://tools/runner.tscn -- --tool=res://tools/bot.gd >"$LOG" 2>&1 || fail bot
  noisy && fail "bot produced errors/warnings"
  grep -E "^bot" "$LOG"
fi
echo "check: OK"
