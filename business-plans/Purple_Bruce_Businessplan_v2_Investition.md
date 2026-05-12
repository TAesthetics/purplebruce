# Purple Bruce
## Tertratronic Rippler — AI-gestütztes Purple-Team-Cyberdeck
### Businessplan v2.0 · Investitionsversion 150.000 – 500.000 €
### Stand: Mai 2026 · HES Marketing FlexCo, Salzburg

---

## 1. Executive Summary

Purple Bruce ist eine proprietäre, AI-gestützte Cyberdeck-Plattform für Purple-Team-Operationen. Das Produkt wird unter dem Codenamen **Tertratronic Rippler v6.0 (Tier 5, Stufe 2)** ausgeliefert und ist ein Geschäftsbereich der HES Marketing FlexCo mit Sitz in Salzburg.

**Die neue strategische Stoßrichtung (v2.0):** Mit der Erweiterung um **Purple Compute** – eigene GPU-Infrastruktur für lokal gehostete KI-Modelle – wird Purple Bruce unabhängig von externen API-Anbietern und positioniert sich als einzige DACH-Lösung für **souveräne, datenschutzkonforme Purple-Team-KI** ohne Cloud-Zwang.

**Finanzierungsbedarf:**
- **Tranche 1 (Seed) – sofort:** 150.000 €
- **Tranche 2 (Growth) – 12 Monate nach Seed:** 350.000 €
- **Gesamtbedarf:** 500.000 €

**Verwendung:** Alle ausgewiesenen Kosten entsprechen direkt dem Investitionsbedarf. Jeder Euro wird in konkrete Leistung überführt: Engineering, Hardware, Markteintritt, IP-Schutz, Compliance.

> **Hinweis zur Glaubwürdigkeit:** Sämtliche Kostenansätze sind am Salzburger und österreichischen Markt recherchiert und nachweisbar. Die formale Bilanz- und GuV-Planung wird separat über **plan4you** (österreichischer Standard) erstellt und als Anlage beigefügt.

---

## 2. Produkt

### 2.1 Produktbeschreibung

Purple Bruce ist eine Sicherheitsplattform für Penetrationstester und Security-Teams, die Angriffssimulation und Verteidigung in einem einzigen, kontrollierten Werkzeug kombiniert. Das Produkt ist kein Konzept – Version 6.0 läuft produktiv.

**Was die Software konkret tut:**

- **Drei-KI-Failover:** Grok-3, Venice/Llama-3.3 und GPT-4o laufen parallel. Fällt ein Anbieter aus oder überschreitet sein Latenzlimit, übernimmt der nächste automatisch – ohne Neustart, ohne manuelle Umkonfiguration, innerhalb von 60 Sekunden.
- **Kontrollierter Operator-Workflow:** Jede von der KI vorgeschlagene Aktion – ob Shell-Befehl, Netzwerkscan oder Dateioperationen – muss vom Operator explizit bestätigt werden. Keine autonome Ausführung.
- **Angriffssimulation mit MITRE-Mapping:** 11 editierbare Module decken reale Angriffsmuster ab (Credential-Dump, Lateral Movement, DNS-Exfiltration, C2-Kommunikation u.a.) – alle mit direkter Referenz auf das MITRE ATT&CK-Framework.
- **Parallele Verteidigungsprotokollierung:** Während ein Angriffsszenario läuft, erfasst ein Hintergrunddienst Systemveränderungen, erstellt forensische Snapshots und schlägt bei kritischen Ereignissen Alarm.
- **Revisionssicheres Audit-Log:** Jede Aktion – KI-Vorschlag, Operator-Entscheidung, Systemreaktion – wird vollständig und unveränderbar protokolliert. Das Log ist direkt in Pentest-Berichte und Compliance-Exporte überführbar.
- **Sprachsteuerung und Terminal-Interface:** Sprachbefehl (Push-to-Talk mit Transkription) und strukturiertes CLI-Interface zeigen denselben Systemzustand – der Operator wählt die Bedienform situativ.

### 2.2 Entwicklungsstand

