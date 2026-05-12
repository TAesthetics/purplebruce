#!/usr/bin/env node
/**
 * Purple Bruce M5Stick — Termux Localhost Flash Server
 *
 * Serves the ESP Web Tools UI so you can flash the M5Stick
 * from Chrome/Chromium on a non-rooted Android device.
 *
 * Usage (in Termux):
 *   node serve.js
 *   → open http://localhost:8080 in Chrome
 *   → connect M5Stick via USB-C OTG
 *   → click INSTALL
 */

'use strict';

const http = require('http');
const fs   = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const ROOT = __dirname;

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.json': 'application/json',
    '.bin' : 'application/octet-stream',
    '.js'  : 'application/javascript',
    '.css' : 'text/css',
    '.ico' : 'image/x-icon',
};

function serveFile(res, filePath) {
    fs.readFile(filePath, (err, data) => {
        if (err) {
            res.writeHead(404, { 'Content-Type': 'text/plain' });
            res.end('404 — not found: ' + filePath);
            return;
        }
        const ext = path.extname(filePath).toLowerCase();
        res.writeHead(200, {
            'Content-Type'                : MIME[ext] || 'application/octet-stream',
            'Access-Control-Allow-Origin' : '*',
            'Access-Control-Allow-Methods': 'GET, OPTIONS',
            'Cache-Control'               : 'no-store',
        });
        res.end(data);
    });
}

const server = http.createServer((req, res) => {
    if (req.method === 'OPTIONS') {
        res.writeHead(204, { 'Access-Control-Allow-Origin': '*' });
        res.end();
        return;
    }

    // default route → web flash UI
    let urlPath = req.url.split('?')[0];
    if (urlPath === '/' || urlPath === '') urlPath = '/web-flash/index.html';

    // security: prevent directory traversal
    const resolved = path.resolve(ROOT, '.' + urlPath);
    if (!resolved.startsWith(ROOT)) {
        res.writeHead(403); res.end('Forbidden'); return;
    }

    serveFile(res, resolved);
});

server.listen(PORT, '127.0.0.1', () => {
    console.log('');
    console.log('  ⛧  PURPLE BRUCE — M5Stick Flash Server  ⛧');
    console.log('  ─────────────────────────────────────────');
    console.log(`  → Open in Chrome:  http://localhost:${PORT}`);
    console.log('  → Connect M5Stick via USB-C (OTG adapter if needed)');
    console.log('  → Click INSTALL in the browser');
    console.log('  → Chrome will ask for USB/Serial permission — Allow');
    console.log('');
    console.log('  NOTE: put your compiled .bin in web-flash/');
    console.log('        See README.md → "Compile the firmware" section');
    console.log('');
    console.log('  Ctrl+C to stop');
    console.log('');
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`\n  [!] Port ${PORT} already in use.`);
        console.error(`  Try: PORT=8081 node serve.js\n`);
    } else {
        console.error(err);
    }
    process.exit(1);
});
