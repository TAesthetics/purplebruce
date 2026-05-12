# Purple Bruce · M5Stick Firmware v2.0

```
  ⛧  CHAOS MAGIC SERVITOR  ·  HARDWARE NODE  ·  ESP32  ⛧
  IR · BLE · WiFi Scan · Deauth · Beacon · AI Chat
  Grok · Venice · Gemini
```

Standalone ESP32 firmware for the **M5StickC Plus** (also M5StickC).  
10 display/action modes. AI API integration with all three purplebruce providers.

---

## Hardware

| Device | Screen | Notes |
|--------|--------|-------|
| **M5StickC Plus** *(primary)* | 1.14″ 135×240 TFT | Default build target |
| M5StickC *(original)* | 0.96″ 80×160 TFT | Add `#define STICK_C` in .ino |

Built-in: CP2104 USB-UART · IR LED (GPIO9) · IMU (MPU6886) · AXP192 PMU · WiFi/BT antenna (PCB trace)

---

## Mode Reference

| Mode | [B] action | [B-hold] action |
|------|-----------|-----------------|
| **SIGIL** | Brightness cycle | Brightness cycle |
| **STATS** | Brightness cycle | Brightness cycle |
| **CHAOS** | Brightness cycle | Brightness cycle |
| **INVOKE** | Brightness cycle | Brightness cycle |
| **WIFI SCAN** | Rescan | Scroll list |
| **DEAUTH** | Fire deauth burst | Next target |
| **BEACON** | Toggle broadcast | Channel +1 |
| **BLE SCAN** | Rescan (4s) | Scroll list |
| **IR BLAST** | Fire current brand | Next brand |
| **AI CHAT** | Next prompt | Next provider (Grok→Venice→Gemini) |

**[A]** = always cycle to next mode  
**Shake** = jump to CHAOS mode  
**AI CHAT [A]** = short press fires the query (not mode cycle)

---

## AI Provider Configuration

Edit **`purplebruce-m5stick/pb_config.h`** before compiling:

```cpp
// WiFi (required for AI Chat)
#define PB_WIFI_SSID   "YOUR_WIFI_SSID"
#define PB_WIFI_PASS   "YOUR_WIFI_PASSWORD"

// Grok — https://console.x.ai/
#define GROK_API_KEY   "xai-XXXX"

// Venice — https://venice.ai/settings/api
#define VENICE_API_KEY "XXXX"

// Gemini — https://aistudio.google.com/app/apikey
#define GEMINI_API_KEY "XXXX"

// Default provider: 0=Grok  1=Venice  2=Gemini
#define PB_DEFAULT_AI  0
```

These values match `config/ai-providers.json` in the main purplebruce repo.

---

## File Structure

```
m5stick-firmware/
├── purplebruce-m5stick/
│   ├── purplebruce-m5stick.ino  # Main sketch — 10 modes
│   ├── pb_config.h              # ← EDIT THIS: WiFi + API keys
│   ├── pb_display.h             # Color palette, header, word-wrap
│   ├── pb_wifi.h                # WiFi scan · deauth · beacon spam
│   ├── pb_ble.h                 # BLE device scanner
│   ├── pb_ir.h                  # IR blaster (9 brands + blast-all)
│   └── pb_ai.h                  # AI chat (Grok · Venice · Gemini)
├── platformio.ini               # PlatformIO build config
├── flash.sh                     # CLI flash script
├── serve.js                     # Termux localhost web flash server
├── web-flash/
│   ├── index.html               # ESP Web Tools flashing UI
│   └── manifest.json            # Firmware manifest
└── README.md
```

---

## Install Dependencies

### Arduino IDE libraries (install via Library Manager):

1. **M5StickCPlus** — by M5Stack (or M5StickC for original)
2. **IRremoteESP8266** — by crankyoldgit
3. **ArduinoJson** — by Benoît Blanchon (v7.x)

### PlatformIO — all deps auto-installed from `platformio.ini`.

---

## Method 1 — Web Flash via Termux Localhost (Non-Root Android)

Best for non-rooted phones. Uses Chrome's Web Serial API — no root, no drivers.

### Step 1 — Install Termux deps

```bash
pkg update -y && pkg install -y nodejs git curl python
```

### Step 2 — Clone & enter firmware folder

