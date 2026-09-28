#!/usr/bin/env bash
# Start 1-hive fresh: archive the old log, destroy the database, bring it up again.
# Only for bad data in the log or a format change. Git repositories are untouched.
source "$(dirname "$0")/lib.sh"
[ "${1:-}" = "--yes-destroy-the-log" ] || { echo "usage: $0 --yes-destroy-the-log"; exit 2; }
mkdir -p "$HIVE_ARCHIVE_DIR"
ARCHIVE="$HIVE_ARCHIVE_DIR/$HIVE_ID-$(date +%Y%m%dT%H%M%S).jsonl"
log "archive the log to $ARCHIVE"
hive export --db-url "$(role_url reader)" > "$ARCHIVE"
hive verify-log "$ARCHIVE" || echo "warning: the archived log did not fully re-verify"
log "stop the gateway and destroy the database"
systemctl --user stop "$UNIT" || true
compose down -v
rm -f "$DB_SECRETS" "$PGPASS" "$PG_ENV"
"$DEPLOY_DIR/up.sh"
log "done. Re-register actors: deploy/register-actors.sh (as the operator)"
