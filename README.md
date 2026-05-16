```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
          N E U R A L   I N T E R F A C E   v 7 . 1
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿

 ██████╗ ██╗   ██╗██████╗ ██████╗ ██╗     ███████╗
 ██╔══██╗██║   ██║██╔══██╗██╔══██╗██║     ██╔════╝
 ██████╔╝██║   ██║██████╔╝██████╔╝██║     █████╗
 ██╔═══╝ ██║   ██║██╔══██╗██╔═══╝ ██║     ██╔══╝
 ██║     ╚██████╔╝██║  ██║██║     ███████╗███████╗
 ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝

          B R U C E  ⚡  L U C Y
    Purple Team · BlackArch · Neural Mesh
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```

**Purple Bruce Lucy** ist eine KI-Sicherheitsplattform für dein Android-Handy.  
Kein Root. Kein Laptop. Keine Cloud nötig. Nur Termux und ein Befehl.

---

## ◈ Installation — 4 Befehle, fertig

Öffne **Termux** (von **F-Droid**, nicht vom Play Store) und füge das ein:

```bash
# 1 — Termux-Pakete installieren
pkg update -y && pkg install -y proot-distro

# 2 — Arch Linux herunterladen und betreten
proot-distro install archlinux && proot-distro login archlinux

# 3 — Purple Bruce installieren (innerhalb von Arch)
wget -qO- https://raw.githubusercontent.com/TAesthetics/purplebruce/main/netrunner/install-arch.sh | bash

# 4 — Neue Shell aktivieren
exec zsh
```

Dauert **10–20 Minuten** (am besten per WLAN). Danach erscheint das Purple Bruce Banner.  
Tippe `go` zum Starten → Browser öffnen: **http://127.0.0.1:3000**

> **WLAN-Tipp:** Falls `wget` mit einem Crypto-Fehler abbricht:  
> `pacman -Sy --noconfirm ngtcp2` ausführen, dann nochmal.

---

## ⚡ Ab jetzt — ein einziger Befehl

Nach der ersten Installation schreibt das Setup automatisch den Alias `pb` in deine Termux-Shell.

**Einfach in Termux eintippen:**

```
pb
```

Fertig. Ein Befehl. Betritt Arch Linux, startet den Server, öffnet das Cyberpunk-Terminal.

---

## ◈ Was ist das hier

```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  Du           →  Android-Handy  (ab ca. 50 €)
  Shell        →  Termux + Arch Linux proot
  Arsenal      →  100+ BlackArch Hacking-Tools
  Gehirn       →  6 KI-Anbieter, automatischer Wechsel
  Ohren        →  Whisper Spracherkennung (Groq)
  Stimme       →  Edge TTS / ElevenLabs
  Augen        →  DJI Mini 4K Drohnenkamera
  Handgelenk   →  M5StickC Plus2 Wearable-Fernbedienung
  Kopfhörer    →  HOCO EQ3 via Bluetooth
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```

---

## ◈ Kopfhörer verbinden — HOCO EQ3

Die HOCO EQ3 werden für Sprachausgabe, KI-Antworten und Drohnen-Alarme genutzt.

### Schritt 1 — PulseAudio starten (einmalig nach jedem Neustart)

Öffne ein **zweites Termux-Fenster** (nicht innerhalb von proot):

```bash
pkg install pulseaudio
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1"
```

### Schritt 2 — HOCO EQ3 koppeln

1. HOCO EQ3 in **Pairing-Modus** setzen → Power-Taste lang drücken bis LED blinkt
2. Am Handy: **Einstellungen → Bluetooth → HOCO EQ3** koppeln
3. In Purple Bruce (innerhalb von Arch proot):

```bash
bt-connect    # HOCO EQ3 automatisch finden und verbinden
bt-status     # Verbindung und Audio-Ausgang prüfen
bt-vol 80     # Lautstärke auf 80 % setzen
```

### Kopfhörer-Befehle

| Befehl | Was passiert |
|--------|--------------|
| `bt` | Interaktives Menü (Scan / Connect / Status / Lautstärke) |
| `bt-connect` | HOCO EQ3 automatisch verbinden |
| `bt-status` | Bluetooth + Audio-Status anzeigen |
| `bt-vol 80` | Lautstärke setzen (0–100) |

> **Hinweis:** Die meisten Android-Kerne leiten Bluetooth nicht in den proot-Container weiter.  
> Deshalb: erst über Android-Einstellungen koppeln, dann über PulseAudio-Bridge nutzen.

---

## ◈ M5StickC Plus2 verbinden

Das M5StickC Plus2 (kleines ESP32-Gerät) hat **zwei Firmware-Optionen**:

### Option A — Bruce Firmware (Hacking-Tool)

Bruce ist ein Allround-Hacking-Framework (WLAN-Scanner, Flipper-Klon, Deauther, etc.)

```bash
# M5StickC Plus2 per USB an das Handy oder einen PC anschließen, dann:
bruce-flash
```

