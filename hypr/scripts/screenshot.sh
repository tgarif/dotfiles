#!/usr/bin/env bash
#  Screenshots — region / window / monitor / annotate
#
#    screenshot.sh region    drag a box          (PRINT)
#    screenshot.sh window    the focused window  (SHIFT+PRINT)
#    screenshot.sh monitor   the whole screen    (CTRL+PRINT)
#    screenshot.sh edit      region, then open the annotation editor
#
#  Everything lands in ~/Pictures/Screenshots AND on the clipboard.

set -uo pipefail

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

MODE="${1:-region}"

# Catppuccin-tinted selection box
SLURP_ARGS=(-d -b 1e1e2e99 -c cba6f7ff -s cba6f722 -w 2)

case "$MODE" in
    region)
        geom=$(slurp "${SLURP_ARGS[@]}") || exit 0
        grim -g "$geom" "$FILE" || exit 1
        ;;
    window)
        # Pull the focused window's geometry straight from Hyprland,
        # accounting for the monitor it sits on.
        geom=$(hyprctl activewindow -j | python3 -c '
import json,sys
w = json.load(sys.stdin)
x, y = w["at"]
cx, cy = w["size"]
print(f"{x},{y} {cx}x{cy}")
') || exit 1
        grim -g "$geom" "$FILE" || exit 1
        ;;
    monitor)
        out=$(hyprctl activeworkspace -j | python3 -c 'import json,sys; print(json.load(sys.stdin)["monitor"])')
        grim -o "$out" "$FILE" || exit 1
        ;;
    edit)
        geom=$(slurp "${SLURP_ARGS[@]}") || exit 0
        if command -v swappy >/dev/null 2>&1; then
            grim -g "$geom" - | swappy -f -
            exit 0
        fi
        grim -g "$geom" "$FILE" || exit 1
        ;;
    *)
        echo "usage: screenshot.sh {region|window|monitor|edit}" >&2
        exit 2
        ;;
esac

wl-copy < "$FILE" >/dev/null 2>&1

notify-send -i "$FILE" -a "Screenshot" "Screenshot captured" \
    "Copied to clipboard\n$(basename "$FILE")"