Version 6.0 ist produktionsreif. Die Architektur ist validiert. Mit der Seed-Finanzierung beginnt die kommerzielle Härtung: Lizenz-Server, signierte Builds, Onboarding, SLAs.

### 2.3 Roadmap 2026–2028 (aktualisiert)

| Phase | Version | Zeitraum | Meilensteine |
|---|---|---|---|
| Kommerzialisierung | v6.x | 2026 H1 | Lizenz-Server, Closed-Beta, Security-Audit |
| Enterprise | v7.0 | 2026 H2 | Multi-Tenant, RBAC, SSO, On-Premise |
| Compliance | v7.x | 2027 | NIS2/DORA-Exports, GRC-Integration |
| **Purple Compute MVP** | **v8.0** | **2027 H1** | **Eigener GPU-Server online, 4. Provider (lokal)** |
| **Purple Compute Scale** | **v8.x** | **2027–2028** | **GPU-Cluster, DACH-Colocation, Air-Gap-KI** |

### 2.4 Innovationsgehalt

Die zentrale Innovation: Multi-Provider-Disziplin + explizite Operator-Genehmigung + lückenloser Audit-Trail + souveräne eigene KI-Infrastruktur. Diese Kombination existiert im DACH-Markt nicht.

### 2.5 Alleinstellungsmerkmal

Purple Bruce ist – nach aktuellem Kenntnisstand – das **einzige Produkt**, das:
1. Self-Healing-Drei-Provider-AI-Team
2. Natives MITRE-ATT&CK-Coverage
3. Integrierten SOC-Daemon
4. Revisionssicheren Audit-Log
5. **Lokal betriebene KI ohne Cloud-Zwang (ab v8.0)**

in einem einzigen Werkzeug vereint. Diese Kombination ist im DACH-Raum unbesetzt.

---

## 3. Purple Compute – Eigene KI-Infrastruktur

### 3.1 Strategische Begründung

Externe KI-Anbieter (OpenAI, xAI, Venice) haben drei strukturelle Nachteile für Sicherheits-Profis:

1. **Datenschutz:** Prompts verlassen die eigene Infrastruktur – für KRITIS-Kunden und Behörden inakzeptabel
2. **Abhängigkeit:** API-Preissteigerungen, ToS-Änderungen, Ausfälle können den Betrieb lahmlegen
3. **Latenz:** Externe APIs haben inhärente Latenz; lokale Modelle können auf spezialisierten Workloads schneller reagieren

Mit **Purple Compute** baut HES Marketing eine eigene GPU-Infrastruktur auf, die:
- Llama-3.3-70b und zukünftige Open-Weight-Modelle lokal betreibt
- Als **4. Provider** in der Self-Healing-Kette eingehängt wird
- Für Air-Gap-Kunden (Behörden, KRITIS) eine vollständig offline-fähige KI-Lösung ermöglicht

### 3.2 Infrastrukturplanung Purple Compute

#### Stufe 1 – Edge AI Server (2027 Q1, Kosten: ~22.000 €)

Sofort verfügbar, betreibbar in einem Coworking-Rack oder Micro-Colocation:

| Position | Stück | Einzelpreis | Gesamt |
|---|---|---|---|
| High-End GPU Workstation (AMD EPYC Basis) | 1 | 3.500 € | 3.500 € |
| NVIDIA RTX 4090 24GB (VRAM für 70B quantisiert) | 2 | 2.200 € | 4.400 € |
| NVMe-SSD 4TB (Samsung 990 Pro) | 2 | 450 € | 900 € |
| 64 GB ECC RAM | 1 Set | 480 € | 480 € |
| 10-GbE Netzwerkkarte | 1 | 220 € | 220 € |
| UPS (1500 VA) | 1 | 350 € | 350 € |
| Rack-Gehäuse / Mounting | 1 | 600 € | 600 € |
| **Subtotal Hardware** | | | **10.450 € ** |
| Colocation (Micro-DC, 2U, 1 Jahr, inkl. Strom) | 12 Mon. | 350 €/Mon. | 4.200 € |
| Setup & Konfiguration (Ollama, vLLM, Monitoring) | 40h | 85 €/h | 3.400 € |
| Monitoring & Sicherheitssoftware (1 Jahr) | | | 1.200 € |
| Netzwerk-Infrastruktur | | | 900 € |
| Puffer (15 %) | | | 1.823 € |
| **Gesamtkosten Stufe 1** | | | **21.973 € ≈ 22.000 €** |

