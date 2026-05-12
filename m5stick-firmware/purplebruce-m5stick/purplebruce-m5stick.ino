/*
 * PURPLE BRUCE · M5Stick Firmware v2.0
 * Chaos Magic Servitor — Hardware Node
 *
 * Modes (press [A] to cycle, long-hold [A] to stay):
 *   SIGIL     Animated chaos sigil display
 *   STATS     Battery · uptime · chip · heap
 *   CHAOS     IMU-driven glitch noise art
 *   INVOKE    Scrolling invocation phrases
 *   WIFI SCAN Passive WiFi network scanner
 *   DEAUTH    Deauth frame injection (authorized testing)
 *   BEACON    Chaos SSID beacon spam
 *   BLE SCAN  BLE device scanner
 *   IR BLAST  IR TV-power blaster (9 brands + all)
 *   AI CHAT   Grok · Venice · Gemini API (configure pb_config.h)
 *
 * Hardware: M5StickC Plus (primary) / M5StickC (define STICK_C)
 * Controls: [A]=cycle mode  [B]=action  shake=CHAOS
 *
 * SECURITY NOTICE: WiFi injection features are for authorized
 * penetration testing only. Obey all applicable laws.
 */

// Uncomment for original M5StickC (80×160 screen):
// #define STICK_C
#ifdef STICK_C
  #include <M5StickC.h>
#else
  #include <M5StickCPlus.h>
#endif

#include "pb_display.h"
#include "pb_wifi.h"
#include "pb_ble.h"
#include "pb_ir.h"
#include "pb_ai.h"

// ── Mode table ──────────────────────────────────────────────────
enum Mode {
    M_SIGIL = 0,
    M_STATS,
    M_CHAOS,
    M_INVOKE,
    M_WIFI_SCAN,
    M_DEAUTH,
    M_BEACON,
    M_BLE,
    M_IR,
    M_AI,
    M_COUNT
};

static const char* MODE_NAMES[] = {
    "SIGIL","STATS","CHAOS","INVOKE",
    "WIFI SCAN","DEAUTH","BEACON","BLE","IR","AI"
};

// ── Global state ────────────────────────────────────────────────
static Mode     mode       = M_SIGIL;
static uint32_t frame      = 0;
static uint32_t modeEnter  = 0;
static bool     redraw     = true;
static uint8_t  brightIdx  = 2;

static const uint8_t BRIGHT_LVLS[] = { 7, 8, 10, 12 };

// ── Chaos RNG (xorshift32) ──────────────────────────────────────
static uint32_t rngSt;
static inline uint32_t chaos() {
    rngSt ^= rngSt << 13;
    rngSt ^= rngSt >> 17;
    rngSt ^= rngSt << 5;
    return rngSt;
}

// ── Sigil art frames ────────────────────────────────────────────
static const char* SIGIL_ART[8] = {
    "  /|\\  ",
    " -[*]- ",
    "  \\|/  ",
    " (|O|) ",
    "  -*-  ",
    " /\\|/\\ ",
    " \\[#]/ ",
    "  |Y|  "
};

// ── Invocation phrases ──────────────────────────────────────────
static const char* INVOCATIONS[] = {
    "IN NOMINE LUCIS",
    "CHAOS SERVITOR",
    "PURPLE TEAM ACTIVE",
    "SIGIL MANIFEST",
    "ENTROPY RISING",
    "NULL POINTER VOID",
    "DAEMON AWAKE",
    "HACK THE SIGIL",
    "AS ABOVE SO BELOW",
    "BREAK THE LOOP",
};
#define N_INVOKE 10

// ── Mode entry — manage radio state transitions ─────────────────
static void enterMode(Mode m) {
    Mode prev = mode;
    mode      = m;
    modeEnter = millis();
    redraw    = true;
    M5.Lcd.fillScreen(PB_BG);

    // ── Beacon: stop when leaving ──────────────────────────────
    if (prev == M_BEACON && m != M_BEACON) {
        beacon_active = false;
    }

    switch (m) {
        case M_WIFI_SCAN:
            pbWifiInitInject();
            pbWifiScanStart();
            break;
        case M_DEAUTH:
            pbWifiInitInject();
            if (ap_count == 0) pbWifiScanStart();
            break;
        case M_BEACON:
            pbWifiInitInject();
            break;
        case M_BLE:
            pbBleInit();
            break;
        case M_IR:
            pbIrInit();
            break;
        case M_AI:
            // WiFi will be established on first query
            ai_done = false;
            break;
        default:
            break;
    }
}

