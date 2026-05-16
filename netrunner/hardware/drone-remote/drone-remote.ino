// ============================================================
//  drone-remote.ino
//  Purple Bruce Lucy — Wearable Drone Remote Controller
//  Platform : M5StickC Plus2 (ESP32)
//  Version  : 1.0.0
// ============================================================

#include <M5StickCPlus2.h>
#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>

// ─────────────────────────────────────────────────────────────
//  COMPILE-TIME DEFAULTS  (overridable at runtime via Serial)
// ─────────────────────────────────────────────────────────────
#define DEFAULT_BRIDGE_IP   "192.168.1.100"
#define BRIDGE_PORT         7778
#define WIFI_SSID           "PurpleBruce"
#define WIFI_PASS           "purplebruce"

// Loop timing
#define LOOP_HZ             30
#define LOOP_MS             (1000 / LOOP_HZ)

// IMU
#define IMU_DEAD_ZONE_DEG   5.0f
#define SHAKE_THRESHOLD_G   2.5f

// WebSocket reconnect
#define WS_RECONNECT_MS     5000

// Button hold time for emergency land
#define EMERG_HOLD_MS       2000

// Button A hold time for mode cycle vs. IP config entry
#define BTN_HOLD_CONFIG_MS  3000

// ─────────────────────────────────────────────────────────────
//  COLOUR PALETTE  (RGB565)
// ─────────────────────────────────────────────────────────────
#define COL_PURPLE    0x89B6   // #8B5CF6
#define COL_CYAN      0x1697   // #22D3EE
#define COL_GREEN     0x2264   // #22C55E
#define COL_RED       0xF800
#define COL_WHITE     0xFFFF
#define COL_BLACK     0x0000
#define COL_DARKGREY  0x3186
#define COL_YELLOW    0xFFE0
#define COL_ARASAKA   0xA800   // Arasaka deep red  #D00000
#define COL_GOLD      0xFEA0   // Arasaka gold      #FFD000

// ─────────────────────────────────────────────────────────────
//  MODE ENUM
// ─────────────────────────────────────────────────────────────
enum DroneMode : uint8_t {
    MODE_HOVER    = 0,
    MODE_IMU_CTRL = 1,
    MODE_STATUS   = 2,
    MODE_WIFI_SCAN = 3,
    MODE_COUNT    = 4
};

const char* MODE_NAMES[MODE_COUNT] = {
    "HOVER",
    "IMU CTRL",
    "STATUS",
    "WIFI SCAN"
};

// ─────────────────────────────────────────────────────────────
//  GLOBAL STATE
// ─────────────────────────────────────────────────────────────

// Runtime-configurable bridge IP (written to EEPROM-style preferences)
char bridgeIP[20] = DEFAULT_BRIDGE_IP;

// Current operating mode
DroneMode currentMode = MODE_HOVER;

// WebSocket
WebSocketsClient wsClient;
bool wsConnected     = false;
uint32_t wsLastTry   = 0;
bool wsNeedsConnect  = true;

// Telemetry from drone
struct DroneTelemetry {
    uint8_t  battery       = 0;
    float    altitude      = 0.0f;
    float    speed_h       = 0.0f;
    String   droneMode     = "UNKNOWN";
    bool     trackingLocked = false;
    float    faceConf      = 0.0f;   // face re-ID confidence 0.0-1.0
    uint32_t lastUpdate    = 0;
};
DroneTelemetry telem;

// IMU data
struct ImuData {
    float pitch = 0.0f;  // forward/back  (degrees)
    float roll  = 0.0f;  // left/right    (degrees)
    float ax    = 0.0f;  // accel X (g)
    float ay    = 0.0f;  // accel Y (g)
    float az    = 0.0f;  // accel Z (g)
};
ImuData imu;

// Armed state (only meaningful in IMU_CTRL mode)
bool armed = false;

// Emergency stop flag
bool emergencyTriggered = false;
uint32_t emergencyFlashUntil = 0;

// WiFi scan results
struct ScanEntry {
    String ssid;
    int32_t rssi;
    uint8_t encryption;
};
#define MAX_SCAN_RESULTS 8
ScanEntry scanResults[MAX_SCAN_RESULTS];
uint8_t   scanCount   = 0;
bool      scanInProgress = false;
uint32_t  scanStartedAt  = 0;

