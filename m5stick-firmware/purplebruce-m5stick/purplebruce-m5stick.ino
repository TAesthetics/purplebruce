/*
 * PURPLE BRUCE · M5Stick Firmware v1.0
 * Chaos Magic Servitor — Hardware Node
 *
 * Target  : M5StickC Plus (primary)
 *           Uncomment STICK_C below for original M5StickC
 * Features: 4 display modes · IMU shake → CHAOS · No WiFi · No BT
 * Controls: [A] = cycle modes | [B] = step brightness
 * USB-C   : CP2104 serial bridge — no antenna required
 */

// Uncomment for original M5StickC (80×160 screen, smaller):
// #define STICK_C

#ifdef STICK_C
  #include <M5StickC.h>
  #define SCR_W 160
  #define SCR_H  80
#else
  #include <M5StickCPlus.h>
  #define SCR_W 240
  #define SCR_H 135
#endif

// ── Color Palette (RGB565) ──────────────────────────────────────
#define PB_BG      0x1003   // near-black deep purple
#define PB_PURPLE  0x780F   // medium purple
#define PB_VIOLET  0x915C   // bright violet
#define PB_MAGENTA 0xF81F   // hot magenta
#define PB_CYAN    0x07FF   // cyan
#define PB_WHITE   0xFFFF   // white
#define PB_GOLD    0xFEA0   // gold/amber
#define PB_DIM     0x3084   // dim gray-purple
#define PB_BLACK   0x0000   // black
#define PB_TEAL    0x0455   // dark teal (stats header)

// ── Display modes ──────────────────────────────────────────────
enum Mode { SIGIL = 0, STATS, CHAOS, INVOKE, MODE_COUNT };

// ── State ──────────────────────────────────────────────────────
Mode     mode      = SIGIL;
uint32_t frame     = 0;
uint32_t modeEnter = 0;
bool     redraw    = true;
uint8_t  brightIdx = 2;

static const uint8_t BRIGHT_LEVELS[] = { 7, 8, 10, 12 };

// ── Chaos RNG (xorshift32, seeded from hardware) ───────────────
uint32_t rngSt;
inline uint32_t chaos() {
    rngSt ^= rngSt << 13;
    rngSt ^= rngSt >> 17;
    rngSt ^= rngSt << 5;
    return rngSt;
}

// ── Battery % from AXP192 voltage ──────────────────────────────
int batPct() {
    float v = M5.Axp.GetBatVoltage();
    return constrain((int)((v - 3.3f) / 0.9f * 100.0f), 0, 100);
}

// ── Common header strip ────────────────────────────────────────
void drawHeader(const char* title, uint16_t accent) {
    M5.Lcd.fillRect(0, 0, SCR_W, 20, accent);
    M5.Lcd.setTextColor(PB_BLACK, accent);
    M5.Lcd.setTextSize(2);
    M5.Lcd.setCursor(4, 2);
    M5.Lcd.print(title);

    int pct = batPct();
    uint16_t bc = (pct > 20) ? PB_BLACK : 0xF800;
    M5.Lcd.setTextColor(bc, accent);
    M5.Lcd.setTextSize(1);
    M5.Lcd.setCursor(SCR_W - 50, 6);
    M5.Lcd.printf("BAT%3d%%", pct);
}

// ── SIGIL mode ─────────────────────────────────────────────────
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

