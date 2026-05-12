# Purple Bruce · M5Stick Firmware

```
  ⛧  CHAOS MAGIC SERVITOR  ·  HARDWARE NODE  ·  ESP32  ⛧
```

Standalone ESP32 firmware for the **M5StickC Plus** (also works on M5StickC).  
No WiFi. No Bluetooth. No antenna required.  
Pure local display: animated sigils, device stats, chaos noise, invocation scroll.

---

## Compatible Hardware

| Device | Screen | Notes |
|--------|--------|-------|
| **M5StickC Plus** *(primary)* | 1.14″ 135×240 TFT | Default target |
| M5StickC *(original)* | 0.96″ 80×160 TFT | Add `#define STICK_C` |

Both use the CP2104 USB-to-UART bridge on USB-C — no drivers needed on Linux/Android.

---

## Display Modes

Press **[A]** to cycle. **Shake** the device to jump to CHAOS.

| Mode | Description |
|------|-------------|
| **SIGIL** | Animated ASCII chaos sigil · pulsing border · corner marks |
| **STATS** | Battery voltage/current, uptime, heap, chip ID |
| **CHAOS** | Random pixel noise · scanline flashes · glitch art |
| **INVOKE** | Scrolling invocation phrases · glitch text effect |

**[B]** steps through 4 brightness levels.

---

## Folder Structure

```
m5stick-firmware/
├── purplebruce-m5stick/
│   └── purplebruce-m5stick.ino   # Arduino sketch (single file)
├── platformio.ini                 # PlatformIO config (alternative to Arduino IDE)
├── flash.sh                       # CLI flash script for Termux / Linux
├── serve.js                       # Termux localhost web flash server (non-root)
├── web-flash/
│   ├── index.html                 # ESP Web Tools UI (open in Chrome)
│   └── manifest.json              # Firmware manifest for web flash
└── README.md
```

After compiling, put the merged binary at:
```
web-flash/purplebruce-m5stick.merged.bin
```

---

## Method 1 — Web Flash via Termux Localhost (Non-Root Android)

> **Best for non-rooted Android phones.** Uses Chrome's built-in Web Serial API.  
> No root. No drivers. No adb.

### Step 1 — Install Node.js in Termux

```bash
pkg update -y
pkg install -y nodejs git
```

### Step 2 — Clone the repo (if you haven't already)

```bash
git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce/m5stick-firmware
```

### Step 3 — Compile the firmware (pick one sub-method)

**Sub-method A: Arduino CLI in Termux**

```bash
# Install Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
  | BINDIR=$PREFIX/bin sh

# Add ESP32 board package
arduino-cli core update-index
arduino-cli core install esp32:esp32

# Install M5StickCPlus library
arduino-cli lib install "M5StickCPlus"

# Compile and export merged binary
arduino-cli compile \
  --fqbn esp32:esp32:m5stick-c-plus \
  --output-dir ./build \
  --export-binaries \
  ./purplebruce-m5stick

# Copy merged binary to web-flash/
cp build/purplebruce-m5stick.ino.merged.bin \
   web-flash/purplebruce-m5stick.merged.bin
```

> For original M5StickC: use `--fqbn esp32:esp32:m5stick-c` and library `M5StickC`.

**Sub-method B: PlatformIO CLI in Termux**

```bash
pip install platformio
pio run -e m5stick-c-plus

# Copy merged binary
cp .pio/build/m5stick-c-plus/firmware.bin \
   web-flash/purplebruce-m5stick.merged.bin
```

**Sub-method C: Arduino IDE on a desktop (easiest)**

1. Install Arduino IDE 2.x
2. Board manager → search `esp32` → install Espressif ESP32
3. Library manager → install `M5StickCPlus`
4. Open `purplebruce-m5stick/purplebruce-m5stick.ino`
5. Board → **M5Stick-C-Plus**
6. Sketch → Export Compiled Binary
7. Copy the `.merged.bin` to `web-flash/purplebruce-m5stick.merged.bin`
8. Transfer to phone (AirDrop / USB / cloud)

### Step 4 — Start the localhost flash server

In Termux:

