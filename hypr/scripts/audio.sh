#!/usr/bin/env bash
#  Audio device switcher  (SUPER+A)
#
#    audio.sh headset   Logitech PRO X 2 LIGHTSPEED (output + its mic)
#    audio.sh elgato    Elgato Wave XLR (output + mic)
#    audio.sh hdmi      HDMI output only, mic left alone
#    audio.sh toggle    flip between headset and elgato
#    audio.sh list      show devices and which is default
#
#  MATCHED BY NAME, NEVER BY NUMERIC ID.
#  PipeWire node IDs change constantly — during this script's own setup
#  the headset moved from 63 to 68 between two consecutive commands. Any
#  script hardcoding `wpctl set-default 63` breaks on the next reconnect.
#  The substrings below come from the ALSA node names, which are derived
#  from the USB product string and are stable.
#
#  Also moves ALREADY-RUNNING streams. `set-default` only affects streams
#  created *after* it, so without the move step a call already in progress
#  keeps using the old device — which is exactly when you least want it.

set -uo pipefail

case "${1:-toggle}" in
    headset|logitech|pro|h) MATCH="Logitech_PRO_X_2" ; LABEL="Logitech PRO X 2" ;;
    elgato|wave|xlr|e)      MATCH="Elgato"           ; LABEL="Elgato Wave XLR" ;;
    hdmi)                   MATCH="hdmi"             ; LABEL="HDMI" ;;
    list|-l)
        printf 'OUTPUTS\n'
        pactl list short sinks   | awk '{printf "  %s\n", $2}'
        printf 'MICS\n'
        pactl list short sources | grep -v monitor | awk '{printf "  %s\n", $2}'
        printf '\ncurrent output: %s\n' "$(pactl get-default-sink)"
        printf 'current mic:    %s\n'   "$(pactl get-default-source)"
        exit 0 ;;
    toggle|t)
        if pactl get-default-sink | grep -q "Logitech_PRO_X_2"; then
            MATCH="Elgato"; LABEL="Elgato Wave XLR"
        else
            MATCH="Logitech_PRO_X_2"; LABEL="Logitech PRO X 2"
        fi ;;
    *)
        echo "usage: audio.sh {headset|elgato|hdmi|toggle|list}" >&2; exit 2 ;;
esac

sink=$(pactl list short sinks | awk -v m="$MATCH" '$2 ~ m {print $2; exit}')
mic=$(pactl list short sources | grep -v monitor | awk -v m="$MATCH" '$2 ~ m {print $2; exit}')

if [ -z "$sink" ]; then
    notify-send -u critical -a "Audio" "$LABEL not found" "Is it connected and powered on?"
    exit 1
fi

pactl set-default-sink "$sink" >/dev/null
# HDMI has no microphone; leave the current mic alone rather than unset it.
[ -n "$mic" ] && pactl set-default-source "$mic" >/dev/null

# Move anything already playing / recording onto the new device.
for id in $(pactl list short sink-inputs | awk '{print $1}'); do
    pactl move-sink-input "$id" "$sink" 2>/dev/null || true
done
if [ -n "$mic" ]; then
    for id in $(pactl list short source-outputs | awk '{print $1}'); do
        pactl move-source-output "$id" "$mic" 2>/dev/null || true
    done
fi

notify-send -a "Audio" -i audio-headphones "$LABEL" \
    "$([ -n "$mic" ] && echo 'Output + mic switched' || echo 'Output switched')"
