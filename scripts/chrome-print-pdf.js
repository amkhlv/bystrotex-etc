#!/usr/bin/env node
'use strict';

/**
 * chrome-print-pdf.js
 * ─────────────────────────────────────────────────────────────────────────
 * Prints an HTML file to PDF using Chrome's DevTools Protocol (CDP).
 * displayHeaderFooter is always false — no date/URL chrome in the PDF.
 * Page margins come entirely from the CSS (padding on .maincolumn).
 *
 * Uses ONLY Node.js built-in modules; no npm packages required.
 *
 * Usage:
 *   node chrome-print-pdf.js <chrome-exe> <file:///abs/path.html> <out.pdf>
 * ─────────────────────────────────────────────────────────────────────────
 */

const { spawn }  = require('child_process');
const http       = require('http');
const net        = require('net');
const crypto     = require('crypto');
const fs         = require('fs');

const [,, chromePath, inputUrl, outputPath] = process.argv;
if (!chromePath || !inputUrl || !outputPath) {
  console.error(
    'Usage: chrome-print-pdf.js <chrome-exe> <file://...> <out.pdf>'
  );
  process.exit(1);
}

// ── Utilities ──────────────────────────────────────────────────────────────

const sleep = ms => new Promise(r => setTimeout(r, ms));

function httpGet(url) {
  return new Promise((resolve, reject) => {
    http.get(url, res => {
      let d = '';
      res.on('data', c => d += c);
      res.on('end', () => resolve(d));
    }).on('error', reject);
  });
}

// ── Minimal WebSocket client (RFC 6455) ───────────────────────────────────

function wsConnect(wsUrl) {
  return new Promise((resolve, reject) => {
    const { hostname, port, pathname } = new URL(wsUrl);
    const socket = net.createConnection(parseInt(port), hostname);
    const key    = crypto.randomBytes(16).toString('base64');

    socket.once('connect', () => {
      socket.write(
        `GET ${pathname} HTTP/1.1\r\n` +
        `Host: ${hostname}:${port}\r\n` +
        `Upgrade: websocket\r\n` +
        `Connection: Upgrade\r\n` +
        `Sec-WebSocket-Key: ${key}\r\n` +
        `Sec-WebSocket-Version: 13\r\n\r\n`
      );
    });

    let upgraded  = false;
    let buf       = Buffer.alloc(0);
    let msgId     = 1;
    const pending   = new Map();  // id  → {resolve, reject}
    const listeners = new Map();  // method → [callback]

    function dispatch(method, params) {
      (listeners.get(method) || []).forEach(cb => cb(params));
    }

    function parseFrames() {
      while (buf.length >= 2) {
        const opcode = buf[0] & 0x0f;
        let len = buf[1] & 0x7f;
        let off = 2;
        if      (len === 126) { if (buf.length < 4)  return; len = buf.readUInt16BE(2);         off = 4; }
        else if (len === 127) { if (buf.length < 10) return; len = Number(buf.readBigUInt64BE(2)); off = 10; }
        if (buf.length < off + len) return;
        const payload = buf.slice(off, off + len);
        buf = buf.slice(off + len);
        if (opcode === 8) { socket.destroy(); return; }
        if (opcode === 1 || opcode === 2) {
          const msg = JSON.parse(payload.toString('utf8'));
          if (msg.id !== undefined) {
            const cb = pending.get(msg.id);
            if (cb) {
              pending.delete(msg.id);
              msg.error ? cb.reject(new Error(msg.error.message))
                        : cb.resolve(msg.result);
            }
          } else if (msg.method) {
            dispatch(msg.method, msg.params);
          }
        }
      }
    }

    socket.on('data', chunk => {
      buf = Buffer.concat([buf, chunk]);
      if (!upgraded) {
        const idx = buf.indexOf('\r\n\r\n');
        if (idx !== -1 && buf.toString('utf8', 0, idx).includes('101')) {
          upgraded = true;
          buf = buf.slice(idx + 4);
          parseFrames();
          resolve(ws);
        }
      } else {
        parseFrames();
      }
    });
    socket.on('error', reject);

    function sendFrame(text) {
      const payload = Buffer.from(text, 'utf8');
      const mask    = crypto.randomBytes(4);
      const masked  = Buffer.alloc(payload.length);
      for (let i = 0; i < payload.length; i++)
        masked[i] = payload[i] ^ mask[i % 4];
      let hdr;
      if (payload.length < 126) {
        hdr = Buffer.from([0x81, 0x80 | payload.length, ...mask]);
      } else if (payload.length < 65536) {
        hdr = Buffer.alloc(8);
        hdr[0] = 0x81; hdr[1] = 0xfe;
        hdr.writeUInt16BE(payload.length, 2);
        mask.copy(hdr, 4);
      } else {
        hdr = Buffer.alloc(14);
        hdr[0] = 0x81; hdr[1] = 0xff;
        hdr.writeBigUInt64BE(BigInt(payload.length), 2);
        mask.copy(hdr, 10);
      }
      socket.write(Buffer.concat([hdr, masked]));
    }

    const ws = {
      send(method, params = {}) {
        return new Promise((res, rej) => {
          const id = msgId++;
          pending.set(id, { resolve: res, reject: rej });
          sendFrame(JSON.stringify({ id, method, params }));
        });
      },
      on(method, cb) {
        if (!listeners.has(method)) listeners.set(method, []);
        listeners.get(method).push(cb);
      },
      close() { socket.destroy(); }
    };
  });
}

