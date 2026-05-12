/*
 * pb_ai.h — Purple Bruce M5Stick AI Chat
 *
 * Connects to WiFi and queries Grok / Venice / Gemini
 * using the same provider routing as the desktop purplebruce.
 *
 * Providers (matching config/ai-providers.json):
 *   0 = Grok-3-mini  (xAI API — OpenAI-compatible)
 *   1 = Venice AI    (llama-3.3-70b — uncensored)
 *   2 = Gemini Flash (Google — free tier)
 *
 * Configure keys in pb_config.h before compiling.
 */

#pragma once
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include "pb_config.h"
#include "pb_display.h"

// ── State ────────────────────────────────────────────────────────
static int     ai_provider    = PB_DEFAULT_AI;   // 0=Grok 1=Venice 2=Gemini
static int     ai_prompt_idx  = 0;
static bool    ai_connecting  = false;
static bool    ai_connected   = false;
static bool    ai_querying    = false;
static bool    ai_done        = false;
static int     ai_scroll      = 0;

static char    ai_response[1024] = {};
static char    ai_error[80]      = {};

static const char* AI_LABELS[]   = { "GROK-3", "VENICE", "GEMINI" };
static const char* AI_BADGES[]   = { "⚡ GROK-3", "🔮 VENICE", "✨ GEMINI" };
static const uint16_t AI_COLORS[]= { PB_MAGENTA, PB_VIOLET, PB_CYAN };

// ── Pre-defined chaos prompts ────────────────────────────────────
static const char* AI_PROMPTS[] = {
    "You are a chaos magic servitor. Give a 2-sentence divination.",
    "Purple Team tip: one offensive tactic and its detection. Be brief.",
    "Summarize the current digital threat landscape in 2 sentences.",
    "Give a hacker koan about entropy and signal. One sentence.",
    "What OSINT technique is most underused? One sentence answer.",
    "Channel a chaos sigil blessing for a network operator. Brief.",
    "One CTF challenge tip for a binary exploitation beginner.",
    "What does the void say about zero-days? Poetic, 1-2 sentences.",
};
#define N_AI_PROMPTS 8

// ── WiFi connect helper ──────────────────────────────────────────
inline bool pbWifiConnect() {
    if (WiFi.status() == WL_CONNECTED) return true;
    ai_connecting = true;
    WiFi.mode(WIFI_STA);
    WiFi.begin(PB_WIFI_SSID, PB_WIFI_PASS);
    uint32_t t = millis();
    while (WiFi.status() != WL_CONNECTED) {
        if (millis() - t > PB_WIFI_TIMEOUT_MS) {
            ai_connecting = false;
            snprintf(ai_error, sizeof(ai_error), "WiFi timeout: %s", PB_WIFI_SSID);
            return false;
        }
        delay(200);
    }
    ai_connecting = false;
    ai_connected  = true;
    return true;
}

// ── Build OpenAI-compatible JSON body (Grok / Venice) ───────────
static String buildOpenAIBody(const char* prompt) {
    JsonDocument doc;
    doc["model"]       = (ai_provider == 0) ? GROK_MODEL : VENICE_MODEL;
    doc["temperature"] = PB_AI_TEMP;
    doc["max_tokens"]  = PB_AI_MAX_TOKENS;
    JsonArray messages = doc["messages"].to<JsonArray>();
    JsonObject sys = messages.add<JsonObject>();
    sys["role"]    = "system";
    sys["content"] = "You are a chaos magic purple team AI servitor. "
                     "Keep responses very short (under 100 words).";
    JsonObject usr = messages.add<JsonObject>();
    usr["role"]    = "user";
    usr["content"] = prompt;
    String out;
    serializeJson(doc, out);
    return out;
}