**Leistung Stufe 1:**
- Llama-3.1-8B: ~120 Tokens/Sekunde (Echtzeitbetrieb)
- Llama-3.3-70B (quantisiert, Q4): ~18 Tokens/Sekunde (nutzbar für den Operator-Workflow)
- Parallele Sessions: 2–4 gleichzeitig
- **Betriebskosten laufend:** ~350 €/Monat (Colocation + Strom)

#### Stufe 2 – Dedizierter GPU-Cluster (2027 Q3, Kosten: ~90.000 €)

Ermöglicht Enterprise-Kundschaft und Air-Gap-Deployment:

| Position | Stück | Einzelpreis | Gesamt |
|---|---|---|---|
| NVIDIA A100 40GB PCIe | 4 | 9.800 € | 39.200 € |
| GPU-Server-Chassis (SuperMicro 2U) | 2 | 7.500 € | 15.000 € |
| NVMe-Storage-Cluster (20TB NVMe) | 1 | 6.500 € | 6.500 € |
| InfiniBand / 25GbE Networking | 1 Set | 4.800 € | 4.800 € |
| PDU & Power-Management | 1 | 2.200 € | 2.200 € |
| Rack (42U, vollständig) | 1 | 2.800 € | 2.800 € |
| **Subtotal Hardware** | | | **70.500 €** |
| Colocation (10U, Tier-2-Rechenzentrum Wien/Salzburg, 1 Jahr) | | | 9.600 € |
| Infrastruktur-Setup (Ingenieursstunden) | 80h | 95 €/h | 7.600 € |
| Monitoring, Sicherheit, Backup (1 Jahr) | | | 2.300 € |
| **Gesamtkosten Stufe 2** | | | **90.000 €** |

**Leistung Stufe 2:**
- Llama-3.3-70B (full precision): ~50 Tokens/Sekunde
- Parallele Enterprise-Mandanten: 10–20
- Air-Gap-fähig: vollständig offline betreibbar

#### Stufe 3 – DACH-Rechenzentrumsstruktur (2028, im Gesamtbedarf enthalten)

Für regulierte Großkunden und KRITIS-Betreiber:
- Dedizierte Rack-Anmietung in einem zertifizierten DACH-Rechenzentrum (ISO 27001, Tier 3)
- H100/A100-Cluster mit Redundanz
- Betriebskosten ~2.000 €/Monat → 24.000 €/Jahr
- Einrichtungskosten ~30.000 €
- Betrieb durch einen Purple-Compute-Operations-Engineer (0,5 FTE)

### 3.3 Wettbewerbsvorteil durch eigene KI

Mit Purple Compute wird Purple Bruce das **einzige Cyberdeck im DACH-Raum**, das:
- Vollständig Air-Gap-fähige KI anbietet
- DSGVO- und BSI-Grundschutz-konforme On-Premise-KI ermöglicht
- Keine Abhängigkeit von US-Cloud-Anbietern hat
- Modell-Customization für spezifische Kundenanforderungen erlaubt

---

## 4. Markt & Wettbewerb

### 4.1 Marktgröße

- Globaler Pentest/Offensive-Security-Markt: ~8 Mrd. USD, +12 % p.a.
- DACH-Markt Detection & Response: ~400 Mio. € (wachsend durch NIS2)
- NIS2 zwingt ca. 100.000 neue Unternehmen in der EU zu formalem Schwachstellenmanagement
- Fachkräftelücke DACH: ~100.000 Security-Spezialisten

### 4.2 Zielgruppen

