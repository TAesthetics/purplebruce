# 🟣 Purple Bruce v5.0 — JARVIS EDITION

**Purple Bruce** ist eine hochmoderne, KI-gesteuerte Purple-Team-Plattform für Sicherheitsanalysen, Bedrohungsjagden und automatisierte Systemhärtung. In der Version 5.0 (Jarvis Edition) wurde das System von einem einfachen Tool zu einem autonomen Security-Agenten hochgestuft.

---

## 🌟 Hauptmerkmale

### 🤖 NetGhost AI-Agent (Jarvis Core)
*   **Chain-of-Thought (CoT) Reasoning**: Der Agent denkt, plant und analysiert (THINK -> PLAN -> CMD -> ANALYSIS), bevor er handelt.
*   **Chat-basierte Steuerung**: Die Chat-Schnittstelle ist die primäre Kontrolleinheit. Ein einfacher Befehl wie "Prüfe mein System auf Rootkits" startet eine komplexe, mehrstufige Untersuchung.
*   **Autonomer Modus**: Kann so konfiguriert werden, dass Befehle ohne manuelle Bestätigung ausgeführt werden.

### 🛡 Blue Team SOC Analyst Daemon
*   **Hintergrund-Überwachung**: Ein aktiver Daemon überwacht kontinuierlich Netzwerk-Listener, ausgehende Verbindungen, `LD_PRELOAD`-Injektionen und Crontabs.
*   **Automatische Forensik**: Bei verdächtigen Aktivitäten erstellt das System automatisch Snapshots und isoliert Dateien in der Quarantäne.
*   **Echtzeit-Alerts**: Sofortige Benachrichtigung über die Weboberfläche bei Sicherheitsvorfällen.

### ⚡ Unrestricted Access (Jarvis Mode)
*   **Vollständiger Zugriff**: In der v5.0 wurden alle "Engagement Scope"-Einschränkungen aufgehoben.
*   **Externe Scans**: Der Agent kann jedes beliebige Ziel (IP oder Domain) im Internet scannen und analysieren.
*   **Keine Safety-Blocker**: Alle Befehle werden ungefiltert ausgeführt (volle Systemgewalt).

---

## 🚀 Installation & Setup (Terminal)

Folge diesen Schritten, um Purple Bruce v5.0 auf deinem System (optimiert für Mac/Linux) zu installieren.

### 1. Repository klonen
```bash
git clone https://github.com/TAesthetics/purplebruce.git
cd purplebruce
```

### 2. Abhängigkeiten installieren
```bash
npm install
```

### 3. Native Module kompilieren (Wichtig für Mac/arm64)
Da `better-sqlite3` ein natives Modul ist, muss es für deine Architektur gebaut werden:
```bash
npm rebuild better-sqlite3
```

### 4. System-Tools installieren (Optional)
Für den vollen Funktionsumfang (Recon) wird `nmap` empfohlen:
```bash
brew install nmap  # Für Mac (Homebrew)
# oder
sudo apt install nmap  # Für Debian/Ubuntu
```

---

## 💻 Starten des Systems

Es gibt zwei Wege, Purple Bruce zu nutzen:

### A. Hybrid-Modus (Web-UI + CLI) — Empfohlen
Verwende das Haupt-Shell-Script, um den Server und das Terminal-Interface gleichzeitig zu starten:
```bash
chmod +x purplebruce.sh
./purplebruce.sh
```
*   **Web-Interface**: Öffne [http://127.0.0.1:3000](http://127.0.0.1:3000) in deinem Browser.
*   **API-Keys**: Konfiguriere deine AI Keys (Grok oder Venice) in den Einstellungen des Web-UI.

### B. Nur Server-Modus
Wenn du nur das Web-UI nutzen möchtest:
```bash
npm start
```

---

## 📁 Projektstruktur
*   `server.js`: Der Kern des Systems (Express Server + Agent Logik).
*   `purplebruce.sh`: Das interaktive Terminal-Frontend.
*   `public/`: Die JARVIS Web-Schnittstelle.
*   `~/.purplebruce/`: Speicherort für Audit-Logs, Quarantäne und Forensik-Daten.

---

## ⚠️ Sicherheitshinweis
Dieses System wurde für Sicherheitsprüfungen entwickelt. Durch den **Unrestricted Access** Modus hat die KI volle Kontrolle über Terminal-Befehle. Nutzen Sie das Tool verantwortungsbewusst und nur auf autorisierten Systemen.

---
**Entwickelt von TAesthetics — Jarvis v5.0**
