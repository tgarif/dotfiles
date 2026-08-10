#!/usr/bin/env bash
#  Pending package updates for waybar.
#
#  checkupdates (pacman-contrib) is used rather than `pacman -Sy`
#  because it refreshes a private database copy — it will never leave
#  your real pacman db in a partially-synced state, which is what
#  causes the classic Arch partial-upgrade breakage.

set -uo pipefail

repo=0
aur=0

if command -v checkupdates >/dev/null 2>&1; then
    repo=$(checkupdates 2>/dev/null | wc -l)
fi

if command -v yay >/dev/null 2>&1; then
    aur=$(yay -Qua 2>/dev/null | wc -l)
fi

total=$(( repo + aur ))

if [ "$total" -eq 0 ]; then
    printf '{"text":"","tooltip":"System is up to date","class":"updated"}\n'
    exit 0
fi

list=$( { checkupdates 2>/dev/null; yay -Qua 2>/dev/null; } | head -25 \
        | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' | paste -sd'\n' - | sed ':a;N;$!ba;s/\n/\\n/g')

[ "$total" -gt 25 ] && list="${list}\\n… and $(( total - 25 )) more"

class="updates"
[ "$total" -ge 50 ] && class="updates-many"

printf '{"text":"󰚰  %s","tooltip":"%s repo · %s AUR\\n\\n%s","class":"%s"}\n' \
    "$total" "$repo" "$aur" "$list" "$class"
