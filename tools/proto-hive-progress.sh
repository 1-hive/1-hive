#!/usr/bin/env bash
# Export the proto-hive record over a short-lived tunnel to vm2 and print the PROGRESS.md proto-hive table.
# Reads only. Needs ~/.ssh/proto-hive-review and ~/repos/proto-hive (for the registry).
# With --write, replaces the table between the proto-hive markers in PROGRESS.md instead of printing it.
set -euo pipefail
KEY=~/.ssh/proto-hive-review
VM2=root@202.181.159.71
PORT=18471
OUT=$(mktemp)
SOCK=$(mktemp -u)
trap 'rm -f "$OUT"; ssh -S "$SOCK" -O exit "$VM2" 2>/dev/null || true' EXIT

# -f returns once the forward is up (ExitOnForwardFailure), and the control socket lets the trap close it.
ssh -i "$KEY" -o ConnectTimeout=20 -o ExitOnForwardFailure=yes -M -S "$SOCK" -f -N -L "$PORT:127.0.0.1:8470" "$VM2"

HIVE_URL=http://127.0.0.1:$PORT HIVE_ID=proto-hive HIVE_KEY_FILE=~/.config/hive/proto-hive-operator.key \
  hive export > "$OUT"
TABLE=$(python3 "$(dirname "$0")/proto-hive-progress.py" "$OUT" ~/repos/proto-hive/deploy/registry.json)
if [ "${1:-}" != --write ]; then printf '%s\n' "$TABLE"; exit 0; fi
TABLE="$TABLE" python3 - "$(dirname "$0")/../PROGRESS.md" <<'PY'
import os, re, sys
path = sys.argv[1]
text = open(path).read()
new, n = re.subn(r"(<!-- proto-hive:begin -->\n)(?:.*?\n)?(<!-- proto-hive:end -->)",
                 lambda m: m.group(1) + os.environ["TABLE"] + "\n" + m.group(2), text, flags=re.S)
if n != 1:
    sys.exit("PROGRESS.md: proto-hive markers not found")
open(path, "w").write(new)
PY
echo "PROGRESS.md updated"
