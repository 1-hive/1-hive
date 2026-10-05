#!/usr/bin/env bash
# Move the running hive to deploy/registry.json with a recorded hive.registry_changed, then
# restart the gateway so it loads that registry (SPEC §6: until both match, every pin is refused).
# Run by the operator: signs with the operator's own key.
#
#   apply-registry.sh [reason]
source "$(dirname "$0")/lib.sh"
export HIVE_KEY_FILE="${HIVE_KEY_FILE:-$HIVE_CONFIG_DIR/operator.key}"
REASON=${1:-"registry update"}
PY=$(head -1 "$HOME/.local/bin/hive" | sed 's/^#!//')   # hive-record's own environment
NEW=$("$PY" -c 'import sys; from hiverecord.pins import registry_digest; print(registry_digest(sys.argv[1]))' "$REGISTRY")
CUR=$(hive state | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("hive", d).get("registry_digest"))')
if [ "$NEW" = "$CUR" ]; then echo "registry already recorded ($NEW)"; else
  DATA=$(python3 -c 'import json,sys; print(json.dumps({"registry_digest": sys.argv[1], "reason": sys.argv[2]}))' "$NEW" "$REASON")
  hive emit hive.registry_changed --data "$DATA" > /dev/null || { echo "refused; see hive events"; exit 1; }
  echo "recorded registry $NEW"
fi
systemctl --user restart "$UNIT"
for i in $(seq 1 30); do hive health >/dev/null 2>&1 && break; sleep 1; done
hive state | python3 -c 'import json,sys; h=json.load(sys.stdin).get("hive",{}); g=(h.get("gateway") or {}); print("gateway registry", g.get("registry_digest"), "recorded", h.get("registry_digest"))'