Das Skript lädt automatisch die neueste Version von GitHub, erkennt den USB-Port und fragt vor dem Flashen nach Bestätigung.

**M5Stick bedienen (Bruce):**
- **Button A** = Auswählen / Weiter
- **Button B** = Zurück
- **Seitlicher Button** = Ein/Aus

### Option B — Drohnen-Fernbedienung Firmware

Macht den M5Stick zur Handgelenk-Fernbedienung für die DJI Mini 4K.  
Handgelenk neigen → Drohne bewegt sich.

```bash
# PlatformIO einmalig installieren:
pip install platformio

# Firmware flashen:
drone-flash
```

**M5Stick als Drohnen-Remote:**

| Aktion | Was passiert |
|--------|--------------|
| Handgelenk neigen | Drohne fliegt in diese Richtung (30 Hz IMU) |
| **Button A** kurz | Modus wechseln: HOVER → IMU-CTRL → STATUS → WLAN-SCAN |
| **Button B** kurz | HOVER-Modus: Takeoff · IMU-Modus: Disarm / Hover |
| **Button B** 2 Sek. halten | Notlandung (von jedem Modus aus) |
| **Schütteln** (> 2,5g) | Notfall-Stopp sofort |

**Verbindungs-IP anpassen** (per USB-Serial, 115200 Baud):
```
IP:192.168.1.100
```
Das M5Stick verbindet sich dann automatisch mit der Drohnen-Bridge auf dieser IP.

---

## ◈ DJI Mini 4K Drohne verbinden

### Schritt 1 — Drohne einschalten + WLAN-Hotspot aktivieren

```
Power-Taste 3 Sekunden gedrückt halten
→ Drohne erstellt WLAN-Hotspot: "DJI_MINI_XXXXXX"
```

### Schritt 2 — Handy mit Drohnen-WLAN verbinden

Am Handy: **WLAN-Einstellungen → DJI_MINI_XXXXXX** verbinden.

### Schritt 3 — Bridge starten

In Purple Bruce (innerhalb von Arch proot):

```bash
drone-bridge
```

Dann im Browser **http://127.0.0.1:3000/drone** öffnen → **Scan** klicken → **Connect**.

### Schritt 4 — Drohne fliegen

```bash
drone-track           # Ziel im Fenster anklicken → autonomes Verfolgen
drone-track-face      # Gesicht erkennen + verfolgen + nach Verlust wiederfinden
drone-track-auto      # Erste Person automatisch erkennen und verfolgen
drone-patrol          # Sicherheits-Patrouille um dein Grundstück
drone-patrol-watch    # Nur hovern + Alarm bei erkannter Person
```

**Bei erkannter Person:** HOCO EQ3 spielt automatisch einen 3-Ton-Alarm (A5→C6→E6).  
Alle Erkennungen werden als JPEG gespeichert und in der Purple Bruce Datenbank protokolliert.

### Drohnen-Befehle Übersicht

| Befehl | Was passiert |
|--------|--------------|
| `drone-bridge` | UDP-Bridge zur DJI Mini 4K starten |
| `drone-track` | Ziel anklicken, Drohne folgt automatisch |
| `drone-track-face` | Gesichtserkennung + Re-Identifikation bei Verlust |
| `drone-track-auto` | Erste Person automatisch erkennen und verfolgen |
| `drone-patrol` | 8m-Viereck patrouillieren (konfigurierbar) |
| `drone-patrol-watch` | Hover + Erkennung + Alarm (ohne Flugroute) |
| `drone-flash` | Drohnen-Remote-Firmware auf M5Stick flashen |

---

## ◈ Alle Befehle

### Server

| Befehl | Was passiert |
|--------|--------------|
| `go` | Purple Bruce Server starten |
| `stop` | Server stoppen |
| `pbrestart` | Server neu starten |
| `logs` | Live-Logs anzeigen |
| `pbupdate` | Neueste Version laden + alles neu einrichten |

### KI-Agent (NemoClaw)

| Befehl | Was passiert |
|--------|--------------|
| `nc` | Interaktiver KI-Chat (wie Claude CLI) |
| `nc "Frage"` | Einmalige Abfrage |
| `nct "Aufgabe"` | Mit Tool-Nutzung — kann Bash-Befehle ausführen |
| `ncg` | Gemini erzwingen |
| `ncc` | Claude erzwingen |
| `nc /setkey gemini KEY` | API-Key speichern |

### Scannen & Hacking

| Befehl | Was passiert |
|--------|--------------|
| `scan <ziel>` | KI-gestützter Recon-Scan |
| `nq <ziel>` | Schneller nmap-Scan |
| `nfull <ziel>` | Vollständiger nmap-Scan (alle Ports) |
| `nstealth <ziel>` | Stealth-Scan |
| `se <begriff>` | Exploit-DB durchsuchen |
| `msfq` | Metasploit starten |
| `toolcheck` | Alle Tools prüfen |

