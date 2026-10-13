#!/usr/bin/env bash
# Back up what 1-hive can't rebuild from GitHub: the record, the local git remotes, and the keys.
#
#   deploy/backup.sh            one backup now (the 1-hive-backup timer runs it daily)
#
# Each backup is a dated folder under $HIVE_BACKUP_DIR (default ~/.local/share/1-hive/backups):
# - record.jsonl   the whole log (`hive export`), re-verified; restore with `hive restore`
# - <repo>.bundle  every ref of each local git remote ($HIVE_BACKUP_REPOS, default ~/repos/*.git);
#                  restore with `git clone --mirror <repo>.bundle <repo>.git`
# - config.tar     $HIVE_CONFIG_DIR: actor keys, database secrets, route overrides (secret: mode 600)
# The last $HIVE_BACKUP_KEEP (default 14) are kept. A copy on the same disk doesn't survive a
# disk failure: set $HIVE_BACKUP_REMOTE (an rsync target, e.g. user@host:backups/1-hive) in
# hive.env to mirror the folder to another machine after each backup.
source "$(dirname "$0")/lib.sh"
umask 077
DEST=${HIVE_BACKUP_DIR:-$HOME/.local/share/1-hive/backups}
KEEP=${HIVE_BACKUP_KEEP:-14}
OUT="$DEST/$HIVE_ID-$(date -u +%Y%m%dT%H%M%SZ)"
mkdir -p "$OUT.partial"

log "record"
hive export --db-url "$(role_url reader)" > "$OUT.partial/record.jsonl"
hive verify-log --registry "$REGISTRY" "$OUT.partial/record.jsonl" >/dev/null \
  || { echo "the exported log did not re-verify; backup kept as $OUT.partial" >&2; exit 1; }

log "git remotes"
for r in ${HIVE_BACKUP_REPOS:-$HOME/repos/*.git}; do
  [ -d "$r" ] || continue
  git -C "$r" bundle create -q "$OUT.partial/$(basename "$r" .git).bundle" --all
done

log "config and keys"
tar -C "$(dirname "$HIVE_CONFIG_DIR")" -cf "$OUT.partial/config.tar" "$(basename "$HIVE_CONFIG_DIR")"

mv "$OUT.partial" "$OUT"
ls -1d "$DEST/$HIVE_ID"-*Z 2>/dev/null | head -n -"$KEEP" | xargs -r rm -rf
log "backup $OUT ($(du -sh "$OUT" | cut -f1))"

if [ -n "${HIVE_BACKUP_REMOTE:-}" ]; then
  log "copy to $HIVE_BACKUP_REMOTE"
  rsync -a --delete --exclude '*.partial' "$DEST/" "$HIVE_BACKUP_REMOTE/"
fi
