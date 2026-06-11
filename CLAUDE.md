Explain current plan before implementing a change and ask for permission. When explaining bring up the reasoning for each decision step by step. When adding comments to code keep it as short as possible. Prioritize using existing code structure. Make explanations short and concise.
Be brutally honest about my ideas/implementation and push back if you can find evidence, or against common wisdom.

Do NOT run git commands. This sandbox can't write to `.git` safely (it has corrupted HEAD before). Edit code files only; the user drives all git operations (commit, branch, push) in GitHub Desktop.

When you change code, update this `CLAUDE.md` in the same session so its architecture/signals/scene-map/gotchas stay accurate — stale docs here are worse than none.

# Multi-Claude coordination

Four Claudes + the user work this project. Identify your role each session; stay in lane.

- **Fable (diagnosis)** — reviews code/design/UI/playtests; returns verdicts and work orders in chat. Edits only CLAUDE.md/HISTORY.md, on request. Spot-checks other roles' diffs.
- **Code Claude** — implements code and scenes. Owns the GDD's "as built" annotations + §11. When a code change contradicts design prose, FLAG it in HISTORY.md — don't rewrite.
- **Design Claude** — owns GDD §1–8 and §10–13 (NOT §9). Doesn't edit code.
- **UI Claude** — owns `docs/ui-spec.md` and GDD §9. Produces specs with acceptance criteria; Code Claude builds them. Visual color authority = ui-spec, which mirrors `Swatch` (code ground truth).

Shared rules:
1. Canonical location: every concept is defined in exactly one place; everywhere else cites it — never restate.
2. One-line HISTORY.md entry per GDD / CLAUDE.md / ui-spec edit.
3. Fable's work orders: execute, then log what was done AND skipped (with reason) in HISTORY.md.
4. Code↔doc mismatches: flagged by whoever finds them, fixed by the owning role.
5. Sim-citation rule: any sim output whose numbers are cited in a GDD/spec decision gets its raw output committed to `docs/sim-results/` (dated file, script version noted) in the same session. Insights without their data are claims.

# Session history

Maintain `HISTORY.md` (same folder). At the end of any session that changes code or makes a design decision, prepend a new dated entry (newest on top): what changed, why, and any open threads. Keep it concise — narrative trail only; code-level detail stays here in `CLAUDE.md`.

# Architecture (Godot 4.6, project root = repo root)

Turn-based combat game. Dice carry a roll value + element; player swaps/rotates dice to set up an attack, then ends turn to resolve combat against a monster.

## Autoloads (singletons)
- `Swatch` (Globals/swatch.gd) — color constants + `from_name(key)`. `ELEMENT_COLOR`, `NEON_COLOR`, `HALF` indexed by Element.
- `GlobalSignal` (Globals/globalsignal.gd) — global signal bus (see Signals).
- `CurrentRoll` (Globals/current_roll.gd) — shared combat numbers + per-turn operators.
- `Constants` (Globals/rollables.gd, `class_name Rollables`) — `enum RollIndex {BASE,MULT,ANTI,ANTI_TYPE}`, `enum Element {RED,GREEN,BLUE,WHITE}`. Most gameplay classes `extends Rollables`, so refer to enums bare (`RollIndex.BASE`) or as `Constants.RollIndex`.
- `CombatState` (Globals/combat_state.gd) — the FSM driving the round.
- `View` (Globals/View.gd) — shared camera state for 2D-projected 3D shapes (cubes). Not gameplay.
- `Encounter` (Globals/encounter.gd) — gauntlet selector: `monster_list` (PackedScenes) + `current_monster_order`; `next_monster` is a getter returning `monster_list[order % size]`. The monster spawner reads `next_monster`.

## Combat flow (CombatState FSM)
`INITIAL → ROUND_START → PLAYER_PLANNING → TURN_RESOLVING → PLAYER_ATTACK → MONSTER_ATTACK → CHECK_DEFEAT → (WIN | LOSE | back to ROUND_START)`. Each enter handler waits a 1s timer. `ROUND_START` calls `round_start()` on every node in group `round_participants` (sorted by `round_start_priority`). Player ends planning via `CombatState.end_player_turn()` (called from swap/rotate).

