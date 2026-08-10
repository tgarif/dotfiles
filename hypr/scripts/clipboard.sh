#!/usr/bin/env bash
#  Clipboard history picker  (SUPER+V)
#
#  cliphist stores everything you copy; this lets you search it.
#  Select an entry to put it back on the clipboard.
#  Shift+Delete on a highlighted entry removes it from history.

set -uo pipefail

if ! command -v cliphist >/dev/null 2>&1; then
    notify-send -u critical "Clipboard" "cliphist is not installed"
    exit 1
fi

choice=$(cliphist list | rofi -dmenu \
    -p "clipboard" \
    -i \
    -kb-custom-1 "Shift+Delete" \
    -theme-str 'window { width: 45%; }' \
    -theme-str 'listview { lines: 12; }')
status=$?

[ -z "$choice" ] && exit 0

case $status in
    # Shift+Delete → forget this entry
    10)
        printf '%s' "$choice" | cliphist delete
        notify-send -a "Clipboard" "Entry deleted from history"
        ;;
    0)
        printf '%s' "$choice" | cliphist decode | wl-copy >/dev/null 2>&1
        ;;
esac
