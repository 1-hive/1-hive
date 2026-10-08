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
| `~/.config/hive/route-overrides.json` (not in git) | The operator's standing route overrides (RT1) for workers, per task or goal: `{"tasks": {...}, "goals": {"<goal>": {"route_id", "reason", "by": "operator"}}}`. The launcher applies them; reviews never take one. `opus-max` (Opus 5.5, max effort) is in no tier, so only an override picks it |
| `review-allowlist.json` | Claude Code permissions for the `claude-code-allowlist` harness (`--permission-mode dontAsk`): what a reviewer on a self-hosted route may do, with no model judging its actions. Not a sandbox: `python3` and `podman` reach what the OS user can. Image reads are denied: the routes on this harness are text-only, and an image ends the attempt with an API error |
| `apply-registry.sh [reason]` | Move the running hive to `registry.json` (e.g. a newly registered repository) with a recorded `hive.registry_changed`, and restart the gateway to load it. Run by the operator |
| `agent-users.sh` | Run once with sudo: one OS user per agent actor (`hive-worker-claude-1`, …), each with its own sub-ids and lingering, plus the sudoers rule that lets the launcher start their containers (`/usr/local/bin/hive-agent-podman`) |
| `runtime` | Where agents run by default: `host` or `container` (`tools/launch-task.sh`, `ROUTE_RUNTIME` overrides) |
| `agent/` | The agent image `localhost/1hive-agent` (`agent/build.sh`): Ubuntu 24.04 with the host's current `claude`, `codex` and `uv`, `hive`/`hive-pin` at hive-record's tag, and nested Podman. Rebuild after upgrading a harness |
| `reset.sh --yes-destroy-the-log` | Start fresh: archive the log to `~/.local/share/1-hive/archive/`, destroy the database, run `up.sh`. Git repositories are untouched |

The gateway runs as the user service `1-hive-gateway.service` on `http://127.0.0.1:8470`. The supervisor (`tools/supervisor.py`) runs as `1-hive-supervisor.service`: it nudges silent workers, restarts dead or stalled ones with context generated from the record, and escalates to the chief of staff. A reviewer that ends without a verdict on a usage or quota limit (e.g. "out of credits") isn't escalated: the dispatcher relaunches it. Three kinds of escalation go to the operator instead, as interrupts (PLAN D15): a task that fails repeatedly (`repeated_failure`), a result whose reviewer hit a usage limit three times (`other`), and an active goal past its budget (`goal.escalated`, `budget_exceeded`; wall clock counts from approval). Everything it does is recorded under the actor `supervisor`. Logs: `journalctl --user -u 1-hive-supervisor`.

The dispatcher (`tools/dispatcher.py`) runs as `1-hive-dispatcher.service`, as actor `dispatcher` (class coordinator, its own key). It starts every agent the record calls for, with kickoffs written from the record:
- **Workers.** A task assigned to a worker is launched once, with no attempt by hand. A blocked task answered since its block (`task.answered`) is relaunched once to read the answer and continue; restarts stay with the supervisor.
- **Reviews.** When a task's current result has no reviewer, it emits `review.assigned` and launches the reviewer. It tries `reviewer.codex.1` first, then `reviewer.claude.1`, never the result's author. If the router has no route for either, it retries every 10 minutes. An assigned reviewer whose launch failed, or whose process hit a usage limit, is relaunched (`ROUTE_LAST_CLASS=capacity`): the launcher holds that pool for the task until the provider's reset, or for an hour when none is known (`ROUTE_CAPACITY_HOLD`), so the router picks another pool or waits. Closing a reviewed task stays with the chief of staff. Logs: `journalctl --user -u 1-hive-dispatcher`.

The Telegram bridge (`tools/telegram-bridge.py`) runs as `1-hive-telegram.service`. Free text goes to the chief of staff (`cos.sh chat`) on its own thread, one message at a time, stopped after 15 minutes; buttons keep working meanwhile. Each `goal.approved` (Telegram or `op`), each escalation to the chief of staff and each passed review is passed to it as a chat message, so it acts unprompted; its reply reaches you in the chat. It pushes the operator's inbox: goals to approve or accept, and escalations to the operator. It also sends a **daily digest at 08:00 local time** (`--digest-at`), and `/digest` sends one on request. Each digest names the time of the next one, so a digest that doesn't arrive is the alarm. When a task is done (closed or cancelled), a one-line note comes without buttons (`--no-feed` turns them off). Logs: `journalctl --user -u 1-hive-telegram`. `/board` there lists open goals and tasks with what each agent is doing now, from the Floor.

