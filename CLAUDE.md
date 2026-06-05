Explain current plan before implementing a change and ask for permission. When explaining bring up the reasoning for each decision step by step. When adding comments to code keep it as short as possible. Prioritize using existing code structure. Make explanations short and concise.

# Architecture (Godot 4.6, project root: DragAndDrop/)

Turn-based combat game. Dice carry a roll value + element; player swaps/rotates dice to set up an attack, then ends turn to resolve combat against a monster.

## Autoloads (singletons)
- `Swatch` (Globals/swatch.gd) — color constants + `from_name(key)`. `ELEMENT_COLOR`, `NEON_COLOR`, `HALF` indexed by Element.
- `GlobalSignal` (Globals/globalsignal.gd) — global signal bus (see Signals).
- `CurrentRoll` (Globals/current_roll.gd) — shared combat numbers + per-turn operators.
- `Constants` (Globals/rollables.gd, `class_name Rollables`) — `enum RollIndex {BASE,MULT,ANTI,ANTI_TYPE}`, `enum Element {RED,GREEN,BLUE,WHITE}`. Most gameplay classes `extends Rollables`, so refer to enums bare (`RollIndex.BASE`) or as `Constants.RollIndex`.
- `CombatState` (Globals/combat_state.gd) — the FSM driving the round.
- `View` (Globals/View.gd) — shared camera state for 2D-projected 3D shapes (cubes). Not gameplay.

## Combat flow (CombatState FSM)
`INITIAL → ROUND_START → PLAYER_PLANNING → TURN_RESOLVING → PLAYER_ATTACK → MONSTER_ATTACK → CHECK_DEFEAT → (WIN | LOSE | back to ROUND_START)`. Each enter handler waits a 1s timer. `ROUND_START` calls `round_start()` on every node in group `round_participants` (sorted by `round_start_priority`). Player ends planning via `CombatState.end_player_turn()` (called from swap/rotate).

## Roll data (on CurrentRoll)
- `current_roll_list` / `current_monster_roll_list` = `[base, mult, anti, anti_type]`.
- Player: damage per hit = base (`current_roll_list[0]`), number of hits = mult (`current_roll_list[1]`).
- `anti_operator()` applies anti reductions. `player_attack()` / `monster_attack()` set damage per hit = base (`monster_damage_operator()` is the old base*mult total, now unused).
- `initial_roll` / `initial_monster_roll` snapshot pre-anti values (used by `get_reduced_roll` for announcements).

Both attacks are staggered coroutines (`attack_stagger`, default 0.3s): a miss loop then a hit loop, awaited by the FSM. Player and monster mirror each other.

## Signals (GlobalSignal)
- `player_attacked` — once per surviving hit in `CurrentRoll.player_attack()`; `monster.gd:monster_hit()` subtracts `player_damage` each time (HP chunks per hit).
- `player_missed` — once per hit lost to anti (no HP change).
- `player_attack_finished` — after the loops.
- `monster_attacked` — once per surviving hit in `CurrentRoll.monster_attack()`; `player_character.gd:player_hit()` subtracts `monster_damage` each time.
- `monster_missed` — once per monster hit lost to anti.
- `monster_atack_finished` (note the typo) — fires once after the monster loops; `monster.gd:_announce_attack()` and `player_character.gd:announce_damage_taken()` log here so announcements fire once, not per hit.
- `updated_roll` — dice/roll changed; player_character, slime current_roll, etc. refresh.
- `announced(String)` — `announce.gd` appends to combat log label.
- `swap_started(Dice)` — `mouse.gd` reparents the dragged die.

## Scene map
`combat_ui.tscn` (root, no script) → `VBoxContainer2`:
- `MarginContainer/Slime` (slime.tscn, `class_name Monster`) + `Anouncement` (announce.gd) + `DamageNumberZone` (damage_number_zone.tscn).
- `MarginContainer2/Playercontainer` (player_vbox.tscn → `PlayerCharacter`): `Rotate` (rotate.gd) + `Swap` (swap.gd) with `Zone1..3` each holding a `Dice`.
- `StateLabel` (State.gd) shows current FSM state.

Dice (dice.gd, `class_name Dice`): value Label over a spinning wireframe `Cube` (cube_2d.gd). Zones (zone.gd) track hover/swap flags; swap.gd & rotate.gd read those flags in `_input` on left mouse up/down.

## Damage numbers
`damage_number_zone.gd` lives only on the `DamageNumberZone` node (instanced under Slime); it has a `DamageNumber` child (damage_number_rich_text_label.tscn, `class_name DamageNumber`). `show_damage_number()` duplicates the child and pops it. Type ref uses `preload` alias + null guards.

The single zone reacts to BOTH sides: player signals → player pop variants (tween up); monster signals → `_monster` variants (tween down). Same miss/block/number logic, read from the player vs monster roll lists.

Pop variants on the label, chosen by what `anti_operator()` reduced (each has a `_monster` twin that tweens down via `pop_show_monster()`):
- `pop_show_number(n)` — no reduction; plain damage.
- `pop_show_block(original, blocked)` — `base` (damage/hit) was reduced; shows `BLOCKED original - blocked`.
- `pop_show_miss()` — for each hit lost to `mult` reduction. e.g. mult 8→5 = 5 damage pops + 3 MISS pops.

## Quirks / gotchas
- `Globals/state.gd` is obsolete (flow moved to CombatState) — safe to ignore.
- RichTextEffect outline pass (`char_fx.outline`) never fires in Godot 4.6 — halo outer ring via shader/effect doesn't work; bitmap-font fallback planned.
- Two files named `current_roll.gd`: the autoload (Globals/) vs the slime's roll display (character/monster/slime/).
- `damage_number.gd` (combat_ui/) is a near-empty stub, distinct from damage_number_label.gd.