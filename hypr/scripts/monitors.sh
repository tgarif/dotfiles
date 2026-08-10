#!/usr/bin/env bash
#  Re-assert the monitor layout.
#
#  Why this exists: DisplayPort link training on very high refresh
#  panels (the BenQ's 400 Hz especially) sometimes settles at 60 Hz on
#  a cold boot. Running this puts everything back where it belongs.
#
#  Called automatically 2s after login, and available as a manual fix.

set -uo pipefail

apply() {
    # Matched by DESCRIPTION, not connector name. DP-N numbering depends
    # on GPU driver load order and has already changed once on this box.
    #
    # `hyprctl eval` (Lua), NOT `hyprctl keyword`: the config is
    # hyprland.lua, and under the Lua parser keyword fails with
    #   "keyword can't work with non-legacy parsers. Use eval."
    hyprctl eval 'hl.monitor({ output = "desc:AOC AG273F1G8R3",        mode = "1920x1080@239.96", position = "0x180",    scale = 1 })'
    hyprctl eval 'hl.monitor({ output = "desc:BNQ XL2566X+",           mode = "1920x1080@400.00", position = "1920x180", scale = 1 })'
    hyprctl eval 'hl.monitor({ output = "desc:Microstep MPG321UX OLED", mode = "3840x2160@239.99", position = "3840x0",   scale = 1.5 })'
}

apply

# Verify, and retry once if any monitor came up below 100 Hz.
sleep 1
low=$(hyprctl monitors -j | grep -o '"refreshRate": [0-9.]*' | awk '{ if ($2 < 100) c++ } END { print c+0 }')

if [ "$low" -gt 0 ]; then
    notify-send -u normal -i display "Display" "A monitor negotiated low — retrying"
    sleep 1
    apply
fi

if [ "${1:-}" = "--verbose" ]; then
    hyprctl monitors -j | python3 -c '
import json,sys
for m in sorted(json.load(sys.stdin), key=lambda x: x["x"]):
    print(f"{m[\"name\"]:6} {m[\"width\"]}x{m[\"height\"]}@{m[\"refreshRate\"]:.2f}  @{m[\"x\"]},{m[\"y\"]}  scale {m[\"scale\"]}")
'
fi
