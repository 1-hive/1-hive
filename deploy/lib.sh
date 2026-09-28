# Shared helpers for the 1-hive deploy scripts. Source it; don't run it.
set -euo pipefail
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
set -a; source "$DEPLOY_DIR/hive.env"; set +a
REGISTRY="$DEPLOY_DIR/registry.json"
PG_ENV="$HIVE_CONFIG_DIR/1-hive-pg.env"          # superuser password (secret)
DB_SECRETS="$HIVE_CONFIG_DIR/1-hive-db.json"     # role passwords (secret)
PGPASS="$HIVE_CONFIG_DIR/1-hive.pgpass"          # libpq password file (secret)
POLICY_PIN="$HIVE_CONFIG_DIR/1-hive-policy.pin"
UNIT=1-hive-gateway.service
export HIVEPIN_REPOSITORY_REGISTRY_PATH="$REGISTRY" PGPASSFILE="$PGPASS"
export HIVE_URL="http://127.0.0.1:$HIVE_GATEWAY_PORT"
compose() { podman-compose -f "$DEPLOY_DIR/compose.yml" -p 1-hive "$@"; }
role_url() { echo "postgresql://${HIVE_DB_PREFIX}_$1@127.0.0.1:$HIVE_DB_PORT/$HIVE_DB"; }
log() { printf '== %s\n' "$*"; }
