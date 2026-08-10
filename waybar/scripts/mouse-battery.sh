#!/usr/bin/env bash
#  Wireless mouse / keyboard battery for waybar.
#
#  Reads the hidpp power_supply entries the kernel creates for Logitech
#  devices (yours reports as "PRO X 2 DEX"). The module renders nothing
#  at all when no such device is present or it is powered off, so the
#  bar does not carry a dead icon around.

set -uo pipefail

out_text=""
out_tip=""
class="mouse"
lowest=100

shopt -s nullglob
for dev in /sys/class/power_supply/hidpp_battery_*; do
    [ -r "$dev/capacity" ] || continue

    cap=$(cat "$dev/capacity" 2>/dev/null) || continue
    [ -z "$cap" ] && continue

    model=$(cat "$dev/model_name" 2>/dev/null || echo "Wireless device")
    status=$(cat "$dev/status" 2>/dev/null || echo "Unknown")

    [ "$cap" -lt "$lowest" ] && lowest=$cap

    [ -n "$out_tip" ] && out_tip="${out_tip}\\n"
    out_tip="${out_tip}${model}: ${cap}%"
    [ "$status" != "Unknown" ] && out_tip="${out_tip} (${status})"
done
shopt -u nullglob

# Nothing found — emit empty text so waybar collapses the module.
if [ -z "$out_tip" ]; then
    printf '{"text":"","tooltip":""}\n'
    exit 0
fi

# Icon reflects the charge level
if   [ "$lowest" -ge 80 ]; then icon="󰥅"
elif [ "$lowest" -ge 60 ]; then icon="󰤾"
elif [ "$lowest" -ge 40 ]; then icon="󰤻"
elif [ "$lowest" -ge 20 ]; then icon="󰤸"
else                            icon="󰤳"; class="mouse-critical"
fi
[ "$lowest" -lt 30 ] && [ "$class" = "mouse" ] && class="mouse-warning"

out_text="${icon}  ${lowest}%"

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$out_text" "$out_tip" "$class"
