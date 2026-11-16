#!/usr/bin/env bash
# Retire Kev, the operator's decision of 2026-11-15 (goal kev-gpu, option d; workspace
# hive-requests/2026-11-15-retire-kev.md). vm2 first, so vm2 never logs a failed reading, then this host.
# Run by the operator, from a terminal (closing the Funnel may ask for sudo):
#
#   ~/repos/1-hive/deploy/retire-kev.sh
#
# Safe to run again: each step checks whether it's done.
#  1. vm2: route table v7 (no reader; staged in /opt/hive-route/state by the host session, checked with
#     `hive-route check`), v6 kept as route-table.yaml.pre-retire-kev-20261115; restart hive-route-serve.
#  2. vm2: remove the reader's egress, which only an operator changes (vm2 deploy/README.md, "Reader"):
#     the refresh timer, the reader.conf drop-in, reader.env (the gate key), the nft table. A note in
#     vm2's README says what changed and who ran it.
#  3. Here: close the public Funnel URL (443 -> kev-gate).
#  4. Here: stop and disable kev-gate; delete its key and hash.
#  5. Here: stop and disable kev.service: its ~10 GB of GPU go free. ~/opt/kev and runs/reader-ft-v1 stay.
# 1-hive's own reader went with route table v21 (1-hive 08a9e45).
set -euo pipefail
mkdir -p ~/.ssh/cm
VM2=(ssh -i ~/.ssh/proto-hive-review -o ConnectTimeout=20 -o ControlMaster=auto -o ControlPath=~/.ssh/cm/vm2
     -o ControlPersist=10m root@202.181.159.71)
step() { printf '\n== %s\n' "$*"; }

step "1/5 vm2: route table v7 (no reader), restart hive-route-serve"
"${VM2[@]}" 'bash -s' <<'EOF'
set -euo pipefail
cd /opt/hive-route/deploy
if grep -q '^version: 7$' route-table.yaml; then
  echo "already on v7"
else
  /opt/hive-route/venv/bin/hive-route check /opt/hive-route/state/route-table.v7.yaml | head -1
  M=$(stat -c %a route-table.yaml)
  cp -p route-table.yaml route-table.yaml.pre-retire-kev-20261115
  install -m "$M" /opt/hive-route/state/route-table.v7.yaml route-table.yaml
  rm /opt/hive-route/state/route-table.v7.yaml
  systemctl restart hive-route-serve.service
  sleep 4
fi
systemctl is-active hive-route-serve.service
H=$(docker exec -u 11004:10001 proto-hive python3 -c 'import urllib.request;print(urllib.request.urlopen("http://172.18.0.1:8480/health").read().decode())')
echo "$H"
case "$H" in *'"reader": {'*) echo "vm2 still has a reader: stopping here" >&2; exit 1 ;; esac
EOF

step "2/5 vm2: remove the reader's egress (timer, drop-in, key, nft table)"
"${VM2[@]}" 'bash -s' <<'EOF'
set -euo pipefail
if [ -e /etc/systemd/system/hive-route-serve.service.d/reader.conf ] || [ -e /etc/hive-route/reader.env ]; then
  systemctl disable --now hive-route-egress-refresh.timer 2>/dev/null || true
  rm -f /etc/systemd/system/hive-route-serve.service.d/reader.conf /etc/hive-route/reader.env
  systemctl daemon-reload
  systemctl restart hive-route-serve.service
  sleep 4
fi
/usr/sbin/nft delete table inet hive_route_egress 2>/dev/null || true
systemctl is-active hive-route-serve.service
docker exec -u 11004:10001 proto-hive python3 -c 'import urllib.request;print(urllib.request.urlopen("http://172.18.0.1:8480/health").read().decode())'
R=/opt/hive-route/deploy/README.md
if ! grep -q '^## Reader retired, 2026-11-15' "$R"; then
  sed -i 's/^## Reader (rev 13, ROUTING.md §4.8): SHADOW on 1-hive.s Kev gate, active since 2026-10-12 19:30Z$/## Reader (rev 13, ROUTING.md §4.8): RETIRED 2026-11-15 (see "Reader retired" at the end); was SHADOW on 1-hive'"'"'s Kev gate from 2026-10-12 19:30Z/' "$R"
  cat >> "$R" <<'NOTE'

## Reader retired, 2026-11-15 (route table v7)
1-hive retired Kev, the operator Andy's decision. 1-hive's goals kev-value and kev-gpu measured it on both hives:
in shadow it never changed a routing decision, and on VM2 it can't, because the fixed facts in agents.yaml
(verification none, consequence costly) put every episode at strong. All 579 successful readings here were
strong -> strong, and 62 of 641 failed on the network path. 1-hive has closed kev-gate and its Funnel URL.
- `deploy/route-table.yaml` **v7**: no `reader:`, no route `kev-1hive`, no pool `onehive-kev`. No episode text
  leaves VM2 for a reader any more. The four work routes and their pins are unchanged. v6 is kept as
  `route-table.yaml.pre-retire-kev-20261115`.
- The reader's egress is gone, removed by the operator with 1-hive's `deploy/retire-kev.sh`: the
  `hive-route-egress-refresh.timer` (disabled), the drop-in `reader.conf`, `/etc/hive-route/reader.env` (the
  gate key, dead now) and the nft table `inet hive_route_egress`. hive-route-serve is back to its original
  sandbox: the Docker bridge only. `serve-egress-*.sh`, `serve-egress.nft` and the timer's unit files stay
  as history.
- `/health` no longer reports a reader, so `hive-route-health-watch` has nothing to warn about.
- To bring a reader back: a new table version with the route and `reader:`, and the egress steps above,
  run by the operator.
NOTE
  echo "README updated"
fi
EOF

step "3/5 here: close the public Funnel URL"
if tailscale funnel status 2>/dev/null | grep -q '127.0.0.1:8010'; then
  tailscale funnel --https=443 off 2>/dev/null || sudo tailscale funnel --https=443 off
fi
tailscale funnel status 2>&1 | head -5

step "4/5 here: retire kev-gate"
systemctl --user disable --now kev-gate.service 2>&1 || true
rm -f ~/.config/hive/kev-gate.key ~/.config/hive/kev-gate.sha256
if ss -ltn | grep -q '127.0.0.1:8010 '; then echo "something still listens on 127.0.0.1:8010" >&2; exit 1; fi
echo "kev-gate stopped and disabled; key and hash deleted"

step "5/5 here: stop Kev"
systemctl --user disable --now kev.service 2>&1 || true
sleep 3
nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader
echo
echo "Kev is retired. ~/opt/kev and ~/opt/kev/runs/reader-ft-v1 stay on disk."
