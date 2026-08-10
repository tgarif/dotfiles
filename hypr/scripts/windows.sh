#!/usr/bin/env bash
#  Window switcher  (SUPER+W)
#
#  WHY THIS EXISTS instead of `rofi -show window`:
#  rofi's built-in window mode talks EWMH over X11. Under Wayland there
#  is no EWMH, so that mode silently returns nothing at all. This asks
#  Hyprland directly via hyprctl.
#
#  It also shows which MONITOR and WORKSPACE each window lives on, which
#  is the whole point on a three-screen desk — "where did that terminal
#  go" gets answered without alt-tabbing across all of them.
#
#    windows.sh          open the switcher
#    windows.sh --list   print the entries as plain text (debugging)

set -uo pipefail

tmp=$(mktemp -d) || exit 1
trap 'rm -rf "$tmp"' EXIT

#  ONE snapshot of Hyprland state, written to two parallel files:
#    labels  — what rofi displays (contains NUL for the icon protocol)
#    addrs   — the window address on the matching line
#  Taking a single snapshot means the index rofi returns can never point
#  at a different window than the one that was displayed.
#
#  NOTE: hyprctl is called via subprocess INSIDE python rather than
#  piped in. `python3 - <<'PY'` already uses stdin for the script
#  itself, so a pipe into it would be swallowed by the heredoc.
python3 - "$tmp/labels" "$tmp/addrs" <<'PY'
import json, subprocess, sys

# Keyed on a substring of the monitor DESCRIPTION, not the connector
# name — DP-N numbering shifts with GPU driver load order.
MON_MATCH = [("AG273F1G8R3", "AOC"), ("XL2566X+", "BenQ"), ("MPG321UX", "MSI 4K")]

def friendly(desc):
    for needle, label in MON_MATCH:
        if needle in (desc or ""):
            return label
    return (desc or "?").split()[0] if desc else "?"

def hypr(*args):
    return json.loads(subprocess.check_output(["hyprctl", *args, "-j"]))

try:
    clients = hypr("clients")
except Exception as e:
    sys.stderr.write(f"hyprctl clients failed: {e}\n")
    sys.exit(1)

try:
    idx2desc = {m["id"]: m.get("description", "") for m in hypr("monitors")}
except Exception:
    idx2desc = {}

rows = []
for c in clients:
    if not c.get("mapped", True):
        continue
    cls   = (c.get("class") or "").strip()
    title = (c.get("title") or "").strip()
    if not cls and not title:
        continue

    desc = idx2desc.get(c.get("monitor"), "")
    rows.append({
        "addr":  c["address"],
        "cls":   cls or "unknown",
        "title": title or cls,
        "ws":    str((c.get("workspace") or {}).get("name", "?")),
        "mon":   friendly(desc),
    })

# Focused window first, then group by monitor for a predictable order
rows.sort(key=lambda r: (r["mon"], r["ws"], r["cls"].lower()))

labels_path, addrs_path = sys.argv[1], sys.argv[2]
width = min(max((len(r["cls"]) for r in rows), default=1), 20)

with open(labels_path, "w", encoding="utf-8") as lf, \
     open(addrs_path, "w", encoding="utf-8") as af:
    for r in rows:
        cls = r["cls"][:width].ljust(width)
        title = r["title"]
        if len(title) > 58:
            title = title[:57] + "…"
        label = f'{cls}  │  {title}   ›  {r["mon"]} ws{r["ws"]}'
        # rofi icon protocol: label \0 icon \x1f <icon-name>
        lf.write(f'{label}\x00icon\x1f{r["cls"].lower()}\n')
        af.write(r["addr"] + "\n")
PY

[ -s "$tmp/addrs" ] || { notify-send -a "Windows" "No open windows"; exit 0; }

if [ "${1:-}" = "--list" ]; then
    paste -d'|' <(tr -d '\000' < "$tmp/labels" | sed 's/icon\x1f.*$//') "$tmp/addrs"
    exit 0
fi

#  -format i makes rofi return the zero-based INDEX of the selection,
#  which we map straight onto the addrs file. No fragile label re-parsing.
idx=$(rofi -dmenu -i \
        -p "windows" \
        -show-icons \
        -format i \
        -theme-str 'window { width: 52%; }' \
        -theme-str 'listview { lines: 12; }' \
        < "$tmp/labels")

[ -z "$idx" ] && exit 0
case "$idx" in ''|*[!0-9]*) exit 0 ;; esac

addr=$(sed -n "$((idx + 1))p" "$tmp/addrs")
[ -z "$addr" ] && exit 0

hyprctl dispatch focuswindow "address:$addr" >/dev/null
