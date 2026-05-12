/*
 * pb_config.h — Purple Bruce M5Stick User Configuration
 *
 * EDIT THIS FILE before compiling. Set your WiFi credentials
 * and AI API keys. Then compile and flash.
 *
 * API keys are stored in firmware flash only — never transmitted
 * except to their respective services over HTTPS.
 */

#pragma once

// ── WiFi (required for AI Chat mode) ────────────────────────────
#define PB_WIFI_SSID   "YOUR_WIFI_SSID"
#define PB_WIFI_PASS   "YOUR_WIFI_PASSWORD"
#define PB_WIFI_TIMEOUT_MS 12000   // connect timeout

// ── Grok (xAI) ──────────────────────────────────────────────────
// Get key: https://console.x.ai/
#define GROK_API_KEY  "xai-REPLACE_ME"
#define GROK_MODEL    "grok-3-mini"
#define GROK_BASE_URL "https://api.x.ai/v1/chat/completions"

// ── Venice AI ───────────────────────────────────────────────────
// Get key: https://venice.ai/settings/api
#define VENICE_API_KEY  "REPLACE_ME"
#define VENICE_MODEL    "llama-3.3-70b"
#define VENICE_BASE_URL "https://api.venice.ai/api/v1/chat/completions"

// ── Gemini (Google) ─────────────────────────────────────────────
// Get key: https://aistudio.google.com/app/apikey
#define GEMINI_API_KEY  "REPLACE_ME"
#define GEMINI_MODEL    "gemini-2.0-flash"
#define GEMINI_BASE_URL "https://generativelanguage.googleapis.com/v1beta/models/" GEMINI_MODEL ":generateContent"

// ── Default provider: 0=Grok  1=Venice  2=Gemini ────────────────
#define PB_DEFAULT_AI  0

// ── AI temperature & max tokens ─────────────────────────────────
#define PB_AI_TEMP        0.75f
#define PB_AI_MAX_TOKENS  120     // keep responses short for the screen
