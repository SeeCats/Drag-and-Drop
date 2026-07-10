# ADR-003 evidence: relic proto findings

Working notes for the ADR-002 proto pass — each relic lands as a bare function + debug
grant, gets played, and its observations accumulate here. When the pass is done, this
file is the evidence ADR-003 (effect machinery choice) argues from. Keep entries honest:
what shape the code wanted, what questions the relic surfaced, no machinery speculation.

---

## 1. skip_highest — "the current highest die skips its reroll" (2026-07-06)

**Class:** round-start transform (ADR-001's "Transform a process").
**Grant:** `@export var relic_skip_highest` on `CombatRework` (inspector toggle).
**Run log:** runs now carry `"relics": [...]` for segmentation (empty = vanilla).

**Where it landed:** inside `combat_rework.roll_dice()` — a skip-slot computed from live
values at the moment of use (`_skip_highest_slot()`, first slot wins ties). **It never
touches the resolver.** First hard evidence that "effects" have at least two distinct
seams: roll-set construction (here) vs ledger construction (the odd-instance example).
Any machinery must serve both without forcing one seam's shape onto the other.

**Shape the code wanted:** `(live values) -> which slots reroll`. As a bare function:
4 lines + a branch. A pipeline version would be a RollEvent carrying a reroll mask —
fine, but nothing about THIS relic needed priorities, phases, or cancellation.

**Preview impact:** none — acts before planning starts, values are final by the time
anything previews. Exact by construction.

**Verified in play (2026-07-07):** two logged runs with the grant (run_log lines 19–20, both
cleared). Kept die survived all 10 round transitions, including a two-6s tie (leftmost kept,
the other rerolled 6→1). Relic segmentation field works. Throwaway code confirmed throwaway-
quality-proof: zero issues.

**Play-discovered property (user, 2026-07-07):** the leftmost tie-break is *player-steerable* —
on a tied-highest hand, your swap/rotate this turn chooses which slot (and therefore which
ELEMENT) carries the kept die into next round. The relic silently extends move decisions one
turn into the future (positioning = reroll policy), and since the anti column's element is your
defense mode, "which color keeps the 6" is strategically real. Double-edged: genuine
depth-per-gesture, but fully invisible (no UI tell) — a rule most players will never know
exists. Evidence for ADR-003: effect rules that read *position* interact with the verbs
themselves, not just the numbers.

**Questions surfaced (for Design / later relics):**
- *First-roll semantics:* the grant also applies to the `_ready()` roll, so the authored
  default hand's highest (the editor-set 5) survives into round 1 of fight 1. Harmless
  today, but "do relics engage on run-start rolls?" is a real rule to write down.
- *Tie-break:* first slot wins. Fine until a relic cares about elements.
- *UI tell:* the kept die is invisible as an effect — nothing marks "this die was held."
  ui-spec §7's motion grammar suggests the answer (kept die skips the roll-reveal
  tumble), but that needs the roll-reveal animation to exist first.
- *State home:* the grant lives on the controller (the player-state owner, model A).
  Worked cleanly here; the swap-lock status (a *duration* on a *gate*) will stress this.

---

## 2. swap_lock — "swap denied for N rounds at each fight start" (2026-07-07)

**Class:** action gate + the first *status* (duration, ticks, self-expires).
**Grant:** `@export var debug_swap_lock : int` on `CombatRework` (N = locked planning phases
per fight; applied in `_spawn_monster`, so initial spawn + every gauntlet respawn).

**Where it landed:** three small pieces, three different homes — itself a finding:
- the RULE (`can_swap()` reading `_swap_lock_rounds`) on the controller — input asks, owner
  decides; effects veto at the owner, never in TrayInput;
- the TICK in `_on_state_changed` (decrements when a planning phase ends — a status duration
  is FSM-clocked, not wall-clocked);
- the ASK in `TrayInput._tap` (first tap = swap intent; denial short-circuits selection).

**Denial feedback:** proto = `print("swap denied")` + a `"swap_denied": N` count on the
round's run-log record (sparse key; player bounced off a gate N times that round — real
frustration telemetry). The actual "how does a denied verb *read*" UX (shake? grayed dice?
lock icon?) is an open ui-spec question — do NOT ship a status that silently eats taps.

**Observation for ADR-003:** the game now has TWO verb-limiting rules in TWO homes —
`_move_done` (one move per turn, input-side bookkeeping) and swap-lock (owner-side gate).
They're the same *kind* of thing; machinery should probably unify them behind one ask-point.

**Questions surfaced:** does a lock survive across fights (currently resets per fight — a
*run-scoped* status would need a different home)? Should rotate be gateable symmetrically
(nothing needs it yet — don't build it, note it)? Duration display (a "locked ×2" chip?) —
ui-spec lane.

---

## 3. rotate_heal — "committing a rotate regains 1 HP" (2026-07-07, user: never shipping, seam probe only)

**Class:** reaction — the first effect that *responds to an event* instead of transforming a
computation. (Chosen over on-hit-shield: reacts to a VERB rather than a replay event, and
needs no new stat. The during-replay reaction class is still unprobed — noted in coverage.)
**Grant:** `@export var relic_rotate_heal` on `CombatRework`.

**The trap it surfaced (why this proto earned its keep):** rotate is instant-staged but
CANCELABLE. A reaction firing on the gesture is farmable (rotate→cancel→rotate = infinite
HP). Reactions to player actions must fire on **commit**, not on staging — that's now a rule
(`_fire_rotate_heal()` runs in `commit()`). Any future machinery needs a first-class notion
of "the action actually happened" vs "the action is staged."

**Second find — logging vs reconstruction:** a mid-round HP gain breaks the run log's
deal/take = HP-delta assumption. Fix shape: log the *actual* effect delta (`"healed": N`,
sparse; a full-HP heal clamps to 0 and logs nothing) and teach `validate_runlog.py` to
offset expected take by it. Generalizes: every effect that touches HP outside the ledger
must report its actual delta or the log stops being reconstructible.

**Also:** the heal fires while the FSM is still in PLANNING, where the HP-ring tween handler
deliberately early-returns — the ring catches up at `_sync_rings_exact()` one beat later.
Fine at 0.1s beats; a slower pacing would show a lag. Reaction-feedback timing is a real
choreography question for the machinery.

**⚑ NOTE TO SELF (user, 2026-07-07): if heal ever ships for real, the preview must show it.**
With the relic on, the planning preview currently under-promises: staging a rotate shows
projected take on the HP ring but not the incoming heal — a deterministic, commit-certain
effect the preview omits, which violates the preview-exactness pillar (GDD §1.2 pillar 2 /
ui-spec T1 "previews are exact"). Deterministic reactions must feed the same preview path the
resolver does (e.g. a "heal band" on the ring, the green twin of the dim take band). This is
a machinery requirement, not polish: whatever shape effects take, their deterministic part
must be previewable.

---

## Coverage note (pass closed by user, 2026-07-07)

Three protos probed: roll-set transform / gate+duration status / commit-reaction. **Unprobed:
ledger-construction effects (odd-instance shape) and during-replay reactions (on-hit-X).**
ADR-003 should commit machinery for the evidenced classes and mark the replay-reaction story
provisional until the first real one forces it.
