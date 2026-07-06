# ADR-001: Effect system architecture (relics & status effects)

**Status:** Superseded by ADR-002 (2026-07-06) — the machinery commitment (event pipeline) is withdrawn pending a relic prototype pass; the options analysis and pattern lineage below remain the reference material. Written pre-rework: the migration map at the bottom names code that no longer exists.
**Date:** 2026-06-06
**Deciders:** C (project owner)

## Context

We need relics (permanent, run-long) and status effects (temporary, N rounds) that change game behavior. The behaviors they touch are diverse:

- **Gate** an action — e.g. a status that blocks swap for a round.
- **Transform** a process — e.g. a relic that skips re-rolling the current highest die at round start. The "which die" depends on live dice values, so it must be evaluated at the moment of use, not precomputed.
- **Modify a stat** — e.g. "+2 base", "double base".
- **React** to events — e.g. "on hit, gain shield".

Forces at play:

- Relics are expected to **get weirder over time** and to **interact with each other** (one effect's change should be visible to the next). The explicit goal stated: *all behaviors should pass through all effects.*
- Stack: Godot 4.6 / GDScript. Existing patterns we should reuse — `GlobalSignal` (Observer bus), Resource-based data (`Pattern`), the `round_participants` group, and the `CombatState` FSM.
- Small solo project: readability matters, but openness/extensibility matters more here because the effect catalogue is open-ended.

## Decision

Adopt an **event pipeline (Chain of Responsibility)**:

- Each meaningful behavior is reified as a mutable **`Event`** (typed subclass: `RollEvent`, `SwapEvent`, `AttackEvent`/`DamageEvent`, …) with PRE (modify/cancel) and POST (react) phases.
- An **`EffectPipeline`** (one per Character) holds an ordered `Array[Effect]` and `dispatch(event)` runs the event through every effect in **priority** order; each may read, modify, or cancel it.
- An **`Effect`** is a `Resource` (Type Object) with a single entry point `handle(event, host)`, a `priority`, and an optional `duration`. Reactive effects simply act on POST events — one mechanism covers modifiers and reactions.
- Decision points follow one shape: **build event → dispatch → read it back**.
- Lifecycle via `add_effect()`: `duplicate()` the resource (isolate per-instance state) → `on_apply(host)` → insert and sort by priority. Relics enter from the reward screen (no duration); statuses enter from other effects' `handle()` (carry `duration`, self-remove via `on_remove()`). The effects list is mutated safely during dispatch (iterate a copy / defer changes).

`GlobalSignal` stays for plain UI notifications (damage numbers, announcements); the pipeline is specifically the effect-processing layer.

## Options Considered

### Option A: Pure signal / Observer bus (extend `GlobalSignal`)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Low |
| Extensibility | Low for gates/transforms |
| Interaction between effects | Hard |
| Team familiarity | High (already used) |

**Pros:** Zero new infrastructure; effects just connect/disconnect; great for reactions.
**Cons:** Signals are fire-and-forget — they can't return a value, block an action, or transform data. Gates ("block swap") and transforms ("skip highest die") don't fit. Effect ordering/interaction is awkward.

### Option B: Pull-query holder (hybrid) + signals for reactions
| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium |
| Extensibility | Good for known seams, friction for new ones |
| Interaction between effects | Possible (fold), but per-hook |
| Team familiarity | Medium |

**Pros:** Decision points call one aggregate method (`allows_swap()`, `reroll_set()`); type-safe and readable; little new machinery.
**Cons:** Open only at pre-cut seams — a *new* kind of interception costs three edits (Effect base + holder aggregator + call site). Two mechanisms to keep straight (pull for gates/transforms, signals for reactions). Interaction is per-hook rather than universal.

### Option C: Event pipeline / Chain of Responsibility (**chosen**)
| Dimension | Assessment |
|-----------|------------|
| Complexity | Medium–High (upfront) |
| Extensibility | High — new hook = new event type, no base-class churn |
| Interaction between effects | First-class (sequential mutation + priority) |
| Team familiarity | Lower (must learn the pattern) |

**Pros:** Any effect can touch any behavior; effect-to-effect interaction is free via sequential mutation; priority gives deterministic ordering; one entry method (`handle`) unifies modifiers and reactions.
**Cons:** More ceremony at each call site (build/dispatch/read vs a one-liner); weaker per-site type safety (effects branch on `is`); long mutation chains are harder to debug; priority becomes load-bearing; bigger refactor since each covered behavior must become an event.

## Trade-off Analysis

The deciding force is the requirement that **effects be open-ended and interact**. Option A can't gate/transform at all. Option B handles today's cases cleanly but is closed beyond its predefined seams — exactly the wrong shape for "relics will get weirder." Option C pays an upfront ceremony/learning cost and weaker call-site typing in exchange for unbounded openness and built-in effect interaction. Given the catalogue is expected to grow in unpredictable directions, C's openness outweighs B's simplicity. Priority-based ordering directly answers the interaction requirement (e.g. "+2 base" at prio 10 vs "double base" at prio 20 resolves deterministically).

## Consequences

- **Easier:** adding new effects (incl. unforeseen ones); composing/ordering interacting effects; one mental model (`handle(event)`).
- **Harder:** each behavior must be converted into an event before effects can touch it; reading a value's final state means tracing the dispatch chain; call sites are more verbose.
- **To revisit:** priority conventions (reserve ranges per effect category); whether the pipeline is strictly per-Character or a global one tagging source/target; performance only if effect counts ever grow large (negligible now); a debug/trace mode for dispatch chains if debugging gets painful.

## Action Items

1. [ ] Scaffold `Effect` (Resource), `Event` (base + PRE/POST), and `EffectPipeline` (per-Character) on branch `feature/effect-system`.
2. [ ] Define first event types: `RollEvent`, `SwapEvent`, `AttackEvent`/`DamageEvent`.
3. [ ] Implement `add_effect()` lifecycle (`duplicate()` → `on_apply` → priority sort) and safe list mutation during dispatch.
4. [ ] Convert the first decision points to build→dispatch→read: round-start reroll, swap input gate.
5. [ ] Prove it with the two example effects: skip-highest-reroll relic (transform) and swap-lock status (gate + duration).
6. [ ] Decide pipeline placement (per-Character vs global) and cross-character dispatch convention.
7. [ ] Wire relic acquisition through the reward screen (`RewardChoice.tscn`).

## Pattern lineage (study notes)

The design sits at the intersection of three patterns from *Game Programming Patterns*:

- **Command** — "a reified method call": an action turned into a data object. Our `Event` objects are exactly this. (Command's `execute(actor)` ≈ our `handle(event, host)`.)
- **Chain of Responsibility** — route a reified action through an ordered list of handlers, each free to act on it or pass it on. This is our `EffectPipeline.dispatch()`. Command's own "See Also" explicitly hands off to it.
- **Event Queue** — the *asynchronous* cousin (decouple in time). We deliberately **stay synchronous**: dispatch must return an answer to the caller (e.g. "is this swap allowed?"), and queues are a poor fit when the sender needs a response. Reserve a small deferral buffer only for (a) effect-spawned effects, to avoid mutating the chain mid-dispatch, and (b) sequencing visual reactions.

Framing that falls out of this:
- **PRE phase = command, POST phase = event.** A PRE event effects may modify/cancel is really a *request* (command); a POST notification is a true *event* ("it happened, react").
- **Flyweight / `duplicate()`:** stateful effects (duration, stacks) must be duplicated per instance; purely stateless ones could be shared.

## Current `CurrentRoll` write sites (to migrate)

These are the only places another node currently *writes* `CurrentRoll`. When the pipeline lands, relic/anti behavior should funnel through here (especially `anti_operator`) instead of new code poking `CurrentRoll` directly. Snapshot as of 2026-06-06:

Direct field writes:
- `PlayerCharacter` — `player_character.gd:30–33` (`update_player_dice`): sets `base`, `mult`, `anti`, `anti_type` (via setters → also writes `current_roll_list[0..3]`).
- `Monster` — `monster.gd:37–40` (`update_roll`): sets `current_monster_roll_list[BASE/MULT/ANTI/ANTI_TYPE]` from the pattern.
- `CombatState` — `combat_state.gd:145,151` (`_on_win`/`_on_lose`): sets `is_player_winning`.

Method calls that mutate `CurrentRoll` internally (all driven by `CombatState`):
- ~~`anti_operator()` / `player_attack()` / `monster_attack()`~~ — **REMOVED 2026-06-30** (Code Claude). The whole mutating path is gone; `CurrentRoll.compute_outcome()` (pure, no side effects) is now the live resolver used by both the FSM and the preview, and is the **transform seam for effects** in their place.

> **Design follow-up (flagged):** this section and the "funnel through `anti_operator`" guidance above were written when `anti_operator` was the seam. They need re-pointing at `compute_outcome`. Code removed the methods at the user's direction; the ADR re-write is Design's lane.

Everything else touching `CurrentRoll` is read-only.
