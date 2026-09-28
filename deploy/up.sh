#!/usr/bin/env bash
# Bring 1-hive up from its declaration. Safe to re-run: each step is skipped if done.
source "$(dirname "$0")/lib.sh"
mkdir -p "$HIVE_CONFIG_DIR" && chmod 700 "$HIVE_CONFIG_DIR"

log "hive-record $HIVE_RECORD_REF (the hive and hive-pin commands)"
uv tool install -q --force --with-executables-from hivepin \
  "git+https://github.com/1-hive/hive-record@$HIVE_RECORD_REF"
SOURCE_COMMIT=$(git ls-remote https://github.com/1-hive/hive-record "refs/tags/$HIVE_RECORD_REF^{}" | cut -f1)

if [ ! -f "$PG_ENV" ]; then
  log "new Postgres superuser password"
  umask 077; printf 'POSTGRES_PASSWORD=%s\n' "$(openssl rand -hex 24)" > "$PG_ENV"
fi
log "database container"
compose up -d
until podman exec 1hive-pg pg_isready -U postgres -q; do sleep 1; done
sleep 2; until podman exec 1hive-pg pg_isready -U postgres -q; do sleep 1; done

if [ ! -f "$DB_SECRETS" ]; then
  log "roles and database"
  SU_PW=$(sed -n 's/^POSTGRES_PASSWORD=//p' "$PG_ENV")
  hive db-bootstrap --superuser-url "postgresql://postgres:$SU_PW@127.0.0.1:$HIVE_DB_PORT/postgres" \
    --db "$HIVE_DB" --prefix "$HIVE_DB_PREFIX" --secrets-file "$DB_SECRETS"
fi
( umask 077; python3 - "$DB_SECRETS" "$HIVE_DB_PORT" "$HIVE_DB" > "$PGPASS" <<'PY'
import json, sys
for role, pw in json.load(open(sys.argv[1])).items():
    print(f"127.0.0.1:{sys.argv[2]}:{sys.argv[3]}:{role}:{pw}")
PY
)

if [ ! -f "$POLICY_PIN" ]; then
  log "pin the policy tree at $HIVE_RECORD_REF"
  hive-pin mint hive-record policy --commit "$HIVE_RECORD_REF" --output "$POLICY_PIN"
fi

if [ -z "$(hive export --db-url "$(role_url reader)" 2>/dev/null | head -c1)" ]; then
  log "initialize hive $HIVE_ID ($HIVE_PROFILE, $HIVE_MODE)"
  hive init --admin-url "$(role_url admin)" --prefix "$HIVE_DB_PREFIX" --hive "$HIVE_ID" \
    --profile "$HIVE_PROFILE" --policy "$POLICY_PIN" --mode "$HIVE_MODE" --registry "$REGISTRY" \
    --operator-id "$OPERATOR_ID" --operator-key "$OPERATOR_KEY"
fi

log "gateway user service"
mkdir -p "$HOME/.config/systemd/user"
cat > "$HOME/.config/systemd/user/$UNIT" <<UNIT
[Unit]
Description=1-hive record gateway (hive-record $HIVE_RECORD_REF)
After=network.target

[Service]
Environment=PGPASSFILE=$PGPASS
Environment=HIVEPIN_REPOSITORY_REGISTRY_PATH=$REGISTRY
ExecStart=$HOME/.local/bin/hive gateway --db-url $(role_url gateway) --registry $REGISTRY --host 127.0.0.1 --port $HIVE_GATEWAY_PORT --source-commit $SOURCE_COMMIT
Restart=on-failure

[Install]
WantedBy=default.target
UNIT
systemctl --user daemon-reload
systemctl --user enable -q "$UNIT"
systemctl --user restart "$UNIT"
for _ in $(seq 30); do hive health >/dev/null 2>&1 && break; sleep 1; done
hive health
