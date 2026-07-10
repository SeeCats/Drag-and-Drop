# ADR-003: Effect machinery — event dispatch with event-side judgment

**Status:** Proposed (rev 3 — rev 1 flat hooks, rev 2 seam-tiered hooks; both superseded by
the owner's dispatch model + the BG3 comparison, same-week)
**Date:** 2026-07-07
**Deciders:** C (project owner)

## Context

ADR-002 deferred machinery to a proto pass. Three protos (skip_highest, swap_lock,
rotate_heal — evidence in `adr-003-proto-findings.md`) showed the duplication is
cross-cutting bookkeeping, not behavior. The owner then supplied the canonical stress case
(three relics: "green die rerolled → deal 4" + "reroll lowest at turn start" + "blue slot
always rerolls"), which proved instance-producing seams need ordered operations, reified
instances, and a react phase — and the owner's dispatch model resolved the remaining fork:
**the EVENT judges which relics apply** (relics declare what they care about as data; the
dispatch matches declarations), rather than relics judging internally or dispatch by
method-override.

Formative constraint, on record: the owner's reference for this architecture class is BG3,
where dispatch was easy and **forensics were hell** (event logs: huge, interleaved, silent
about non-matches). Forensics are therefore a day-one requirement, not polish.

Standing invariants (proto pass, carried as law):
- Reactions to player actions fire on **commit, never staging** (staged moves are cancelable
  → gesture-fired reactions are farmable).
- Effects touching HP/state outside the damage ledger **log their actual delta**.
- **Deterministic effects must feed the preview** (exactness pillar).

## Decision

**Registry:** `current_effect_list : Array[Effect]` on the controller (player-state owner).
`Effect` is a `Resource` (authored data, like `Pattern`/`MonsterResource`): `id` (log tag),
`duration` (0 = relic; >0 = status, ticks per planning phase, self-removes), **declared
trigger** (enum, one per proven seam — grown lazily), **declared conditions** (typed exported
fields, e.g. `condition_element : Element` — NO string DSL; BG3's runtime-parsed condition
strings fail silently on typos, exported enums fail at authoring time), and `effect(event)`
for the payload. Simple relics are pure `.tres` — no script. Complex transforms (skip-highest)
implement `effect(event)`; their trigger match is trivial, their operation is code.

**Events:** one `RefCounted` subclass per seam (`RerollEvent`, `MoveEvent`, `CommitEvent`, …)
— transient runtime envelopes (deliberately NOT Resources: "Resource = static data only" is
already project law). The event carries the seam's working data and owns `matches(effect)`.
Two lifetime rules, as law: **events are consumed during dispatch, never stored** (log
copies, not references) and **effects never hold references to events** (RefCounted has no
cycle collector).

**Dispatch (the one loop, written once per seam):**
`for e in current_effect_list (acquisition order): if event.matches(e): e.effect(event)`.
Acquisition order is the ONLY ordering — deterministic and player-legible ("the order you
took them is the order they fire"); no priority numbers until a design need is proven.
Instance-producing seams (reroll now; damage ledger when the first replay-reaction lands)
run the three-step shape: **transform ops → instance record → react dispatch over the
record.** Question seams (gates) and commit reactions are single-phase dispatches of the
same form. Game code never names a relic; adding relic #N = author one Resource. New SEAM =
one event class + one dispatch call (the priced, rare cost).

**Forensics (day-one, BG3 lesson):**
- **Console trace, toggleable:** the dispatcher prints the full story per event — payload,
  each effect's match/skip **with the failing condition named** ("green_proc? NO —
  condition_element GREEN, got RED"). Volume is structurally bounded (a handful of events
  per turn, one registry).
- **Dispatcher-owned run-log:** every effect that ACTS is auto-logged on the round as
  `"events": [{relic, trigger, delta…}]` — supersedes the hand-wired sparse keys
  (`healed`, `swap_denied`) once migrated; the actual-delta law becomes machinery, not
  discipline. run_log records what acted (analysis); the trace records why/why-not (debug).
  `validate_runlog.py` folds event deltas into reconstruction (it already handles two
  schema eras; this adds a third).

**Preview:** transform phases are pure and shared with the preview path; deterministic
reactions preview (a staged swap of a known-green die shows its +4); `preview_hp_delta`-class
contributions render on the rings (the heal band). First nondeterministic effect forces the
badge policy — explicit escalation trigger.

**BG3-informed boundaries (from the owner's reference architecture):**
- **Boost note:** continuous always-on modifiers (+N base/anti) are pull-shaped, not
  event-shaped. At current scale they ship as always-matching resolve transforms; if they
  multiply, the aggregate-read layer (BG3 Boosts) is the named escape hatch — don't force
  the event system to fake a stat sheet forever.
- **Interrupt note:** reactions that PAUSE resolution for player input (BG3 interrupts) are
  a different mechanism with UI implications — never fold them into the silent-proc chain.

**Escalation triggers** (any one → revisit): cross-effect inspection/cancel; ordering needs
beyond acquisition order; nondeterministic preview policy; interactive reactions; a seam
fitting neither dispatch shape.

## Options Considered (survey summary — full pros/cons argued in-session, 2026-07-07)

| Option | Verdict |
|--------|---------|
| Signal bus (ADR-001 A) | Can't gate/transform; forensics scatter across connections. Rejected (again). |
| Named-hook registry (rev 1/2) | Dispatch by method-override: conditions become code inside relics; not enumerable for tooling/sim/UI. Superseded. |
| Relic-side `handle(event)` (ADR-001 C) | Moves the if-chain inside every relic; judgment invisible to tooling. Superseded. |
| **Event-side judgment (chosen)** | Conditions are declared data → simple relics are pure `.tres`, matches are enumerable (proc UI, sim mirror, auto-log), non-matches are *explainable* (the forensics fix). |
| Pull/query aggregation | Complementary, not competing — named as the boost escape hatch. |
| Command middleware / rules interpreter / ECS / relic-as-Node | Event dispatch in heavier clothing, or forensics-hostile; rejected in survey. |

## Consequences

- **Easier:** stress-case relics expressible day one; simple relics are data; procs
  self-document in log + trace; sim can mirror declaratively; "which relics touch rerolls"
  is a query (powers future proc-highlight UI).
- **Harder:** one event class per seam to keep honest; two lifetime rules to keep; seam
  authors classify (instance-producing vs question).
- **Revisit:** at the escalation triggers; monster-side effects' home; boost layer if flat
  relics multiply.

## Action Items

1. [ ] Scaffold `Effect` + `Event` base + the dispatch loop **with the console trace in the
       same commit** (forensics-first, per the owner's BG3 requirement).
2. [ ] Build the reroll seam (transform ops → `{slot, element, old, new}` record → react
       dispatch); migrate the three protos (regression suite); express the stress-case trio
       as authored `.tres` to prove the data path.
3. [ ] `MoveEvent` gate absorbs `_move_done` + swap-lock behind one ask-point.
4. [ ] Dispatcher-owned run-log `"events"` array; migrate `healed`/`swap_denied`; teach
       `validate_runlog.py` the third schema era.
5. [ ] Wire deterministic preview contributions into `_push_rings` (heal band — closes the
       owner's note).
6. [ ] Findings file stays open; check escalation triggers per new effect.
