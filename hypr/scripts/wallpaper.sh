#!/usr/bin/env bash
#  Wallpaper manager  (SUPER+SHIFT+W)
#
#    wallpaper.sh          picker with thumbnails
#    wallpaper.sh init     restore the last wallpaper at login
#    wallpaper.sh random   pick a random one
#    wallpaper.sh next     step to the next one alphabetically
#
#  Uses awww, so changes cross-fade instead of snapping. Applied to
#  all three monitors at once.

set -uo pipefail

DIR="$HOME/Pictures/Wallpapers"
STATE="${XDG_CACHE_HOME:-$HOME/.cache}/current-wallpaper"

mkdir -p "$DIR" "$(dirname "$STATE")"

# awww-daemon may not have finished starting up at login.
wait_for_daemon() {
    for _ in $(seq 1 20); do
        awww query >/dev/null 2>&1 && return 0
        sleep 0.25
    done
    awww-daemon &
    sleep 1
}

list() {
    find -L "$DIR" -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
           -o -iname '*.webp' -o -iname '*.gif' -o -iname '*.bmp' \) \
        | sort
}

apply() {
    local img="$1"
    [ -f "$img" ] || return 1

    local transitions=(wipe wave grow outer center random)
    local t=${transitions[$RANDOM % ${#transitions[@]}]}

    awww img "$img" \
        --transition-type "$t" \
        --transition-fps 60 \
        --transition-duration 1.2 \
        --transition-angle 30 >/dev/null 2>&1

    printf '%s' "$img" > "$STATE"
}

mapfile -t WALLS < <(list)

if [ ${#WALLS[@]} -eq 0 ]; then
    [ "${1:-}" = "init" ] || notify-send -u normal -a "Wallpaper" \
        "No wallpapers found" "Drop images into $DIR"
    exit 0
fi

case "${1:-pick}" in
    init)
        wait_for_daemon
        if [ -s "$STATE" ] && [ -f "$(cat "$STATE")" ]; then
            apply "$(cat "$STATE")"
        else
            apply "${WALLS[0]}"
        fi
        ;;

    random)
        wait_for_daemon
        apply "${WALLS[$RANDOM % ${#WALLS[@]}]}"
        ;;

    next)
        wait_for_daemon
        cur=$(cat "$STATE" 2>/dev/null || true)
        idx=0
        for i in "${!WALLS[@]}"; do
            [ "${WALLS[$i]}" = "$cur" ] && idx=$(( (i + 1) % ${#WALLS[@]} ))
        done
        apply "${WALLS[$idx]}"
        ;;

    pick)
        wait_for_daemon
        # Feed rofi the filename plus an icon, so you get a thumbnail grid.
        #
        # NOTE: this is piped straight into rofi rather than captured in
        # a variable first. rofi's icon protocol is "label\0icon\x1fpath",
        # and command substitution silently strips NUL bytes — which
        # would leave the icons dead and the labels mangled.
        sel=$({
            printf '%s\n' "🎲  Random"
            for w in "${WALLS[@]}"; do
                printf '%s\x00icon\x1f%s\n' "$(basename "${w%.*}")" "$w"
            done
        } | rofi -dmenu -i \
            -p "wallpaper" \
            -show-icons \
            -theme-str 'window { width: 60%; }' \
            -theme-str 'listview { columns: 4; lines: 3; }' \
            -theme-str 'element-icon { size: 8em; }' \
            -theme-str 'element { orientation: vertical; }')

        [ -z "$sel" ] && exit 0

        if [ "$sel" = "🎲  Random" ]; then
            apply "${WALLS[$RANDOM % ${#WALLS[@]}]}"
            exit 0
        fi

        for w in "${WALLS[@]}"; do
            if [ "$(basename "${w%.*}")" = "$sel" ]; then
                apply "$w"
                exit 0
            fi
        done
        ;;

    *)
        echo "usage: wallpaper.sh {pick|init|random|next}" >&2
        exit 2
        ;;
esac