// Button tracking
uint32_t btnBPressedAt = 0;
bool     btnBHeld      = false;
bool     btnAPressedAt_ts = 0;
uint32_t btnAHoldStart = 0;
bool     btnAHeld      = false;

// Display dirty flag — full redraw on mode change
bool needsFullRedraw = true;
DroneMode lastDrawnMode = (DroneMode)255;

// Loop timing
uint32_t lastLoopMs = 0;

// Serial IP config buffer
String serialBuf = "";

// Server uptime (seconds, received from WS status messages)
uint32_t serverUptime = 0;
bool     serverConnected = false;

// ─────────────────────────────────────────────────────────────
//  FORWARD DECLARATIONS
// ─────────────────────────────────────────────────────────────
void connectWiFi();
void connectWS();
void wsEventHandler(WStype_t type, uint8_t* payload, size_t length);
void sendRC(int lr, int fb);
void sendCommand(const char* cmd);
void sendEmergencyLand();
void readIMU();
void handleButtons();
void processSerial();
void triggerEmergencyStop();
void startWifiScan();
void pollWifiScan();
void drawScreen();
void drawTopBar();
void drawHoverMode();
void drawImuCtrlMode();
void drawStatusMode();
void drawWifiScanMode();
void drawEmergencyOverlay();
String rssiToBar(int32_t rssi);
int   angleToRC(float deg);

// ─────────────────────────────────────────────────────────────
//  SETUP
// ─────────────────────────────────────────────────────────────
void setup() {
    // Init M5StickC Plus2
    auto cfg = M5.config();
    M5.begin(cfg);

    // Screen: landscape orientation, purple background
    M5.Lcd.setRotation(1);           // landscape: 240 wide × 135 tall
    M5.Lcd.fillScreen(COL_BLACK);
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setTextSize(1);

    // Splash — Arasaka Neural Mesh
    M5.Lcd.fillScreen(COL_BLACK);
    M5.Lcd.setTextColor(COL_ARASAKA, COL_BLACK);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("A R A S A K A", 120, 38, 2);
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.drawString("NEURAL MESH", 120, 60, 3);
    M5.Lcd.setTextColor(COL_GOLD, COL_BLACK);
    M5.Lcd.drawString("DRONE REMOTE  v2.0", 120, 92, 1);
    M5.Lcd.setTextColor(COL_DARKGREY, COL_BLACK);
    M5.Lcd.drawString("PURPLE BRUCE LUCY", 120, 110, 1);
    M5.Lcd.setTextDatum(TL_DATUM);

    Serial.begin(115200);
    Serial.println(F("[PB-REMOTE] Arasaka Neural Mesh — Drone Remote v2.0"));
    Serial.printf("[PB-REMOTE] Bridge target: ws://%s:%d\n", bridgeIP, BRIDGE_PORT);

    // IMU
    M5.Imu.init();

    delay(1200);

    // WiFi
    M5.Lcd.fillScreen(COL_BLACK);
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setCursor(4, 4);
    M5.Lcd.printf("Connecting WiFi...\n%s", WIFI_SSID);

    connectWiFi();

    // WebSocket setup (connection attempt in loop)
    wsClient.onEvent(wsEventHandler);
    wsClient.setReconnectInterval(WS_RECONNECT_MS);
    wsNeedsConnect = true;

    M5.Lcd.fillScreen(COL_BLACK);
    needsFullRedraw = true;
    lastLoopMs = millis();
}