// ── Button B short-press action (mode-specific) ─────────────────
static void onBtnB_short() {
    switch (mode) {
        case M_SIGIL:
        case M_STATS:
        case M_CHAOS:
        case M_INVOKE:
            // brightness cycle
            brightIdx = (brightIdx + 1) % 4;
            M5.Axp.ScreenBreath(BRIGHT_LVLS[brightIdx]);
            break;

        case M_WIFI_SCAN:
            if (!scan_running) pbWifiScanStart();
            break;

        case M_DEAUTH:
            pbDeauthFire(ap_target % max(ap_count, 1));
            break;

        case M_BEACON:
            beacon_active = !beacon_active;
            redraw = true;
            break;

        case M_BLE:
            if (!ble_scanning) pbBleScan(4);
            redraw = true;
            break;

        case M_IR:
            pbIrFire();
            break;

        case M_AI:
            if (!ai_querying) {
                ai_prompt_idx = (ai_prompt_idx + 1) % N_AI_PROMPTS;
                redraw = true;
            }
            break;
    }
}

// ── Button B long-press action (mode-specific secondary) ────────
static void onBtnB_long() {
    switch (mode) {
        case M_SIGIL:
        case M_STATS:
        case M_CHAOS:
        case M_INVOKE:
            // same as short: extra brightness cycle
            brightIdx = (brightIdx + 1) % 4;
            M5.Axp.ScreenBreath(BRIGHT_LVLS[brightIdx]);
            break;

        case M_WIFI_SCAN:
            // scroll AP list
            if (ap_count > 0) {
                ap_scroll = (ap_scroll + 1) % ap_count;
                redraw = true;
            }
            break;

        case M_DEAUTH:
            // cycle target
            if (ap_count > 0) {
                ap_target = (ap_target + 1) % ap_count;
                redraw = true;
            }
            break;

        case M_BEACON:
            // increment channel
            beacon_channel = (beacon_channel % 13) + 1;
            redraw = true;
            break;

        case M_BLE:
            // scroll BLE list
            if (ble_count > 0) {
                ble_scroll = (ble_scroll + 1) % ble_count;
                redraw = true;
            }
            break;

        case M_IR:
            // next brand
            ir_idx = (ir_idx + 1) % N_IR;
            redraw = true;
            break;

        case M_AI:
            // cycle provider
            if (!ai_querying) {
                ai_provider = (ai_provider + 1) % 3;
                ai_done     = false;
                redraw      = true;
            }
            break;
    }
}

// ── Button B query (separate from regular [B] action) ──────────
static void onAiQuery() {
    if (!ai_querying) pbAiQuery();
}

// ── Draw mode content ───────────────────────────────────────────
static void drawSigil() {
    drawHeader(" SIGIL    ", PB_PURPLE);
    uint16_t bord = (frame % 20 < 10) ? PB_VIOLET : PB_MAGENTA;
    M5.Lcd.drawRect(2, 22, SCR_W - 4, SCR_H - 24, bord);
    M5.Lcd.drawRect(4, 24, SCR_W - 8, SCR_H - 28, PB_DIM);

    M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
    M5.Lcd.setTextSize(3);
    int sigilW = 7 * 18;
    M5.Lcd.setCursor((SCR_W - sigilW) / 2, 50);
    M5.Lcd.print(SIGIL_ART[(frame / 8) % 8]);

    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(6, 26);         M5.Lcd.print("*");
    M5.Lcd.setCursor(SCR_W-14, 26);  M5.Lcd.print("*");
    M5.Lcd.setCursor(6, SCR_H-16);   M5.Lcd.print("*");
    M5.Lcd.setCursor(SCR_W-14, SCR_H-16); M5.Lcd.print("*");

    drawFooter("[A]next mode [B]brightness");
}

static void drawStats() {
    drawHeader(" STATS    ", PB_TEAL);
    float batV = M5.Axp.GetBatVoltage();
    float batI = M5.Axp.GetBatCurrent();
    uint32_t upS = millis() / 1000;
    int pct = pbBatPct();

    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(8, 26);
    M5.Lcd.printf("UPTIME   %02lu:%02lu:%02lu",
                  (unsigned long)(upS/3600),
                  (unsigned long)((upS%3600)/60),
                  (unsigned long)(upS%60));

    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(8, 38);  M5.Lcd.printf("BAT V    %.2f V", batV);
    M5.Lcd.setCursor(8, 50);  M5.Lcd.printf("BAT I    %+.1f mA", batI);

    M5.Lcd.drawRect(8, 63, 104, 12, PB_VIOLET);
    M5.Lcd.fillRect(9, 64, pct, 10, (pct > 30) ? PB_VIOLET : PB_RED);
    M5.Lcd.setTextColor(PB_WHITE, PB_BG);
    M5.Lcd.setCursor(118, 66);  M5.Lcd.printf("%3d%%", pct);

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(8, 82);
    M5.Lcd.printf("CHIP   %08lX",
                  (unsigned long)(ESP.getEfuseMac() & 0xFFFFFFFFUL));
    M5.Lcd.setCursor(8, 94);
    M5.Lcd.printf("HEAP   %luK free",
                  (unsigned long)(ESP.getFreeHeap() / 1024));
    M5.Lcd.setCursor(8, 106);
    M5.Lcd.print("FW     purplebruce m5 v2.0");

    drawFooter("[A]next mode [B]brightness");
}

