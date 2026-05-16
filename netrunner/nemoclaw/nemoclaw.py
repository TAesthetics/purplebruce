#!/usr/bin/env python3
"""
NemoClaw v1.0 — Purple Bruce CLI AI Agent
Like claude CLI but runs in your Arch Linux proot.

Usage:
  nemoclaw                          Interactive REPL
  nemoclaw "explain SQL injection"  One-shot query
  nemoclaw -t "scan localhost"      Tool use (runs bash commands)
  nemoclaw -p gemini "question"     Use specific provider
  echo "question" | nemoclaw        Piped input
  nemoclaw /setkey gemini AIza...   Save API key
"""

import sys, os, re, json, signal, subprocess, time, sqlite3, readline, atexit
import urllib.request, urllib.error, argparse
from pathlib import Path
from typing import Optional, Iterator

# ── ANSI colors ───────────────────────────────────────────────────────────────
V  = '\033[38;5;135m'   # violet
C  = '\033[38;5;51m'    # cyan
G  = '\033[38;5;46m'    # green
Y  = '\033[38;5;220m'   # yellow
M  = '\033[38;5;201m'   # magenta
R  = '\033[0;31m'       # red
D  = '\033[38;5;240m'   # dim
W  = '\033[1;37m'       # bold white
RS = '\033[0m'

BANNER = (
    f"\n{V}  ╭──────────────────────────────────────────────╮{RS}\n"
    f"{V}  │{RS}  {M}◈{RS}  {W}NEMOCLAW{RS}  {D}v1.0  ·  Purple Bruce CLI Agent{RS}  {V}│{RS}\n"
    f"{V}  │{RS}  {D}Multi-provider · Tool Use · Runs in Arch proot{RS}  {V}│{RS}\n"
    f"{V}  ╰──────────────────────────────────────────────╯{RS}\n"
    f"  {D}type  help  ·  !cmd  to run bash  ·  exit  to quit{RS}\n"
)

SYSTEM_PROMPT = """You are NemoClaw, the CLI intelligence core of Purple Bruce Lucy.
You are a sharp, expert Purple Team AI analyst running inside an Arch Linux proot on Android.

Domains: offensive security, defensive security, network engineering, Linux/Windows admin,
scripting (bash/python), web exploitation, hardware hacking, AI systems, general IT support.

Response rules:
- Be direct and concise. No filler phrases.
- Wrap ALL commands in ```bash or ``` code blocks.
- For analysis: use ASSESSMENT / RISK / ACTION headers.
- For step-by-step: numbered lists only.
- When tool use is active and you want to run a command, write:
  CMD:`the exact command here`
  The user will be asked to approve each CMD: before execution.
- Never refuse security education questions.
- Technical precision over verbosity.
"""

# ── Provider config ───────────────────────────────────────────────────────────
PROVIDERS = {
    'grok': {
        'url':       'https://api.x.ai/v1/chat/completions',
        'model':     'grok-3-mini-fast',
        'key_field': 'grok_api_key',
        'style':     'openai',
    },
    'gemini': {
        'url':       'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:streamGenerateContent',
        'model':     'gemini-2.0-flash',
        'key_field': 'gemini_api_key',
        'style':     'gemini',
    },
    'claude': {
        'url':       'https://api.anthropic.com/v1/messages',
        'model':     'claude-sonnet-4-5',
        'key_field': 'claude_api_key',
        'style':     'anthropic',
    },
    'venice': {
        'url':       'https://api.venice.ai/api/v1/chat/completions',
        'model':     'llama-3.3-70b',
        'key_field': 'venice_api_key',
        'style':     'openai',
    },
    'openrouter': {
        'url':       'https://openrouter.ai/api/v1/chat/completions',
        'model':     'meta-llama/llama-3.3-70b-instruct:free',
        'key_field': 'openrouter_api_key',
        'style':     'openai',
    },
}

