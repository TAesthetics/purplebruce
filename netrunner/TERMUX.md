# TERMUX — manual setup (Layer 1)

The Android side is **not** installed from the repo. Follow these steps so the host shell looks identical to the Ubuntu proot-distro layer.

## 1. Core packages

```bash
pkg update -y && pkg upgrade -y
pkg install -y zsh git curl wget tmux fzf eza bat zoxide proot-distro termux-api
```

Install a Nerd Font via **Termux:Styling**: open the app, pick *FiraCode Nerd Font* (or *JetBrainsMono Nerd Font*). This is required for the Powerlevel10k icons and `eza --icons`.

## 2. Oh-My-Zsh + theme + plugins

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git           "$ZSH_CUSTOM/themes/powerlevel10k"
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions       "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting   "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
git clone --depth=1 https://github.com/zsh-users/zsh-completions           "$ZSH_CUSTOM/plugins/zsh-completions"
```

## 3. Dotfiles from this repo

Pull the same configs we use inside the proot — so the look is identical:

```bash
REPO=TAesthetics/purplebruce
BRANCH=main
BASE="https://raw.githubusercontent.com/$REPO/$BRANCH/netrunner"

mkdir -p ~/.netrunner
curl -fsSL "$BASE/dotfiles/zshrc"      -o ~/.zshrc
curl -fsSL "$BASE/dotfiles/p10k.zsh"   -o ~/.p10k.zsh
curl -fsSL "$BASE/dotfiles/tmux.conf"  -o ~/.tmux.conf
curl -fsSL "$BASE/assets/logo.ascii"   -o ~/.netrunner/logo.ascii
curl -fsSL "$BASE/assets/motd.sh"      -o ~/.netrunner/motd.sh
chmod +x ~/.netrunner/motd.sh
```

## 4. `netrunner` command (Termux side)

Add a tiny zsh function that jumps into the proot — same name as the one inside the proot, so muscle-memory is consistent:

```bash
cat >> ~/.zshrc <<'EOF'

# Termux netrunner — jump into the Ubuntu proot
netrunner() {
  local distro="${NETRUNNER_DISTRO:-ubuntu}"
  if ! command -v proot-distro >/dev/null 2>&1; then
    echo "[!] proot-distro missing. pkg install proot-distro"
    return 1
  fi
  if ! proot-distro list 2>/dev/null | grep -qi "${distro}.*installed"; then
    echo "[*] Installing ${distro} proot-distro (one-time)..."
    proot-distro install "${distro}"
  fi
  exec proot-distro login "${distro}"
}
EOF
```

## 5. Make zsh the default shell

```bash
chsh -s zsh
```

Close and reopen Termux. You should see the top-bar banner + the saturn-snake ASCII logo.

## 6. First time inside the proot

```bash
netrunner                      # jumps into Ubuntu proot
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
```

From now on:

- **Termux shell** → `netrunner` → Ubuntu proot
- **Ubuntu proot** → `netrunner` → Purple Bruce launcher

## Troubleshooting

| Symptom | Fix |
|---|---|
| Icons show as squares / `?` | Install a Nerd Font via Termux:Styling, restart Termux |
| Colors flat / no pink | Check `echo $TERM` → should be `xterm-256color`; set `export TERM=xterm-256color` in `~/.zshrc` |
| p10k asks for configuration | Shipped `.p10k.zsh` disables the wizard; if it still appears, `cp ~/.zshrc ~/.zshrc.bak && curl -fsSL .../dotfiles/zshrc -o ~/.zshrc` |
| Cursor stays white/block | OSC 12 + `\e[5 q` require a compatible terminal. Termux supports both; desktop: use Alacritty / Kitty / WezTerm |
| `netrunner` not found | New shell needed: `exec zsh` |
