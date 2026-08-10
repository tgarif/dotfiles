#!/usr/bin/env bash
#  RTX 5080 status for waybar.
#  Emits JSON: utilisation in the bar, full detail in the tooltip.

set -uo pipefail

if ! command -v nvidia-smi >/dev/null 2>&1; then
    printf '{"text":"","tooltip":"nvidia-smi not available","class":"gpu-error"}\n'
    exit 0
fi

read -r util temp memused memtotal power name < <(
    nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,power.draw,name \
               --format=csv,noheader,nounits 2>/dev/null \
        | awk -F', *' '{ printf "%s %s %s %s %s %s\n", $1, $2, $3, $4, $5, $6 }'
) || { printf '{"text":"","tooltip":"GPU query failed","class":"gpu-error"}\n'; exit 0; }

[ -z "${util:-}" ] && { printf '{"text":"","tooltip":"GPU query returned nothing","class":"gpu-error"}\n'; exit 0; }

# Colour-code the bar entry by load
class="gpu"
if   [ "$util" -ge 90 ]; then class="gpu-critical"
elif [ "$util" -ge 60 ]; then class="gpu-warning"
fi

mempct=$(( memused * 100 / (memtotal > 0 ? memtotal : 1) ))

tooltip=$(printf '%s\\nLoad     %s%%\\nTemp     %s°C\\nVRAM     %s / %s MiB  (%s%%)\\nPower    %s W' \
    "$name" "$util" "$temp" "$memused" "$memtotal" "$mempct" "$power")

printf '{"text":"󰢮  %s%%","tooltip":"%s","class":"%s"}\n' "$util" "$tooltip" "$class"