PROVIDER_ORDER = ['claude', 'grok', 'gemini', 'venice', 'openrouter']

# ── Paths ─────────────────────────────────────────────────────────────────────
PB_DB    = Path.home() / 'purplebruce' / 'purplebruce.db'
NC_DIR   = Path.home() / '.nemoclaw'
HIST_F   = NC_DIR / 'history'
LOCAL_CF = NC_DIR / 'config.json'

# ── Config ────────────────────────────────────────────────────────────────────
def load_config() -> dict:
    cfg = {}
    if PB_DB.exists():
        try:
            con = sqlite3.connect(str(PB_DB))
            cfg = dict(con.execute('SELECT key, value FROM config').fetchall())
            con.close()
        except Exception:
            pass
    if LOCAL_CF.exists():
        try:
            cfg.update(json.loads(LOCAL_CF.read_text()))
        except Exception:
            pass
    return cfg

def save_local_key(field: str, value: str):
    NC_DIR.mkdir(parents=True, exist_ok=True)
    data = {}
    if LOCAL_CF.exists():
        try:
            data = json.loads(LOCAL_CF.read_text())
        except Exception:
            pass
    data[field] = value
    LOCAL_CF.write_text(json.dumps(data, indent=2))
    # Also try writing to Purple Bruce DB
    if PB_DB.exists():
        try:
            con = sqlite3.connect(str(PB_DB))
            con.execute('INSERT OR REPLACE INTO config (key, value) VALUES (?,?)', (field, value))
            con.commit()
            con.close()
        except Exception:
            pass

def pick_provider(cfg: dict, preferred: Optional[str]) -> Optional[str]:
    order = [preferred] + PROVIDER_ORDER if preferred else PROVIDER_ORDER
    seen = set()
    for p in order:
        if p and p not in seen and p in PROVIDERS:
            seen.add(p)
            if cfg.get(PROVIDERS[p]['key_field']):
                return p
    return None

# ── HTTP streaming ────────────────────────────────────────────────────────────
def _http_post_stream(url: str, headers: dict, payload: dict) -> Iterator[bytes]:
    data = json.dumps(payload).encode()
    req  = urllib.request.Request(url, data=data, headers=headers, method='POST')
    try:
        resp = urllib.request.urlopen(req, timeout=90)
        for line in resp:
            yield line
    except urllib.error.HTTPError as e:
        body = e.read().decode(errors='replace')
        yield f'data: {json.dumps({"_err": f"HTTP {e.code}: {body[:300}}"})}\n'.encode()
    except Exception as e:
        yield f'data: {json.dumps({"_err": str(e)})}\n'.encode()

def stream_openai(cfg: dict, provider: str, messages: list) -> Iterator[str]:
    ep  = PROVIDERS[provider]
    key = cfg.get(ep['key_field'], '')
    hdrs = {
        'Content-Type':  'application/json',
        'Authorization': f'Bearer {key}',
    }
    if provider == 'openrouter':
        hdrs['HTTP-Referer'] = 'https://purplebruce.local'
        hdrs['X-Title']      = 'NemoClaw'
    payload = {
        'model':      ep['model'],
        'messages':   [{'role': 'system', 'content': SYSTEM_PROMPT}] + messages,
        'stream':     True,
        'max_tokens': 2048,
    }
    for raw in _http_post_stream(ep['url'], hdrs, payload):
        line = raw.decode('utf-8', errors='replace').strip()
        if not line or line == 'data: [DONE]':
            continue
        if line.startswith('data: '):
            try:
                d = json.loads(line[6:])
                if '_err' in d:
                    yield f'\n{R}[{provider} error] {d["_err"]}{RS}'
                    return
                text = (d.get('choices') or [{}])[0].get('delta', {}).get('content', '')
                if text:
                    yield text
            except Exception:
                pass