// ─────────────────────────────────────────────────────────────
//  MAIN LOOP
// ─────────────────────────────────────────────────────────────
void loop() {
    uint32_t now = millis();
    if (now - lastLoopMs < LOOP_MS) return;
    lastLoopMs = now;

    M5.update();  // refresh button state

    // Serial config
    processSerial();

    // WiFi watchdog
    if (WiFi.status() != WL_CONNECTED) {
        wsConnected = false;
        connectWiFi();
    }

    // WebSocket connect / loop
    if (WiFi.status() == WL_CONNECTED) {
        if (wsNeedsConnect) {
            connectWS();
            wsNeedsConnect = false;
            wsLastTry = now;
        }
        wsClient.loop();
    }

    // IMU
    readIMU();

    // Shake → emergency stop
    if (!emergencyTriggered) {
        float mag = sqrtf(imu.ax * imu.ax + imu.ay * imu.ay + imu.az * imu.az);
        if (mag > SHAKE_THRESHOLD_G) {
            triggerEmergencyStop();
        }
    }

    // Buttons
    handleButtons();

    // IMU control send (only in IMU_CTRL + armed)
    if (currentMode == MODE_IMU_CTRL && armed && wsConnected) {
        int lr = angleToRC(imu.roll);
        int fb = angleToRC(-imu.pitch);  // pitch forward = negative IMU reading
        sendRC(lr, fb);
    }

    // WiFi scan polling
    if (currentMode == MODE_WIFI_SCAN && scanInProgress) {
        pollWifiScan();
    }

    // Draw screen (30Hz — always redraw for live data)
    drawScreen();
}

// ─────────────────────────────────────────────────────────────
//  WIFI
// ─────────────────────────────────────────────────────────────
void connectWiFi() {
    if (WiFi.status() == WL_CONNECTED) return;

    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);

    uint32_t start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 8000) {
        delay(200);
        M5.Lcd.print('.');
    }

    if (WiFi.status() == WL_CONNECTED) {
        Serial.printf("[WIFI] Connected. IP: %s\n", WiFi.localIP().toString().c_str());
    } else {
        Serial.println(F("[WIFI] Failed to connect."));
    }
}

// ─────────────────────────────────────────────────────────────
//  WEBSOCKET
// ─────────────────────────────────────────────────────────────
void connectWS() {
    Serial.printf("[WS] Connecting to ws://%s:%d\n", bridgeIP, BRIDGE_PORT);
    wsClient.begin(bridgeIP, BRIDGE_PORT, "/");
}

void wsEventHandler(WStype_t type, uint8_t* payload, size_t length) {
    switch (type) {
        case WStype_DISCONNECTED:
            wsConnected = false;
            serverConnected = false;
            Serial.println(F("[WS] Disconnected"));
            wsNeedsConnect = true;
            break;

        case WStype_CONNECTED:
            wsConnected = true;
            Serial.printf("[WS] Connected to %s\n", bridgeIP);
            // Announce ourselves
            wsClient.sendTXT("{\"type\":\"hello\",\"client\":\"drone-remote\",\"version\":\"1.0\"}");
            break;

        case WStype_TEXT: {
            // Parse incoming JSON
            JsonDocument doc;
            DeserializationError err = deserializeJson(doc, payload, length);
            if (err) break;

            const char* msgType = doc["type"] | "";

            if (strcmp(msgType, "telemetry") == 0) {
                JsonObject data = doc["data"];
                if (!data.isNull()) {
                    telem.battery        = data["battery"]         | telem.battery;
                    telem.altitude       = data["altitude"]        | telem.altitude;
                    telem.speed_h        = data["speed_h"]         | telem.speed_h;
                    telem.droneMode      = data["mode"]            | telem.droneMode.c_str();
                    telem.trackingLocked = data["tracking_locked"] | telem.trackingLocked;
                    telem.faceConf       = data["face_conf"]       | telem.faceConf;
                    telem.lastUpdate     = millis();
                }
            } else if (strcmp(msgType, "tracker_status") == 0) {
                telem.trackingLocked = doc["locked"]    | telem.trackingLocked;
                telem.faceConf       = doc["face_conf"] | telem.faceConf;
                telem.lastUpdate     = millis();
            } else if (strcmp(msgType, "status") == 0) {
                serverConnected = true;
                serverUptime    = doc["uptime"] | serverUptime;
            } else if (strcmp(msgType, "ack") == 0) {
                // Command acknowledged — no action needed
            }
            break;
        }

        case WStype_ERROR:
            Serial.println(F("[WS] Error"));
            wsConnected = false;
            break;

        default:
            break;
    }
}

