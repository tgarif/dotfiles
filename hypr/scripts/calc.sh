#!/usr/bin/env bash
#  Inline calculator  (SUPER+=)
#
#  Type any expression — "1920/1.5", "17% of 4000", "3 GiB to MB",
#  "sqrt(2)", "0xff", "25 USD to MYR" — press Enter and the result
#  is copied to the clipboard.
#
#  Backed by qalc (libqalculate), which is far smarter than bc:
#  it does units, currencies and percentages.

set -uo pipefail

if ! command -v qalc >/dev/null 2>&1; then
    notify-send -u critical "Calculator" "libqalculate (qalc) is not installed"
    exit 1
fi

expr=$(rofi -dmenu \
    -p "calc" \
    -theme-str 'window { width: 30%; }' \
    -theme-str 'listview { enabled: false; }' \
    -theme-str 'inputbar { children: [ prompt, entry ]; }')

[ -z "$expr" ] && exit 0

result=$(qalc -t -- "$expr" 2>/dev/null)

if [ -z "$result" ]; then
    notify-send -u normal -a "Calculator" "Could not evaluate" "$expr"
    exit 1
fi

printf '%s' "$result" | wl-copy >/dev/null 2>&1
notify-send -a "Calculator" "$expr" "= $result   (copied)"
