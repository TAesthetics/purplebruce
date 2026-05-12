/*
 * pb_ir.h — Purple Bruce M5Stick IR Blaster
 *
 * Sends IR remote codes via the M5StickC Plus built-in
 * IR LED on GPIO 9. Supports NEC, Sony SIRC, RC5 protocols.
 *
 * TV-B-Gone style: cycles through brands to blast all power codes.
 * Use only on your own equipment or with permission.
 */

#pragma once
#include <IRremoteESP8266.h>
#include <IRsend.h>
#include "pb_display.h"

#define IR_TX_PIN 9   // M5StickC / M5StickC Plus IR LED

// ── IR code table ───────────────────────────────────────────────
struct IREntry {
    const char* brand;
    uint8_t     proto;   // 0=NEC32, 1=SONY12, 2=RC5
    uint32_t    code;
};

// 0 = NEC 32-bit,  1 = Sony 12-bit,  2 = RC5 13-bit
static const IREntry IR_CODES[] = {
    { "SAMSUNG",   0, 0xE0E040BFUL },
    { "LG",        0, 0x20DF10EFUL },
    { "VIZIO",     0, 0xE1E0F00FUL },
    { "TCL",       0, 0x5EA1C03FUL },
    { "TOSHIBA",   0, 0x02FD48B7UL },
    { "HISENSE",   0, 0x40040100UL },
    { "SHARP",     0, 0xF728B649UL },
    { "SONY",      1, 0x00000A90UL },  // Sony 12-bit SIRC
    { "PHILIPS",   2, 0x0000080CUL },  // RC5 13-bit
    { "ALL->OFF",  0, 0x00000000UL },  // meta: blast all
};
#define N_IR  (int)(sizeof(IR_CODES) / sizeof(IR_CODES[0]))

// ── State ───────────────────────────────────────────────────────
static int     ir_idx      = 0;
static int     ir_sent     = 0;
static bool    ir_inited   = false;
static bool    ir_blasting = false;   // "ALL->OFF" in progress
static int     ir_blast_i  = 0;

static IRsend* irsend_ptr  = nullptr;

// ── Init ─────────────────────────────────────────────────────────
inline void pbIrInit() {
    if (!ir_inited) {
        static IRsend _ir(IR_TX_PIN);
        irsend_ptr = &_ir;
        irsend_ptr->begin();
        ir_inited = true;
    }
}

// ── Send one code ────────────────────────────────────────────────
inline void pbIrSendOne(const IREntry& e) {
    switch (e.proto) {
        case 0: irsend_ptr->sendNEC(e.code, 32);      break;
        case 1: irsend_ptr->sendSony(e.code, 12, 3);  break;
        case 2: irsend_ptr->sendRC5(e.code, 13);       break;
    }
    delay(40);
}

// ── Fire selected brand or blast all ────────────────────────────
inline void pbIrFire() {
    if (!irsend_ptr) return;
    const IREntry& e = IR_CODES[ir_idx];
    if (e.code == 0) {
        // "ALL->OFF" — blast every code
        ir_blasting = true;
        ir_blast_i  = 0;
    } else {
        pbIrSendOne(e);
        ir_sent++;
    }
}

// ── Blast-all tick (call from loop while ir_blasting) ───────────
inline void pbIrBlastTick() {
    if (!ir_blasting) return;
    if (ir_blast_i < N_IR - 1) {  // skip last entry (the meta one)
        pbIrSendOne(IR_CODES[ir_blast_i]);
        ir_blast_i++;
        ir_sent++;
    } else {
        ir_blasting = false;
    }
}

// ── Display ─────────────────────────────────────────────────────
inline void drawIR(bool redraw) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);
    drawHeader(" IR BLAST ", PB_VIOLET);

    const IREntry& e = IR_CODES[ir_idx % N_IR];
    bool isAll = (e.code == 0);

    // brand box
    M5.Lcd.fillRect(8, 28, SCR_W - 16, 28, PB_PURPLE);
    M5.Lcd.drawRect(7, 27, SCR_W - 14, 30, PB_MAGENTA);
    M5.Lcd.setTextColor(PB_WHITE, PB_PURPLE);
    M5.Lcd.setTextSize(2);
    int bw = strlen(e.brand) * 12;
    M5.Lcd.setCursor((SCR_W - bw) / 2, 35);
    M5.Lcd.print(e.brand);

    M5.Lcd.setTextSize(1);
    // protocol line
    const char* proto_str = (e.proto == 0) ? "NEC-32" :
                            (e.proto == 1) ? "SONY-12" : "RC5-13";
    if (!isAll) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(8, 62);
        M5.Lcd.printf("PROTO  %-8s CODE  0x%08lX", proto_str, (unsigned long)e.code);
    } else {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(8, 62);
        M5.Lcd.print("BLAST ALL BRANDS IN SEQUENCE");
    }

    // status
    if (ir_blasting) {
        M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
        M5.Lcd.setCursor(8, 76);
        M5.Lcd.printf("BLASTING... %d/%d", ir_blast_i, N_IR - 1);
    } else {
        M5.Lcd.setTextColor(PB_CYAN, PB_BG);
        M5.Lcd.setCursor(8, 76);
        M5.Lcd.printf("SENT: %d", ir_sent);
    }

    // index dots
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(8, 90);
    for (int i = 0; i < N_IR; i++) {
        M5.Lcd.print(i == (ir_idx % N_IR) ? 'o' : '.');
    }

    drawFooter("[A]next mode [B]fire [B-hold]next brand");
}