// ─────────────────────────────────────────────────────────────
//  SEND HELPERS
// ─────────────────────────────────────────────────────────────
void sendRC(int lr, int fb) {
    if (!wsConnected) return;

    // Clamp
    lr = constrain(lr, -100, 100);
    fb = constrain(fb, -100, 100);

    // Suppress dead zone (already handled in angleToRC, double-check here)
    JsonDocument doc;
    doc["action"] = "command";
    doc["cmd"]    = "rc";
    JsonObject params = doc.createNestedObject("params");
    params["lr"] = lr;
    params["fb"] = fb;

    String out;
    serializeJson(doc, out);
    wsClient.sendTXT(out);
}

void sendCommand(const char* cmd) {
    if (!wsConnected) return;

    JsonDocument doc;
    doc["action"] = "command";
    doc["cmd"]    = cmd;

    String out;
    serializeJson(doc, out);
    wsClient.sendTXT(out);
    Serial.printf("[CMD] Sent: %s\n", cmd);
}

void sendEmergencyLand() {
    if (!wsConnected) return;

    JsonDocument doc;
    doc["action"] = "command";
    doc["cmd"]    = "emergency_land";
    doc["priority"] = "critical";

    String out;
    serializeJson(doc, out);
    wsClient.sendTXT(out);
    Serial.println(F("[CMD] EMERGENCY LAND SENT"));
}

// ─────────────────────────────────────────────────────────────
//  EMERGENCY STOP
// ─────────────────────────────────────────────────────────────
void triggerEmergencyStop() {
    armed = false;
    emergencyTriggered = true;
    emergencyFlashUntil = millis() + 3000;
    sendEmergencyLand();
    Serial.println(F("[EMERG] Emergency stop triggered!"));
    // Flash the screen red
    M5.Lcd.fillScreen(COL_RED);
    M5.Lcd.setTextColor(COL_WHITE, COL_RED);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("EMERGENCY LAND", 120, 60, 4);
    M5.Lcd.drawString("DISARMED", 120, 95, 2);
    M5.Lcd.setTextDatum(TL_DATUM);
    delay(800);
    emergencyTriggered = false;
    needsFullRedraw = true;
}

// ─────────────────────────────────────────────────────────────
//  IMU
// ─────────────────────────────────────────────────────────────
void readIMU() {
    float gx, gy, gz;
    M5.Imu.getGyroData(&gx, &gy, &gz);
    M5.Imu.getAccelData(&imu.ax, &imu.ay, &imu.az);

    // Use accelerometer to compute tilt angles (gravity-referenced)
    // Roll  = atan2(ay, az)  — side tilt
    // Pitch = atan2(-ax, sqrt(ay^2 + az^2))  — fore/aft tilt
    imu.roll  = atan2f(imu.ay, imu.az) * RAD_TO_DEG;
    imu.pitch = atan2f(-imu.ax, sqrtf(imu.ay * imu.ay + imu.az * imu.az)) * RAD_TO_DEG;
}

// Map angle (degrees) to RC value (-100 to 100) with dead zone
int angleToRC(float deg) {
    if (fabsf(deg) < IMU_DEAD_ZONE_DEG) return 0;

    // Full range assumed ±45 degrees → maps to ±100
    float clamped = constrain(deg, -45.0f, 45.0f);
    // Remove dead zone contribution
    float sign    = (clamped > 0) ? 1.0f : -1.0f;
    float adjusted = (fabsf(clamped) - IMU_DEAD_ZONE_DEG) * sign;
    float maxAdjusted = 45.0f - IMU_DEAD_ZONE_DEG;
    return (int)(adjusted / maxAdjusted * 100.0f);
}