| Segment | Charakteristik | Lizenzmodell | ARPU (jährlich) |
|---|---|---|---|
| Interne Security-Teams | CISO/SecOps, 50–500 Endpoints | Per-Operator | 2.400–4.800 € |
| MSSPs / Pentest-Anbieter | Mehrkundenbetrieb, Multiplikatoreffekt | Volumenpaket | 9.600–24.000 € |
| Regulierte Großkunden (KRITIS) | Banken, Versicherer, Behörden | On-Premise/Air-Gap | 48.000–120.000 € |
| Forschung & Lehre | FHs, Universitäten, Research | Education-Lizenz | 1.200–2.400 € |

### 4.3 Wettbewerbsanalyse

| Wettbewerber | Stärke | Purple Bruce Vorteil |
|---|---|---|
| Cobalt Strike / Brute Ratel | Etabliertes Red-Team-Tooling | Integriertes Blue-Team + AI-Orchestrierung + eigene KI |
| Metasploit Pro | Breite Abdeckung | AI-native Operator-Experience, Voice |
| Pentest-Copiloten (PentestGPT) | AI-Komponenten | Vollständiges Cyberdeck, Multi-Provider-Failover |
| XDR-Plattformen (CrowdStrike) | Detection-Stärke | Offensives Tooling + Air-Gap-KI |

### 4.4 Marktpositionierung

Purple Bruce = **Operator-First-Cyberdeck** für disziplinierte, auditierbare, souveräne Security-Operationen im DACH-Raum.

---

## 5. Marketing & Vertrieb

### 5.1 Marketingstrategie

Zwei Kanäle – konsequent umgesetzt, nicht fünf halb. Qualität schlägt Quantität.

**Kanal 1 – Fachvorträge auf DACH-Security-Konferenzen (BSidesVienna, DeepSec Salzburg):**
Zwei Auftritte pro Jahr mit einer Live-Demo des echten Operator-Workflows – kein Slide-Deck ohne laufendes System. Ziel ist Glaubwürdigkeit bei Praktikern, nicht bei Marketing-Entscheidern. Jeder Vortrag endet mit einem konkreten Angebot: 90-Tage-Pilotlizenz zum Sonderpreis für Konferenzteilnehmer.

**Kanal 2 – Privater Operator-Discord mit Referral-Zugang:**
Kein offenes Forum. Zugang ausschließlich über Empfehlung eines aktiven Operators. Innerhalb der Community: wöchentliche technische Walkthrough-Videos, ehrliche Changelogs, direkter Draht zum Entwicklungsteam. Diese Hürde ist gewollt – sie filtert auf echte Praktiker und verhindert Verwässerung der Marke.

### 5.2 Vertriebsstrategie

- **Pilotprogramm (90 Tage):** Einstieg für jeden neuen Kunden – mit klarem Rückgaberecht und begleitetem Onboarding. Kein Kaltverkauf.
- **MSSP-Direktkontakt:** Persönlicher Erstkontakt mit IT-Sicherheitshäusern im DACH-Raum – kein Cold-Mailing, sondern warme Übergaben aus dem Konferenz- und Community-Netzwerk.
- **Education:** Vergünstigte Lizenzen für FHs/Universitäten über Sovereign Youth als Bildungspartner.
- **Air-Gap-Demo für Behörden:** Purple-Compute-Node als mobile Demo-Unit für KRITIS-Betreiber und Behörden – physisch im Haus, kein Cloudanschluss nötig.

### 5.3 Preisgestaltung

| Tier | Zielgruppe | Preis (jährlich) |
|---|---|---|
| Operator Solo | Einzelner Pen-Tester | 1.980 € |
| Team (5 Seats) | Interne SecOps, kleine MSSPs | 7.800 € |
| Enterprise (25 Seats) | Große SecOps, mittlere MSSPs | 28.800 € |
| Enterprise On-Premise | KRITIS, Behörden, Air-Gap | ab 48.000 € / Individualvertrag |
| Education | FHs, Universitäten, Research | 480 € |
| Purple Compute Add-on | Lokale KI-Infrastruktur (Air-Gap) | Hardwarepreis + 4.800 € Setup |

---

## 6. Unternehmen & Management

### 6.1 Information zum Unternehmen

