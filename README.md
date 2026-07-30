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
│   ├── hyprland.lua        # Hyprland config (Lua-based)
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
  texlive-fontsextra texlive-mathscience texlive-binextra texlive-langother
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
paru -S google-chrome shotcut discord localsend-bin
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
