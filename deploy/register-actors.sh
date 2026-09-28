#!/usr/bin/env bash
# Register every actor in actors.json that the hive doesn't know yet.
# Run by the operator: signs with the operator's own key.
source "$(dirname "$0")/lib.sh"
export HIVE_KEY_FILE="${HIVE_KEY_FILE:-$HIVE_CONFIG_DIR/operator.key}"
known=$(hive actors | python3 -c 'import json,sys; print(" ".join(a["id"] for a in json.load(sys.stdin)))')
python3 - "$DEPLOY_DIR/actors.json" <<'PY' | while IFS= read -r line; do
import json, sys
for a in json.load(open(sys.argv[1]))["actors"]:
    print(json.dumps(a, separators=(",", ":")))
PY
  id=$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["actor_id"])' "$line")
  case " $known " in *" $id "*) echo "skip $id (registered)"; continue;; esac
  hive emit actor.registered --data "$line" >/dev/null && echo "registered $id"
done
