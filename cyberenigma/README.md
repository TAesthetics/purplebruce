# 🐍 CYBERENIGMA — Layer 1

Clean, reproducible Termux terminal setup.
zsh · neofetch · top-bar HUD · pink blinking cursor · snake/rune/saturn ascii logo.

> Layer 1 = the **Android / Termux host** interface. Layer 2 (the Ubuntu proot environment) is shipped separately (see [purplebruce/netrunner](../netrunner/) in this repo).

---

## ✨ What you get

- **One-file installer** that sets up zsh + plugins + neofetch + HUD in one shot.
- **Clean `.zshrc`** — no `preexec` spam, no alias/function collisions, idempotent.
- **`ai` / `agent`** helpers — opt-in, no per-command animations unless you ask for them.
- **`netrunner`** command — jumps straight into the Ubuntu proot-distro (auto-installs on first run).
- **Pink blinking bar cursor** via OSC 12 + `\e[5 q`.
- **Top-bar HUD** with live clock, printed once at login.

Palette: magenta `201` · purple `129` · cyan `51` · yellow `226` on deep black.

---

## 📂 Layout

```
cyberenigma/
├── install.sh                  # one-shot installer (install | uninstall | status)
├── README.md
├── zshrc                       # deployed to ~/.zshrc
├── bin/
│   ├── netrunner               # → ~/cyberenigma/bin/netrunner
│   └── agent                   # → ~/cyberenigma/bin/agent
├── config/neofetch/
│   ├── config.conf             # → ~/.config/neofetch/config.conf
│   └── ascii.txt               # → ~/.config/neofetch/ascii.txt (snake + rune + rings)
└── hud/
    └── topbar.sh               # → ~/.cyberenigma/hud/topbar.sh
```

---

## ⚡ Install

In Termux:

```bash
git clone https://github.com/YOUR-USER/cyberenigma.git ~/cyberenigma-src
cd ~/cyberenigma-src
bash install.sh install
exec zsh
```

Or one-liner (replace the URL once you've pushed the repo):

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR-USER/cyberenigma/main/install.sh | bash
```

Commands:

```bash
bash install.sh install      # deploys all dotfiles, installs packages, chsh zsh
bash install.sh status       # shows what's installed
bash install.sh uninstall    # restores .zshrc backup, removes files
```

---

## 🧪 After install

```bash
exec zsh                 # reload shell
neofetch                 # custom snake/rune logo
netrunner                # jumps into Ubuntu proot-distro
ai "ls -la"              # opt-in "thinking…" wrapper around any command
agent "say hi in German" # forwards a prompt to an LLM (needs key, see below)
```

### `agent` — key setup (optional)

```bash
mkdir -p ~/.cyberenigma
echo 'xai-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' > ~/.cyberenigma/agent.key
chmod 600 ~/.cyberenigma/agent.key
```

Override the model or endpoint via env vars:

```bash
export CYBERENIGMA_MODEL="grok-3-mini"
export CYBERENIGMA_URL="https://api.x.ai/v1/chat/completions"
```

Works with any OpenAI-compatible chat-completions endpoint (xAI, OpenAI, Groq, Venice, …).

---

## 🎨 Nerd font requirement

The logo + neofetch icons look best with a Nerd Font. In Termux install **Termux:Styling** → pick *FiraCode Nerd Font* or *JetBrainsMono Nerd Font*.

---

## 🛠 Uninstall

```bash
bash install.sh uninstall
```

Restores the newest `~/.zshrc.cyberenigma-backup.*` and removes `~/cyberenigma` / `~/.cyberenigma` / `~/.config/neofetch`.

---

## 🔗 Layer 2 (next step)

After `netrunner` drops you into the Ubuntu proot, install Layer 2:

```bash
curl -fsSL https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install.sh | bash
exec zsh
```

Both layers share the same palette and `netrunner` command so the switch between Android host and proot feels seamless.
