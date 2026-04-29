# 🟣 Purple Bruce — Quickstart (für Anfänger)

Du hast ein Android-Handy, du willst Lucy. Zwei Befehle.

---

## 1. Termux installieren

Lade **Termux** aus F-Droid: <https://f-droid.org/de/packages/com.termux/>
(Nicht aus dem Play Store — die Version dort ist veraltet.)

Termux öffnen. Du siehst einen schwarzen Bildschirm mit `$`. Das ist deine
Konsole.

---

## 2. Diese eine Zeile reinkopieren

```bash
pkg install -y git curl && git clone https://github.com/TAesthetics/purplebruce.git && bash purplebruce/netrunner/install.sh
```

Drück **Enter**. Geh einen Kaffee holen — der Download dauert ein paar
Minuten. Ubuntu wird installiert (~200 MB).

---

## 3. Starten

Wenn der Installer durch ist, tippe:

```bash
netrunner
```

Das Ding macht jetzt **alles selbst**:

- springt in die Ubuntu-Sandbox
- lädt Node.js, zsh, fastfetch
- startet Lucy auf `http://127.0.0.1:3000`
- zeigt dir den fetten Cyberpunk-Banner

Wenn unten steht `lucy is alive @ http://127.0.0.1:3000` → öffne diese
Adresse in **Chrome / Firefox auf deinem Handy**. Da redest du mit ihr.

---

## 4. API-Key

Damit Lucy denken kann, braucht sie einen LLM-Schlüssel. In der Web-UI:
**⚙ Settings → Grok API Key** rein. Den Schlüssel holst du dir kostenlos auf
<https://console.x.ai>.

Optional: ElevenLabs (für die Stimme), Groq (für das Mikro).

---

## 5. Tägliche Nutzung

Ab jetzt für immer nur:

```bash
netrunner          # alles starten
netrunner stop     # alles stoppen
netrunner logs     # gucken was los ist
netrunner status   # gucken was läuft
netrunner chat     # mit Lucy im Terminal reden
```

Du musst **nie wieder** `proot-distro login`, `cd`, `npm install` oder
sowas tippen. Alles ist `netrunner`.

---

## Wenn was nicht klappt

```bash
netrunner status     # zeigt dir was fehlt
netrunner logs       # zeigt dir warum's brennt
```

Server-Log liegt unter `~/purplebruce/.purplebruce/server.log`.

Wenn das alles nichts hilft: GitHub-Issue mit der Ausgabe von
`netrunner status` öffnen unter <https://github.com/TAesthetics/purplebruce>.

---

**Viel Spaß mit Lucy. 🟣**