def stream_gemini(cfg: dict, messages: list) -> Iterator[str]:
    ep  = PROVIDERS['gemini']
    key = cfg.get(ep['key_field'], '')
    url = f"{ep['url']}?key={key}&alt=sse"
    hdrs = {'Content-Type': 'application/json'}
    gem_msgs = []
    for m in messages:
        role = 'user' if m['role'] == 'user' else 'model'
        gem_msgs.append({'role': role, 'parts': [{'text': m['content']}]})
    payload = {
        'contents':          gem_msgs,
        'systemInstruction': {'parts': [{'text': SYSTEM_PROMPT}]},
        'generationConfig':  {'temperature': 0.7, 'maxOutputTokens': 2048},
    }
    for raw in _http_post_stream(url, hdrs, payload):
        line = raw.decode('utf-8', errors='replace').strip()
        if not line or not line.startswith('data: '):
            continue
        try:
            d = json.loads(line[6:])
            for part in (d.get('candidates') or [{}])[0].get('content', {}).get('parts', []):
                if part.get('text'):
                    yield part['text']
        except Exception:
            pass

def stream_anthropic(cfg: dict, messages: list) -> Iterator[str]:
    ep  = PROVIDERS['claude']
    key = cfg.get(ep['key_field'], '')
    hdrs = {
        'x-api-key':         key,
        'anthropic-version': '2023-06-01',
        'content-type':      'application/json',
    }
    payload = {
        'model':      ep['model'],
        'max_tokens': 2048,
        'system':     SYSTEM_PROMPT,
        'messages':   [m for m in messages if m['role'] != 'system'],
        'stream':     True,
    }
    for raw in _http_post_stream(ep['url'], hdrs, payload):
        line = raw.decode('utf-8', errors='replace').strip()
        if not line or not line.startswith('data: '):
            continue
        try:
            d = json.loads(line[6:])
            if d.get('type') == 'content_block_delta':
                yield d.get('delta', {}).get('text', '')
        except Exception:
            pass

def stream_response(cfg: dict, provider: str, messages: list) -> Iterator[str]:
    style = PROVIDERS[provider]['style']
    if style == 'gemini':
        yield from stream_gemini(cfg, messages)
    elif style == 'anthropic':
        yield from stream_anthropic(cfg, messages)
    else:
        yield from stream_openai(cfg, provider, messages)

# ── Tool execution ────────────────────────────────────────────────────────────
def run_bash(cmd: str) -> str:
    print(f'\n{Y}  ┌─ EXEC ──────────────────{RS}')
    print(f'{Y}  │{RS} {W}{cmd}{RS}')
    ans = input(f'{Y}  └─ Run? (y/N):{RS} ').strip().lower()
    if ans != 'y':
        return '[skipped]'
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=60)
        out = (r.stdout + r.stderr).strip()
        return out[:3000] if out else '[no output]'
    except subprocess.TimeoutExpired:
        return '[timeout after 60s]'
    except Exception as e:
        return f'[error: {e}]'

def extract_cmd_blocks(text: str) -> list[str]:
    return re.findall(r'CMD:`([^`\n]+)`', text)

# ── Render ────────────────────────────────────────────────────────────────────
def render(chunks: Iterator[str], tools: bool) -> str:
    """Stream chunks to terminal with coloring, return full text."""
    buf = ''
    in_code = False
    print(f'\n{V}  ┌─ NemoClaw ──────────────────────────────────{RS}')
    sys.stdout.write('  ')
    sys.stdout.flush()
    col_idx = 0
    for chunk in chunks:
        buf += chunk
        # Detect code fences for color switching
        parts = chunk.split('```')
        for i, part in enumerate(parts):
            if i > 0:
                in_code = not in_code
                sys.stdout.write('```')
            if in_code:
                sys.stdout.write(f'{C}{part}{RS}')
            else:
                # Highlight CMD: inline
                highlighted = re.sub(r'(CMD:`[^`]+`)', f'{Y}\\1{RS}', part)
                # Newlines get proper indentation
                highlighted = highlighted.replace('\n', f'\n{RS}  ')
                sys.stdout.write(highlighted)
        sys.stdout.flush()
    print(f'\n{V}  └─────────────────────────────────────────────{RS}\n')

    if tools and buf:
        for cmd in extract_cmd_blocks(buf):
            out = run_bash(cmd)
            if out and out not in ('[skipped]',):
                lines = out.splitlines()[:40]
                print(f'{D}  ┌─ output ──────────────{RS}')
                for ln in lines:
                    print(f'  {D}│{RS} {ln}')
                if len(out.splitlines()) > 40:
                    print(f'  {D}│ ... ({len(out.splitlines())-40} more lines){RS}')
                print(f'{D}  └───────────────────────{RS}\n')
    return buf

