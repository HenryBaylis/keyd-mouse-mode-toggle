#!/usr/bin/env bash
# Install keyd-mouse-mode-toggle.
#
# Usage: ./install.sh [vendor:product]
#   vendor:product  USB ID of the mouse (e.g. 373e:0022). Detected if omitted.
set -euo pipefail

cd "$(dirname "$0")"

# List USB mice as "vendor:product<TAB>name", excluding keyd's virtual pointer.
list_mice() {
    awk 'BEGIN { RS = ""; FS = "\n" }
        /Bus=0003/ && /Handlers=[^\n]*mouse[0-9]/ {
            match($0, /Vendor=[0-9a-f]+/);  v = substr($0, RSTART + 7, RLENGTH - 7)
            match($0, /Product=[0-9a-f]+/); p = substr($0, RSTART + 8, RLENGTH - 8)
            match($0, /Name="[^"]*"/);      n = substr($0, RSTART + 6, RLENGTH - 7)
            if (v != "0fac") print v ":" p "\t" n
        }' /proc/bus/input/devices | sort -u -t$'\t' -k1,1
}

mouse_id="${1:-}"
if [[ -z "$mouse_id" ]]; then
    mapfile -t mice < <(list_mice)
    if (( ${#mice[@]} == 1 )); then
        mouse_id="${mice[0]%%$'\t'*}"
        echo "Detected mouse: ${mice[0]#*$'\t'} ($mouse_id)"
    else
        echo "Found ${#mice[@]} mice; pass the ID of the one to use:" >&2
        printf '  %s\n' "${mice[@]}" >&2
        echo "Usage: $0 vendor:product" >&2
        exit 1
    fi
fi
if [[ ! "$mouse_id" =~ ^[0-9a-f]{4}:[0-9a-f]{4}$ ]]; then
    echo "Invalid mouse ID '$mouse_id' (expected e.g. 373e:0022)" >&2
    exit 1
fi

if ! command -v keyd >/dev/null; then
    if command -v pacman >/dev/null; then
        sudo pacman -S --needed keyd
    else
        echo "Install keyd with your package manager, then re-run this script." >&2
        exit 1
    fi
fi

# keyd config (back up any existing one first)
conf=/etc/keyd/default.conf
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
sed "s/@MOUSE_ID@/$mouse_id/" keyd/default.conf.in > "$tmp"
keyd check "$tmp" >/dev/null
if [[ -e "$conf" ]] && ! cmp -s "$tmp" "$conf"; then
    sudo cp "$conf" "$conf.bak"
    echo "Backed up existing $conf to $conf.bak"
fi
sudo install -Dm644 "$tmp" "$conf"

# Toggle script
install -Dm755 bin/mouse-mode-toggle "$HOME/.local/bin/mouse-mode-toggle"

# Service and permissions
sudo systemctl enable --now keyd
sudo keyd reload
needs_reboot=false
if ! id -nG "$USER" | tr ' ' '\n' | grep -qx keyd; then
    sudo usermod -aG keyd "$USER"
    needs_reboot=true
fi

cat <<EOF

Installed.
  keyd config:   $conf (mouse $mouse_id)
  toggle script: ~/.local/bin/mouse-mode-toggle

Next, bind a key to the toggle script. For Hyprland, add one of:
  hypr/mouse-mode.lua   (Lua config)
  hypr/mouse-mode.conf  (hyprland.conf)
EOF
if $needs_reboot; then
    echo
    echo "You were added to the keyd group. Reboot before using the toggle"
    echo "(logging out is not enough if your session runs under systemd/UWSM)."
fi
