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
│   └── .bash_profile       # auto-login + auto-start Hyprland on tty1
├── ssh/
│   └── config              # GitHub uses ed25519 key
└── waybar/
    ├── config.jsonc         # modules: workspaces, clock, cpu, memory, battery, wifi
    └── style.css            # styling
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
ln -sf ~/arch-dotfiles/ssh/config ~/.ssh/config
```

> **Note:** Make sure to generate a new SSH key on the new machine and add it to GitHub before running the restore script.
