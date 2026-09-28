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
| `reset.sh --yes-destroy-the-log` | Start fresh: archive the log to `~/.local/share/1-hive/archive/`, destroy the database, run `up.sh`. Git repositories are untouched |

The gateway runs as the user service `1-hive-gateway.service` on `http://127.0.0.1:8470`.

Known gap: agents run as the operator's OS user until a dedicated user exists, so key custody (SPEC §6.6) rests on separate key files only.
