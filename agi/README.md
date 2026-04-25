# 🧠 AGI · CLI Layer 2

Multi-provider, multi-role AGI CLI. Pairs with the CyberEnigma terminal (Layer 1) and the Purple Bruce server.

```
agi/
├── ai                        # CLI entry (Node 18+, no deps)
├── safe_exec.sh              # safety wrapper: preview · confirm · log · dry-run
├── package.json
├── core/
│   ├── personas.js           # Lucy · Bruce · Strategist · Operator system prompts
│   ├── router.js             # role → provider resolver, env / config-driven
│   └── pipeline.js           # Lucy → Bruce → Strategist → Operator chain
├── providers/
│   └── openai-compat.js      # one fetch, OpenAI / Grok / Venice / OpenRouter
├── cli/
│   └── repl.js               # interactive loop
└── config/
    └── default.example.json
```

## Roles (the 4-agent system)

| Layer | Role | Default provider | Purpose |
|---|---|---|---|
| L1 Input  | **Lucy**       | Grok (`XAI_API_KEY`)    | Scout · classify the request as JSON |
| L1 Attack | **Bruce**      | Grok                    | Auditor · safety verdict on plan/input |
| L2 Logic  | **Strategist** | OpenAI (`OPENAI_API_KEY`) | Plan · numbered steps with `cmd:` lines |
| L2 Exec   | **Operator**   | OpenAI                  | Translate plan into `safe_exec.sh` lines |

## Setup

```bash
# 1) keys (any subset; missing keys disable the matching role)
export OPENAI_API_KEY=sk-...
export XAI_API_KEY=xai-...
export VENICE_API_KEY=...
export OPENROUTER_API_KEY=...

# 2) optional config override
mkdir -p ~/.agi
cp agi/config/default.example.json ~/.agi/config.json

# 3) make ai callable
chmod +x agi/ai agi/safe_exec.sh
ln -sf "$PWD/agi/ai" ~/.local/bin/ai     # or PATH+=…/agi
```

## Usage

```bash
ai                                # interactive REPL (full pipeline)
ai "audit my open ports"          # one-shot pipeline (Lucy → Bruce → Strat → Op)
ai role lucy "scan localhost"     # talk to a single role
ai role strategist "plan a backup script"
ai providers                      # list providers + key presence
ai exec -e "list listeners" -- ss -tlnp        # safe wrapper around a command
ai exec -n -- rm -rf ./build                   # dry-run preview
```

### REPL commands

```
/role <name>       switch to single-role mode (lucy|bruce|strategist|operator)
/mode pipeline     run all 4 roles for each prompt (default)
/mode role         run only the chosen role
/quit              exit
```

## Safety guarantees

- `safe_exec.sh` enforces a hard denylist (`rm -rf /`, fork bombs, `mkfs`, `dd of=/dev/sd*`, `chmod -R 777 /`, `shutdown`/`reboot`/`halt`, `curl … | bash`).
- Every command is **previewed**, **confirmed** (or `-y`), and **logged** to `~/.agi/logs/exec.log`.
- `-n` runs as dry-run only.
- The Operator role only emits `safe_exec.sh` lines — it cannot execute on its own.
- Pipeline blocks if Bruce returns `verdict: block`.

## Provider matrix

All four providers speak the OpenAI `/chat/completions` shape and route through `providers/openai-compat.js`:

| Provider   | env key             | default model                          |
|---         |---                  |---                                     |
| OpenAI     | `OPENAI_API_KEY`    | `gpt-4o-mini`                          |
| Grok (xAI) | `XAI_API_KEY`       | `grok-3-mini`                          |
| Venice     | `VENICE_API_KEY`    | `llama-3.3-70b`                        |
| OpenRouter | `OPENROUTER_API_KEY`| `meta-llama/llama-3.3-70b-instruct`    |

Override per-provider in `~/.agi/config.json` (`providers.<name>.model`, `.baseURL`, `.temperature`, `.maxTokens`, `.timeoutMs`).

## Integration with Purple Bruce

The Operator's emitted `./safe_exec.sh` lines can be piped into the existing 24/7 service or run by hand. The pipeline stays read-only by design: nothing executes without the user pressing `y` in the safe_exec confirmation.