### Dashboard

| Befehl | Was passiert |
|--------|--------------|
| `tui` | Interaktives TUI-Dashboard |
| `deck` | Cyberdeck-Status |
| `team` | KI-Anbieter-Status |
| `doctor` | Probleme erkennen + automatisch beheben |

---

## ◈ KI-Anbieter — API-Keys eintragen

Im Browser: **http://127.0.0.1:3000** → Einstellungen ⚙ → Keys eingeben.

Oder im Terminal:

```bash
nc /setkey gemini DEIN_KEY
nc /setkey grok   DEIN_KEY
nc /setkey claude DEIN_KEY
```

| Anbieter | Kostenlos? | Key-URL |
|----------|------------|---------|
| **Gemini** (Google) | ✅ Gratis-Tier | aistudio.google.com/app/apikey |
| **Groq** (Sprache/STT) | ✅ Gratis-Tier | console.groq.com |
| **Grok** (xAI) | Teilweise gratis | console.x.ai |
| **Claude** (Anthropic) | Kostenpflichtig | console.anthropic.com |
| **Venice** | Kostenpflichtig | venice.ai |
| **OpenRouter** | Pay-per-Use | openrouter.ai |

**Empfehlung zum Starten:** Gemini — kostenlos, keine Kreditkarte, sofort verfügbar.

---

## ◈ Häufige Fehler

**`pb` nicht gefunden in Termux**
```bash
echo "alias pb='proot-distro login archlinux -- bash ~/purplebruce/netrunner/launch.sh'" >> ~/.bashrc
source ~/.bashrc
```

**`npm install` schlägt fehl**
```bash
pacman -S --noconfirm python make gcc
cd ~/purplebruce && npm install
```

**`wget` Crypto-Fehler**
```bash
pacman -Sy --noconfirm ngtcp2 && ldconfig
```

**Server startet, Browser kann nicht verbinden**
```bash
doctor
curl http://127.0.0.1:3000/api/health
```

**Bluetooth: "adapter not found"**  
Normal auf Android. HOCO EQ3 über Android-Bluetooth koppeln, dann PulseAudio in Termux starten (siehe oben).

**Drohne verbindet sich nicht**  
Prüfen: Handy per WLAN mit DJI_MINI_XXXXXX verbunden? → `drone-bridge` neu starten → Browser: Scan → Connect.

---

## ◈ Update

```bash
pbupdate
```

Lädt neueste Version, installiert Abhängigkeiten, richtet alles neu ein. Danach `exec zsh`.

---

## ◈ Dateistruktur

```
purplebruce/
├── server.js                      KI-Server — Express + WebSocket
├── public/
│   ├── index.html                 Web-Oberfläche
│   ├── hud.html                   Smart-Glasses HUD
│   └── drone.html                 Drohnen-Steuerung
├── netrunner/
│   ├── launch.sh                  ← einziges 'pb' Startziel
│   ├── bin/netrunner              CLI: doctor/deck/team/scan/nc
│   ├── install-arch.sh            Kompletter Arch + BlackArch Installer
│   ├── firmware/
│   │   └── flash-bruce.sh         Bruce Firmware → M5StickC Plus2
│   ├── dotfiles/
│   │   ├── zshrc                  ZSH v7.1 — alle Aliases
│   │   └── install.sh             Dotfiles + 'pb' Alias schreiben
│   ├── nemoclaw/
│   │   └── nemoclaw.py            KI-Agent CLI (nc)
│   ├── audio/
│   │   └── bt-setup.sh            Bluetooth Audio — HOCO EQ3
│   ├── drone/
│   │   ├── mini4k.py              DJI Mini 4K Bridge (Port 7778)
│   │   ├── tracker.py             Autonomes Tracking + Gesichtserkennung
│   │   └── patrol.py              Sicherheits-Patrouille
│   └── hardware/
│       └── drone-remote/          M5StickC Plus2 Wearable-Remote
│           ├── drone-remote.ino   IMU Drohnen-Firmware
│           └── platformio.ini
└── purplebruce.db                 SQLite: Config, Keys, Verlauf, Alerts
```

---

## ◈ Sicherheit

- **Operator-Token** — wird beim ersten Start generiert, liegt in `~/.purplebruce/operator.txt`
- **Nur Localhost** — Server bindet an `127.0.0.1`
- **Audit-Log** — jeder Befehl in `~/.purplebruce/audit.log`
- **Rate-Limiting** — 120 Anfragen/Minute
- Drohne, Scan, Exec: alle benötigen den Operator-Token

---

## ◈ Links

- GitHub: https://github.com/TAesthetics/purplebruce
- Issues: https://github.com/TAesthetics/purplebruce/issues
- Kostenloser Gemini-Key: aistudio.google.com/app/apikey
- Kostenloser Groq-Key (Sprache): console.groq.com

```
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
  PURPLE BRUCE LUCY v7.1 — NEURAL MESH AKTIV
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
```
