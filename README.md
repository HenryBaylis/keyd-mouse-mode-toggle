# keyd-mouse-mode-toggle

Switch your mouse's side buttons between **Back / Forward** and **Ctrl / Shift** with a hotkey, with a notification popup showing the current mode. Built on [keyd](https://github.com/rvaiya/keyd), so it works on Wayland (tested on Hyprland).

| Mode | Back button | Forward button |
|---|---|---|
| Normal (default) | Back | Forward |
| Modifier | Ctrl | Shift |

Press **Ctrl+Alt+M** to switch.

## How it works

- `keyd/default.conf.in` makes keyd manage your mouse (and keyboards, so the side-button modifiers combine with keyboard keys, e.g. side button + C = Ctrl+C). Out of the box nothing is remapped.
- `bin/mouse-mode-toggle` uses `keyd bind` to switch the side buttons (`mouse1`/`mouse2`, i.e. `BTN_SIDE`/`BTN_EXTRA`) to modifiers at runtime, or `keyd bind reset` to switch back, and shows a popup with `notify-send`.
- `hypr/` holds the Hyprland keybind that runs the script.

## Install

```sh
git clone git@github.com:HenryBaylis/keyd-mouse-mode-toggle.git
cd keyd-mouse-mode-toggle
./install.sh              # detects your mouse
./install.sh 373e:0022    # or give its USB ID (see `lsusb`)
```

The installer:
1. installs keyd (Arch-based distros; elsewhere install it first),
2. writes `/etc/keyd/default.conf` for your mouse, backing up any existing one to `default.conf.bak`,
3. installs the script to `~/.local/bin/mouse-mode-toggle`,
4. enables keyd and adds you to the `keyd` group (needed for `keyd bind`).

Then add the keybind to your Hyprland config:
- **Lua config:** copy `hypr/mouse-mode.lua` into your config directory and `require` it, or paste its line into your binds file.
- **hyprland.conf:** paste the line from `hypr/mouse-mode.conf`.

**Reboot** if the installer added you to the `keyd` group.

## Customising

**Different modifiers:** set `MOUSE_MODE_BACK` / `MOUSE_MODE_FORWARD` (keyd layer names: `control`, `shift`, `alt`, `meta`) in the bind:

```lua
hl.bind("CONTROL + ALT + M", hl.dsp.exec_cmd("MOUSE_MODE_BACK=alt MOUSE_MODE_FORWARD=meta ~/.local/bin/mouse-mode-toggle"))
```

**Different hotkey:** change the Hyprland bind. It uses your actual keyboard layout.

## Troubleshooting

**`Failed to connect to "/var/run/keyd.socket"`:** your session doesn't have the `keyd` group yet. Check with `id -nG`. If you start Hyprland through UWSM/systemd, logging out and back in is **not** enough: the systemd user manager keeps running with the old groups and every new session inherits them. Reboot.

**Side buttons do nothing in modifier mode:** run `sudo keyd monitor` and press them. Most mice report `mouse1`/`mouse2`. If yours shows `mouseback`/`mouseforward` or keyboard keys, edit the names in `bin/mouse-mode-toggle`.

**Wrong mode after `sudo keyd reload`:** reloading resets keyd's bindings to Back / Forward, but the script still thinks modifier mode is on. Press the hotkey once more to resync.

**Why the hotkey isn't in keyd itself:** keyd names keys by their US-layout position, so a keyd `m` binding lands on a different key with AZERTY and other layouts. Hyprland binds follow your real layout.

## Uninstall

```sh
rm ~/.local/bin/mouse-mode-toggle
sudo mv /etc/keyd/default.conf.bak /etc/keyd/default.conf   # or remove it
sudo keyd reload                                            # or: sudo systemctl disable --now keyd
```

Then remove the Hyprland bind.
