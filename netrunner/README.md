# 🟣 NETRUNNER — Cyberpunk terminal module

Two-layer cyberpunk terminal for the Purple Bruce project.
Same design language on the Android side and inside the proot.

- **Layer 1 — Termux (Android)**: manual setup, see [TERMUX.md](./TERMUX.md).
  `netrunner` there → drops you into the Ubuntu proot.
- **Layer 2 — Ubuntu proot-distro (this module)**: one-liner installer below.
  `netrunner` there → launches Purple Bruce (`purplebruce.sh`).

Palette: pink `#ff2bd6` · purple `#bd00ff` · cyan `#00fff5` · yellow `#fcee0a` on deep-black.

---

## Install (inside the proot-distro)

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
```

Or from a local clone:

```bash
cd ~/purplebruce/netrunner && ./install.sh install
```

Sub-commands:

```bash
./install.sh install     # install zsh + Oh-My-Zsh + Powerlevel10k + plugins + cyberpunk dotfiles
./install.sh uninstall   # restore backed-up dotfiles; remove the netrunner command
./install.sh status      # show what's present
```

### What gets installed

| Component | Source | Purpose |
|---|---|---|
| `zsh` + Oh-My-Zsh + plugins | apt + git | shell engine |
| Powerlevel10k | romkatv/powerlevel10k | two-line prompt, wizard-free (see `.p10k.zsh`) |
| `zsh-autosuggestions` / `syntax-highlighting` / `completions` | zsh-users | live hints, color, completions |
| `fzf` · `zoxide` · `bat` · `eza` · `tmux` | apt (+ upstream fallback) | fuzzy · smart cd · pretty cat/ls · multiplexer |
| `~/.zshrc` · `~/.p10k.zsh` · `~/.tmux.conf` | `netrunner/dotfiles/` | theme + aliases + cursor |
| `~/.netrunner/{logo.ascii,motd.sh}` | `netrunner/assets/` | login banner |
| `/usr/local/bin/netrunner` | `netrunner/bin/netrunner` | cross-layer command |

Existing dotfiles are backed up to `*.netrunner-backup.<timestamp>` before overwrite; `uninstall` restores the newest backup.

### Aliases shipped

```
ls / ll / la / lt      → eza with icons + git
cat                    → bat (no paging)
gs gp gl gd ga gc      → git shortcuts
.. ... ....            → cd walkers
please                 → sudo !!
weather                → wttr.in single-line
myip                   → ifconfig.me
ports                  → listening sockets (ss / netstat)
pb / pb-status / pb-logs → Purple Bruce shortcuts
```

### Pink blinking cursor

Set every prompt via OSC 12 + `\e[5 q` (blinking bar). Already wired in `~/.zshrc`:

```zsh
_cursor_pink_bar() { printf '\033]12;#ff2bd6\007'; printf '\e[5 q'; }
precmd_functions+=(_cursor_pink_bar)
```

### Nerd font requirement

Powerlevel10k icons and `eza --icons` need a [Nerd Font](https://www.nerdfonts.com/). In Termux install **Termux:Styling** and pick *FiraCode Nerd Font* or *JetBrainsMono Nerd Font*; on desktop terminals (Alacritty/Kitty/WezTerm) set the font in your terminal's config.

### Customising Powerlevel10k

The shipped `.p10k.zsh` skips the wizard (`POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true`). To run the full wizard later:

```zsh
unset POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD
p10k configure
```

---

## File layout

```
netrunner/
├── install.sh              # main installer (MODE = install | uninstall | status)
├── README.md               # this file
├── TERMUX.md               # manual setup steps for the Android host layer
├── bin/
│   └── netrunner           # shared command (Termux → proot, proot → Purple Bruce)
├── dotfiles/
│   ├── zshrc               # cyberpunk .zshrc with aliases + cursor + motd hook
│   ├── p10k.zsh            # compact Powerlevel10k preset
│   └── tmux.conf           # cyberpunk tmux theme (optional)
└── assets/
    ├── logo.ascii          # snake + rune + saturn ASCII silhouette
    └── motd.sh             # greeter: top bar + logo + sysinfo + clock
```

---

## Uninstall

```bash
./install.sh uninstall
```

Leaves Oh-My-Zsh + plugins in place (easy to re-install later); removes the dotfiles, restores backups, deletes the `netrunner` command.