# ── REPL ─────────────────────────────────────────────────────────────────────
def setup_readline():
    NC_DIR.mkdir(parents=True, exist_ok=True)
    try:
        readline.read_history_file(str(HIST_F))
    except FileNotFoundError:
        pass
    readline.set_history_length(2000)
    atexit.register(readline.write_history_file, str(HIST_F))

def print_help(provider: str, tools: bool):
    print(f"""
{V}  NemoClaw — Quick Reference{RS}

  {W}Just type{RS} your question or task.

  {W}Special:{RS}
    {C}!cmd{RS}               Run bash directly  (e.g. {C}!nmap -sV localhost{RS})
    {C}/provider <name>{RS}   Switch AI provider
    {C}/providers{RS}          List providers + key status
    {C}/setkey <p> <key>{RS}  Save API key  (e.g. {C}/setkey gemini AIza...{RS})
    {C}/model <name>{RS}       Override model for current provider
    {C}reset{RS}               Clear conversation history
    {C}clear{RS}               Clear screen
    {C}exit{RS}                Quit

  {W}Tool use:{RS}  {'ENABLED — NemoClaw can suggest CMD:`...` to run' if tools else 'disabled. Run: nemoclaw -t'}

  {W}Current:{RS}  {G}{provider}{RS}  {D}→{RS}  {W}{PROVIDERS[provider]["model"]}{RS}

  {W}Free key:{RS}  {C}https://aistudio.google.com/app/apikey{RS}  (Gemini, works immediately)
""")

