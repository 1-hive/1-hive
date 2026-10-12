#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""kev-gate: lets another hive use this host's Kev (kev.service, loopback only) as its
reader (hive-route ROUTING §4.8), through one narrow, authenticated door.

- Listens on KEV_GATE_BIND (default 127.0.0.1:8010; Tailscale Funnel publishes it).
- Serves only POST /v1/systemone, with "Authorization: Bearer <key>". The key's SHA-256 is
  in KEV_GATE_KEY_SHA256_FILE (default ~/.config/hive/kev-gate.sha256); the key itself is
  never stored here.
- Bodies up to 256 KiB; at most 4 requests at once; forwards to 127.0.0.1:8009.
- Logs one line per request (time, client, status, bytes, seconds), never the text.

Standard library only. Kev's own server never faces the network.
"""

from __future__ import annotations

import hashlib
import hmac
import os
import sys
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

UPSTREAM = "http://127.0.0.1:8009/v1/systemone"
MAX_BODY = 256 * 1024
SLOTS = threading.BoundedSemaphore(4)
KEY_FILE = Path(os.path.expanduser(os.environ.get("KEV_GATE_KEY_SHA256_FILE",
                                                  "~/.config/hive/kev-gate.sha256")))


def key_hash() -> str:
    return KEY_FILE.read_text().strip()


class Gate(BaseHTTPRequestHandler):
    server_version = "kev-gate"
    sys_version = ""

    def log_message(self, fmt, *args):  # one line per request, from _done; nothing else
        pass

    def _done(self, status: int, body: bytes, t0: float, n_in: int = 0) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)
        print(f"{time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())} {self.client_address[0]} "
              f"{status} in={n_in} out={len(body)} {time.monotonic() - t0:.2f}s", flush=True)

    def _refuse(self, status: int, why: str, t0: float) -> None:
        self._done(status, ('{"error": "%s"}' % why).encode(), t0)

    def do_GET(self):
        self._refuse(404, "not found", time.monotonic())

    def do_POST(self):
        t0 = time.monotonic()
        if self.path != "/v1/systemone":
            return self._refuse(404, "not found", t0)
        auth = self.headers.get("Authorization", "")
        given = auth[7:] if auth.startswith("Bearer ") else ""
        if not given or not hmac.compare_digest(hashlib.sha256(given.encode()).hexdigest(),
                                                key_hash()):
            return self._refuse(401, "unauthorized", t0)
        try:
            n = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            n = -1
        if not 0 < n <= MAX_BODY:
            return self._refuse(413, "body missing or too large", t0)
        body = self.rfile.read(n)
        if not SLOTS.acquire(timeout=30):
            return self._refuse(503, "busy", t0)
        try:
            req = urllib.request.Request(UPSTREAM, data=body,
                                         headers={"Content-Type": "application/json"})
            try:
                with urllib.request.urlopen(req, timeout=60) as r:
                    return self._done(r.status, r.read(), t0, n)
            except urllib.error.HTTPError as e:
                return self._done(e.code, e.read(), t0, n)
            except (urllib.error.URLError, TimeoutError, OSError):
                return self._refuse(502, "kev unavailable", t0)
        finally:
            SLOTS.release()


def main() -> int:
    host, _, port = os.environ.get("KEV_GATE_BIND", "127.0.0.1:8010").rpartition(":")
    if not KEY_FILE.is_file():
        print(f"no key hash at {KEY_FILE}", file=sys.stderr)
        return 2
    ThreadingHTTPServer((host, int(port)), Gate).serve_forever()
    return 0


if __name__ == "__main__":
    sys.exit(main())
