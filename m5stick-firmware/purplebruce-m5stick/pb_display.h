/*
 * pb_display.h — Purple Bruce M5Stick Display Helpers
 */

#pragma once
#include <stdarg.h>

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
#define PB_TEAL    0x0455   // dark teal
#define PB_RED     0xF800   // red
#define PB_GREEN   0x07E0   // green
#define PB_ORANGE  0xFD20   // orange

// ── Screen dimensions (landscape rotation 3) ───────────────────
#ifdef STICK_C
  #define SCR_W 160
  #define SCR_H  80
#else
  #define SCR_W 240
  #define SCR_H 135
#endif

#define SCR_CONTENT_Y  22            // content starts below header
#define SCR_CONTENT_H  (SCR_H - 24) // usable height below header
#define SCR_FOOTER_Y   (SCR_H - 11) // bottom hint line

// ── Battery percentage from AXP192 ─────────────────────────────
inline int pbBatPct() {
    float v = M5.Axp.GetBatVoltage();
    return constrain((int)((v - 3.3f) / 0.9f * 100.0f), 0, 100);
}

// ── Common header strip ─────────────────────────────────────────
inline void drawHeader(const char* title, uint16_t accent,
                        const char* hint = nullptr) {
    M5.Lcd.fillRect(0, 0, SCR_W, 20, accent);
    M5.Lcd.setTextColor(PB_BLACK, accent);
    M5.Lcd.setTextSize(2);
    M5.Lcd.setCursor(4, 2);
    M5.Lcd.print(title);

    int pct = pbBatPct();
    M5.Lcd.setTextColor((pct > 20) ? PB_BLACK : PB_RED, accent);
    M5.Lcd.setTextSize(1);
    M5.Lcd.setCursor(SCR_W - 50, 6);
    M5.Lcd.printf("BAT%3d%%", pct);
}

// ── Footer hint line ────────────────────────────────────────────
inline void drawFooter(const char* hint) {
    M5.Lcd.setTextSize(1);
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(4, SCR_FOOTER_Y);
    // clear and rewrite
    M5.Lcd.fillRect(0, SCR_FOOTER_Y - 1, SCR_W, 11, PB_BG);
    M5.Lcd.print(hint);
}

// ── Word-wrap print within a bounding box ──────────────────────
// Returns number of lines printed.
inline int drawWrapped(int x, int y, int maxW, int lineH,
                        uint16_t col, uint8_t sz, const char* text) {
    M5.Lcd.setTextColor(col, PB_BG);
    M5.Lcd.setTextSize(sz);
    int charW  = 6 * sz;
    int charsPerLine = maxW / charW;
    if (charsPerLine < 1) charsPerLine = 1;

    int len = strlen(text);
    int cursor = 0;
    int line   = 0;
    int curY   = y;

    while (cursor < len && curY < SCR_H - lineH) {
        // find break point
        int end = cursor + charsPerLine;
        if (end >= len) { end = len; }
        else {
            // try to break at space
            int sp = end;
            while (sp > cursor && text[sp] != ' ') sp--;
            if (sp > cursor) end = sp;
        }
        char buf[64] = {};
        int n = end - cursor;
        if (n > 63) n = 63;
        memcpy(buf, text + cursor, n);
        buf[n] = '\0';
        M5.Lcd.setCursor(x, curY);
        M5.Lcd.print(buf);
        cursor = end;
        if (cursor < len && text[cursor] == ' ') cursor++;
        curY += lineH;
        line++;
    }
    return line;
}

// ── Progress/spinner ───────────────────────────────────────────
static const char SPINNER[] = { '-', '\\', '|', '/' };
inline char spinChar(uint32_t frame) { return SPINNER[frame % 4]; }
