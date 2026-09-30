#!/usr/bin/env bash
# Move the running hive to the policy at HIVE_RECORD_REF (hive.env) with a recorded
# hive.policy_changed. Run by the operator: signs with the operator's own key.
# A policy the gateway can't load is refused and recorded (POLICY_INVALID); nothing changes.
source "$(dirname "$0")/lib.sh"
export HIVE_KEY_FILE="${HIVE_KEY_FILE:-$HIVE_CONFIG_DIR/operator.key}"
REASON=${1:-"move to hive-record $HIVE_RECORD_REF"}
NEW_PIN=$(mktemp)
hive-pin mint hive-record policy --commit "$HIVE_RECORD_REF" --output "$NEW_PIN" >/dev/null
if cmp -s "$NEW_PIN" "$POLICY_PIN"; then echo "already on $HIVE_RECORD_REF"; rm -f "$NEW_PIN"; exit 0; fi
DATA=$(python3 -c 'import json,sys; print(json.dumps({"profile": sys.argv[1], "reason": sys.argv[2]}))' "$HIVE_PROFILE" "$REASON")
if hive emit hive.policy_changed --data "$DATA" --ref policy="$NEW_PIN" > /dev/null; then
  cp "$NEW_PIN" "$POLICY_PIN"; echo "policy now $HIVE_RECORD_REF"
else
  echo "refused; see the gateway.rejected event (hive events)"; rm -f "$NEW_PIN"; exit 1
fi
rm -f "$NEW_PIN"
