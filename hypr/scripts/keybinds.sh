#!/usr/bin/env bash
#  Keybinding cheatsheet  (SUPER+/)
#
#  Built from the `description` field of the LIVE bind table.
#
#  WHY descriptions and not the dispatcher: under the Lua config parser
#  `hyprctl binds` reports every bind as
#      "dispatcher": "__lua",  "arg": "207"
#  where the arg is an internal closure index. The action is genuinely
#  unrecoverable at runtime, so the description set in hyprland.lua is the
#  only human-readable label there is.
#
#  If a bind shows as "(no description)", add one in hyprland.lua — every
#  bind there goes through the local bind() helper which takes one.
#
#    keybinds.sh          open the searchable cheatsheet
#    keybinds.sh --list   print to stdout (debugging)

set -uo pipefail

render() {
    hyprctl binds -j | python3 -c '
import json, sys

# X11 modifier bitmask as reported by Hyprland
MODS = [(1, "SHIFT"), (2, "CAPS"), (4, "CTRL"), (8, "ALT"), (64, "SUPER")]

PRETTY = {
    "return": "Enter", "space": "Space", "period": ".", "slash": "/",
    "equal": "=", "grave": "`", "escape": "Esc", "print": "PrtSc",
    "left": "←", "right": "→", "up": "↑", "down": "↓",
    "mouse_down": "Scroll↓", "mouse_up": "Scroll↑",
    "mouse:272": "L-drag", "mouse:273": "R-drag",
    "tab": "Tab", "minus": "-", "plus": "+",
}

# Group headings so the list reads as a reference, not a dump
def group(desc, combo):
    d = desc.lower()
    if "screenshot" in d or "colour" in d or "color" in d: return "3 Screenshots"
    if "monitor" in d or any(k in combo for k in ("F1", "F2", "F3")):  return "2 Monitors"
    if "workspace" in d or "scratchpad" in d:                          return "4 Workspaces"
    if any(k in d for k in ("volume", "mute", "track", "play", "bright", "playback")):
        return "6 Media keys"
    if any(k in d for k in ("lock", "power", "reload", "notification",
                            "disturb", "wallpaper", "game mode")):     return "5 Session"
    if any(k in d for k in ("focus", "swap", "move window", "resize", "cycle")):
        return "1 Windows"
    if any(k in d for k in ("terminal", "browser", "file manager", "launch",
                            "run a command", "clipboard", "emoji",
                            "calculator", "cheatsheet", "switch window")):
        return "0 Launch"
    return "1 Windows"

def combo(b):
    mask = b.get("modmask", 0) or 0
    parts = [n for bit, n in MODS if mask & bit]
    key = b.get("key") or ""
    if not key and b.get("keycode"):
        key = f"code:{b['keycode']}"
    parts.append(PRETTY.get(key.lower(), key))
    return " + ".join(p for p in parts if p)

rows = []
for b in json.load(sys.stdin):
    desc = (b.get("description") or "").strip()
    sub  = (b.get("submap") or "").strip()
    c = combo(b)
    if sub:
        # Submap binds only apply inside that mode; label them clearly.
        c = f"{c}   ({sub} mode)"
        g = "1 Windows"
    else:
        g = group(desc, c)
    rows.append((g, c, desc or "(no description)"))

rows.sort(key=lambda r: (r[0], r[1].count("+"), r[1]))

width = max((len(c) for _, c, _ in rows), default=0)
last = None
for g, c, d in rows:
    if g != last:
        print(f"─── {g[2:]} " + "─" * max(0, width + 24 - len(g)))
        last = g
    print(f"  {c.ljust(width)}   {d}")
'
}

if [ "${1:-}" = "--list" ]; then
    render
    exit 0
fi

render | rofi -dmenu -i \
    -p "keybinds" \
    -theme-str 'window { width: 62%; }' \
    -theme-str 'listview { lines: 20; }' \
    -theme-str 'element-text { font: "JetBrainsMono Nerd Font 11"; }' >/dev/null