// ── Build Gemini request body ─────────────────────────────────────
static String buildGeminiBody(const char* prompt) {
    JsonDocument doc;
    JsonObject gc = doc["generationConfig"].to<JsonObject>();
    gc["temperature"]   = PB_AI_TEMP;
    gc["maxOutputTokens"] = PB_AI_MAX_TOKENS;
    JsonArray contents = doc["contents"].to<JsonArray>();
    JsonObject c = contents.add<JsonObject>();
    JsonArray parts = c["parts"].to<JsonArray>();
    JsonObject p = parts.add<JsonObject>();
    p["text"] = prompt;
    String out;
    serializeJson(doc, out);
    return out;
}

// ── Parse OpenAI-compatible response ────────────────────────────
static bool parseOpenAI(const String& body, char* out, int maxLen) {
    JsonDocument doc;
    DeserializationError e = deserializeJson(doc, body);
    if (e) { snprintf(out, maxLen, "JSON err: %s", e.c_str()); return false; }
    if (doc.containsKey("error")) {
        const char* msg = doc["error"]["message"] | "API error";
        snprintf(out, maxLen, "API: %s", msg);
        return false;
    }
    const char* text = doc["choices"][0]["message"]["content"] | "";
    strlcpy(out, text, maxLen);
    return true;
}

// ── Parse Gemini response ────────────────────────────────────────
static bool parseGemini(const String& body, char* out, int maxLen) {
    JsonDocument doc;
    DeserializationError e = deserializeJson(doc, body);
    if (e) { snprintf(out, maxLen, "JSON err: %s", e.c_str()); return false; }
    if (doc.containsKey("error")) {
        const char* msg = doc["error"]["message"] | "API error";
        snprintf(out, maxLen, "API: %s", msg);
        return false;
    }
    const char* text =
        doc["candidates"][0]["content"]["parts"][0]["text"] | "";
    strlcpy(out, text, maxLen);
    return true;
}

// ── Make the API call ────────────────────────────────────────────
inline void pbAiQuery() {
    ai_querying = true;
    ai_done     = false;
    ai_scroll   = 0;
    memset(ai_response, 0, sizeof(ai_response));
    memset(ai_error,    0, sizeof(ai_error));

    if (!pbWifiConnect()) {
        ai_querying = false;
        ai_done     = true;
        strlcpy(ai_response, ai_error, sizeof(ai_response));
        return;
    }

    WiFiClientSecure client;
    client.setInsecure();   // skip cert validation (adequate for this use)
    HTTPClient https;
    https.setTimeout(10000);

    const char* prompt = AI_PROMPTS[ai_prompt_idx % N_AI_PROMPTS];
    String body, url;
    bool ok = false;

    if (ai_provider == 2) {
        // Gemini: key in URL, different body format
        url = String(GEMINI_BASE_URL) + "?key=" + GEMINI_API_KEY;
        body = buildGeminiBody(prompt);
        if (https.begin(client, url)) {
            https.addHeader("Content-Type", "application/json");
            int code = https.POST(body);
            if (code == 200) {
                ok = parseGemini(https.getString(), ai_response, sizeof(ai_response));
            } else {
                snprintf(ai_error, sizeof(ai_error), "HTTP %d", code);
            }
            https.end();
        }
    } else {
        // Grok or Venice: OpenAI-compatible
        url = (ai_provider == 0) ? GROK_BASE_URL : VENICE_BASE_URL;
        const char* key = (ai_provider == 0) ? GROK_API_KEY : VENICE_API_KEY;
        body = buildOpenAIBody(prompt);
        if (https.begin(client, url)) {
            https.addHeader("Content-Type", "application/json");
            https.addHeader("Authorization", String("Bearer ") + key);
            int code = https.POST(body);
            if (code == 200) {
                ok = parseOpenAI(https.getString(), ai_response, sizeof(ai_response));
            } else {
                snprintf(ai_error, sizeof(ai_error), "HTTP %d", code);
            }
            https.end();
        }
    }

    if (!ok && ai_response[0] == '\0') {
        strlcpy(ai_response,
                ai_error[0] ? ai_error : "No response.",
                sizeof(ai_response));
    }
    ai_querying = false;
    ai_done     = true;
}

