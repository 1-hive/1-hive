#!/usr/bin/env bash
# The hive gateway (hive-route ROUTING.md §8): LiteLLM on 127.0.0.1:4000, for routes with
# via_gateway (SingularityCompute) and the local model. Safe to re-run: regenerates the config
# from the route table and restarts the service.
#
# Secrets stay in ~/.config/hive: gateway.env (the gateway's key, created here) and
# singularity.env (SINGULARITY_API_KEY). The config holds only os.environ/ references.
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF=$HOME/.config/hive
LITELLM=1.103.0          # pinned; re-run the canaries after changing it
UNIT=hive-llm-gateway.service
mkdir -p "$CONF" && chmod 700 "$CONF"

if [ ! -f "$CONF/gateway.env" ]; then
  echo "== new gateway key"
  K="sk-hive-$(openssl rand -hex 24)"   # systemd's EnvironmentFile doesn't expand, so the key is written twice
  ( umask 077; printf 'HIVE_GATEWAY_KEY=%s\nLITELLM_MASTER_KEY=%s\n' "$K" "$K" > "$CONF/gateway.env" ); unset K
fi
[ -f "$CONF/singularity.env" ] || { echo "missing $CONF/singularity.env (SINGULARITY_API_KEY=...)" >&2; exit 2; }

echo "== config from the route table"
uv run -q --frozen --project /home/omegahive/repos/hive-route hive-route gateway-config \
  "$DEPLOY_DIR/route-table.yaml" --no-database > "$CONF/litellm.yaml"

echo "== user service $UNIT"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/$UNIT" <<UNITFILE
[Unit]
Description=Hive gateway (LiteLLM $LITELLM) for hive-route, loopback only
After=network-online.target

[Service]
EnvironmentFile=$CONF/singularity.env
EnvironmentFile=$CONF/gateway.env
ExecStart=$HOME/.local/bin/uvx --from litellm[proxy]==$LITELLM litellm --config $CONF/litellm.yaml --host 127.0.0.1 --port 4000
Restart=on-failure

[Install]
WantedBy=default.target
UNITFILE
systemctl --user daemon-reload
systemctl --user enable -q "$UNIT"
systemctl --user restart "$UNIT"
for _ in $(seq 60); do curl -s -o /dev/null -w '%{http_code}' 127.0.0.1:4000/health/liveliness | grep -q 200 && break; sleep 2; done
echo "== up: $(curl -s 127.0.0.1:4000/health/liveliness)"
