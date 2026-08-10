# dotfiles

Arch Linux + Hyprland, Catppuccin Mocha throughout.
Three monitors, dual boot with Windows, Secure Boot enabled.

## Layout

Each directory here is symlinked into place — the repo is the single
source of truth, edit files here (or through the symlink, same thing).

| repo | linked to |
|---|---|
| `hypr/` | `~/.config/hypr` |
| `waybar/` | `~/.config/waybar` |
| `rofi/` | `~/.config/rofi` |
| `ghostty/` | `~/.config/ghostty` |
| `swaync/` | `~/.config/swaync` |
| `wlogout/` | `~/.config/wlogout` |
| `fontconfig/` | `~/.config/fontconfig` |
| `gtk-3.0/` `gtk-4.0/` | `~/.config/gtk-3.0`, `~/.config/gtk-4.0` |
| `qt5ct/` `qt6ct/` | `~/.config/qt5ct`, `~/.config/qt6ct` |
| `xdg-desktop-portal/` | `~/.config/xdg-desktop-portal` |
| `nvim/` | `~/.config/nvim` |
| `starship.toml` | `~/.config/starship.toml` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |
| `.zshrc` | `~/.zshrc` |
| `systemd/user/*.{service,timer}` | individual files into `~/.config/systemd/user/` |

`systemd/user` links the unit **files** rather than the directory,
because `~/.config/systemd/user/` also holds `timers.target.wants/` —
generated enable-state that does not belong in version control.

## Fresh install

```sh
git clone git@github.com:tgarif/dotfiles.git ~/dotfiles

# desktop configs
for d in hypr waybar rofi ghostty swaync wlogout fontconfig \
         gtk-3.0 gtk-4.0 qt5ct qt6ct xdg-desktop-portal nvim; do
  ln -sfn ~/dotfiles/$d ~/.config/$d
done
ln -sfn ~/dotfiles/starship.toml ~/.config/starship.toml
ln -sfn ~/dotfiles/tmux/.tmux.conf ~/.tmux.conf
ln -sfn ~/dotfiles/.zshrc ~/.zshrc

# wallpaper rotation timer
mkdir -p ~/.config/systemd/user
ln -sfn ~/dotfiles/systemd/user/wallpaper-rotate.service ~/.config/systemd/user/
ln -sfn ~/dotfiles/systemd/user/wallpaper-rotate.timer   ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now wallpaper-rotate.timer

# tmux plugins
git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
git clone --depth=1 https://github.com/catppuccin/tmux ~/.tmux/plugins/catppuccin/tmux
```

Wallpapers are **not** in this repo (~70 MB). Drop images into
`~/Pictures/Wallpapers`; anything there gets picked up.

## Gotchas worth knowing

**Hyprland uses the Lua config format.** `hyprland.lua`, not
`hyprland.conf` — `.conf` support is removed in Hyprland 0.57. Under the
Lua parser `hyprctl keyword` does not work; the equivalent is:

```sh
hyprctl eval 'hl.config({ general = { gaps_out = 20 } })'
```

Always validate before logging out — a broken config means a black
screen and a bounce back to the display manager:

```sh
Hyprland --verify-config
```

**Monitors are matched by description, never by `DP-N`.** Connector
numbering depends on which GPU driver initialises first. This machine
has an NVIDIA card plus an AMD iGPU, and adding the NVIDIA modules to
the initramfs renamed everything from `DP-4/5/6` to `DP-1/2/3` — which
silently detached the monitor config, the workspace bindings and every
waybar bar at once. `desc:` matching does not care.

**waybar is the exception.** Its `output` field needs the full
`make model serial` string and does *not* accept a partial match, so the
serials are hardcoded in `waybar/config.jsonc`. Replace them with your
own from `hyprctl monitors | grep description`.

**Every keybind needs a `description`.** Under the Lua parser
`hyprctl binds` reports each dispatcher as `__lua` with an opaque
closure index, so the description is the only human-readable label
available — and the `SUPER+/` cheatsheet is built entirely from it.
All binds go through a small `bind()` helper that takes one.

**Never write glyphs by pasting them.** Several waybar icons silently
became plain spaces that way. Insert them by codepoint instead, and
verify the font actually has them:

```sh
fc-list --format '%{charset}\n' 'JetBrainsMono Nerd Font'
```

## System-level settings (outside `$HOME`, not symlinked)

Not tracked here since they live on the ESP or in `/etc` and need root.
Recorded so a rebuild is reproducible.

| what | where | value |
|---|---|---|
| Boot menu | `/boot/EFI/refind/refind.conf` | rEFInd, `scan_all_linux_kernels false` + `dont_scan_files vmlinuz-linux` — this is a UKI-only setup with no `initramfs-linux.img`, so a bare-kernel entry would fail to mount root |
| Login screen | `/etc/sddm.conf.d/10-theme.conf` | `Current=catppuccin-mocha-mauve` |
| initramfs | `/etc/mkinitcpio.conf` | `MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)` |
| Kernel image | `/etc/mkinitcpio.d/linux.preset` | UKI at `/boot/EFI/Linux/arch-linux.efi` |
| Secure Boot | `sbctl` | own keys enrolled with `-m -f` so Microsoft + firmware certs stay in `db`, keeping Windows and the GPU option ROM valid |

**BIOS: "Provision Factory Default Keys" must stay Disabled.** It
re-provisions the factory PK/KEK/db on boot. Leaving it enabled makes
clearing Secure Boot keys appear to work and then silently revert, and
it would overwrite enrolled custom keys.

After a hand-run `mkinitcpio -P`, re-sign — the sbctl pacman hook only
fires on package transactions, and an unsigned UKI will not boot with
Secure Boot on:

```sh
sudo sbctl sign-all && sudo sbctl verify
```

`vmlinuz-linux` always reports unsigned. That is correct — it is a build
input, never loaded by the firmware.

## Known non-portable bits

- `qt5ct/qt5ct.conf` and `qt6ct/qt6ct.conf` hardcode
  `/home/atengku/...` for `color_scheme_path`. Fix the path after
  cloning to a different username.
- `gtk-4.0/` theme files are symlinks into `/usr/share/themes/` and are
  gitignored; recreate them after installing
  `catppuccin-gtk-theme-mocha`.