Purple Bruce ist ein Geschäftsbereich der HES Marketing FlexCo, Sitz Salzburg. Eine separate Verwertungsgesellschaft wird ab Erreichen eines definierten Lizenzvolumens (> 500 k€ ARR) geprüft.

### 6.2 Management & Team

Die Kerntechnik von Purple Bruce wurde intern entwickelt. Folgende Personen tragen direkte inhaltliche und technische Verantwortung – keine externen Berater, kein ausgelagertes Entwicklungsteam:

| Rolle | Person | Credentials & Hintergrund |
|---|---|---|
| Produktleitung / AI-Architektur | Carl Friedrich | Geschäftsführung HES Marketing FlexCo und Sovereign Youth; Strategie, Multi-Provider-AI-Routing, Förderanträge, operatives Management; 5+ Jahre Projektleitung |
| Head of Cybersecurity / Security Engineering | Terence Nwaeke | Offensive & defensive Security-Praxis (Kali Linux, Metasploit, MITRE ATT&CK); Netzwerk-Forensik, Penetrationstests; Head of Cybersecurity Sovereign Youth; reale Lab-Erfahrung im Digital Coil Security Lab |
| Security Engineering (stv.) / Infrastruktur | Alex Holzer | Netzwerk-Security, Infrastrukturarchitektur, Firewall/IDS-Konfiguration; stv. Head of Cybersecurity; Linux-Systemadministration, VPN/Segmentierung |
| Backend-Entwicklung / CLI | [Besetzung in Vorbereitung] | Python/Bash, tmux-Automation, REST-API-Integration, ArduinoESP32 (M5Stick-Firmware); Stellenprofil liegt vor, Besetzung bis Q3 2026 |

> _Detaillierte Lebensläufe und Referenzprojekte werden auf Anfrage bereitgestellt._

### 6.3 Kooperationspartnerschaften

- AI-Provider (xAI, Venice, OpenAI) – kommerzielle Verträge auf Plattform-Ebene
- AWS / Hetzner – Cloud-Infrastruktur für SaaS-Variante
- ElevenLabs / Groq – Voice-Stack
- MSSP-Partner – Reseller & Co-Delivery
- **Sovereign Youth** – Nachwuchs- und Bildungspipeline (Digital Coil Security Lab)
- **Zertifiziertes DACH-Rechenzentrum** (Gespräche laufend) – Purple-Compute-Colocation

---

## 7. Status Quo

- Version 6.0 produktionsreif, drei AI-Provider operativ
- CLI, Voice-UI, SOC-Daemon und Black-Ice-Module vollständig funktionsfähig
- Erste Closed-Beta-Lizenznehmer in Vorbereitung
- Markenanmeldung in Vorbereitung
- Closed-Source-Migration in Umsetzung
- **Purple Compute:** Evaluierungsphase abgeschlossen; Hardware-Konfiguration festgelegt, Colocation-Partnerschaft in Verhandlung

---

## 8. Finanzplanung

> **Coach-Feedback integriert:** Die Finanzplanung ist realistisch und glaubwürdig. Jede Kostenposition entspricht einer konkreten, nachweisbaren Leistung. Es gilt: Was als Kosten ausgewiesen ist, entspricht dem beantragten Investment. Formal wird die Bilanz + GuV-Planung über **plan4you** (österreichischer Standard für Investoren und Förderstellen) finalisiert und beigefügt.

### 8.1 Laufende Kosten – Tranche 1 (150.000 €, Jahr 1)

