# arch-dotfiles

Personal dotfiles for an Arch Linux + Hyprland setup.

## Stack

- **WM/Compositor:** Hyprland (Wayland, Lua config)
- **Bar:** Waybar
- **Launcher:** Rofi
- **Terminal:** Kitty
- **Editor:** Neovim (lazy.nvim)

## Structure (excluding `README.md`)

Each folder maps directly to its corresponding `~/.config/<folder>` directory.

```
arch-dotfiles/
├── hypr/
│   ├── hypridle.conf       # idle timings: lock, screen off, suspend
│   ├── hyprland.lua        # Hyprland config (Lua-based)
│   ├── hyprlock.conf       # lock screen appearance
│   └── hyprpaper.conf      # Wallpaper config
├── kitty/
│   └── kitty.conf          # Kitty terminal
├── nvim/
│   ├── init.lua            # entry point
│   ├── lazy-lock.json      # plugin lockfile
│   └── lua/
│       ├── config/
│       │   ├── keybinds.lua
│       │   ├── lazy.lua    # plugin definitions
│       │   └── options.lua
│       └── plugins/        # per-plugin configs
│           ├── colors.lua
│           ├── lsp.lua
│           ├── oneliners.lua
│           ├── telescope.lua
│           └── treesitter.lua
├── rofi/
│   └── config.rasi         # rofi launcher theme
├── shell/
|   ├── .bashrc             # opam's auto generated messsage + custom OpenSpiel helpers
│   └── .bash_profile       # auto-login + auto-start Hyprland on tty1
├── ssh/
│   └── config              # GitHub uses ed25519 key
└── waybar/
    ├── config.jsonc         # modules: workspaces, clock, cpu, memory, battery, wifi
    └── style.css            # styling
```

## Prerequisites

If config files are the only thing that matter, skip this section (but keep in mind, `nvim`'s language servers do need programming languages and their package managers installed):

### 1. Enable multilib repo
Edit `/etc/pacman.conf` and uncomment the `[multilib]` section (both `[multilib]` and the line below it), then:
```bash
sudo pacman -Syu
```

### 2. Official packages
```bash
sudo pacman -S \
  base-devel git neovim \
  mesa vulkan-radeon libva-mesa-driver \
  pipewire pipewire-pulse pipewire-alsa wireplumber \
  hyprland kitty waybar rofi-wayland hyprpaper hyprlock hypridle \
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland polkit-kde-agent \
  grim slurp swappy wl-clipboard \
  brightnessctl playerctl dunst nemo network-manager-applet pavucontrol \
  gcc rust ocaml opam nodejs npm python python-pip uv clang cmake \
  glfw-x11 glew freeglut mesa-utils \
  keepassxc mpv firefox okular docker openssh \
  telegram-desktop steam \
  ttf-jetbrains-mono-nerd noto-fonts \
  texlive-basic texlive-latex texlive-latexrecommended texlive-latexextra \
  texlive-fontsextra texlive-mathscience texlive-binextra texlive-langother \
  bluez bluez-utils pipewire-audio pipewire-pulse wireplumber gst-plugin-pipewire \
  tlp tlr-rdw
```

### 3. AUR helper (paru)
```bash
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
```

### 4. AUR packages
```bash
paru -S google-chrome shotcut discord localsend-bin elan-lean-bin
```

### 5. OCaml LSP
```bash
opam init
eval $(opam env --switch=default)
opam install ocaml-lsp-server
echo 'eval $(opam env)' >> ~/.bashrc
```

### 6. SSH key for GitHub
```bash
ssh-keygen -t ed25519 -C "EMAIL"
cat ~/.ssh/id_ed25519.pub  # add this to GitHub -> Settings -> SSH keys
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### 7. Bluetooth Connection Setup (for Earbuds)
MAC address used here is a random MAC address for convenience:
```bash
sudo systemctl disable bluetooth
sudo rfkill block bluetooth
systemctl --user enable --now pipewire pipewire-pulse wireplumber
# Put earbuds in the case, leave lid open, press the white button below the right earbud for 2 seconds until status LED flashes white.
sudo rfkill unblock bluetooth
sudo systemctl start bluetooth
bluetoothctl
[bluetoothctl]> power on
[bluetoothctl]> agent on
[bluetoothctl]> default-agent
[bluetoothctl]> pair 3C:B0:ED:AF:08:B2
[bluetoothctl]> trust 3C:B0:ED:AF:08:B2
[bluetoothctl]> connect 3C:B0:ED:AF:08:B2
[bluetoothctl]> exit
```

### 8. Power management

TLP runs on stock defaults - no `/etc/tlp.conf` changes needed:

```bash
sudo systemctl enable --now tlp
sudo tlp-stat -s   # verify: should show "tlp = enabled"
```

Check the CPU driver is `amd-pstate-epp` (no kernel params needed if so):

```bash
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver
```

Battery conservation mode is **off** by default and should stay off unless the laptop lives on AC. On `ideapad_laptop` the value is `0` (Standard) / `1` (Long_Life), *not* a percentage - set `STOP_CHARGE_THRESH_BAT0=1` in `/etc/tlp.conf` and run `sudo tlp start` only if you want it.

### 9. Suspend & lock on lid close

Lid close is handled by `systemd-logind`. In `/etc/systemd/logind.conf`, uncomment:
```ini
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
```
```bash
sudo systemctl restart systemd-logind
```

Idle behavior comes from `hypr/hypridle.conf` (lock at 5 min, screen off at 10,
suspend at 30), with `hypr/hyprlock.conf` as the lock screen. `before_sleep_cmd`
locks the session *before* suspending, so the laptop is never unlocked on resume.
`hypridle` is started from the autostart block in `hyprland.lua`.

Test `hyprlock` on its own before relying on it - a broken lock config locks you out
of your session. Keep a TTY open (`Ctrl+Alt+F2`) as an escape hatch while testing:
```bash
hyprlock
```

Verify after a Hyprland restart:
```bash
pgrep -a hypridle          # should return a PID
loginctl lock-session      # should lock immediately
journalctl -b | grep -i "suspend\|lid" | tail -20   # after closing/reopening lid
```

> **Hibernate** is not configured. It needs a swapfile at least as large as RAM
> (32 GB here; current swapfile is 4 GB), a `resume=` kernel parameter with
> `resume_offset`, and the `resume` hook in `/etc/mkinitcpio.conf`. Suspend (s2idle)
> is used instead - note s2idle still draws a few percent per hour.

### 10. Lean 4
```bash
elan default stable
```

Verify:
```bash
lean --version
lake --version
```

Creating a new project:
```bash
lake new project_name math
cd project_name
lake build
```


## Restore

Clone the repo and symlink each folder into `~/.config/`:

```bash
git clone git@github.com:Stochastic-Batman/arch-dotfiles.git ~/arch-dotfiles
cd ~/arch-dotfiles

for dir in hypr kitty nvim rofi ssh waybar; do
    ln -sf ~/arch-dotfiles/$dir ~/.config/$dir
done

ln -sf ~/arch-dotfiles/shell/.bash_profile ~/.bash_profile
ln -sf ~/arch-dotfiles/shell/.bashrc ~/.bashrc
ln -sf ~/arch-dotfiles/ssh/config ~/.ssh/config
```

> **Note:** Make sure to generate a new SSH key on the new machine and add it to GitHub before running the restore script.
