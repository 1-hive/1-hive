# One Hive progress

_Updated 2026-11-10. Last shared: never._

Where One Hive's releases stand, and what the proto-hive (Ben's hive, the first one that isn't ours) has built for itself. [`PLAN.md`](PLAN.md) has the detail. The release plan counts a release done only when a hive other than the development team's runs it.

## Releases

| Release | What | Status | Evidence | Next |
|---|---|---|---|---|
| R0 | Pins | **Done** | `hive-pin` v2.0.0 (pin format v2) | — |
| R1 | The record: log, gateway, fold | **Done, adopted** | `hive-record` v1.4.0, spec v1.0-a6; proto-hive authoritative since 2026-10-22; [adoption note](https://github.com/1-hive/hive-record/blob/main/docs/adoption/proto-hive.md) | Mirror adapter only if a hive wants to mirror |
| R2 | Legality table, review-gated close | **Done, adopted** | Failure suite green in CI; proto-hive closes only after Astra passes a result | — |
| R3 | Projections (read-only views) | Partial, 1-hive form | The Floor (`hive-bridge`) is a read-only board; runs on 1-hive and the proto-hive | Atomspace/OmegaClaw view not started |
| R4 | Skills | Not started | — | — |
| R5 | Review verdicts, independent review | **Built, adopted** | The review the close gate requires: an independent reviewer on another model, its verdict recorded as `review.recorded`; both hives use it (the proto-hive through Astra, Fable and Sol). Since `hive-runtime` v0.5.56 a 1-hive worker waits for the verdict in its own session and fixes a failed review there; `op review` asks for one by hand. [Review contract](https://github.com/1-hive/hive-runtime/blob/main/docs/review-contract.md) | Measure: share of tasks passing their first review, reviews per closed task, repeated findings |
| R6 | Worker runtime | Minimal form | `hive-runtime` v0.5.59: launcher, dispatcher, supervisor (`op restart` gives a task it gave up on a fresh attempt); Iter and OpenClaw sidecars for long-lived bots; reviews routed by tier to long-lived reviewers; a second model account when one hits its limit; files attached to an order reach the agent | Context capture (D17) for new runtime work |
| R7 | Humans and agents talking | Partial | `hive-bridge` v0.5.41: Telegram bridge, chief of staff, work group, decision cards answered by tapping; files people send reach the chief of staff (PDFs with a text copy), and it sends files and chat transcripts back; dialogue log outside the record | `message.*` events (the logging half) deferred |
| R8 | Routing, canaries | Built; review routing adopted | `hive-route` runs live on 1-hive; rev 21 routes the proto-hive's reviews by tier to its long-lived reviewers (Astra, Fable, Sol) since 2026-11-05 | Work routing on another hive |
| R9 | Replay, shadow trials | Not started | — | Needs context capture (D17) |
| R10 | Writable shared memory | Not started | — | — |

## What the proto-hive built itself

Each row is a task one of the proto-hive's bots did, which Astra reviewed and the chief of staff closed. Generated from its record by `tools/proto-hive-progress.sh --write`; don't edit by hand.

<!-- proto-hive:begin -->
52 tasks closed after an independent review; 16 open. Record position 1844 (2026-11-09T22:48Z).

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
| 2026-10-28 | wmtm | wmtm test: README flags section matches runtime_config.SPEC | protocosmo2 | 3 | [#2](https://github.com/bgoertzel-sing/wmtm/pull/2) merged |
| 2026-10-28 | wmtm | Status of wmtm's goalchainer v2 migration on ProtoCosmo2, and its testing evidence (report only) | protocosmo2 | 4 | — |
| 2026-10-28 | wmtm | Check for newer public versions of Roman's pettachainer and ManHin's semantic parser (report only) | protocosmo2 | 3 | — |
| 2026-11-03 | wmtm | WMTM goal lifecycle (stable IDs, dedup, states) + rating export, log only | protocosmo2 | 11 | [#4](https://github.com/bgoertzel-sing/wmtm/pull/4) merged |
| 2026-11-03 | wmtm | Evaluate rTreutlein/PeTTaChainer (49ca6f3) fitness for wmtm (report only) | protocosmo2 | 5 | — |
| 2026-11-04 | wmtm | PeTTaChainer migration: write up shims, open items and options from existing work; commit shims (no more probing) | protocosmo2 | 5 | [#7](https://github.com/bgoertzel-sing/wmtm/pull/7) merged |
| 2026-11-04 | wmtm | Could GoalChainer take PeTTaChainer's core mechanisms natively instead of shims? Analysis (report only) | protocosmo2 | 5 | — |
| 2026-11-04 | wmtm | Track P / P2: WMTM adapter for Man Hin's template parser @ 1f1a7a6f + Anthropic provider PR | protomegabot2 | 8 | [#3](https://github.com/bgoertzel-sing/wmtm/pull/3) merged |
| 2026-11-04 | wmtm | Track P / P2: measure the new parser on 30+ real ProtoCosmo2 notes on pop-os (ids and numbers only) | protocosmopopos | 3 | — |
| 2026-11-05 | wmtm | Track P / P1: WMTM + GoalChainer on Roman's PeTTaChainer @ 202b9379 (242/242, end to end, repros upstream) | protocosmo2 | 7 | [#6](https://github.com/bgoertzel-sing/wmtm/pull/6) closed |
| 2026-11-05 | wmtm | Track P: Man Hin's seeded rules on Roman's PeTTaChainer @ 202b9379, failures and fork comparison (report for Man Hin) | protocosmopopos | 5 | — |
| 2026-11-05 | wmtm | Draft GitHub issues for Roman's PeTTaChainer: PC3/PC8, PY1-PY5, Man Hin-rule engine bugs (andy sends) | protocosmopopos | 2 | — |
| 2026-11-05 | wmtm | Track P / P3: join P1 + P2 and A/B-replay against live wmtm (deploy readiness) | protocosmo2 | 4 | [#6](https://github.com/bgoertzel-sing/wmtm/pull/6) closed |
| 2026-11-05 | mettadinc | MeTTaDinC E0: ingest docs and fixtures, structure the 8 milestones, pin and build Cetta (no implementation) | protocosmopopos | 1 | — |
| 2026-11-05 | mettadinc | Seed the mettadinc repository with E0's documents, milestone files and Ben's decisions | protocosmopopos | 1 | [#1](https://github.com/bgoertzel-sing/mettadinc/pull/1) merged |
| 2026-11-05 | mettadinc | MeTTaDinC M0 prerequisites: adopt the bundle registry patches, vendor Cetta @ 12da03b4, green-baseline harness | protocosmopopos | 1 | [#2](https://github.com/bgoertzel-sing/mettadinc/pull/2) closed |
| 2026-11-06 | wmtm | Track P / P4: wmtm on Roman's and Man Hin's latest code, parser facts chaining, A/B vs live (strong review) | protocosmo2 | 5 | [#8](https://github.com/bgoertzel-sing/wmtm/pull/8) closed |
| 2026-11-06 | wmtm | Track P / A v2: latest-upstream reruns; LIST-roman + LIST-manhin as a fork-vs-master gap map (carries over A's work) | protocosmopopos | 5 | — |
| 2026-11-06 | mettadinc | Redo m0-prep with CeTTa as a submodule pinned to 12da03b (no copied CeTTa in history); rerun the green baseline | protocosmopopos | 1 | [#3](https://github.com/bgoertzel-sing/mettadinc/pull/3) merged |
| 2026-11-06 | mettadinc | CeTTa at Zar's latest main: extension points, dialect vs native module, Mettapedia-dependent tests (report only; carries over cetta-latest) | protomegabot2 | 4 | — |
| 2026-11-06 | cettapack | CettaPack M1: guarded hot match kernel in CeTTa (PathMap narrowing + native seeded rematch), differential tests, benchmark with guards | protocosmopopos | 2 | [#1](https://github.com/bgoertzel-sing/cettapack/pull/1) merged |
| 2026-11-06 | mettadinc | MeTTaDinC: move the CeTTa submodule pin to Zar's latest main (4c285a97) and re-freeze the gcc green baseline | protocosmopopos | 2 | `mettadinc@476a79f` |
| 2026-11-06 | hive-ops | ProtoMegaBot2: user-space gcc/Rust toolchain on vm2; prove the CeTTa gcc baseline reproduces exactly | protomegabot2 | 1 | — |
| 2026-11-06 | hive-ops | ProtomegaTron: user-space gcc/Rust toolchain on vm2; prove the CeTTa gcc baseline reproduces exactly | protomegatron | 2 | — |
| 2026-11-06 | hive-ops | protocosmo: user-space gcc/Rust toolchain on vm2; prove the CeTTa gcc baseline reproduces exactly | protocosmo | 1 | — |
| 2026-11-06 | wmtm | Track P / P4 follow-up: note-free branch history, F7 as design, proof kind per answer, deploy flag vs Roman, review 3 loose ends | protocosmo2 | 3 | [#9](https://github.com/bgoertzel-sing/wmtm/pull/9) closed |
| 2026-11-06 | wmtm | Track P: proof makeup (derivation / antecedent completion / population prior, nested) per answer in the P4 A/B; reporting only | protocosmo2 | 1 | [#10](https://github.com/bgoertzel-sing/wmtm/pull/10) merged |
| 2026-11-06 | wmtm | Track P / F1: wmtm memory lifecycle and admission (Mesto review 1, 3, 4, 9, 11; drop MIN_CONFIDENCE; F7 both ways) | protocosmo2 | 2 | [#12](https://github.com/bgoertzel-sing/wmtm/pull/12) closed |
| 2026-11-06 | wmtm | Track P / F2: wmtm context and goals (Mesto review 5, 7, 10; stemmer) | protocosmopopos | 1 | [#11](https://github.com/bgoertzel-sing/wmtm/pull/11) closed |
| 2026-11-07 | wmtm | Track P: merge wmtm F1 + F2 into one tree; apply andy's 4 decisions (derive notes, source lookup, recent focus, ties as a choice) | protocosmo2 | 1 | [#13](https://github.com/bgoertzel-sing/wmtm/pull/13) merged |
| 2026-11-08 | mettadinc | Redo cetta-pin-latest (476a79f) with the chat id scrubbed from all history; Supersedes t-2026-11-06-mettadinc-cetta-pin-latest | protocosmopopos | 1 | [#4](https://github.com/bgoertzel-sing/mettadinc/pull/4) merged |
| 2026-11-08 | wmtm | Track P / F3 v3: answer v2 review 1 + andy's additions (inline §11, deploy line, criterion 5; native class-level check per dropped conclusion; is_derivation test) | protocosmo2 | 2 | [#15](https://github.com/bgoertzel-sing/wmtm/pull/15) merged |
| 2026-11-08 | wmtm | Rerun LIST-roman on PeTTaChainer master (vm2, renamed repros); reviewed GitHub issue drafts for what is still broken (andy files) | protocosmo | 1 | — |
| 2026-11-09 | mettadinc | MeTTaDinC M0 v2: continue the review-2 fixes from your folder (carries over t-2026-11-06-mettadinc-m0) | protomegabot2 | 2 | `mettadinc@5c91a95` |
| 2026-11-09 | wmtm | Roman issue drafts: rerun on PeTTaChainer b6aacc68, dedupe against #175-179, final paste-ready list (andy files) | protocosmo | 2 | — |
| 2026-11-09 | mettadinc | MeTTaDinC M0: rebase onto the scrubbed main (95e00d0) so it can publish; Supersedes t-2026-11-09-mettadinc-m0-v2 | protomegabot2 | 1 | [#5](https://github.com/bgoertzel-sing/mettadinc/pull/5) merged |
| 2026-11-09 | wmtm | wmtm B flat Inheritance v2: check parser coverage of the 2 notes first; if our KB build drops the statements, fix it so the 2 lost correct conclusions come back and (chat_send valid) doesn't | protocosmo2 | 1 | [#15](https://github.com/bgoertzel-sing/wmtm/pull/15) merged |
| 2026-11-09 | wmtm | wmtm live-path replay v3 (F3 criterion 5): carry over v2; plus why rule_goal_pool is 0 on parser 533c2274, and B through the live path on f44d7b74 | protocosmo2 | 1 | [#16](https://github.com/bgoertzel-sing/wmtm/pull/16) merged |
| 2026-11-09 | mettadinc | MeTTaDinC M0: fix Zar's Codex review findings F1-F6 (envelope binding, capacity, arithmetic, interfaces, obligations, composition) + CeTTa rerun | protomegabot2 | 2 | [#6](https://github.com/bgoertzel-sing/mettadinc/pull/6) merged |
| 2026-11-09 | wmtm | wmtm: prove and judge the 49-goal probe (B's code on A's legacy parse) vs A's 2C/2W | protocosmopopos | 1 | — |
| 2026-11-09 | wmtm | wmtm: deploy-split feasibility (F1/F2 live, new reasoner shadow only), code reading, report only | protocosmo | 1 | — |

Open: What wmtm would need to change to run on rTreutlein/PeTTaChainer: migration plan and options (report only) (protocosmo2); Create bgoertzel-sing/mettadinc and seed it with E0's documents and milestone files (protocosmopopos); Track P / A: rerun every known engine and parser repro on Roman's and Man Hin's latest code; two plain lists for andy (protocosmopopos); MeTTaDinC: move the Cetta host to zariuq main (4c285a97), re-freeze the green baseline, re-map extension points, dialect vs native-module recommendation (protomegabot2); CettaPack M1: guarded hot match kernel in CeTTa (PathMap narrowing + native seeded rematch), differential tests, benchmark with guards (unassigned); MeTTaDinC M0: strict certificate boundaries: native CeTTa module, claims E05/E08/E09/H08/H10/H12/C01-C03, negative acceptance suite (protomegabot2); Track P / F3: A/B rerun of the fixed wmtm (F1+F2 merged) vs live on pop-os: count rule + Mesto §11, budget, warm-up (protocosmo2); Track P / F3 v2: drop wmtm's generic rules (mem_inh, inh_trans, imp_trans) on the PeTTaChainer path, then F3 result 2 with B on the fixed commit (protocosmo2); Rerun LIST-roman R1-R8 on PeTTaChainer master; reviewed GitHub issue drafts for what is still broken (andy files) (protocosmopopos); wmtm B: emit flat Inheritance for class-level statements; F3's 2 lost correct conclusions come back, (chat_send valid) doesn't (protocosmo2); wmtm live-path replay before deploy (F3 criterion 5): sandbox turn loop with GoalChainer v2, A vs B, on b6aacc68; W1 by premise source notes (unassigned); wmtm live-path replay before deploy (F3 criterion 5): sandbox turn loop with GoalChainer v2, A vs B, on b6aacc68 (v2: W1 as in F3 v3) (protocosmo2); wmtm: parse normaliser (all parser shapes into one form, unrecognised shapes counted) + frozen parse caches; B before/after on 3 parses (protocosmo2); wmtm: same-version parse variance at Man Hin 533c2274 (two more parses of the 20 notes, counts only) (protocosmopopos); wmtm gap check against Ben's design doc: component table, §12 tests on synthetic data, usefulness of derived beliefs, Mesto's examples; ranked gaps + acceptance suite (protocosmo); wmtm split deploy (F1/F2 live, reasoner shadow): legacy vs catalog parse feed, sandbox comparison on frozen parses (protocosmopopos)
<!-- proto-hive:end -->

## Log

Newest first. One line per milestone; an update to share is the lines since "Last shared".

- 2026-11-10: R5's first real run on 1-hive (best-1b-fixes): the review failed on one skipped item, the worker fixed it in the same session and posted again a minute later, with no restart; it passed and closed 41 min after it started. A task the supervisor gave up on (repeated_failure) gets a fresh attempt from the operator: `op restart <task> [note]` or 🔁 Restart on the Telegram alert; before, the only way back was to cancel it and open a new task (hive-runtime v0.5.59, hive-bridge v0.5.41).
- 2026-11-09: R5 as the release plan defines it: a 1-hive worker waits for its independent review in its own session and fixes a failed one with its context, instead of being restarted; a review can be asked for by hand (`op review`); the review contract is written down (hive-runtime v0.5.56). Before it, 48 of 1-hive's 87 reviews and 97 of the proto-hive's 150 didn't pass.
- 2026-11-09: Files people send in Telegram reach the chief of staff (a PDF with a text copy), and it passes the ones a task needs to the worker with the order; a review too thin to show its checks, or re-assigned to the same reviewer, now runs again; a result posted while an escalation is open still gets its review; an agent that can't run gets one escalation instead of repeated nudges (hive-runtime v0.5.55, hive-bridge v0.5.37, both on 1-hive).
- 2026-11-08: A bot or reviewer whose model account runs out says so on the Floor and alerts the operators once, instead of looking idle; the chief of staff and OpenClaw gateways fall back to a second Claude account (hive-runtime v0.5.47, hive-bridge v0.5.33).
- 2026-11-06: Decision cards: a question for a human is a short card, answered by tapping a button in the chat; the Floor's "Needs you" is grouped (Decide, Fix, Merge).
- 2026-11-05: The proto-hive's reviews are routed by tier through hive-route rev 21, to three long-lived reviewers (Astra, Fable, Sol); a reviewer out of credits hands its reviews on. New repositories come from the hive by button (mettadinc first).
- 2026-11-03: 1-hive's route table v19 retires the unused Qwen scorer (Ollama) and, for security, the LiteLLM model gateway with every route through it (SingularityCompute, Anthropic API). Kev-4B stays as the shadow reader.
- 2026-10-31: 1-hive's SOTA/XMage research task finally started. Its order had an invalid route value, so every launch was refused for 30 hours and only the journal showed it. A refused launch now reaches the chief of staff (hive-runtime v0.5.23, on 1-hive).
- 2026-10-28: ProtoCosmo2 back after five days cut off; its wmtm README flags task went through review, publishing and a merge. Bots can no longer push to Ben's repos outside review.
- 2026-10-27: First proto-hive code change merged upstream (iter #1: bots cite the Telegram message).
- 2026-10-23: The proto-hive's Floor goes live on vm2.
- 2026-10-22: The proto-hive adopts R1 + R2, authoritative from the start: the first release counted done.
- 2026-10-14: 1-hive's operating loop meets its exit criteria.