// ── Main ──────────────────────────────────────────────────────────────────

async function main() {
  // Pick a free port for the debug endpoint
  const debugPort = await new Promise((res, rej) => {
    const s = net.createServer();
    s.listen(0, () => { const p = s.address().port; s.close(() => res(p)); });
    s.on('error', rej);
  });

  const chrome = spawn(chromePath, [
    '--headless', '--disable-gpu', '--no-sandbox',
    '--no-first-run', '--no-default-browser-check',
    '--disable-extensions',
    `--remote-debugging-port=${debugPort}`,
  ], { stdio: 'ignore' });

  chrome.on('error', e => {
    console.error('Failed to start Chrome:', e.message);
    process.exit(1);
  });

  // Poll until Chrome's debug port is ready
  for (let i = 0; i < 30; i++) {
    await sleep(300);
    try {
      await httpGet(`http://localhost:${debugPort}/json/version`);
      break;
    } catch {
      if (i === 29) {
        chrome.kill();
        throw new Error('Chrome debug port did not open in time');
      }
    }
  }

  try {
    // Get the existing blank tab Chrome opens in headless mode.
    // Avoid /json/new — in Chrome ≥ 109 GET /json/new returns a plain-text
    // deprecation warning rather than JSON.
    const targets = JSON.parse(
      await httpGet(`http://localhost:${debugPort}/json/list`)
    );
    const target = targets.find(t => t.type === 'page');
    if (!target) throw new Error('No page target found in /json/list');

    // Connect via WebSocket
    const ws = await wsConnect(target.webSocketDebuggerUrl);

    // Enable Page domain, navigate, wait for load
    await ws.send('Page.enable');
    const loaded = new Promise(res => ws.on('Page.loadEventFired', res));
    await ws.send('Page.navigate', { url: inputUrl });
    await Promise.race([loaded, sleep(15000)]);
    // Extra pause so web fonts / SVG images fully settle
    await sleep(1000);

    // Print — no header/footer; margins come from CSS padding
    const { data } = await ws.send('Page.printToPDF', {
      displayHeaderFooter: false,
      printBackground:     true,
      preferCSSPageSize:   true,   // honour @page { size: A4 }
      paperWidth:          8.27,   // A4 fallback (inches)
      paperHeight:         11.69,
      marginTop:    0,
      marginBottom: 0,
      marginLeft:   0,
      marginRight:  0,
    });

    fs.writeFileSync(outputPath, Buffer.from(data, 'base64'));
    console.log(`${fs.statSync(outputPath).size} bytes written to ${outputPath}`);
    ws.close();
  } finally {
    chrome.kill();
  }
}

main().catch(e => {
  console.error(e.message || e);
  process.exit(1);
});