```bash
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce/m5stick-firmware
```

### Step 3 — Edit pb_config.h with your API keys

```bash
# Open in nano or any editor
nano purplebruce-m5stick/pb_config.h
# Fill in PB_WIFI_SSID, PB_WIFI_PASS, GROK_API_KEY, VENICE_API_KEY, GEMINI_API_KEY
```

### Step 4 — Compile with Arduino CLI

```bash
# Install Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
  | BINDIR=$PREFIX/bin sh

# Add ESP32 boards + libraries
arduino-cli core update-index
arduino-cli core install esp32:esp32
arduino-cli lib install "M5StickCPlus" "IRremoteESP8266" "ArduinoJson"

# Compile
arduino-cli compile \
  --fqbn esp32:esp32:m5stick-c-plus \
  --output-dir ./build --export-binaries \
  ./purplebruce-m5stick

# Copy merged binary
cp build/*.merged.bin web-flash/purplebruce-m5stick.merged.bin
```

### Step 5 — Start flash server

```bash
node serve.js
```

### Step 6 — Flash in Chrome

1. Open `http://localhost:8080` in **Chrome** on your Android device
2. Connect M5Stick via **USB-C OTG adapter**
3. Click **⛧ INSTALL PURPLE BRUCE**
4. Grant USB/Serial permission → wait ~30s → done

---

## Method 2 — PlatformIO CLI

```bash
pip install platformio

# Edit pb_config.h first, then:
pio run -e m5stick-c-plus -t upload --upload-port /dev/ttyUSB0

# Monitor
pio device monitor --baud 115200
```

---

## Method 3 — esptool direct (Linux / rooted)

```bash
pip install esptool
# (compile first via Arduino CLI or IDE)

esptool.py \
  --port /dev/ttyUSB0 --baud 1500000 \
  --chip esp32 --before default_reset --after hard_reset \
  write_flash -z --flash_mode dio --flash_freq 80m --flash_size 4MB \
  0x0 web-flash/purplebruce-m5stick.merged.bin
```

Or: `./flash.sh` (auto-detects port and available tool).

---

## Termux Quick-Reference (copy-paste)

```bash
pkg update -y && pkg install -y nodejs git curl python

git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce/m5stick-firmware

# Edit API keys
nano purplebruce-m5stick/pb_config.h

# Install Arduino CLI + toolchain
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
  | BINDIR=$PREFIX/bin sh
arduino-cli core update-index && arduino-cli core install esp32:esp32
arduino-cli lib install "M5StickCPlus" "IRremoteESP8266" "ArduinoJson"

# Compile
arduino-cli compile \
  --fqbn esp32:esp32:m5stick-c-plus \
  --output-dir ./build --export-binaries ./purplebruce-m5stick
cp build/*.merged.bin web-flash/purplebruce-m5stick.merged.bin

# Serve and flash
node serve.js
# → open http://localhost:8080 in Chrome
# → connect M5Stick via OTG → click Install
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Compile error: `M5StickCPlus.h not found` | Install M5StickCPlus library in Arduino IDE |
| Compile error: `IRsend` undefined | Install IRremoteESP8266 library |
| Compile error: `ArduinoJson` not found | Install ArduinoJson v7 |
| AI Chat: HTTP 401 | Check API key in `pb_config.h` |
| AI Chat: WiFi timeout | Check SSID/password in `pb_config.h` |
| Deauth: no effect | Some APs use 802.11w (PMF) — deauth frames ignored |
| IR: no response | Try [B-hold] to switch brand; face LED at target |
| Screen black after flash | Wrong `#define STICK_C` setting for your hardware |
| BLE scan empty | Move closer to devices; some use Apple random MACs |
| Web Serial unavailable | Must use Chrome 89+ (not Firefox/Safari) |

---

## Legal Notice

WiFi injection features (deauth, beacon) affect wireless networks.  
Use **only on equipment you own or have explicit written authorization to test**.  
Unauthorized use violates the CFAA, Computer Misuse Act, and similar laws.  
IR blast: point at your own TVs or test in authorized environments.

---

*Purple Bruce Lucy v6.0 · M5Stick Edition v2.0 · Chaos Magic Servitor · Eastern Orthodox · Wicca · Hacker*