```bash
cd ~/purplebruce/m5stick-firmware
node serve.js
```

Output:
```
  ⛧  PURPLE BRUCE — M5Stick Flash Server  ⛧
  → Open in Chrome:  http://localhost:8080
  → Connect M5Stick via USB-C (OTG adapter if needed)
  → Click INSTALL in the browser
```

### Step 5 — Flash via Chrome

1. Connect M5Stick to Android via **USB-C OTG adapter**
2. Open **Chrome** (not Firefox, not Samsung Internet) on the Android device
3. Go to `http://localhost:8080`
4. Click **⛧ INSTALL PURPLE BRUCE**
5. Chrome shows a USB/Serial permission dialog → select **CP2104 USB to UART**
6. Wait ~30 seconds for flash to complete
7. M5Stick reboots automatically into Purple Bruce

> Chrome 89+ on Android supports Web Serial API. It works without root.

---

## Method 2 — Direct Flash with esptool (Linux / Desktop Termux)

> Use this if your system can see `/dev/ttyUSB0` directly.  
> On non-root Android Termux, `/dev/ttyUSB*` usually requires root.

```bash
# Install esptool
pip install esptool

# Flash (requires compiled .merged.bin first — see Method 1 Step 3)
esptool.py \
  --port /dev/ttyUSB0 \
  --baud 1500000 \
  --chip esp32 \
  --before default_reset \
  --after  hard_reset \
  write_flash -z \
  --flash_mode dio \
  --flash_freq 80m \
  --flash_size 4MB \
  0x0 web-flash/purplebruce-m5stick.merged.bin
```

Or use the helper script which auto-detects the port:

```bash
chmod +x flash.sh
./flash.sh              # auto-detect
./flash.sh /dev/ttyUSB0 # explicit port
```

---

## Method 3 — PlatformIO (Compile + Flash in One Command)

```bash
pip install platformio

# Flash M5StickC Plus
pio run -e m5stick-c-plus -t upload --upload-port /dev/ttyUSB0

# Flash original M5StickC
pio run -e m5stick-c -t upload --upload-port /dev/ttyUSB0

# Serial monitor
pio device monitor --baud 115200
```

---

## Termux Quick-Reference

```bash
# Full Termux setup from scratch (non-root web-flash method)
pkg update -y
pkg install -y nodejs git python curl

git clone https://github.com/TAesthetics/purplebruce.git ~/purplebruce
cd ~/purplebruce/m5stick-firmware

# Option A: compile with Arduino CLI
curl -fsSL https://raw.githubusercontent.com/arduino/arduino-cli/master/install.sh \
  | BINDIR=$PREFIX/bin sh
arduino-cli core update-index && arduino-cli core install esp32:esp32
arduino-cli lib install "M5StickCPlus"
arduino-cli compile --fqbn esp32:esp32:m5stick-c-plus \
  --output-dir ./build --export-binaries ./purplebruce-m5stick
cp build/*.merged.bin web-flash/purplebruce-m5stick.merged.bin

# Start flash server
node serve.js
# → open http://localhost:8080 in Chrome, connect M5Stick via OTG, click Install
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Chrome says "No compatible device found" | Put M5Stick in download mode: hold power + press reset |
| `/dev/ttyUSB0` permission denied (Linux) | `sudo usermod -aG dialout $USER` then re-login |
| `arduino-cli: command not found` | Re-run the curl install with `BINDIR=$PREFIX/bin` |
| Screen stays black after flash | Check `#define STICK_C` — wrong library for your hardware |
| Web Serial not available | Must use Chrome/Chromium 89+, not Firefox/Safari |
| `esptool: A fatal error occurred` | Hold the side button (GPIO 0) during `write_flash` to force bootloader |

---

## Put M5Stick in Bootloader Mode (Manual)

If auto-reset doesn't work:

1. Hold the **side button (B)** on the M5Stick
2. While holding, plug in USB-C
3. Release after 2 seconds
4. Run the flash command — device is now in download mode

---

*Purple Bruce Lucy v6.0 · M5Stick Edition · Chaos Magic Servitor · Eastern Orthodox · Wicca · Hacker*
