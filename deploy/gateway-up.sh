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

echo "== worker key (model calls only; the master key stays here for admin and spend reads)"
GWKEY=$(sed -n 's/^HIVE_GATEWAY_KEY=//p' "$CONF/gateway.env")
ALIASES=$(uv run -q --frozen --project /home/omegahive/repos/hive-route python -c '
import json, sys
from hiveroute.table import load_table
t = load_table(sys.argv[1])
# Only routes the router can choose (in a tier): a paused route is not callable with the worker key.
live = {r for ids in t.data["tiers"].values() for r in ids}
print(json.dumps(sorted(r for r, v in t.routes.items() if v.get("via_gateway") and r in live)))' "$DEPLOY_DIR/route-table.yaml")
WKEY=$(sed -n 's/^HIVE_WORKER_KEY=//p' "$CONF/gateway.env")
if [ -z "$WKEY" ]; then
  [ "$ALIASES" != "[]" ] || ALIASES='["no-live-routes"]'
  WKEY=$(curl -s -X POST 127.0.0.1:4000/key/generate -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' \
    -d "$(jq -n --argjson m "$ALIASES" '{key_alias: "hive-workers", models: $m, metadata: {purpose: "launched agents: model calls only"}}')" | jq -r '.key // empty')
  [ -n "$WKEY" ] || { echo "couldn't create the worker key" >&2; exit 3; }
  ( umask 077; printf 'HIVE_WORKER_KEY=%s\n' "$WKEY" >> "$CONF/gateway.env" )
else  # keep its model list in step with the table
  curl -s -X POST 127.0.0.1:4000/key/update -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' \
    -d "$(jq -n --arg k "$WKEY" --argjson m "$ALIASES" '{key: $k, models: $m}')" >/dev/null
fi
# LiteLLM reads an empty model list as "every model", so with no live gateway routes the key
# is blocked instead.
if [ "$ALIASES" = "[]" ]; then
  curl -s -X POST 127.0.0.1:4000/key/block -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' \
    -d "$(jq -n --arg k "$WKEY" '{key: $k}')" >/dev/null
  echo "   hive-workers: blocked (no live gateway routes)"
else
  curl -s -X POST 127.0.0.1:4000/key/unblock -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' \
    -d "$(jq -n --arg k "$WKEY" '{key: $k}')" >/dev/null
  echo "   hive-workers may call: $(jq -r 'join(", ")' <<<"$ALIASES")"
fi

echo "== budgets for metered pools (tag budgets, from the route table)"
uv run -q --frozen --project /home/omegahive/repos/hive-route hive-route gateway-config \
  "$DEPLOY_DIR/route-table.yaml" --budgets | jq -c '.[]' | while IFS= read -r b; do
  name=$(jq -r .name <<<"$b")
  r=$(curl -s -X POST 127.0.0.1:4000/tag/update -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' -d "$b")
  jq -e '.name // .tag.name // .message' <<<"$r" >/dev/null 2>&1 && grep -qv -i 'not found\|does not exist' <<<"$r" ||
    r=$(curl -s -X POST 127.0.0.1:4000/tag/new -H "Authorization: Bearer $GWKEY" -H 'Content-Type: application/json' -d "$b")
  echo "   $name: $(jq -c '{max_budget: ($b.max_budget), duration: ($b.budget_duration)}' --argjson b "$b" -n) $(jq -r '.message // .detail // "ok"' <<<"$r" | head -c 80)"
done