The Floor (`tools/floor.py`, page `tools/floor/index.html`) runs as `1-hive-floor.service` on `http://127.0.0.1:8476`: a read-only live board. Goals as lanes with their wall-clock budget, tasks moving through queued, working, in review and closed, and the record as a strip of cells, one per event, that you drag to see the board at any position (the gateway's own fold, `GET /v1/state?at=`). It reads the record as actor `floor` (class instrument, its own key `~/.config/hive/floor.key`), which never emits. What each agent is doing (last tool call, activity in the last hour, quiet time, model, a task in review whose reviewer never started) comes from each attempt's log in its task folder (`worker-N.jsonl`, `review-N.jsonl`, `codex-N.log`) and `.route/<task>/*.attempt.json`; it is never authoritative. Loopback only: on the phone, use `/board`. Logs: `journalctl --user -u 1-hive-floor`.

**Container runtime** (PLAN Phase E 1; the default since 2026-10-06, goal `container-pilot`). With `runtime` set to `container`, each attempt runs in its own rootless Podman container (`hive-<task>-<role>-<n>`, removed when it ends). The container gets:
- the task's folder, at the same path;
- this actor's record key and git key, read-only;
- the harness's credentials. For Claude Code this is `~/.config/hive/claude-oauth-token`, made with `claude setup-token`, never the operator's own login. For Codex it is the shared `~/.codex` login.

It has no route to the host's loopback: the record, the model gateway and sshd reach it through Unix sockets (`tools/agent-ports.py`, user service `1-hive-agent-ports`, in `~/work/1hive/.ports`, which only group `hive` may enter). The image's `hive-entry` relays them to the same ports on the container's own loopback. Nothing else on the host is reachable, the record's Postgres included. Git goes over SSH as the actor: `tools/git/hive-git-shell` is the key's forced command, and the repositories' `pre-receive` hook lets agents create or fast-forward only `hive/*` branches and the workspace's `main`. No deletions, rewrites or tags. The agent runs as container root, which is the operator's user on the host, so it can run nested Podman for games. That includes bridge networks like the human-play sandbox's, which need `NET_ADMIN` and `SYS_ADMIN` over the container's own namespaces; rootless, these give nothing beyond the operator's user on the host. The supervisor stops a container by name (`podman stop`). One-time operator setup: `tools/git/install.sh` (hooks, per-agent SSH keys in `authorized_keys`), `deploy/agent/build.sh`, `claude setup-token` saved to `~/.config/hive/claude-oauth-token`.

**Agent users** (`deploy/agent-users.sh`, since 2026-10-06). Each actor has its own OS user (`hive-worker-claude-1`, …), and its containers run in that user's rootless Podman (`sudo -u <user> /usr/local/bin/hive-agent-podman`). An agent that escapes its container is that unprivileged user: it can't read the operator's files, other agents' keys or other tasks' folders. In detail:
- **Keys and settings** reach the container as that user's Podman secrets, per attempt: the record key, the git key, `known_hosts`, the review allow-list, and the Claude token.
- **Task folders:** the launcher grants the user only that task's folder (ACLs, which keep the operator's access too).
- **Codex:** each Codex actor needs its own login, once. As the operator, run `sudo -u hive-reviewer-codex-1 /usr/local/bin/hive-agent-podman run --rm -it --network host -v /var/lib/1hive-agents/hive-reviewer-codex-1/.codex:/root/.codex localhost/1hive-agent:latest codex login`, then open the URL it prints.
  - If the browser is on another device, the final redirect to `localhost:1455` fails there. Copy that whole address and run `curl '<address>'` on this machine while the login waits. Keep the quotes, so `&state=` survives.
  - Use `codex login --device-auth` instead if the account allows device codes.
- **The image** is copied into each user's storage when it changes.

Without an agent user, the launcher falls back to the operator's Podman and the operator's Codex login.

**Route facts.** Every work order states its task's facts on a line of its own, which `tools/launch-task.sh` passes to the router: `Route facts: specification=explicit verification=independent scope=few consequence=reversible leverage=0`. Any fact may be `unknown` (it then takes the costly default). A new task whose order has no such line is refused at launch (`ROUTE_FACTS=none` launches it without facts on purpose), because without facts every task runs on the strong tier. Restarts and reviews reuse the facts; a worker's checkpoint may change `specification` and `scope` (worker contract). What each fact means: hive-route ADOPTING.md §4, "Facts".

**Scorers** (table version 15). For a task with unknown facts, the router's scorers estimate them from the order's text and log their estimates (shadow mode: never used). Two scorers run, both as user services on loopback:
- `qwen-local`: Qwen 8B on `ollama.service`, port 11434.
- `kev-4b`: Kev-4B 1.0, a self-hosted decision model with the System One API, on `kev.service`, port 8009. It's installed in `~/opt/kev`. CUDA graphs and the prefix cache are off so it stays under about 10 GB of GPU memory, next to Ollama. Any local process may call it.

Compare them with `hive-route scorer-eval deploy/route-table.yaml <hive-route>/fixtures/scorer/suite.jsonl --workspace ~/repos/hive-workspace.git --commit <the suite's commit>`.

**Review tiers.** A review runs at least at the author's tier (router rule F7). For a high-stakes task, the order can ask for more with a line `Review tier: strong`; `tools/launch-task.sh` passes it to the router as a hint, which can only raise the tier. The review-only route `sc-deepseek-v4` (standard) then can't take it.

**Canaries.** `canaries/reviews/` is 1-hive's own review suite (cases from past reviews with known verdicts); run it with `hive-route canary run deploy/route-table.yaml <route> --suite canaries/reviews --sources deploy/route-sources.yaml --log ~/work/1hive/route-log.jsonl`.