The FSM is **not** self-starting: `combat_ui.gd` calls `CombatState.start()` (reset to INITIAL → ROUND_START) on each combat load — ad-hoc so restarts after a loss work; a proper scene-start/run-reset is a TODO. **WIN**: if the `Encounter` gauntlet has more monsters, advance `current_monster_order`, `respawn()` the monster (player + HP persist), and `start()` a new round; else reset order → WIN menu. **LOSE** resets order → LOSE menu.

## Roll data (on CurrentRoll)
- `current_roll_list` / `current_monster_roll_list` = `[base, mult, anti, anti_type]`.
- Player: damage per hit = base (`current_roll_list[0]`), number of hits = mult (`current_roll_list[1]`).
- `anti_operator()` applies anti reductions. `player_attack()` / `monster_attack()` set damage per hit = base. `monster_damage_operator()` (old base*mult total) and its only caller `monster_turn_end()` are both dead now.
- `initial_roll` / `initial_monster_roll` snapshot pre-anti values (used by `get_reduced_roll` for announcements).
- `compute_outcome(player_roll, monster_roll)` — **pure** resolver (no side effects): mirrors `anti_operator` + base×mult on copies, returns `{player/monster:{per_hit,hits,total,blocked,misses}}`. The shared seam the preview UI uses and the effect pipeline will hook. Live combat still resolves the mutating way above.
- `next_pattern` (a `Pattern`) — the upcoming round's pattern, published by `monster.update_roll`; drives the lookahead label/halo.

Both attacks are staggered coroutines (`attack_stagger`, default 0.3s): a miss loop then a hit loop, awaited by the FSM. Player and monster mirror each other.

## Signals (GlobalSignal)
- `player_attacked` — once per surviving hit in `CurrentRoll.player_attack()`; `monster.gd:monster_hit()` subtracts `player_damage` each time (HP chunks per hit).
- `player_missed` — once per hit lost to anti (no HP change).
- `player_attack_finished` — after the loops.
- `monster_attacked` — once per surviving hit in `CurrentRoll.monster_attack()`; `player_character.gd:player_hit()` subtracts `monster_damage` each time.
- `monster_missed` — once per monster hit lost to anti.
- `monster_atack_finished` (note the typo) — fires once after the monster loops; `monster.gd:_announce_attack()` and `player_character.gd:announce_damage_taken()` log here so announcements fire once, not per hit.
- `updated_roll` — dice/roll changed; player_character, slime current_roll, etc. refresh.
- `announced(String)` — `announce.gd` appends to combat log.
- `swap_started(Dice)` — `mouse.gd` reparents the dragged die.
- `preview_set(String)` / `preview_clear` — hover preview: `swap.gd`/`rotate.gd` emit a hypothetical readout while dragging; `announce.gd` shows it, reverts on clear.

## Preview UI
- `announce.gd` (on `Anouncement`) is a dual readout: PREVIEW (`Deal X  Take Y` from `compute_outcome`, recomputed on `updated_roll` via `CONNECT_DEFERRED` so the player roll refreshes first) vs LOG (combat log). A horizontal swipe *started on the label* toggles modes.
- Hover preview: `player_character.preview_rotate(src,tgt)` (single value) / `preview_swap(src,tgt)` (`Deal X~Y` range over the 6 reroll values — swap reroll is unpreviewable by design, so it shows stakes not result). `swap.gd`/`rotate.gd` `_process` polls the hovered zone during a drag and emits `preview_set`/`preview_clear`.
- `Pattern` (character/monster/pattern/pattern.gd) is a Resource: `type` (`enum Type {HEAVY,FLURRY,GUARDED,SPIKE}` — authored role) + `base/mult/anti/anti_type`. `next_pattern.gd` (on `NextPattern` label) shows the next roll as `Base: N  Mult: N  Block/Miss: N` (Block if `anti_type==BASE`, else Miss). Role/type is meant to be conveyed by a halo color (deferred).

## Scene map
`combat_ui.tscn` root runs `combat_ui.gd` (kicks the FSM via `start()`, plus juice: screen shake + hit/miss SFX). Under `VBoxContainer2`:
- `MarginContainer/Slime` — a plain `Control` running `monster_spawner.gd` (no longer a baked slime). On load it instantiates `Encounter.next_monster` as a child filling the slot; `respawn()` swaps it between gauntlet fights. Its children `Anouncement` (announce.gd) and `DamageNumberZone` (damage_number_zone.tscn) are combat UI and persist across monster swaps.
- `MarginContainer2/Playercontainer` (player_vbox.tscn → `PlayerCharacter`): `Rotate` (rotate.gd) + `Swap` (swap.gd) with `Zone1..3` each holding a `Dice`.
- `StateLabel` (State.gd) shows current FSM state.
Also under the root: `NextPattern` (next_pattern.gd) — lookahead label for the monster's next roll (see Preview UI). `Anouncement` (under Slime) is the shared preview/log readout, not just the log.