static const uint16_t CHAOS_POOL[] = {
    PB_PURPLE, PB_VIOLET, PB_MAGENTA, PB_BG, PB_BG, PB_BG, PB_BG
};

static void drawChaos() {
    drawHeader(" CHAOS    ", PB_MAGENTA);
    int cx = 4, cy = 23, cw = SCR_W - 8, ch = SCR_H - 27;
    for (int i = 0; i < 500; i++) {
        M5.Lcd.drawPixel(
            (int)(chaos() % (uint32_t)cw) + cx,
            (int)(chaos() % (uint32_t)ch) + cy,
            CHAOS_POOL[chaos() % 7]);
    }
    if ((chaos() % 15) == 0)
        M5.Lcd.drawFastHLine(cx, (int)(chaos()%(uint32_t)ch)+cy, cw, PB_MAGENTA);
    drawFooter("[A]next mode [B]brightness  shake=CHAOS");
}

static void drawInvoke() {
    drawHeader(" INVOKE   ", PB_GOLD);
    int idx = (int)((millis() - modeEnter) / 1400UL) % N_INVOKE;
    uint16_t tc = ((frame % 20) < 18) ? PB_GOLD : PB_MAGENTA;

    M5.Lcd.setTextSize(2);
    M5.Lcd.setTextColor(tc, PB_BG);
    const char* line = INVOCATIONS[idx];
    int len = (int)strlen(line) * 12;
    M5.Lcd.setCursor((SCR_W - len) / 2, 58);
    M5.Lcd.print(line);

    M5.Lcd.drawFastHLine(10, 50, SCR_W - 20, PB_VIOLET);
    M5.Lcd.drawFastHLine(10, 80, SCR_W - 20, PB_VIOLET);

    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    for (int i = 0; i < N_INVOKE; i++) {
        M5.Lcd.setCursor(85 + i * 7, 92);
        M5.Lcd.print(i == idx ? 'o' : '.');
    }
    drawFooter("[A]next mode [B]brightness");
}

// ── Boot animation ──────────────────────────────────────────────
static void bootAnim() {
    M5.Lcd.fillScreen(PB_BLACK);
    for (int y = 0; y <= SCR_H; y += 2) {
        M5.Lcd.drawFastHLine(0, y, SCR_W, PB_PURPLE);
        delay(5);
    }
    delay(100);
    M5.Lcd.fillScreen(PB_BG);

    M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
    M5.Lcd.setTextSize(2);
    M5.Lcd.setCursor(16, 8);
    M5.Lcd.print("PURPLE BRUCE");

    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setTextSize(1);
    M5.Lcd.setCursor(46, 30);
    M5.Lcd.print("M5STICK EDITION  v2.0");

    M5.Lcd.drawFastHLine(8, 42, SCR_W - 16, PB_PURPLE);

    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(16, 50); M5.Lcd.print("CHAOS MAGIC SERVITOR");
    M5.Lcd.setCursor(16, 61); M5.Lcd.print("IR  BLE  WIFI  AI");
    M5.Lcd.setCursor(16, 72); M5.Lcd.print("GROK · VENICE · GEMINI");

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(16, 86); M5.Lcd.print("[A] CYCLE MODES");
    M5.Lcd.setCursor(16, 96); M5.Lcd.print("[B] MODE ACTION");

    M5.Lcd.drawFastHLine(8, 108, SCR_W - 16, PB_PURPLE);

    M5.Lcd.setTextColor(PB_GOLD, PB_BG);
    M5.Lcd.setCursor(8, 117);
    M5.Lcd.printf("BAT:%.2fV  INITIALIZING...", M5.Axp.GetBatVoltage());

    for (int i = 0; i < 3; i++) {
        delay(90);
        M5.Lcd.setTextColor(PB_BG, PB_BG);
        M5.Lcd.setCursor(16, 8); M5.Lcd.print("PURPLE BRUCE");
        delay(55);
        M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
        M5.Lcd.setCursor(16, 8); M5.Lcd.print("PURPLE BRUCE");
        delay(100);
    }
}