| Kostenposition | Betrag | Anteil | Erläuterung |
|---|---|---|---|
| **Engineering (2 FTEs × 12 Monate)** | 84.000 € | 56 % | 3.500 €/Monat/Person (österreichische Junior-Senior-Mischrate netto) |
| – Lead Engineer / AI-Architekt | 48.000 € | | Architektur, Provider-Routing, Purple-Compute-Integration |
| – Security Engineer / CLI | 36.000 € | | CLI, Black-Ice-Module, SOC-Daemon, Audit-Trail |
| **Purple Compute Stufe 1 (Edge-Server)** | 22.000 € | 15 % | Hardware + Colocation + Setup (siehe Kap. 3.2) |
| **AI-Provider-API-Kosten (1 Jahr)** | 12.000 € | 8 % | Grok, Venice, OpenAI – je ~4.000 €/Jahr bei Betabetrieb |
| **Rechtliche Absicherung (IP, Marke)** | 10.000 € | 7 % | Markenanmeldung (AT/DE), Gebrauchsmuster (AT), Lizenzrecht-Beratung, NDA-Templates |
| **Security Audit (extern, unabhängig)** | 8.000 € | 5 % | 1 Pentest der eigenen Plattform (Österreichischer Anbieter) |
| **Marketing / Messen / Events** | 8.000 € | 5 % | BSidesVienna, DeepSec, Flyermaterial, Website-Relaunch |
| **Cloud-Infrastruktur (AWS/Hetzner)** | 6.000 € | 4 % | SaaS-Infrastruktur, CI/CD, Lizenz-Server-Hosting |
| **Beratung (Steuer, Recht, Förderantrag)** | 5.000 € | 3 % | Wirtschaftsprüfer, Rechtsanwalt, aws-Förderberatung |
| **Puffer / Unvorhergesehenes (8 %)** | 11.960 € | | |
| **Subtotal Tranche 1** | **166.960 €** | | |
| _Gerundet auf:_ | **150.000 €** | | _(Puffer reduziert, Eigenleistung deckt Rest)_ |

### 8.2 Laufende Kosten – Tranche 2 (350.000 €, Jahr 2)

| Kostenposition | Betrag | Anteil | Erläuterung |
|---|---|---|---|
| **Engineering (4 FTEs × 12 Monate)** | 180.000 € | 51 % | Scale auf 4 Engineers (inkl. 1 DevOps für Purple Compute) |
| **Purple Compute Stufe 2 (GPU-Cluster)** | 90.000 € | 26 % | A100-Cluster + Colocation + Setup (siehe Kap. 3.2) |
| **Sales & Customer Success (1 FTE)** | 42.000 € | 12 % | MSSP-Vertrieb, Pilot-Begleitung, Onboarding |
| **AI-Provider-APIs + laufende Infrastruktur** | 18.000 € | 5 % | Externe APIs + wachsende Cloud-Kosten |
| **Marketing Scale** | 12.000 € | 3 % | Konferenzpräsenz, Case Studies, PR |
| **Compliance / Audit / IP-Erweiterung** | 8.000 € | 2 % | NIS2-Compliance-Check, Patenterweiterung |
| **Puffer** | 10.000 € | 3 % | |
| **Subtotal Tranche 2** | **360.000 €** | | |
| _Gerundet auf:_ | **350.000 €** | | |

### 8.3 Gesamtkapitalbedarf

| Tranche | Zeitpunkt | Betrag | Verwendung |
|---|---|---|---|
| Tranche 1 (Seed) | Sofort / Q3 2026 | 150.000 € | Engineering MVP, Purple Compute Stufe 1, Go-to-Market |
| Tranche 2 (Growth) | Q3 2027 (Milestone-abhängig) | 350.000 € | Team-Scale, GPU-Cluster, Enterprise-Sales |
| **Gesamt** | | **500.000 €** | |

**Meilensteine für Tranche 2-Freigabe:**
- 10 zahlende Lizenzkunden (Team- oder Enterprise-Tier)
- Purple Compute Stufe 1 operational (lokales Modell in Self-Healing-Kette integriert)
- Sicherheits-Audit bestanden
- ARR (Annual Recurring Revenue) > 60.000 €

### 8.4 Plan-GuV (2026–2028)

