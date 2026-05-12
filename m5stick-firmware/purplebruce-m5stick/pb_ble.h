/*
 * pb_ble.h — Purple Bruce M5Stick BLE Scanner
 *
 * Scans for nearby Bluetooth Low Energy devices and displays
 * their MAC address, name, RSSI, and company identifier.
 *
 * Authorized scanning / passive sniffing only.
 */

#pragma once
#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include "pb_display.h"

// ── BLE device record ────────────────────────────────────────────
struct BLEDev {
    char  name[28];
    char  addr[18];
    int   rssi;
    uint8_t addrType;  // 0=public 1=random
};

#define MAX_BLE 14
static BLEDev       ble_devs[MAX_BLE];
static volatile int ble_count   = 0;
static int          ble_scroll  = 0;
static bool         ble_inited  = false;
static bool         ble_scanning = false;
static bool         ble_done    = false;

// ── Scan callback ────────────────────────────────────────────────
class PBBleCB : public BLEAdvertisedDeviceCallbacks {
    void onResult(BLEAdvertisedDevice dev) override {
        // Deduplicate by address
        const char* newAddr = dev.getAddress().toString().c_str();
        for (int i = 0; i < ble_count; i++) {
            if (strncmp(ble_devs[i].addr, newAddr, 17) == 0) {
                ble_devs[i].rssi = dev.getRSSI();  // update RSSI
                return;
            }
        }
        if (ble_count >= MAX_BLE) return;
        int i = ble_count;
        strlcpy(ble_devs[i].name,
                dev.haveName() ? dev.getName().c_str() : "[?]",
                sizeof(ble_devs[i].name));
        strlcpy(ble_devs[i].addr, newAddr, sizeof(ble_devs[i].addr));
        ble_devs[i].rssi     = dev.getRSSI();
        ble_devs[i].addrType = (uint8_t)dev.getAddressType();
        ble_count++;
    }
};

static PBBleCB  bleCB;
static BLEScan* bleScanObj = nullptr;

// ── Init (call once) ─────────────────────────────────────────────
inline void pbBleInit() {
    if (!ble_inited) {
        BLEDevice::init("purplebruce");
        bleScanObj = BLEDevice::getScan();
        bleScanObj->setAdvertisedDeviceCallbacks(&bleCB, false);
        bleScanObj->setActiveScan(true);
        bleScanObj->setInterval(100);
        bleScanObj->setWindow(99);
        ble_inited = true;
    }
}

// ── Blocking scan (call from button action) ──────────────────────
inline void pbBleScan(int seconds = 4) {
    ble_count   = 0;
    ble_scroll  = 0;
    ble_scanning = true;
    ble_done    = false;
    memset(ble_devs, 0, sizeof(ble_devs));
    bleScanObj->clearResults();
    bleScanObj->start(seconds, false);
    ble_scanning = false;
    ble_done     = true;
}

// ── RSSI bar (5 chars) ───────────────────────────────────────────
static void rssiBar(int rssi, char* out) {
    int bars = (rssi > -55) ? 5 :
               (rssi > -65) ? 4 :
               (rssi > -75) ? 3 :
               (rssi > -85) ? 2 : 1;
    for (int i = 0; i < 5; i++) out[i] = (i < bars) ? '#' : '.';
    out[5] = '\0';
}

// ── Display ─────────────────────────────────────────────────────
inline void drawBLE(bool redraw) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);
    drawHeader(" BLE SCAN ", PB_CYAN & 0x7BEF);   // dark cyan

    int y = SCR_CONTENT_Y + 2;
    M5.Lcd.setTextSize(1);

    if (ble_scanning) {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(8, y + 20);
        M5.Lcd.print("SCANNING... please wait ~4s");
        return;
    }

    if (!ble_done) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(8, y + 20);
        M5.Lcd.print("Press [B] to scan for BLE devices");
        drawFooter("[A]next mode [B]scan");
        return;
    }

    if (ble_count == 0) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(8, y + 20);
        M5.Lcd.print("No BLE devices found.");
        drawFooter("[A]next mode [B]rescan");
        return;
    }

    // header row
    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("%-17s %-4s %-5s NAME", "ADDR", "RSSI", "SIG");
    y += 10;
    M5.Lcd.drawFastHLine(0, y - 1, SCR_W, PB_DIM);

    int visible = (SCR_CONTENT_H - 12) / 10;  // rows available
    int start   = ble_scroll;
    int end     = min(start + visible, ble_count);

    for (int i = start; i < end && y < SCR_FOOTER_Y - 2; i++) {
        BLEDev& d = ble_devs[i];
        char bar[6]; rssiBar(d.rssi, bar);
        M5.Lcd.setTextColor((d.rssi > -65) ? PB_GREEN : PB_DIM, PB_BG);
        M5.Lcd.setCursor(4, y);
        M5.Lcd.printf("%-17s %4d %s %.12s",
                      d.addr, d.rssi, bar, d.name);
        y += 10;
    }

    // scroll indicator
    if (ble_count > visible) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(SCR_W - 30, SCR_CONTENT_Y + 2);
        M5.Lcd.printf("%d/%d", ble_scroll + 1, ble_count);
    }

    drawFooter("[A]next mode [B]rescan [B-hold]scroll");
}
