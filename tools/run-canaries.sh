#!/usr/bin/env bash
# Qualify 1-hive's routes on hive-route's starter canary suite (ROUTING.md §3).
# The two plans run in parallel, their routes in turn. Canaries draw on the same plans as
# live work, so each stops before a case once its pool is past MAX (default: 0.65 for the
# Claude plan, 0.70 for the ChatGPT plan). Results: ~/work/1hive/route-qualifications.json,
# route.canary_recorded in ~/work/1hive/route-log.jsonl, output in ~/work/1hive/canary/.
#
#   run-canaries.sh [route...]      # default: every route with a harness
set -uo pipefail
T=/home/omegahive/repos/1-hive/deploy/route-table.yaml
SRC=/home/omegahive/repos/1-hive/deploy/route-sources.yaml
LOG=$HOME/work/1hive/route-log.jsonl
SUITE=/home/omegahive/repos/hive-route/canaries/starter
hr() { uv run -q --frozen --project /home/omegahive/repos/hive-route hive-route "$@"; }
run() { local max=$1; shift; for r in "$@"; do
  echo "== $r $(date -u +%FT%TZ)"
  hr canary run "$T" "$r" --suite "$SUITE" --sources "$SRC" --log "$LOG" --max-usage "$max"
  echo "== $r exit $?"; done; }
if [ $# -gt 0 ]; then run "${MAX:-0.65}" "$@"; exit; fi
mkdir -p "$HOME/work/1hive/canary"
run "${MAX_CLAUDE:-0.65}" haiku-plan sonnet-plan opus-plan > "$HOME/work/1hive/canary/claude.txt" 2>&1 &
run "${MAX_CHATGPT:-0.70}" gpt-sol-low gpt-sol-plan gpt-sol-high > "$HOME/work/1hive/canary/codex.txt" 2>&1 &
wait
cat "$HOME/work/1hive/canary/claude.txt" "$HOME/work/1hive/canary/codex.txt" | grep -E '^(== |[a-z-]+: (qualified|candidate))'
