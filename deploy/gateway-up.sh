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
# Provider API keys for metered pools, one KEY=value file each (e.g. anthropic-api.env), optional.
KEYFILES=$(ls "$CONF"/*-api.env 2>/dev/null || true)

echo "== database (container hive-gw-pg, 127.0.0.1:5434)"
if [ ! -f "$CONF/gateway-pg.env" ]; then
  ( umask 077; printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)" > "$CONF/gateway-pg.env" )
fi
podman-compose -f "$DEPLOY_DIR/gateway-compose.yml" -p hive-gw up -d >/dev/null
until podman exec hive-gw-pg pg_isready -U postgres -q; do sleep 1; done
PGPW=$(sed -n 's/^POSTGRES_PASSWORD=//p' "$CONF/gateway-pg.env")
grep -q '^LITELLM_DATABASE_URL=' "$CONF/gateway.env" || \
  printf 'LITELLM_DATABASE_URL=postgresql://postgres:%s@127.0.0.1:5434/litellm\n' "$PGPW" >> "$CONF/gateway.env"

echo "== LiteLLM $LITELLM (uv tool, with the Prisma client its database needs)"
TOOL=$(uv tool dir)/litellm
if ! "$TOOL/bin/python" -c "import litellm, importlib.metadata as m; assert m.version('litellm') == '$LITELLM'" 2>/dev/null; then
  uv tool install -q --force "litellm[proxy]==$LITELLM" --with prisma
fi
SCHEMA=$(ls "$TOOL"/lib/python3*/site-packages/litellm/proxy/schema.prisma)
( cd "$(dirname "$SCHEMA")" && PATH="$TOOL/bin:$PATH" "$TOOL/bin/prisma" generate --schema "$SCHEMA" >/dev/null )

echo "== config from the route table"
uv run -q --frozen --project /home/omegahive/repos/hive-route hive-route gateway-config \
  "$DEPLOY_DIR/route-table.yaml" > "$CONF/litellm.yaml"

echo "== user service $UNIT"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/$UNIT" <<UNITFILE
[Unit]
Description=Hive gateway (LiteLLM $LITELLM) for hive-route, loopback only
After=network-online.target

[Service]
EnvironmentFile=$CONF/singularity.env
EnvironmentFile=$CONF/gateway.env
$(for f in $KEYFILES; do echo "EnvironmentFile=$f"; done)
Environment=PATH=$TOOL/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$TOOL/bin/litellm --config $CONF/litellm.yaml --host 127.0.0.1 --port 4000
Restart=on-failure

[Install]
WantedBy=default.target
UNITFILE
systemctl --user daemon-reload
systemctl --user enable -q "$UNIT"
systemctl --user restart "$UNIT"
for _ in $(seq 120); do curl -s -o /dev/null -w '%{http_code}' 127.0.0.1:4000/health/liveliness | grep -q 200 && break; sleep 2; done
echo "== up: $(curl -s 127.0.0.1:4000/health/liveliness)"

echo "== budgets for metered pools (tag budgets, from the route table)"
GWKEY=$(sed -n 's/^HIVE_GATEWAY_KEY=//p' "$CONF/gateway.env")
uv run -q --frozen --project /home/omegahive/repos/hive-route hive-route gateway-config \
  "$DEPLOY_DIR/route-table.yaml" --budgets | jq -c '.[]' | while IFS= read -r b; do
  name=$(jq -r .name <<<"$b")
  r=$(curl -s -X POST 127.0.0.1:4000/tag/update -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' -d "$b")
  jq -e '.name // .tag.name // .message' <<<"$r" >/dev/null 2>&1 && grep -qv -i 'not found\|does not exist' <<<"$r" ||
    r=$(curl -s -X POST 127.0.0.1:4000/tag/new -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' -d "$b")
  echo "   $name: $(jq -c '{max_budget: ($b.max_budget), duration: ($b.budget_duration)}' --argjson b "$b" -n) $(jq -r '.message // .detail // "ok"' <<<"$r" | head -c 80)"
done