// ── Button state machines ────────────────────────────────────────
// [A] short = cycle mode | [A] long (800ms) = no-op (future use)
// [B] short = mode action | [B] long (800ms) = secondary action

enum BtnState { BS_IDLE, BS_DOWN, BS_LONG };
static BtnState aState = BS_IDLE, bState = BS_IDLE;
static uint32_t aDown  = 0,       bDown  = 0;
static bool     aLongFired = false, bLongFired = false;

static void updateButtons() {
    bool aPressed = M5.BtnA.isPressed();
    bool bPressed = M5.BtnB.isPressed();
    uint32_t now  = millis();

    // ── Button A ──────────────────────────────────────────────────
    switch (aState) {
        case BS_IDLE:
            if (aPressed) { aState = BS_DOWN; aDown = now; aLongFired = false; }
            break;
        case BS_DOWN:
            if (!aPressed) {
                // short press
                if (!aLongFired) {
                    // in AI mode, short press queries; elsewhere cycles mode
                    if (mode == M_AI) {
                        onAiQuery();
                    } else {
                        enterMode((Mode)((mode + 1) % M_COUNT));
                    }
                }
                aState = BS_IDLE;
            } else if (now - aDown > 800 && !aLongFired) {
                // long press = always cycle mode
                aLongFired = true;
                enterMode((Mode)((mode + 1) % M_COUNT));
                aState = BS_LONG;
            }
            break;
        case BS_LONG:
            if (!aPressed) aState = BS_IDLE;
            break;
    }

    // ── Button B ──────────────────────────────────────────────────
    switch (bState) {
        case BS_IDLE:
            if (bPressed) { bState = BS_DOWN; bDown = now; bLongFired = false; }
            break;
        case BS_DOWN:
            if (!bPressed) {
                if (!bLongFired) onBtnB_short();
                bState = BS_IDLE;
            } else if (now - bDown > 800 && !bLongFired) {
                bLongFired = true;
                onBtnB_long();
                bState = BS_LONG;
            }
            break;
        case BS_LONG:
            if (!bPressed) bState = BS_IDLE;
            break;
    }
}

// ── Setup ───────────────────────────────────────────────────────
void setup() {
    M5.begin();
    M5.Lcd.setRotation(3);
    M5.IMU.Init();
    M5.Axp.ScreenBreath(BRIGHT_LVLS[brightIdx]);

    rngSt = (uint32_t)(ESP.getCycleCount() ^
             (uint32_t)(ESP.getEfuseMac() & 0xFFFFFFFFUL));
    if (rngSt == 0) rngSt = 0xDEADBEEFUL;

    bootAnim();
    delay(1800);

    M5.Lcd.fillScreen(PB_BG);
    enterMode(M_SIGIL);
}

// ── Loop ────────────────────────────────────────────────────────
void loop() {
    M5.update();
    frame++;

    updateButtons();

    // Background tasks
    pbWifiScanCheck();    // async WiFi scan completion
    pbBeaconTick();       // beacon frame injection
    pbIrBlastTick();      // TV-B-Gone blast-all progress

    // IMU shake → CHAOS (threshold ~2.4 g squared)
    float ax, ay, az;
    M5.IMU.getAccelData(&ax, &ay, &az);
    if ((ax*ax + ay*ay + az*az) > 6.0f && mode != M_CHAOS) {
        enterMode(M_CHAOS);
    }

    // Refresh only what needs it
    bool needsFullRedraw = redraw;
    redraw = false;

    switch (mode) {
        case M_SIGIL:
            drawSigil();
            break;
        case M_STATS:
            if (needsFullRedraw) M5.Lcd.fillScreen(PB_BG);
            drawStats();
            break;
        case M_CHAOS:
            drawChaos();
            break;
        case M_INVOKE:
            if (needsFullRedraw) M5.Lcd.fillScreen(PB_BG);
            drawInvoke();
            break;
        case M_WIFI_SCAN:
            drawWifiScan(needsFullRedraw, frame);
            break;
        case M_DEAUTH:
            drawDeauth(needsFullRedraw);
            break;
        case M_BEACON:
            if (needsFullRedraw || (frame % 20 == 0))
                drawBeacon(needsFullRedraw);
            break;
        case M_BLE:
            drawBLE(needsFullRedraw);
            break;
        case M_IR:
            drawIR(needsFullRedraw);
            break;
        case M_AI:
            drawAI(needsFullRedraw, frame);
            break;
        default: break;
    }

    delay(50);  // ~20 FPS
}