Monsters: one scene per monster at `character/monster/<name>/<name>.tscn` (alien, alligator, ghost, slime, slimeboss), each with `monster.gd` (`class_name Monster`), an exported `pattern_list: Array[Pattern]`, HP, and a sprite. Player and every monster share `character/monster/hp_bar.tscn` (→ `hp.gd` + `slime/hplabel.gd`); the monster sets its own name on its HP label, the player leaves it blank.

Dice (dice.gd, `class_name Dice`): value Label over a spinning wireframe `Cube` (cube_2d.gd). Zones (zone.gd) track hover/swap flags; swap.gd & rotate.gd read those flags in `_input` on left mouse up/down. Both `_input` handlers early-return unless `CombatState.current_state == PLAYER_PLANNING`, so dice can't be picked up or committed outside the planning phase.

## Damage numbers
`damage_number_zone.gd` lives only on the `DamageNumberZone` node (instanced under Slime); it has a `DamageNumber` child (damage_number_rich_text_label.tscn, `class_name DamageNumber`). `show_damage_number()` duplicates the child and pops it. Type ref uses `preload` alias + null guards.

The single zone reacts to BOTH sides: player signals → player pop variants (tween up); monster signals → `_monster` variants (tween down). Same miss/block/number logic, read from the player vs monster roll lists.

Pop variants on the label, chosen by what `anti_operator()` reduced (each has a `_monster` twin that tweens down via `pop_show_monster()`):
- `pop_show_number(n)` — no reduction; plain damage.
- `pop_show_block(original, blocked)` — `base` (damage/hit) was reduced; shows two lines: `Blocked` / `original -blocked`.
- `pop_show_miss()` — for each hit lost to `mult` reduction. e.g. mult 8→5 = 5 damage pops + 3 MISS pops.

## Quirks / gotchas
- `Globals/state.gd` is obsolete (flow moved to CombatState) — safe to ignore.
- RichTextEffect outline pass (`char_fx.outline`) never fires in Godot 4.6 — halo outer ring via shader/effect doesn't work; bitmap-font fallback planned.
- Many `current_roll.gd` files: the autoload (`Globals/current_roll.gd`, combat numbers) vs a per-monster roll-display copy in each `character/monster/<name>/` folder. Those folders also carry duplicated display scripts (blurry_halo, glow, etc.) copied when monsters were branched from slime.
- `damage_number.gd` (combat_ui/) is a near-empty stub, distinct from damage_number_label.gd.
- `hp.gd`: `max_hp`/`current_hp` are `@export` (set per monster in inspector). Setters guard `if label:` because `@export` assignment fires before `@onready var label`. HP **persists across a gauntlet** — only the monster is freed/respawned between fights; the player node survives.
- Monster pattern cycling: `round_start()` calls `update_roll()` *before* `current_round += 1`, so round 1 uses `pattern[0]` (no skip).
- Autoloads `CombatState` and `Encounter` persist across scene reloads, so run-state resets (FSM, gauntlet order) are manual — currently in `combat_ui.gd` `start()` and the win/lose handlers.
- **Don't use `:=` on autoload method calls.** `var o := CurrentRoll.compute_outcome(...)` fails to parse on a cold `.godot/` cache ("Cannot infer the type of 'o'") — GDScript's analyzer doesn't reliably resolve a method's return type through an autoload singleton until the class registry is built. A warm cache hides it, so it can pass on one machine and break after another deletes `.godot/`. Annotate explicitly instead: `var o: Dictionary = CurrentRoll.compute_outcome(...)`. (Fixed at `player_character.gd` preview_rotate/preview_swap and `announce.gd._update_preview`.) When such a script fails to compile, scenes that instance its `class_name` (e.g. `PlayerCharacter`) can hard-crash the editor on scene-restore (null script deref) — open in Recovery Mode to break the loop.