void drawSigil() {
    if (redraw) { M5.Lcd.fillScreen(PB_BG); redraw = false; }
    drawHeader(" SIGIL    ", PB_PURPLE);

    uint16_t bord = (frame % 20 < 10) ? PB_VIOLET : PB_MAGENTA;
    M5.Lcd.drawRect(2, 22, SCR_W - 4, SCR_H - 24, bord);
    M5.Lcd.drawRect(4, 24, SCR_W - 8, SCR_H - 28, PB_DIM);

    // animated sigil glyph (cycles every 8 frames)
    M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
    M5.Lcd.setTextSize(3);
    int sigilW = 7 * 18;  // 7 chars × 18px at size 3
    M5.Lcd.setCursor((SCR_W - sigilW) / 2, 50);
    M5.Lcd.print(SIGIL_ART[(frame / 8) % 8]);

    // corner rune marks
    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(6,         26); M5.Lcd.print("*");
    M5.Lcd.setCursor(SCR_W-14, 26); M5.Lcd.print("*");
    M5.Lcd.setCursor(6,  SCR_H-16); M5.Lcd.print("*");
    M5.Lcd.setCursor(SCR_W-14, SCR_H-16); M5.Lcd.print("*");

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(54, SCR_H - 12);
    M5.Lcd.print("[A] next  [B] dim");
}

// ── STATS mode ─────────────────────────────────────────────────
void drawStats() {
    if (redraw) { M5.Lcd.fillScreen(PB_BG); redraw = false; }
    drawHeader(" STATS    ", PB_TEAL);

    float batV = M5.Axp.GetBatVoltage();
    float batI = M5.Axp.GetBatCurrent();
    uint32_t upS = millis() / 1000;
    int pct = batPct();

    M5.Lcd.setTextSize(1);

    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(8, 26);
    M5.Lcd.printf("UPTIME   %02lu:%02lu:%02lu",
                  (unsigned long)(upS / 3600),
                  (unsigned long)((upS % 3600) / 60),
                  (unsigned long)(upS % 60));

    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(8, 38);
    M5.Lcd.printf("BAT V    %.2f V", batV);
    M5.Lcd.setCursor(8, 50);
    M5.Lcd.printf("BAT I    %+.1f mA", batI);

    // battery bar
    M5.Lcd.drawRect(8, 63, 104, 12, PB_VIOLET);
    M5.Lcd.fillRect(9, 64, pct, 10, (pct > 30) ? PB_VIOLET : PB_MAGENTA);
    M5.Lcd.setTextColor(PB_WHITE, PB_BG);
    M5.Lcd.setCursor(118, 66);
    M5.Lcd.printf("%3d%%", pct);

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(8, 82);
    M5.Lcd.printf("CHIP   %08lX",
                  (unsigned long)(ESP.getEfuseMac() & 0xFFFFFFFFUL));
    M5.Lcd.setCursor(8, 94);
    M5.Lcd.printf("HEAP   %luK free",
                  (unsigned long)(ESP.getFreeHeap() / 1024));
    M5.Lcd.setCursor(8, 106);
    M5.Lcd.print("FW     purplebruce m5 v1.0");

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(54, SCR_H - 12);
    M5.Lcd.print("[A] next  [B] dim");
}

// ── CHAOS mode ─────────────────────────────────────────────────
static const uint16_t CHAOS_POOL[] = {
    PB_PURPLE, PB_VIOLET, PB_MAGENTA,
    PB_BG, PB_BG, PB_BG, PB_BG
};

void drawChaos() {
    drawHeader(" CHAOS    ", PB_MAGENTA);

    int cx = 4, cy = 23, cw = SCR_W - 8, ch = SCR_H - 27;

    for (int i = 0; i < 500; i++) {
        int x = (int)(chaos() % (uint32_t)cw) + cx;
        int y = (int)(chaos() % (uint32_t)ch) + cy;
        M5.Lcd.drawPixel(x, y, CHAOS_POOL[chaos() % 7]);
    }
    // occasional scanline flash
    if ((chaos() % 15) == 0) {
        int y = (int)(chaos() % (uint32_t)ch) + cy;
        M5.Lcd.drawFastHLine(cx, y, cw, PB_MAGENTA);
    }

    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(54, SCR_H - 12);
    M5.Lcd.print("[A] next  [B] dim");
}

// ── INVOKE mode ────────────────────────────────────────────────
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