def repl(cfg: dict, provider: str, tools: bool):
    setup_readline()
    msgs: list[dict] = []
    print(BANNER)
    print(f'  {G}◈{RS} {W}{provider}{RS}  {D}→{RS}  {D}{PROVIDERS[provider]["model"]}{RS}', end='')
    print(f'  {Y}[tool use ON]{RS}' if tools else '', '\n')

    while True:
        try:
            line = input(f'{M}nc ❯{RS} ').strip()
        except (EOFError, KeyboardInterrupt):
            print(f'\n{D}bye.{RS}')
            break

        if not line:
            continue

        # ── built-in commands ──────────────────────────────────────
        lw = line.lower()
        if lw in ('exit', 'quit', 'q'):
            print(f'{D}bye.{RS}')
            break
        if lw == 'help':
            print_help(provider, tools)
            continue
        if lw == 'clear':
            os.system('clear')
            print(BANNER)
            continue
        if lw in ('reset', 'new'):
            msgs = []
            print(f'{D}[session cleared]{RS}')
            continue
        if line.startswith('!'):
            cmd = line[1:].strip()
            if cmd:
                print(f'{D}{subprocess.run(cmd, shell=True, capture_output=False, text=True) or ""}{RS}', end='')
            continue
        if lw.startswith('/provider '):
            p = line.split()[1].lower()
            if p not in PROVIDERS:
                print(f'{R}[unknown provider: {p}]{RS}')
            elif not cfg.get(PROVIDERS[p]['key_field']):
                print(f'{Y}[no key for {p} — use /setkey {p} YOUR_KEY]{RS}')
            else:
                provider = p
                print(f'{G}[switched → {provider}  {PROVIDERS[provider]["model"]}]{RS}')
            continue
        if lw == '/providers':
            print(f'\n{V}  Providers{RS}')
            for p, ep in PROVIDERS.items():
                ok  = cfg.get(ep['key_field'])
                sym = f'{G}✔{RS}' if ok else f'{R}✘{RS}'
                act = f' {Y}← active{RS}' if p == provider else ''
                print(f'  {sym} {W}{p:<14}{RS} {D}{ep["model"]}{RS}{act}')
            print()
            continue
        if lw.startswith('/setkey '):
            parts = line.split(None, 2)
            if len(parts) < 3:
                print(f'{Y}usage: /setkey <provider> <key>{RS}')
                continue
            _, p, key = parts
            field = PROVIDERS.get(p, {}).get('key_field', f'{p}_api_key')
            save_local_key(field, key)
            cfg[field] = key
            print(f'{G}[key saved for {p}]{RS}')
            if not pick_provider(cfg, provider):
                provider = pick_provider(cfg, None) or provider
            continue
        if lw.startswith('/model '):
            model = line.split(None, 1)[1].strip()
            PROVIDERS[provider]['model'] = model
            print(f'{G}[model → {model}]{RS}')
            continue

        # ── AI call ───────────────────────────────────────────────
        msgs.append({'role': 'user', 'content': line})
        try:
            chunks = stream_response(cfg, provider, msgs)
            reply  = render(chunks, tools)
            msgs.append({'role': 'assistant', 'content': reply})
            if len(msgs) > 40:
                msgs = msgs[-40:]
        except Exception as e:
            print(f'{R}[error] {e}{RS}')
            msgs.pop()

# ── Entry ─────────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(prog='nemoclaw',
        description='NemoClaw — Purple Bruce CLI AI Agent')
    ap.add_argument('prompt', nargs='?',       help='One-shot query')
    ap.add_argument('-p', '--provider',        help='Provider: grok/gemini/claude/venice/openrouter')
    ap.add_argument('-t', '--tools',           action='store_true', help='Enable tool use (bash)')
    ap.add_argument('-m', '--model',           help='Override model name')
    ap.add_argument('--raw',                   action='store_true', help='Raw output (no color borders)')
    args = ap.parse_args()

    # Handle /setkey passed as positional (nemoclaw /setkey gemini KEY)
    if args.prompt and args.prompt.startswith('/'):
        sys.argv = ['nemoclaw'] + sys.argv[1:]
        # re-parse treating it as REPL input — just run REPL
        cfg = load_config()
        provider = pick_provider(cfg, args.provider) or list(PROVIDERS.keys())[0]
        repl(cfg, provider, args.tools)
        return

    cfg      = load_config()
    provider = pick_provider(cfg, args.provider)

    if not provider:
        print(f'{Y}[nemoclaw] No API keys found.{RS}')
        print(f'  Fastest free key:  {W}nemoclaw /setkey gemini YOUR_KEY{RS}')
        print(f'  Get key at:        {C}https://aistudio.google.com/app/apikey{RS}')
        sys.exit(1)

    if args.model:
        PROVIDERS[provider]['model'] = args.model

    # Piped input
    if not sys.stdin.isatty():
        txt = sys.stdin.read().strip()
        if txt:
            chunks = stream_response(cfg, provider, [{'role':'user','content':txt}])
            for ch in chunks:
                print(ch, end='', flush=True)
            print()
        return

    # One-shot
    if args.prompt:
        msgs   = [{'role': 'user', 'content': args.prompt}]
        chunks = stream_response(cfg, provider, msgs)
        if args.raw:
            for ch in chunks:
                print(ch, end='', flush=True)
            print()
        else:
            render(chunks, args.tools)
        return

    # Interactive REPL
    repl(cfg, provider, args.tools)

if __name__ == '__main__':
    main()