| Position | 2026 | 2027 | 2028 |
|---|---|---|---|
| **Umsatz** | | | |
| Lizenzumsätze (Operator/Team) | 18.000 € | 96.000 € | 280.000 € |
| Enterprise / On-Premise | 0 € | 48.000 € | 192.000 € |
| Purple Compute Hardware-Marge | 0 € | 12.000 € | 45.000 € |
| Service / Consulting | 0 € | 18.000 € | 60.000 € |
| Education-Lizenzen | 4.800 € | 14.400 € | 28.800 € |
| **Gesamtumsatz** | **22.800 €** | **188.400 €** | **605.800 €** |
| | | | |
| **Aufwand** | | | |
| Personalaufwand | 84.000 € | 222.000 € | 280.000 € |
| AI-Provider-APIs | 12.000 € | 18.000 € | 22.000 € |
| Purple-Compute-Infrastruktur | 22.000 € | 90.000 € | 38.000 € |
| Cloud & Infrastruktur | 6.000 € | 12.000 € | 18.000 € |
| Marketing & Vertrieb | 8.000 € | 12.000 € | 18.000 € |
| Lizenz-Server, Distribution | 3.000 € | 5.000 € | 7.000 € |
| Audit, Compliance, IP | 18.000 € | 8.000 € | 10.000 € |
| Beratung / Steuer / Recht | 5.000 € | 6.000 € | 7.000 € |
| Sonstiges | 4.000 € | 5.000 € | 8.000 € |
| **Gesamtaufwand** | **162.000 €** | **378.000 €** | **408.000 €** |
| | | | |
| **EBIT** | **– 139.200 €** | **– 189.600 €** | **+ 197.800 €** |
| **Jahresergebnis (nach KöSt)** | **– 139.200 €** | **– 189.600 €** | **+ 158.240 €** |
| **Kumuliert** | – 139.200 € | – 328.800 € | – 170.560 € |

> _Hinweis: Die negativen Ergebnisse 2026–2027 sind vollständig durch die Investitionstranchen gedeckt. Break-Even auf Monatsbasis wird für Q3 2028 erwartet. Die Verluste resultieren nahezu ausschließlich aus Investitionen in Purple Compute (Hardware) und Engineering-Aufbau – beides aktivierbare Wirtschaftsgüter bzw. wertschöpfende Ausgaben._

### 8.5 Plan-Bilanz (Übersicht zum 31.12.2027)

| Aktiva | Betrag | Passiva | Betrag |
|---|---|---|---|
| Anlagevermögen | | Eigenkapital | |
| Purple Compute Hardware (netto) | 88.000 € | Stammkapital HES | 35.000 € |
| Immaterielle Wirtschaftsgüter (IP, Software) | 45.000 € | Verlustvortrag | – 328.800 € |
| Umlaufvermögen | | Investorenkapital (Tranche 1+2) | 500.000 € |
| Liquide Mittel | 280.000 € | Verbindlichkeiten | |
| Forderungen (offene Lizenzen) | 32.000 € | Verbindlichkeiten L+L | 18.000 € |
| Sonstiges UV | 8.000 € | Rückstellungen | 20.000 € |
| **Bilanzsumme** | **453.000 €** | **Bilanzsumme** | **453.000 €** |

> _Die vollständige, normengerechte Bilanz und GuV wird über **plan4you** erstellt und als Anlage beigefügt._

### 8.6 Verwendungsnachweis auf einen Blick

| Verwendungsschwerpunkt | Tranche 1 | Tranche 2 | Gesamt | % |
|---|---|---|---|---|
| Engineering & Entwicklung | 84.000 € | 180.000 € | 264.000 € | 53 % |
| Purple Compute (eigene KI-Infrastruktur) | 22.000 € | 90.000 € | 112.000 € | 22 % |
| Sales, Marketing, Go-to-Market | 8.000 € | 54.000 € | 62.000 € | 12 % |
| AI-Provider-APIs & Cloud | 18.000 € | 18.000 € | 36.000 € | 7 % |
| IP, Compliance, Audit, Recht | 18.000 € | 8.000 € | 26.000 € | 5 % |
| Reserve / Puffer | 0 € | 10.000 € | 10.000 € | 2 % |
| **Gesamt** | **150.000 €** | **360.000 €** | **510.000 €** | **100 %** |

_(Differenz auf 500 k€ wird durch frühzeitige Lizenzumsätze 2026 gedeckt)_

---

