#!/usr/bin/env bash
#  Game / performance mode toggle  (SUPER+ALT+G)
#
#  Strips every effect — blur, shadows, animations, rounding, gaps,
#  inactive dimming — so the GPU spends its time on the game. Also handy
#  before a screen recording. Press again to restore your config as it is
#  on disk.
#
#  Uses `hyprctl eval` with Lua, NOT `hyprctl keyword`: the config is
#  hyprland.lua, and under the Lua parser keyword fails with
#    "keyword can't work with non-legacy parsers. Use eval."

set -uo pipefail

state=$(hyprctl getoption animations:enabled -j | python3 -c 'import json,sys; print(json.load(sys.stdin)["int"])')

if [ "$state" = "1" ]; then
    hyprctl eval '
        hl.config({
            animations = { enabled = false },
            decoration = {
                blur = { enabled = false },
                shadow = { enabled = false },
                dim_inactive = false,
                rounding = 0,
                inactive_opacity = 1.0,
            },
            general = {
                gaps_in = 0,
                gaps_out = 0,
                border_size = 1,
            },
        })
    ' >/dev/null

    notify-send -a "Hyprland" -i applications-games \
        "Game mode ON" "Effects disabled"
else
    hyprctl reload >/dev/null
    notify-send -a "Hyprland" -i preferences-desktop-theme \
        "Game mode OFF" "Effects restored"
fi
