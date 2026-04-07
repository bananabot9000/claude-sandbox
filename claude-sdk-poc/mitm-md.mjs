/**
 * MITM proxy: intercepts queries to api.anthropic.com,
 * writes raw request/response JSON as JSONL.
 *
 * Usage: ANTHROPIC_BASE_URL=http://localhost:18899 claude -p "prompt"
 * Output: requests.jsonl, responses.jsonl (one JSON object per line)
 */
import http from 'node:http';
import https from 'node:https';
import fs from 'node:fs';
import path from 'node:path';

const PORT = 18899;
const TARGET = 'api.anthropic.com';
const OUTPUT_DIR = process.env.MITM_OUTPUT_DIR || '.';

const REQUEST_FILE = path.join(OUTPUT_DIR, 'requests.jsonl');
const RESPONSE_FILE = path.join(OUTPUT_DIR, 'responses.jsonl');

let queryCount = 0;

function appendLine(filepath, obj) {
  fs.appendFileSync(filepath, JSON.stringify(obj) + '\n');
}

// Clear files on startup
fs.writeFileSync(REQUEST_FILE, '');
fs.writeFileSync(RESPONSE_FILE, '');

const server = http.createServer((req, res) => {
  let body = '';
  req.on('data', chunk => body += chunk);
  req.on('end', () => {
    const isMessages = req.method === 'POST' && req.url.startsWith('/v1/messages');

    if (isMessages && body) {
      try {
        queryCount++;
        const parsed = JSON.parse(body);
        appendLine(REQUEST_FILE, {
          turn: queryCount,
          timestamp: new Date().toISOString(),
          method: req.method,
          url: req.url,
          headers: req.headers,
          body: parsed,
        });
        console.log(`# Turn ${queryCount} request written (${parsed.messages?.length || 0} messages)`);
      } catch (e) {
        console.error('# Parse error:', e.message);
      }
    }

    const fwdReq = https.request({
      hostname: TARGET,
      path: req.url,
      method: req.method,
      headers: {
        ...req.headers,
        host: TARGET,
      },
    }, (fwdRes) => {
      console.log(`# Response: ${fwdRes.statusCode} ${req.method} ${req.url}`);

      const isStreaming = fwdRes.headers['content-type']?.includes('text/event-stream');

      if (isMessages && !isStreaming) {
        let responseBody = '';
        fwdRes.on('data', chunk => responseBody += chunk);
        fwdRes.on('end', () => {
          let parsed;
          try {
            parsed = JSON.parse(responseBody);
          } catch {
            parsed = responseBody;
          }
          appendLine(RESPONSE_FILE, {
            turn: queryCount,
            timestamp: new Date().toISOString(),
            status: fwdRes.statusCode,
            headers: fwdRes.headers,
            body: parsed,
          });
          console.log(`# Turn ${queryCount} response written`);
        });
      }

      if (isMessages && isStreaming) {
        // Capture full SSE stream
        let streamBody = '';
        fwdRes.on('data', chunk => streamBody += chunk);
        fwdRes.on('end', () => {
          appendLine(RESPONSE_FILE, {
            turn: queryCount,
            timestamp: new Date().toISOString(),
            status: fwdRes.statusCode,
            headers: fwdRes.headers,
            streaming: true,
            body: streamBody,
          });
          console.log(`# Turn ${queryCount} streaming response written`);
        });
      }

      res.writeHead(fwdRes.statusCode, fwdRes.headers);
      fwdRes.pipe(res);
    });

    fwdReq.on('error', (e) => {
      console.error('# Forward error:', e.message);
      res.writeHead(502);
      res.end('Bad Gateway');
    });

    fwdReq.write(body);
    fwdReq.end();
  });
});

server.listen(PORT, () => {
  console.log(`# MITM-JSONL proxy on :${PORT}`);
  console.log(`# Output: ${path.resolve(REQUEST_FILE)} / ${path.resolve(RESPONSE_FILE)}`);
  console.log(`# Files cleared on startup, one JSON object per line`);
  console.log(`# Usage: ANTHROPIC_BASE_URL=http://localhost:${PORT} claude -p "prompt"`);
});
