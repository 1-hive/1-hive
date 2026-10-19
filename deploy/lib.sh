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
# hive-runtime and hive-bridge, each a clean checkout at its pinned tag; the services run from there.
COMPONENTS=$HOME/.local/share/1-hive
RUNTIME=$COMPONENTS/hive-runtime BRIDGE=$COMPONENTS/hive-bridge
install_component() {  # install_component <repo name> <ref> <dir>
  local name=$1 ref=$2 dir=$3
  [ -d "$dir/.git" ] || git clone -q "https://github.com/1-hive/$name.git" "$dir"
  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    echo "$dir has local changes; it must stay a clean checkout of $name" >&2; return 1
  fi
  git -C "$dir" rev-parse -q --verify "refs/tags/$ref" >/dev/null || git -C "$dir" fetch -q --tags origin
  git -C "$dir" -c advice.detachedHead=false checkout -q "refs/tags/$ref"
}