// ─────────────────────────────────────────────────────────────
//  BUTTON HANDLING
// ─────────────────────────────────────────────────────────────
void handleButtons() {
    uint32_t now = millis();

    // ── Button B (top small button) ──────────────────────────
    if (M5.BtnB.wasPressed()) {
        btnBPressedAt = now;
        btnBHeld      = false;
    }

    if (M5.BtnB.isPressed() && !btnBHeld) {
        if (now - btnBPressedAt >= EMERG_HOLD_MS) {
            // 2-second hold = emergency land from any mode
            btnBHeld = true;
            triggerEmergencyStop();
        }
    }

    if (M5.BtnB.wasReleased() && !btnBHeld) {
        // Short press action
        if (currentMode == MODE_HOVER) {
            // ARM — send takeoff
            if (wsConnected) {
                armed = true;
                sendCommand("takeoff");
                Serial.println(F("[BTN B] Takeoff / Arm"));
            } else {
                Serial.println(F("[BTN B] Not connected — cannot arm"));
            }
        } else if (currentMode == MODE_IMU_CTRL) {
            // DISARM — send hover
            armed = false;
            sendCommand("hover");
            Serial.println(F("[BTN B] Disarmed / Hover"));
        }
        needsFullRedraw = true;
    }

    // ── Button A (big side button) ───────────────────────────
    if (M5.BtnA.wasPressed()) {
        btnAHoldStart = now;
        btnAHeld      = false;
    }

    if (M5.BtnA.isPressed() && !btnAHeld) {
        if (now - btnAHoldStart >= BTN_HOLD_CONFIG_MS) {
            // Long hold: enter serial IP config prompt
            btnAHeld = true;
            M5.Lcd.fillScreen(COL_DARKGREY);
            M5.Lcd.setTextColor(COL_CYAN, COL_DARKGREY);
            M5.Lcd.setTextDatum(MC_DATUM);
            M5.Lcd.drawString("SERIAL CONFIG", 120, 40, 2);
            M5.Lcd.drawString("Send: IP:x.x.x.x", 120, 65, 1);
            M5.Lcd.drawString("Current:", 120, 85, 1);
            M5.Lcd.drawString(bridgeIP, 120, 100, 2);
            M5.Lcd.setTextDatum(TL_DATUM);
            Serial.println(F("[CFG] Enter bridge IP: IP:x.x.x.x"));
            delay(2000);
            needsFullRedraw = true;
        }
    }

    if (M5.BtnA.wasReleased() && !btnAHeld) {
        // Short press: cycle mode
        uint8_t next = ((uint8_t)currentMode + 1) % MODE_COUNT;
        currentMode = (DroneMode)next;
        armed = false;  // disarm when switching mode for safety
        needsFullRedraw = true;
        Serial.printf("[BTN A] Mode → %s\n", MODE_NAMES[currentMode]);

        // Kick off WiFi scan when entering that mode
        if (currentMode == MODE_WIFI_SCAN) {
            startWifiScan();
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  SERIAL IP CONFIG
// ─────────────────────────────────────────────────────────────
void processSerial() {
    while (Serial.available()) {
        char c = (char)Serial.read();
        if (c == '\n' || c == '\r') {
            serialBuf.trim();
            if (serialBuf.startsWith("IP:")) {
                String newIP = serialBuf.substring(3);
                newIP.trim();
                if (newIP.length() > 6 && newIP.length() < 20) {
                    strncpy(bridgeIP, newIP.c_str(), sizeof(bridgeIP) - 1);
                    bridgeIP[sizeof(bridgeIP) - 1] = '\0';
                    Serial.printf("[CFG] Bridge IP set to: %s\n", bridgeIP);
                    // Force reconnect
                    wsClient.disconnect();
                    wsConnected    = false;
                    wsNeedsConnect = true;
                    needsFullRedraw = true;
                }
            }
            serialBuf = "";
        } else {
            serialBuf += c;
            if (serialBuf.length() > 32) serialBuf = "";  // overflow guard
        }
    }
}

// ─────────────────────────────────────────────────────────────
//  WIFI SCAN
// ─────────────────────────────────────────────────────────────
void startWifiScan() {
    scanCount       = 0;
    scanInProgress  = true;
    scanStartedAt   = millis();
    WiFi.scanNetworks(true /*async*/, true /*show hidden*/);
    Serial.println(F("[SCAN] WiFi scan started"));
}

void pollWifiScan() {
    int16_t n = WiFi.scanComplete();
    if (n == WIFI_SCAN_RUNNING) return;  // still scanning

    scanInProgress = false;
    if (n < 0) {
        Serial.println(F("[SCAN] Scan failed"));
        scanCount = 0;
        return;
    }

    scanCount = (uint8_t)min((int16_t)MAX_SCAN_RESULTS, n);
    for (uint8_t i = 0; i < scanCount; i++) {
        scanResults[i].ssid       = WiFi.SSID(i);
        scanResults[i].rssi       = WiFi.RSSI(i);
        scanResults[i].encryption = (uint8_t)WiFi.encryptionType(i);
    }
    WiFi.scanDelete();
    Serial.printf("[SCAN] Found %d networks\n", scanCount);
}

// ─────────────────────────────────────────────────────────────
//  SCREEN DRAWING
// ─────────────────────────────────────────────────────────────

// Top bar: 16px high, shows connection status + mode name
void drawTopBar() {
    // Background
    M5.Lcd.fillRect(0, 0, 240, 16, COL_DARKGREY);

    // Connection dot
    uint16_t dotColor = wsConnected ? COL_GREEN : COL_RED;
    M5.Lcd.fillCircle(8, 8, 5, dotColor);

    // IP or "NO WIFI"
    M5.Lcd.setTextColor(COL_WHITE, COL_DARKGREY);
    M5.Lcd.setTextSize(1);
    if (WiFi.status() == WL_CONNECTED) {
        M5.Lcd.setCursor(17, 4);
        M5.Lcd.print(bridgeIP);
    } else {
        M5.Lcd.setCursor(17, 4);
        M5.Lcd.setTextColor(COL_YELLOW, COL_DARKGREY);
        M5.Lcd.print("NO WIFI");
    }

    // Mode name (right-aligned area)
    M5.Lcd.setTextColor(COL_CYAN, COL_DARKGREY);
    M5.Lcd.setCursor(170, 4);
    M5.Lcd.print(MODE_NAMES[currentMode]);
}

void drawScreen() {
    bool modeChanged = (currentMode != lastDrawnMode);
    if (modeChanged) {
        M5.Lcd.fillScreen(COL_BLACK);
        lastDrawnMode = currentMode;
    }

    drawTopBar();

    // Emergency flash
    if (millis() < emergencyFlashUntil) {
        drawEmergencyOverlay();
        return;
    }

    switch (currentMode) {
        case MODE_HOVER:     drawHoverMode();    break;
        case MODE_IMU_CTRL:  drawImuCtrlMode();  break;
        case MODE_STATUS:    drawStatusMode();   break;
        case MODE_WIFI_SCAN: drawWifiScanMode(); break;
        default: break;
    }
}

// ── HOVER MODE ───────────────────────────────────────────────
void drawHoverMode() {
    // Title
    M5.Lcd.setTextColor(COL_PURPLE, COL_BLACK);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("HOVER", 120, 35, 4);

    // Battery bar
    uint8_t bat = telem.battery;
    uint16_t batColor = bat > 50 ? COL_GREEN : (bat > 20 ? COL_YELLOW : COL_RED);
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setTextDatum(TL_DATUM);
    M5.Lcd.setCursor(10, 60);
    M5.Lcd.printf("BAT: ");
    M5.Lcd.setTextColor(batColor, COL_BLACK);
    M5.Lcd.printf("%3d%%", bat);

    // Battery bar graphic
    M5.Lcd.drawRect(80, 60, 52, 10, COL_WHITE);
    int barW = (int)(bat / 100.0f * 50);
    M5.Lcd.fillRect(81, 61, barW, 8, batColor);
    if (barW < 50) M5.Lcd.fillRect(81 + barW, 61, 50 - barW, 8, COL_DARKGREY);

    // Altitude
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setCursor(10, 78);
    M5.Lcd.printf("ALT: %5.1f m", telem.altitude);

    // Drone mode string
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setCursor(10, 93);
    M5.Lcd.printf("DRONE: %-8s", telem.droneMode.substring(0, 8).c_str());

    // Footer hint
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setTextDatum(BC_DATUM);
    if (wsConnected) {
        M5.Lcd.drawString("[ B = ARM / TAKEOFF ]", 120, 133, 1);
    } else {
        M5.Lcd.setTextColor(COL_RED, COL_BLACK);
        M5.Lcd.drawString("DISCONNECTED — CHECK BRIDGE", 120, 133, 1);
    }
    M5.Lcd.setTextDatum(TL_DATUM);
}

// ── IMU CTRL MODE ────────────────────────────────────────────
void drawImuCtrlMode() {
    // Armed indicator
    uint16_t armColor = armed ? COL_GREEN : COL_RED;
    const char* armStr = armed ? "  ARMED  " : "DISARMED ";
    M5.Lcd.setTextColor(COL_BLACK, armColor);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString(armStr, 120, 30, 2);
    M5.Lcd.setTextDatum(TL_DATUM);

    // Tilt angles
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setCursor(10, 48);
    M5.Lcd.printf("PITCH: %+7.1f deg", imu.pitch);
    M5.Lcd.setCursor(10, 63);
    M5.Lcd.printf("ROLL : %+7.1f deg", imu.roll);

    // RC output values
    int lr = angleToRC(imu.roll);
    int fb = angleToRC(-imu.pitch);
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setCursor(10, 80);
    M5.Lcd.printf("L/R: %+4d  F/B: %+4d", lr, fb);

    // Neural lock + face confidence
    M5.Lcd.setCursor(10, 95);
    if (telem.trackingLocked) {
        M5.Lcd.setTextColor(COL_ARASAKA, COL_BLACK);
        M5.Lcd.print("NEURAL LOCK  ");
        // Face confidence bar (only when face re-ID is active)
        if (telem.faceConf > 0.01f) {
            uint8_t pct = (uint8_t)(telem.faceConf * 100.0f);
            M5.Lcd.setTextColor(COL_GOLD, COL_BLACK);
            M5.Lcd.printf("FACE:%3d%%", pct);
            // Mini bar below
            int barW = (int)(telem.faceConf * 60.0f);
            M5.Lcd.fillRect(10, 107, barW, 4, COL_GOLD);
            M5.Lcd.fillRect(10 + barW, 107, 60 - barW, 4, COL_DARKGREY);
        }
    } else {
        M5.Lcd.setTextColor(COL_DARKGREY, COL_BLACK);
        M5.Lcd.print("LOCK: ---           ");
        M5.Lcd.fillRect(10, 107, 60, 4, COL_DARKGREY);
    }

    // Footer
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setTextDatum(BC_DATUM);
    M5.Lcd.drawString("[ B=DISARM | hold B=EMERG ]", 120, 133, 1);
    M5.Lcd.setTextDatum(TL_DATUM);
}

// ── STATUS MODE ──────────────────────────────────────────────
void drawStatusMode() {
    M5.Lcd.setTextColor(COL_PURPLE, COL_BLACK);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("SERVER STATUS", 120, 28, 2);
    M5.Lcd.setTextDatum(TL_DATUM);

    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setCursor(10, 44);

    // WS connection
    if (wsConnected) {
        M5.Lcd.setTextColor(COL_GREEN, COL_BLACK);
        M5.Lcd.print("WS: CONNECTED   ");
    } else {
        M5.Lcd.setTextColor(COL_RED, COL_BLACK);
        M5.Lcd.print("WS: DISCONNECTED");
    }

    // Bridge IP
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setCursor(10, 58);
    M5.Lcd.printf("IP : %s", bridgeIP);

    // Uptime
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setCursor(10, 72);
    uint32_t h = serverUptime / 3600;
    uint32_t m = (serverUptime % 3600) / 60;
    uint32_t s = serverUptime % 60;
    M5.Lcd.printf("UP : %02lu:%02lu:%02lu", (unsigned long)h, (unsigned long)m, (unsigned long)s);

    // Telem freshness
    M5.Lcd.setCursor(10, 86);
    if (telem.lastUpdate > 0) {
        uint32_t age = (millis() - telem.lastUpdate) / 1000;
        if (age < 5) {
            M5.Lcd.setTextColor(COL_GREEN, COL_BLACK);
        } else {
            M5.Lcd.setTextColor(COL_YELLOW, COL_BLACK);
        }
        M5.Lcd.printf("TELEM: %lus ago   ", (unsigned long)age);
    } else {
        M5.Lcd.setTextColor(COL_DARKGREY, COL_BLACK);
        M5.Lcd.print("TELEM: no data  ");
    }

    // Drone battery summary
    M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
    M5.Lcd.setCursor(10, 100);
    M5.Lcd.printf("DRONE BAT: %3d%%  ALT: %.1fm", telem.battery, telem.altitude);

    // Footer
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setTextDatum(BC_DATUM);
    M5.Lcd.drawString("[ A = next mode ]", 120, 133, 1);
    M5.Lcd.setTextDatum(TL_DATUM);
}

// ── WIFI SCAN MODE ───────────────────────────────────────────
void drawWifiScanMode() {
    M5.Lcd.setTextColor(COL_PURPLE, COL_BLACK);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("WIFI SCAN", 120, 28, 2);
    M5.Lcd.setTextDatum(TL_DATUM);

    if (scanInProgress) {
        M5.Lcd.setTextColor(COL_YELLOW, COL_BLACK);
        M5.Lcd.setTextDatum(MC_DATUM);
        M5.Lcd.drawString("Scanning...", 120, 80, 2);
        M5.Lcd.setTextDatum(TL_DATUM);
        return;
    }

    if (scanCount == 0) {
        M5.Lcd.setTextColor(COL_DARKGREY, COL_BLACK);
        M5.Lcd.setTextDatum(MC_DATUM);
        M5.Lcd.drawString("No networks found", 120, 80, 1);
        M5.Lcd.setTextDatum(TL_DATUM);
    } else {
        M5.Lcd.setTextColor(COL_WHITE, COL_BLACK);
        int y = 42;
        for (uint8_t i = 0; i < scanCount && y < 128; i++) {
            // RSSI bar
            String bar = rssiToBar(scanResults[i].rssi);

            // Colour by signal strength
            uint16_t col = COL_GREEN;
            if (scanResults[i].rssi < -70) col = COL_YELLOW;
            if (scanResults[i].rssi < -85) col = COL_RED;

            M5.Lcd.setTextColor(col, COL_BLACK);
            M5.Lcd.setCursor(10, y);

            String ssid = scanResults[i].ssid;
            if (ssid.length() > 14) ssid = ssid.substring(0, 13) + "~";
            M5.Lcd.printf("%-14s %s", ssid.c_str(), bar.c_str());

            // Lock icon if encrypted
            if (scanResults[i].encryption != WIFI_AUTH_OPEN) {
                M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
                M5.Lcd.print(" *");
            }

            y += 13;
        }
    }

    // Re-scan hint
    M5.Lcd.setTextColor(COL_CYAN, COL_BLACK);
    M5.Lcd.setTextDatum(BC_DATUM);
    M5.Lcd.drawString("[ A = rescan/next mode ]", 120, 133, 1);
    M5.Lcd.setTextDatum(TL_DATUM);
}

// ── EMERGENCY OVERLAY ────────────────────────────────────────
void drawEmergencyOverlay() {
    // Alternating flash between black and red
    bool flashOn = ((millis() / 250) % 2 == 0);
    uint16_t bg = flashOn ? COL_RED : COL_BLACK;
    M5.Lcd.fillRect(0, 17, 240, 118, bg);
    M5.Lcd.setTextColor(COL_WHITE, bg);
    M5.Lcd.setTextDatum(MC_DATUM);
    M5.Lcd.drawString("EMERGENCY LAND", 120, 65, 3);
    M5.Lcd.drawString("DISARMED", 120, 100, 2);
    M5.Lcd.setTextDatum(TL_DATUM);
}

// ─────────────────────────────────────────────────────────────
//  HELPERS
// ─────────────────────────────────────────────────────────────
String rssiToBar(int32_t rssi) {
    // 4-block bar: rssi > -55 = 4, > -65 = 3, > -75 = 2, > -85 = 1, else 0
    int bars;
    if      (rssi > -55) bars = 4;
    else if (rssi > -65) bars = 3;
    else if (rssi > -75) bars = 2;
    else if (rssi > -85) bars = 1;
    else                 bars = 0;

    String out = "[";
    for (int i = 0; i < 4; i++) {
        out += (i < bars) ? '#' : '-';
    }
    out += "]";
    return out;
}
