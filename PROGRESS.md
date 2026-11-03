# One Hive progress

_Updated 2026-10-31. Last shared: never._

Where One Hive's releases stand, and what the proto-hive (Ben's hive, the first one that isn't ours) has built for itself. [`PLAN.md`](PLAN.md) has the detail. The release plan counts a release done only when a hive other than the development team's runs it.

## Releases

| Release | What | Status | Evidence | Next |
|---|---|---|---|---|
| R0 | Pins | **Done** | `hive-pin` v2.0.0 (pin format v2) | — |
| R1 | The record: log, gateway, fold | **Done, adopted** | `hive-record` v1.4.0, spec v1.0-a6; proto-hive authoritative since 2026-10-22; [adoption note](https://github.com/1-hive/hive-record/blob/main/docs/adoption/proto-hive.md) | Mirror adapter only if a hive wants to mirror |
| R2 | Legality table, review-gated close | **Done, adopted** | Failure suite green in CI; proto-hive closes only after Astra passes a result | — |
| R3 | Projections (read-only views) | Partial, 1-hive form | The Floor (`hive-bridge`) is a read-only board; runs on 1-hive and the proto-hive | Atomspace/OmegaClaw view not started |
| R4 | Skills | Not started | — | — |
| R5 | Review verdicts, independent review | Minimal form | `review.recorded` events; Astra reviews proto-hive work on another model | Model-diversity rule deferred (PLAN §9) |
| R6 | Worker runtime | Minimal form | `hive-runtime` v0.5.23: launcher, dispatcher, supervisor; Iter sidecars for long-lived bots | Context capture (D17) for new runtime work |
| R7 | Humans and agents talking | Partial | `hive-bridge` v0.5.12: Telegram bridge, chief of staff, work group; dialogue log outside the record | `message.*` events (the logging half) deferred |
| R8 | Routing, canaries | Built, 1-hive only | `hive-route` runs live on 1-hive | Adoption by another hive |
| R9 | Replay, shadow trials | Not started | — | Needs context capture (D17) |
| R10 | Writable shared memory | Not started | — | — |

## What the proto-hive built itself

Each row is a task one of the proto-hive's bots did, which Astra reviewed and the chief of staff closed. Generated from its record by `tools/proto-hive-progress.sh --write`; don't edit by hand.

<!-- proto-hive:begin -->
12 tasks closed after an independent review; 0 open. Record position 320 (2026-10-28T16:48Z).

| Closed | Project | Task | Bot | Reviews | Code |
|---|---|---|---|---|---|
| 2026-10-23 | hive-appliance | README: add a top line saying work is tracked on the proto-hive record | protomegabot2 | 2 | `hive-appliance@988f57b` |
| 2026-10-23 | hive-appliance | One consolidated, downloadable markdown summary of hive-appliance (for Charlie) | protomegabot2 | 5 | [#1](https://github.com/bgoertzel-sing/hive-appliance/pull/1) merged |
| 2026-10-24 | hive-appliance | One-page overview: hive-appliance vs the One Hive proposal | protocosmo | 3 | — |
| 2026-10-27 | iter | Iter bots cite the Telegram message (telegram:<chat>/<msg>) when they propose | protomegabot2 | 2 | [#1](https://github.com/bgoertzel-sing/iter/pull/1) merged |
| 2026-10-28 | iter | Deploy the merged cite fix (protomega 0f8774e) to ProtoMegaBot2's live tree | protomegabot2 | 2 | — |
| 2026-10-28 | iter | Apply the merged cite fix (protomega 0f8774e) to ProtomegaTron's live tree | protomegatron | 3 | — |
| 2026-10-28 | iter | Check whether ProtoCosmo2's Iter channel shows the Telegram chat and message ids (report only) | protocosmopopos | 3 | — |
| 2026-10-28 | iter | Make iter's protomega branch shared by ProtomegaTron and ProtoMegaBot2 | protomegabot2 | 1 | [#2](https://github.com/bgoertzel-sing/iter/pull/2) merged |
| 2026-10-28 | iter | Apply the reviewed cite fix to ProtoCosmo2's live Iter (pop-os) | protocosmopopos | 3 | — |
| 2026-10-28 | iter | Put per-bot transformation files (dashboard*.py, .runtime/) in protomega's shared .gitignore | protomegatron | 1 | [#3](https://github.com/bgoertzel-sing/iter/pull/3) merged |
| 2026-10-28 | wmtm | wmtm README: section listing every flag in memory/_wmtm_flags.json | protocosmo2 | 7 | [#1](https://github.com/bgoertzel-sing/wmtm/pull/1) merged |
| 2026-10-28 | wmtm | wmtm test: README flags section matches runtime_config.SPEC | protocosmo2 | 3 | `wmtm@30a1916` |
<!-- proto-hive:end -->

## Log

Newest first. One line per milestone; an update to share is the lines since "Last shared".

- 2026-10-31: 1-hive's SOTA/XMage research task finally started. Its order had an invalid route value, so every launch was refused for 30 hours and only the journal showed it. A refused launch now reaches the chief of staff (hive-runtime v0.5.23, on 1-hive).
- 2026-10-28: ProtoCosmo2 back after five days cut off; its wmtm README flags task went through review, publishing and a merge. Bots can no longer push to Ben's repos outside review.
- 2026-10-27: First proto-hive code change merged upstream (iter #1: bots cite the Telegram message).
- 2026-10-23: The proto-hive's Floor goes live on vm2.
- 2026-10-22: The proto-hive adopts R1 + R2, authoritative from the start: the first release counted done.
- 2026-10-14: 1-hive's operating loop meets its exit criteria.
