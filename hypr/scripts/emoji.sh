#!/usr/bin/env bash
#  Emoji picker  (SUPER+.)
#
#  Selecting one copies it to the clipboard and types it into the
#  focused window if wtype is available.
#
#  No AUR plugin needed — the emoji list is generated once from
#  Python's built-in Unicode database and cached.

set -uo pipefail

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/emoji-list.txt"

if [ ! -s "$CACHE" ]; then
    mkdir -p "$(dirname "$CACHE")"
    python3 - "$CACHE" <<'PY'
import sys, unicodedata

# The blocks that actually contain pictographic emoji.
RANGES = [
    (0x1F300, 0x1F5FF),  # misc symbols & pictographs
    (0x1F600, 0x1F64F),  # emoticons
    (0x1F680, 0x1F6FF),  # transport & map
    (0x1F900, 0x1F9FF),  # supplemental symbols
    (0x1FA70, 0x1FAFF),  # extended-A
    (0x2600,  0x26FF),   # misc symbols
    (0x2700,  0x27BF),   # dingbats
    (0x1F1E6, 0x1F1FF),  # regional indicators
]

with open(sys.argv[1], "w", encoding="utf-8") as fh:
    for lo, hi in RANGES:
        for cp in range(lo, hi + 1):
            ch = chr(cp)
            try:
                name = unicodedata.name(ch)
            except ValueError:
                continue
            fh.write(f"{ch}  {name.lower()}\n")
PY
fi

choice=$(rofi -dmenu -i \
    -p "emoji" \
    -theme-str 'window { width: 40%; }' \
    -theme-str 'listview { lines: 10; columns: 1; }' \
    < "$CACHE")

[ -z "$choice" ] && exit 0

emoji="${choice%% *}"

printf '%s' "$emoji" | wl-copy >/dev/null 2>&1

# Type it directly if we can, so it appears without a manual paste.
if command -v wtype >/dev/null 2>&1; then
    wtype -- "$emoji" 2>/dev/null || true
fi

notify-send -a "Emoji" "$emoji copied to clipboard"
