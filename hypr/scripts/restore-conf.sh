#!/usr/bin/env bash
#  EMERGENCY ROLLBACK: hyprland.lua  ->  the previous hyprland.conf setup
#
#  Use this if the Lua config fails to start a session (log in → black
#  screen → back to sddm). Get to a TTY with Ctrl+Alt+F3, log in, then:
#
#      ~/.config/hypr/scripts/restore-conf.sh
#
#  and log in again from sddm.
#
#  The .conf format still works on Hyprland 0.56 — it is only removed in
#  0.57 — so this is a safe fallback *today*. If you are reading this
#  after upgrading to 0.57 or later, .conf will no longer be parsed and
#  you need to fix hyprland.lua instead. Check with:
#      Hyprland --version
#      Hyprland --verify-config

set -uo pipefail

H="$HOME/.config/hypr"
B="$H/conf.bak"

if [ ! -f "$B/hyprland.conf" ]; then
    echo "No backup found at $B/hyprland.conf — nothing to restore." >&2
    exit 1
fi

ts=$(date +%Y%m%d-%H%M%S)

# Park the Lua config rather than deleting it, so it can be fixed later.
if [ -f "$H/hyprland.lua" ]; then
    mv "$H/hyprland.lua" "$H/hyprland.lua.parked-$ts"
    echo "Moved hyprland.lua -> hyprland.lua.parked-$ts"
fi

mkdir -p "$H/conf"
for f in "$B"/*.conf; do
    base=$(basename "$f")
    if [ "$base" = "hyprland.conf" ]; then
        cp -f "$f" "$H/hyprland.conf"
    else
        cp -f "$f" "$H/conf/$base"
    fi
done

echo "Restored the .conf setup:"
echo "  $H/hyprland.conf"
echo "  $H/conf/*.conf"

echo
echo "Validating..."
if Hyprland --verify-config >/dev/null 2>&1; then
    echo "  ✅ config is valid — log out and back in."
else
    echo "  ⚠ validation reported problems:"
    Hyprland --verify-config 2>&1 | sed -n '/parsing result/,$p' | sort -u | head -10
fi

echo
echo "NOTE: monitors.sh and gamemode.sh were converted to 'hyprctl eval'"
echo "for the Lua parser. Under .conf they need 'hyprctl keyword' again."
echo "The cheatsheet (keybinds.sh) reads 'hyprctl binds' and works with both."