// ── Display ─────────────────────────────────────────────────────
inline void drawAI(bool redraw, uint32_t frame) {
    if (redraw) M5.Lcd.fillScreen(PB_BG);

    uint16_t accent = AI_COLORS[ai_provider % 3];
    drawHeader(" AI CHAT  ", accent);

    int y = SCR_CONTENT_Y + 2;
    M5.Lcd.setTextSize(1);

    // provider + prompt selector row
    M5.Lcd.setTextColor(accent, PB_BG);
    M5.Lcd.setCursor(4, y);
    M5.Lcd.printf("%-8s  PROMPT %d/%d", AI_LABELS[ai_provider],
                  ai_prompt_idx + 1, N_AI_PROMPTS);
    y += 10;

    M5.Lcd.setTextColor(PB_DIM, PB_BG);
    M5.Lcd.setCursor(4, y);
    // show truncated prompt
    const char* prompt = AI_PROMPTS[ai_prompt_idx % N_AI_PROMPTS];
    char pbuf[36];
    strlcpy(pbuf, prompt, sizeof(pbuf));
    if (strlen(prompt) > 35) { pbuf[32] = '.'; pbuf[33] = '.'; pbuf[34] = '.'; pbuf[35] = '\0'; }
    M5.Lcd.print(pbuf);
    y += 12;

    M5.Lcd.drawFastHLine(0, y - 1, SCR_W, PB_DIM);

    if (ai_connecting) {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(4, y + 8);
        M5.Lcd.printf("Connecting to WiFi... %c", spinChar(frame));
        return;
    }
    if (ai_querying) {
        M5.Lcd.setTextColor(PB_GOLD, PB_BG);
        M5.Lcd.setCursor(4, y + 8);
        M5.Lcd.printf("Querying %s... %c", AI_LABELS[ai_provider], spinChar(frame));
        return;
    }
    if (!ai_done) {
        // idle state
        bool hasKey = true;
        if (ai_provider == 0 && strncmp(GROK_API_KEY,   "xai-", 4) != 0) hasKey = false;
        if (ai_provider == 1 && strncmp(VENICE_API_KEY, "REPL", 4) == 0) hasKey = false;
        if (ai_provider == 2 && strncmp(GEMINI_API_KEY, "REPL", 4) == 0) hasKey = false;
        if (!hasKey) {
            M5.Lcd.setTextColor(PB_RED, PB_BG);
            M5.Lcd.setCursor(4, y + 8);
            M5.Lcd.print("Set API key in pb_config.h");
        } else {
            M5.Lcd.setTextColor(PB_DIM, PB_BG);
            M5.Lcd.setCursor(4, y + 8);
            M5.Lcd.print("Press [B] to query");
        }
        drawFooter("[A]nxt mode [B]query [B-hold]nxt provider");
        return;
    }

    // show response with word-wrap + scroll
    int available = SCR_FOOTER_Y - y - 2;
    int lineH = 9;
    int maxLines = available / lineH;

    // split response into lines for scrolling
    const char* resp = ai_response;
    int respLen = strlen(resp);

    // apply scroll offset (skip characters)
    int skipChars = ai_scroll * 38;  // ~38 chars per line at size 1
    if (skipChars > respLen) skipChars = 0;

    drawWrapped(4, y, SCR_W - 8, lineH, PB_WHITE, 1, resp + skipChars);

    if (respLen > (size_t)(maxLines * 38)) {
        M5.Lcd.setTextColor(PB_DIM, PB_BG);
        M5.Lcd.setCursor(SCR_W - 20, y);
        M5.Lcd.printf("[%d]", ai_scroll);
    }

    drawFooter("[A]nxt mode [B]query [B-hold]nxt provider");
}
