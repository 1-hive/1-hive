#!/usr/bin/env python3
"""Tell the operator on Telegram when 1-hive is down, and again when it is back.

    watchdog.py [--dry-run]

Run every two minutes by the `1-hive-watchdog` timer (deploy/up.sh). Checks the record's
databases (Postgres containers), the gateway's health, and that every 1-hive service is active
and no 1-hive timer job failed. A problem must show on two checks in a row before it is
reported, so a restart in progress isn't an alert. Only changes are sent: what broke, and
"all clear" once nothing is wrong. It messages Telegram's API directly (hive-bridge's telegram-say.py),
so it works while the Telegram bridge is down. Touches nothing on the record.
"""
from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

# The message goes out through hive-bridge's telegram-say.py, as installed by deploy/up.sh.
SAY = Path.home() / ".local" / "share" / "1-hive" / "hive-bridge" / "telegram-say.py"
STATE = Path.home() / ".local" / "share" / "1-hive" / "watchdog.json"
CONTAINERS = ["1hive-pg", "hive-gw-pg"]
SERVICES = [
    "1-hive-gateway", "1-hive-supervisor", "1-hive-dispatcher", "1-hive-cos", "1-hive-telegram",
    "1-hive-floor", "1-hive-agent-ports", "hive-llm-gateway",
]
JOBS = ["1-hive-backup", "1-hive-sweeper"]  # oneshots: only "failed" is a problem


def run(*cmd: str) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True, timeout=60)


def problems() -> list[str]:
    found = []
    for c in CONTAINERS:
        r = run("podman", "inspect", "--format", "{{.State.Running}}", c)
        if r.stdout.strip() != "true":
            found.append(f"database container {c} is not running")
    for s in SERVICES:
        state = run("systemctl", "--user", "is-active", s).stdout.strip()
        if state != "active":
            found.append(f"{s} is {state or 'unknown'}")
    for j in JOBS:
        if run("systemctl", "--user", "is-failed", j).stdout.strip() == "failed":
            found.append(f"{j} failed its last run")
    if "1-hive-gateway is" not in " ".join(found):
        r = run(str(Path.home() / ".local" / "bin" / "hive"), "health")
        try:
            ok = r.returncode == 0 and json.loads(r.stdout).get("status") == "ok"
        except ValueError:
            ok = False
        if not ok:
            found.append("the record gateway is running but its health check fails")
    return found


def main() -> None:
    dry = "--dry-run" in sys.argv
    now = problems()
    if dry:
        print("\n".join(now) or "all clear")
        return
    try:
        prev = json.loads(STATE.read_text())
    except (OSError, ValueError):
        prev = {"seen": [], "reported": []}
    # report a problem once it shows twice in a row; drop it once it's gone
    confirmed = sorted(p for p in now if p in prev["seen"])
    reported = prev["reported"]
    message = None
    if confirmed and confirmed != reported:
        message = "1-hive watchdog: something is down.\n- " + "\n- ".join(confirmed)
        message += "\n(Reply here goes to the chief of staff; the operator's host session can fix this.)"
        reported = confirmed
    elif reported and not now:
        message = "1-hive watchdog: all clear, everything is running again."
        reported = []
    if message:
        r = subprocess.run([sys.executable, str(SAY), message],
                           capture_output=True, text=True, timeout=60)
        if r.returncode != 0:  # retry on the next run
            reported = prev["reported"]
            print("could not send:", r.stderr.strip(), file=sys.stderr)
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(json.dumps({"seen": sorted(now), "reported": reported}))
    print("\n".join(now) or "all clear")


if __name__ == "__main__":
    main()
