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
| `runtime` | Where agents run by default: `host` or `container` (`tools/launch-task.sh`, `ROUTE_RUNTIME` overrides) |
| `agent/` | The agent image `localhost/1hive-agent` (`agent/build.sh`): Ubuntu 24.04 with the host's current `claude`, `codex` and `uv`, `hive`/`hive-pin` at hive-record's tag, and nested Podman. Rebuild after upgrading a harness |
| `reset.sh --yes-destroy-the-log` | Start fresh: archive the log to `~/.local/share/1-hive/archive/`, destroy the database, run `up.sh`. Git repositories are untouched |

The gateway runs as the user service `1-hive-gateway.service` on `http://127.0.0.1:8470`. The supervisor (`tools/supervisor.py`) runs as `1-hive-supervisor.service`: it nudges silent workers, restarts dead or stalled ones with context generated from the record, and escalates to the chief of staff. Two kinds of escalation go to the operator instead, as interrupts (PLAN D15): a task that fails repeatedly (`repeated_failure`), and an active goal past its budget (`goal.escalated`, `budget_exceeded`; wall clock counts from approval). Everything it does is recorded under the actor `supervisor`. Logs: `journalctl --user -u 1-hive-supervisor`.

The Telegram bridge (`tools/telegram-bridge.py`) runs as `1-hive-telegram.service`. It pushes the operator's inbox: goals to approve or accept, and escalations to the operator. It also sends a **daily digest at 08:00 local time** (`--digest-at`), and `/digest` sends one on request. Each digest names the time of the next one, so a digest that doesn't arrive is the alarm. Nothing else is pushed. Logs: `journalctl --user -u 1-hive-telegram`.

**Container runtime** (PLAN Phase E 1). With `runtime` set to `container`, each attempt runs in its own rootless Podman container (`hive-<task>-<role>-<n>`, removed when it ends). The container gets:
- the task's folder, at the same path;
- this actor's record key and git key, read-only;
- the harness's credentials. For Claude Code this is `~/.config/hive/claude-oauth-token`, made with `claude setup-token`, never the operator's own login. For Codex it is the shared `~/.codex` login.

It reaches the record, the model gateway and sshd at 10.0.2.2, the host's loopback. Git goes over SSH as the actor: `tools/git/hive-git-shell` is the key's forced command, and the repositories' `pre-receive` hook lets agents create or fast-forward only `hive/*` branches and the workspace's `main`. No deletions, rewrites or tags. The agent runs as container root, which is the operator's user on the host, so it can run nested Podman for games. That includes bridge networks like the human-play sandbox's, which need `NET_ADMIN` and `SYS_ADMIN` over the container's own namespaces; rootless, these give nothing beyond the operator's user on the host. The supervisor stops a container by name (`podman stop`). One-time operator setup: `tools/git/install.sh` (hooks, per-agent SSH keys in `authorized_keys`), `deploy/agent/build.sh`, `claude setup-token` saved to `~/.config/hive/claude-oauth-token`.

Known gaps:
- Agents still run as the operator's OS user, inside containers or not, until a dedicated user exists. Key custody (SPEC §6.6) therefore rests on what each container mounts.
- A container reaches every host loopback port, including the record's Postgres, which still needs its password.
- Codex agents share the operator's Codex login directory.

**Route facts.** Every work order states its task's facts on a line of its own, which `tools/launch-task.sh` passes to the router: `Route facts: specification=explicit verification=independent scope=few consequence=reversible leverage=0`. Any fact may be `unknown` (it then takes the costly default). A new task whose order has no such line is refused at launch (`ROUTE_FACTS=none` launches it without facts on purpose), because without facts every task runs on the strong tier. Restarts and reviews reuse the facts; a worker's checkpoint may change `specification` and `scope` (worker contract). What each fact means: hive-route ADOPTING.md §4, "Facts".

**Review tiers.** A review runs at least at the author's tier (router rule F7). For a high-stakes task, the order can ask for more with a line `Review tier: strong`; `tools/launch-task.sh` passes it to the router as a hint, which can only raise the tier. The review-only route `sc-deepseek-v4` (standard) then can't take it.

**Canaries.** `canaries/reviews/` is 1-hive's own review suite (cases from past reviews with known verdicts); run it with `hive-route canary run deploy/route-table.yaml <route> --suite canaries/reviews --sources deploy/route-sources.yaml --log ~/work/1hive/route-log.jsonl`.
