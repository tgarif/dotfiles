#!/usr/bin/env bash
#  Reload the whole desktop shell  (SUPER+SHIFT+R)
#
#  hyprctl reload only re-reads Hyprland's own config — waybar and
#  swaync keep running with their old settings. This restarts the lot.

set -uo pipefail

hyprctl reload >/dev/null 2>&1

pkill -x waybar 2>/dev/null
pkill -x swaync 2>/dev/null

sleep 0.4

waybar >/dev/null 2>&1 &
disown
swaync >/dev/null 2>&1 &
disown

# Put the monitors back to full refresh in case the reload reset them.
"$HOME/.config/hypr/scripts/monitors.sh" >/dev/null 2>&1 &
disown

sleep 0.6
notify-send -a "Hyprland" -i view-refresh "Config reloaded" \
    "Hyprland · waybar · swaync restarted"
