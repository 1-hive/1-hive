# 1-hive deployment

Everything needed to rebuild 1-hive's record. Secrets and private keys live in `~/.config/hive/`, never here.

| File | What |
|---|---|
| `hive.env` | Settings: hive id, profile, mode, ports, the hive-record version, the operator's **public** key |
| `registry.json` | hivepin repository registry: hive-record (policy), the workspace, mtg-player |
| `compose.yml` | The record's Postgres (container `1hive-pg`, loopback port 5433) |
| `actors.json` | The agent actors, with **public** keys only |
| `up.sh` | Bring 1-hive up; every step is skipped when already done |
| `register-actors.sh` | Register new actors from `actors.json`. Run by the operator; signs with `~/.config/hive/operator.key` |
| `apply-policy.sh [reason]` | Move the running hive to the policy at `HIVE_RECORD_REF` with a recorded `hive.policy_changed`. Run by the operator |
| `route-table.yaml`, `route-sources.yaml` | The router's table (routes, pools, tiers) and its sources (usage readers, harness commands, the qualifications file) |
| `review-allowlist.json` | Claude Code permissions for the `claude-code-allowlist` harness (`--permission-mode dontAsk`): what a reviewer on a self-hosted route may do, with no model judging its actions. Not a sandbox: `python3` and `podman` reach what the OS user can |
| `apply-registry.sh [reason]` | Move the running hive to `registry.json` (e.g. a newly registered repository) with a recorded `hive.registry_changed`, and restart the gateway to load it. Run by the operator |
| `reset.sh --yes-destroy-the-log` | Start fresh: archive the log to `~/.local/share/1-hive/archive/`, destroy the database, run `up.sh`. Git repositories are untouched |

The gateway runs as the user service `1-hive-gateway.service` on `http://127.0.0.1:8470`. The supervisor (`tools/supervisor.py`) runs as `1-hive-supervisor.service`: it nudges silent workers, restarts dead or stalled ones with context generated from the record, and escalates to the chief of staff. Everything it does is recorded under the actor `supervisor`. Logs: `journalctl --user -u 1-hive-supervisor`.

Known gap: agents run as the operator's OS user until a dedicated user exists, so key custody (SPEC §6.6) rests on separate key files only.

**Review tiers.** A review runs at least at the author's tier (router rule F7). For a high-stakes task, the order can ask for more with a line `Review tier: strong`; `tools/launch-task.sh` passes it to the router as a hint, which can only raise the tier. The review-only route `sc-deepseek-v4` (standard) then can't take it.

**Canaries.** `canaries/reviews/` is 1-hive's own review suite (cases from past reviews with known verdicts); run it with `hive-route canary run deploy/route-table.yaml <route> --suite canaries/reviews --sources deploy/route-sources.yaml --log ~/work/1hive/route-log.jsonl`.