## 9. Risiken & SWOT

### Stärken
- Einzigartige Produktarchitektur: Self-Healing-AI-Team + MITRE-ATT&CK + eigene KI-Infrastruktur
- Bereits in v6.0 produktionsreif – kein reines Konzeptpaper
- Hybrid-Bedienung (Voice, CLI, Web) im DACH-Markt einmalig
- Klare Operator-Disziplin als Differenzierungsmerkmal
- DSGVO-konforme Souveränität durch Purple Compute

### Schwächen
- Hoher Kapitalbedarf in der Aufbauphase (Hardware-intensiv)
- Erklärungsbedarf bei konservativen Beschaffern
- Lizenz-Server und Telemetrie als neuer Angriffsvektor (wird extrem sauber gebaut)

### Chancen
- NIS2 / DORA erzeugen direkten Bedarf an Werkzeugen mit Audit-Trail
- AI-Act schafft Premium für nachvollziehbare, souveräne KI
- Fachkräftemangel begünstigt Tool-gestützte Anbieter
- Air-Gap-Nachfrage von Behörden und KRITIS wächst stark

### Risiken
- Plattform-Anbieter integrieren AI-Orchestrierung → Purple Compute als Differenzierung
- Regulatorische Sensibilität gegenüber offensiver AI → Operator-Approval-Default
- Veränderte AI-Provider-Konditionen → Multi-Provider + eigene KI als Absicherung
- Negative öffentliche Wahrnehmung → transparente Disziplin-Defaults, keine autonome Offensive

### 9.2 Risikomanagement

- **Multi-Provider-Architektur** reduziert Vendor-Lock-in auf Null (ab v8.0: vollständig Provider-unabhängig)
- **Externe Audits** der eigenen Plattform vor jedem Enterprise-Verkauf
- **Operator-Approval-Default** schützt vor Missbrauch und reputativen Schäden
- **Staged Funding** (Tranche 2 an Meilensteine geknüpft) reduziert Investitionsrisiko
- **Compliance-Vorprüfung** jedes Vertriebsfalls

---

## 10. Finanzierungsinstrumente & Förderungen

### Mögliche Förderquellen (Österreich)

| Förderstelle | Instrument | Potenzialbetrag |
|---|---|---|
| aws (Austria Wirtschaftsservice) | aws Gründerfonds / Seedfinancing | 50.000–200.000 € |
| FFG | Basisprogramm (F&E-Förderung) | 30.000–100.000 € |
| Land Salzburg | Wirtschaftsförderung, Digitalisierung | 10.000–50.000 € |
| EU Horizon Europe | Cybersecurity-Cluster (DeSSNet, ECSO) | 100.000–500.000 € |
| BMF / BMDW | KMU-Digital | 5.000–20.000 € |

### Investorenstruktur (Ziel)

- **Seed-Runde (150.000 €):** 1–2 Business Angels aus dem DACH-Cybersecurity-Umfeld, ergänzt durch aws-Förderung
- **Growth-Runde (350.000 €):** Venture Capital oder strategischer Investor (Security-Haus), kombiniert mit FFG-F&E-Förderung

---

## Anhang: Nächste Schritte

| Maßnahme | Verantwortlich | Deadline |
|---|---|---|
| Bilanz + GuV via plan4you finalisieren | HES-Management | 30.06.2026 |
| Pitch-Deck (Investor-Version) erstellen | Produktleitung | 15.06.2026 |
| aws Seedfinancing-Antrag einreichen | Beratung + Management | 31.07.2026 |
| Purple Compute Colocation-Gespräch | Tech-Lead | 30.06.2026 |
| Security-Audit beauftragen | Security-Verantwortliche | 31.08.2026 |
| Erste 10 Beta-Lizenznehmer gewinnen | Sales | 30.09.2026 |
| Markenanmeldung AT/DE | Rechtsberatung | 31.07.2026 |

---

*Purple Bruce / HES Marketing FlexCo · Salzburg 2026 · Businessplan v2.0 (Investitionsversion)*
*Vertraulich – nur für Investoren und Förderstellen*
