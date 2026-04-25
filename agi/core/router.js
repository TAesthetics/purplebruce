// agi/core/router.js — Picks a provider configuration for a given role.
// Each role can be pinned to a provider in config; otherwise falls back to a default.

'use strict';

const fs = require('fs');
const path = require('path');
const os = require('os');

function readJsonIfExists(p) {
  try { return JSON.parse(fs.readFileSync(p, 'utf8')); } catch { return null; }
}

function loadConfig() {
  const candidates = [
    process.env.AGI_CONFIG,
    path.join(os.homedir(), '.agi', 'config.json'),
    path.join(__dirname, '..', 'config', 'default.json'),
    path.join(__dirname, '..', 'config', 'default.example.json'),
  ].filter(Boolean);
  for (const p of candidates) {
    const j = readJsonIfExists(p);
    if (j) return j;
  }
  return {};
}

const PROVIDER_DEFAULTS = {
  openai: {
    baseURL: 'https://api.openai.com/v1',
    apiKeyEnv: 'OPENAI_API_KEY',
    model: 'gpt-4o-mini',
  },
  grok: {
    baseURL: 'https://api.x.ai/v1',
    apiKeyEnv: 'XAI_API_KEY',
    model: 'grok-3-mini',
  },
  venice: {
    baseURL: 'https://api.venice.ai/api/v1',
    apiKeyEnv: 'VENICE_API_KEY',
    model: 'llama-3.3-70b',
  },
  openrouter: {
    baseURL: 'https://openrouter.ai/api/v1',
    apiKeyEnv: 'OPENROUTER_API_KEY',
    model: 'meta-llama/llama-3.3-70b-instruct',
  },
};

const DEFAULT_ROLE_PROVIDER = {
  lucy:       'grok',
  bruce:      'grok',
  strategist: 'openai',
  operator:   'openai',
};

function resolveProvider(role) {
  const cfg = loadConfig();
  const providerName = (cfg.roles?.[role] || DEFAULT_ROLE_PROVIDER[role] || 'openai');
  const def  = PROVIDER_DEFAULTS[providerName];
  if (!def) throw new Error(`unknown provider: ${providerName}`);
  const overrides = cfg.providers?.[providerName] ?? {};
  const apiKey = overrides.apiKey || process.env[def.apiKeyEnv] || '';
  return {
    name: providerName,
    baseURL: overrides.baseURL || def.baseURL,
    apiKey,
    model: overrides.model || def.model,
    temperature: overrides.temperature,
    maxTokens: overrides.maxTokens,
    timeoutMs: overrides.timeoutMs,
  };
}

function listStatus() {
  return Object.fromEntries(
    Object.entries(PROVIDER_DEFAULTS).map(([k, v]) => {
      const key = process.env[v.apiKeyEnv];
      return [k, { hasKey: !!key, keyEnv: v.apiKeyEnv, model: v.model, baseURL: v.baseURL }];
    })
  );
}

module.exports = { resolveProvider, listStatus, PROVIDER_DEFAULTS, DEFAULT_ROLE_PROVIDER };