void drawInvoke() {
    if (redraw) { M5.Lcd.fillScreen(PB_BG); redraw = false; }
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

    // dot progress indicator
    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    for (int i = 0; i < N_INVOKE; i++) {
        M5.Lcd.setCursor(85 + i * 7, 92);
        M5.Lcd.print(i == idx ? "o" : ".");
    }

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(54, SCR_H - 12);
    M5.Lcd.print("[A] next  [B] dim");
}

// ── Boot animation ─────────────────────────────────────────────
void bootAnim() {
    M5.Lcd.fillScreen(PB_BLACK);

    // purple scanline sweep
    for (int y = 0; y <= SCR_H; y += 2) {
        M5.Lcd.drawFastHLine(0, y, SCR_W, PB_PURPLE);
        delay(5);
    }
    delay(120);
    M5.Lcd.fillScreen(PB_BG);

    // title
    M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
    M5.Lcd.setTextSize(2);
    M5.Lcd.setCursor(16, 8);
    M5.Lcd.print("PURPLE BRUCE");

    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setTextSize(1);
    M5.Lcd.setCursor(46, 30);
    M5.Lcd.print("M5STICK EDITION  v1.0");

    M5.Lcd.drawFastHLine(8, 42, SCR_W - 16, PB_PURPLE);

    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(16, 50); M5.Lcd.print("CHAOS MAGIC SERVITOR");
    M5.Lcd.setCursor(16, 61); M5.Lcd.print("HARDWARE NODE ACTIVE");
    M5.Lcd.setCursor(16, 72); M5.Lcd.print("NO ANTENNAS NEEDED");

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(16, 86); M5.Lcd.print("[A] CYCLE MODES");
    M5.Lcd.setCursor(16, 96); M5.Lcd.print("[B] BRIGHTNESS");

    M5.Lcd.drawFastHLine(8, 108, SCR_W - 16, PB_PURPLE);

    M5.Lcd.setTextColor(PB_GOLD, PB_BG);
    M5.Lcd.setCursor(8, 117);
    M5.Lcd.printf("BAT:%.2fV  INITIALIZING...", M5.Axp.GetBatVoltage());

    // logo flicker effect
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

// ── Setup ──────────────────────────────────────────────────────
void setup() {
    M5.begin();
    M5.Lcd.setRotation(3);
    M5.IMU.Init();
    M5.Axp.ScreenBreath(BRIGHT_LEVELS[brightIdx]);

    // seed RNG from hardware sources
    rngSt = (uint32_t)(ESP.getCycleCount() ^ (uint32_t)(ESP.getEfuseMac() & 0xFFFFFFFFUL));
    if (rngSt == 0) rngSt = 0xDEADBEEFUL;

    bootAnim();
    delay(2000);

    M5.Lcd.fillScreen(PB_BG);
    mode      = SIGIL;
    modeEnter = millis();
    redraw    = true;
}

// ── Loop ───────────────────────────────────────────────────────
void loop() {
    M5.update();
    frame++;

    // [A] → next mode
    if (M5.BtnA.wasPressed()) {
        mode      = (Mode)((mode + 1) % MODE_COUNT);
        modeEnter = millis();
        redraw    = true;
        M5.Lcd.fillScreen(PB_BG);
    }

    // [B] → step brightness
    if (M5.BtnB.wasPressed()) {
        brightIdx = (brightIdx + 1) % 4;
        M5.Axp.ScreenBreath(BRIGHT_LEVELS[brightIdx]);
    }

    // IMU shake detection → CHAOS mode (threshold ~2.4 g²)
    float ax, ay, az;
    M5.IMU.getAccelData(&ax, &ay, &az);
    if ((ax*ax + ay*ay + az*az) > 6.0f && mode != CHAOS) {
        mode      = CHAOS;
        modeEnter = millis();
        redraw    = true;
    }

    switch (mode) {
        case SIGIL:  drawSigil();  break;
        case STATS:  drawStats();  break;
        case CHAOS:  drawChaos();  break;
        case INVOKE: drawInvoke(); break;
        default: break;
    }

    delay(50);  // ~20 FPS
}
