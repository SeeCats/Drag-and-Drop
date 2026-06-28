Explain current plan before implementing a change and ask for permission. When explaining bring up the reasoning for each decision step by step. Comments: a 1–2 sentence what/how blurb atop each function; keep "why" rare (only real gotchas); no class-header essays, no `# --- section ---` dividers, no line-by-line narration — comment the function, not the lines. Prioritize using existing code structure. Make explanations short and concise.
Be brutally honest about my ideas/implementation and push back if you can find evidence, or against common wisdom.

Do NOT run git commands. This sandbox can't write to `.git` safely (it has corrupted HEAD before). Edit code files only; the user drives all git operations (commit, branch, push) in GitHub Desktop.

When you change code, update this `CLAUDE.md` in the same session so its architecture/signals/scene-map/gotchas stay accurate — stale docs here are worse than none.

# Coordination

The user + a few **topic-focused Claude sessions** work this project. Work in your current task's lane; the shared docs (this file, HISTORY.md, `docs/ui-spec.md`, the GDD) are the coordination layer — keep them current so any session can pick up cold. Topic leads (soft, not strict ownership):

- **Code Claude** — code + scenes; the GDD's "as built" annotations + §11; owns `tools/balance_sim.py` and all sim runs (sim fidelity tracks code ground truth — the `KEEP IN SYNC` gauntlet table — so execution lives here; commits raw output to `docs/sim-results/` per rule 4). Also covers ad-hoc diagnosis/review (no dedicated diagnosis role now).
- **Design Claude** — GDD §1–8 and §10–13 (NOT §9). Doesn't edit code. Requests sims (specifies variant + metric) and prices the committed numbers; doesn't run the sim itself.
- **UI** — `docs/ui-spec.md` and GDD §9. **UI work currently runs in the Code session** (Fable model suspended indefinitely 2026-06-12; a fresh cold Opus UI session underperformed at understanding/implementing UI, while Opus *with* this session's context handles it). `ui-spec.md` is **Code-maintained, user-directed**; color authority = ui-spec, mirrors `Swatch`. If a capable dedicated UI session returns, it reclaims this lane.

Shared rules:
1. Canonical location: every concept is defined in exactly one place; everywhere else cites it — never restate.
2. One-line HISTORY.md entry per GDD / CLAUDE.md / ui-spec edit. Every entry heading names its author.
3. **Lane rule:** work in your current task's topic by default. You MAY edit outside it when a change genuinely needs it — but never silently: make the edit and FLAG it (a HISTORY line **and** call it out to the user in chat) so the topic's lead can review. Same for any code↔doc mismatch you spot — flag where you found it.
4. Sim-citation rule: any sim output whose numbers are cited in a GDD/spec decision gets its raw output committed to `docs/sim-results/` (dated file, script version noted) in the same session. Insights without their data are claims. **Always record version info when simming:** `balance_sim.py` self-stamps `# balance_sim.py sha <hash> | run <date> | <seed/N>` in its printed header (`version_stamp()`) — keep that stamp in any committed or pasted sim output.

# UI work (legibility is make-or-break)

This game lives or dies on legibility (UI-as-precondition, GDD §1.2), so UI is never where we cut corners:
1. **Exhaustive protos.** Any mockup / prototype / visualization must implement EVERY specified feature, not a representative subset — audit against the full ui-spec §8 acceptance criteria before showing it. A partial proto can't tell us whether the design reads.
2. **Ask one at a time.** When a UI request is underspecified, ask single, sequential clarifying questions before building — slower is fine.

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
- `Screenshot` (Globals/screenshot.gd) — debug-only: F12 saves the viewport to `screenshots/` (gitignored) for the ui-spec §8 checklist. Not gameplay; editor/debug builds only (res:// is read-only when exported).
- `Combatants` (Globals/combatants.gd) — live combatant registry: `player` + `monster` node refs. Entities **self-register** in `_ready` (`Combatants.player/monster = self`) and clear in `_exit_tree` (guarded `== self`, so a respawn's new monster isn't clobbered by the old one's clear). Lets the FSM read both HPs without scanning `round_participants`. Refs, not NodePaths (paths go stale on respawn/reparent).

## Combat flow (CombatState FSM)
`INITIAL → ROUND_START → PLAYER_PLANNING → TURN_RESOLVING → PLAYER_ATTACK → MONSTER_ATTACK → (WIN | LOSE | back to ROUND_START)`. Each enter handler waits a 1s timer. `ROUND_START` calls `round_start()` on every node in group `round_participants` (sorted by `round_start_priority`). Player ends planning via `CombatState.end_player_turn()` (called from swap/rotate).

**Death is decoupled from attacks.** Every state ends through one gate, `_advance(next_state)`, which reads `Combatants.player.hp` / `Combatants.monster.hp` (via `_is_dead()` + `is_instance_valid`): player ≤0 → LOSE, else monster ≤0 → WIN, else `next_state`. So a kill from ANY source — a plain attack, a mid-attack hit, or a future round-start DoT — is caught at the next boundary, not just after an attack. Player is checked first, so a mutual kill resolves to LOSE for now (the tie "both win" / `RETREAT` / fight-start-gate model is designed but **parked** until effects exist — see HISTORY 2026-06-25). The old vestigial `CHECK_DEFEAT` state + inline `_is_monster_dead`/`_is_player_dead` group-scans are gone; `State.gd`'s name array mirrors the enum so it stays index-aligned.

The FSM is **not** self-starting: it's kicked by `CombatState.start()` (reset to INITIAL → ROUND_START) on combat load — `combat_rework.gd._ready()` does this for the rework (legacy `combat_ui.gd` did it for the old scene). A proper scene-start/run-reset is still a TODO. **WIN / LOSE are currently terminal in the rework** — the loop lands there and stops (phase shows victory/defeat). The old gauntlet flow (advance `Encounter`, `respawn()` the monster via the `monster_spawner` group, `start()` the next fight; else → menu) was removed from `_on_win`/`_on_lose` because that group doesn't exist in the rework scene (it crashed). Re-implementing gauntlet respawn — owned by the controller, since it spawns monsters — is the next step of #2.

## Roll data (on CurrentRoll)
- `current_roll_list` / `current_monster_roll_list` = `[base, mult, anti, anti_type]`.
- Player: damage per hit = base (`current_roll_list[0]`), number of hits = mult (`current_roll_list[1]`).
- `anti_operator()` applies anti reductions. `player_attack()` / `monster_attack()` set damage per hit = base. `monster_damage_operator()` (old base*mult total) and its only caller `monster_turn_end()` are both dead now.
- `initial_roll` / `initial_monster_roll` snapshot pre-anti values (used by `get_reduced_roll` for announcements).
- `compute_outcome(player_roll, monster_roll)` — **pure** resolver (no side effects): mirrors `anti_operator` + base×mult on copies, returns `{player/monster:{per_hit,hits,total,blocked,misses}}`. The shared seam the preview UI **and the FSM** use; the effect pipeline will hook here too. The FSM now resolves combat through this in `_on_turn_resolving` (→ `CombatState._outcome`); the mutating `anti_operator`/`player_attack`/`monster_attack` path is **dead** (no FSM caller). `current_roll_list` is published by the rework controller on commit; `current_monster_roll_list` by `monster.update_roll` at round start.
- `next_pattern` (a `Pattern`) — the upcoming round's pattern, published by `monster.update_roll`; drives the lookahead label/halo.

The FSM's `_apply_attack(target, side, hit_signal, miss_signal)` is a staggered coroutine (`attack_stagger`, default 0.3s): a miss loop then a hit loop, applying `side.per_hit` straight to the target's `Hp` (`take_damage`) and emitting the per-hit signals for juice only; it bails the instant the target is dead (no over-kill). The lean monster (data set) does **not** connect `monster_hit` (would double-apply); the lean player never had a damage handler. `CurrentRoll.player_attack()`/`monster_attack()` (old signal-emitting versions) are now unused by the FSM.

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
- `MarginContainer2/Playercontainer` (player_vbox.tscn → `PlayerCharacter`): `Rotate` (rotate.gd) + `Swap` (swap.gd) with `Zone1..3` each holding a `Dice`. This is the **fat/legacy** player; the rework uses the lean `character/Player.tscn` instead (see below).
- `StateLabel` (State.gd) shows current FSM state.
Also under the root: `NextPattern` (next_pattern.gd) — lookahead label for the monster's next roll (see Preview UI). `Anouncement` (under Slime) is the shared preview/log readout, not just the log.

Monsters (data-driven): `monster.gd` (`class_name Monster`, extends Character) is the runtime — pattern cycling, HP, `update_roll()` → `CurrentRoll.current_monster_roll_list` + `next_pattern`, takes/deals damage. Its data comes from a `MonsterResource` (`monster/monster_resource/monster_resource.gd` — note the subfolder; uid `k3dthoavmsp4`; fields `monster_name`, `texture`, `max_hp`, `pattern_list: Array[Pattern]`) assigned to `@export var data`; `_ready`→`_load_data()` pulls name/patterns/max_hp from it. Per-monster `.tres` at `character/monster/<name>/<name>.tres`; `Encounter.monster_list` is `Array[MonsterResource]` (loosely typed so the legacy PackedScene spawner still compiles). The rework spawns the **lean** `character/monster/Monster.tscn` (a `Node` + hidden `Hp`, no sprite/roll-display) and sets `data` before adding it. **Resource = static data only; runtime state (current_hp/current_round/current_pattern) lives on the node** — resources are shared + persist to disk. The `$VBar/CurrentRoll` ref in `monster.gd` is `get_node_or_null`-guarded so the lean scene runs; legacy scene-per-monster `<name>.tscn` (sprite/halo/HP-bar/roll-display) leaves `data` null + uses baked `@export`s and is legacy. Player + monster share `character/Hp/hp_bar.tscn` (→ `hp.gd`).

Player (rework): the lean `character/Player.tscn` mirrors the lean Monster — a `Node` running `player_character.gd` + a hidden `HpBar`, nothing else. `player_character.gd` is now **lean-safe** (same trick as `monster.gd`): `$Rotate`/`$Swap` became `get_node_or_null`, and `_ready()` early-returns after `super()` when `rotate` is absent, so the lean entity wires **none** of the legacy combat signals (`updated_roll`/`monster_attacked`/etc.) — it's just HP + `round_participants` membership for the FSM to read. The fat `player_vbox.tscn` (Rotate/Swap present) keeps the full legacy wiring. `combat_rework.gd` spawns it via `_spawn_player()` and reads `_player.hp` in `_push_rings` (the `_player_hp`/`_player_max_hp` vars are now fallback-only, like the monster's).

Dice (dice.gd, `class_name Dice`): value Label over a spinning wireframe `Cube` (cube_2d.gd). Zones (zone.gd) track hover/swap flags; swap.gd & rotate.gd read those flags in `_input` on left mouse up/down. Both `_input` handlers early-return unless `CombatState.current_state == PLAYER_PLANNING`, so dice can't be picked up or committed outside the planning phase.

Cube sizing: the `Cube` is a `Node2D`, so its drawn size comes from the perspective projection (`corner * focal_length / camera_distance`), NOT Control/container sizing. `Cube.fit_to(diameter)` scales the node so its rest silhouette fits `diameter` px (scale multiplies geometry + line widths together). `dice.gd` calls it each frame when `@export fit_to_control` is on (**default true**), so the die tracks its slot size — used by the rework `DiceSlot`. Turn it off only for a fixed-size cube; the old UI dice that wanted fixed sizing now live in a legacy branch and aren't a concern. `Dice.element` has a setter that re-tints the cube (fill+halo) live, so a die can be recoloured when reassigned between slots — not just at `_ready`.

Rework slot widgets (`MainUI/combat_ui/rework/`): `DiceSlot` (`dice_slot/dice_slot.gd`, a dumb `VBoxContainer` — `@export role`/`element` in, `set_value`/`set_sub` in, `is_inside` off `Slot`'s hover out) wraps a reused `dice.tscn`; the controller pushes data in and reads `is_inside`, it never reads game state. `Outliner` (`widgets/outliner.gd`, `PanelContainer`) is a reusable framed panel — a script-built StyleBoxFlat (border + `padding` content-margin), tunable via exports, transparent fill by default. Three `DiceSlot` instances fill `CombatRework.tscn`'s `DiceRow` (roles BASE/MULT/ANTI).

Rework controller (`CombatRework.tscn` root → `combat_rework.gd`, `class_name CombatRework`): the adapter and single state-knower. Owns the player dice (`_values`/`_elements`; model A = roles fixed to columns, dice move). Two channels: **OUT** `render()` (push to dumb widgets) fired on `GlobalSignal.updated_roll` (CONNECT_DEFERRED) + `CombatState.state_changed`; **IN** `request_swap`/`request_rotate`/`cancel`/`commit` (from `TrayInput` + the Cancel/Confirm buttons). Pure helpers on `CurrentRoll`: `get_roll_from_dice(values, elements)` (column-order projection — replaces `player_character._roll_from`) + `compute_outcome`. `_resolve()` runs `compute_outcome` over a staged swap's 1..6 possibilities → min/max ranges (the gamble preview). It reads the monster from the **owner** (`monster.current_pattern` → chips, `monster.hp` → scouter), NOT the `current_monster_roll_list` global (which `anti_operator` mutates mid-resolve). Spawns the monster + lean player in `_ready`, then calls `CombatState.start()` to **drive the FSM**. **Cancel**/**Commit** act only during PLAYER_PLANNING (gated); a fresh snapshot is taken on entering planning so Cancel restores *that* round's hand. **Commit** publishes the roll to `CurrentRoll.current_roll_list`, reveals the gamble, then `end_player_turn()`. WIN/LOSE are terminal for now — controller-owned gauntlet respawn is the next step. `_on_state_changed` calls `render()` on every transition; `_push_rings` sets the rings **only during PLANNING** (the 3-band gamble preview). Outside planning the rings are **tween-driven**: the controller connects each spawned entity's `Hp.hp_changed` to `_on_*_hp_changed` → `RadialBar.tween_to(current)`, so HP drains live per hit during resolve (a kill bleeds the ring to 0). `_sync_rings_exact()` snaps the rings off the preview to live HP once at TURN_RESOLVING (the tween baseline). Handlers skip PLANNING (preview owns the rings) + ROUND_START (regen would fire a no-op flash). All refs via `%`-unique-names. `CurrentRoll` is trending toward a pure *resolver* — owners hold truth (controller=player dice, Monster=its roll+HP), not a god-object.

Rework widgets (`rework/widgets/` + sibling folders): `Chip`/`ChipRow` (monster stat chips; `ChipRow.set_roll(roll)` fans the roll to each child `Chip` by its own `role`, found via recursive `find_children` so wrapping doesn't break it). `DamagePreview` (knob DEAL readout; `value` is a **String** so it shows ranges like `8~14`; a deferred `_pending`/`call_deferred` refresh coalesces value+sub into one rebuild per frame). `DiceSlot.set_unknown()` shows `?` for the hidden swap gamble. `RadialBar` draws a **3-band** ring — bright `value` (sure survivors) + middle `range_amount` (uncertain gamble, `value_color.lerp(secondary_color,0.5)`) + dim `secondary` (sure loss); `set_hp_range(current, dmg_min, dmg_max, max)` (equal min/max collapses the middle = exact; damage is clamped to `current` so an over-kill gamble preview doesn't overflow the bands and pop the ring to full). `tween_to(target)` clears both `secondary` + `range_amount` so the live drain leaves no preview band behind. `TrayInput` (`tray_input/`, a `Node` child of the root, refs via `owner`/`%`): drag a die → `request_swap`, flick the knob horizontally (`flick_threshold` px) → `request_rotate`; `_move_done` enforces one move per turn (reset on Cancel **and on entering each planning phase**, via `state_changed`). `_input` is gated to PLAYER_PLANNING (no dice grabbing mid-resolve). **Swap is a gamble:** the grabbed die is marked `_pending` (NOT rerolled until commit), shows `?`, and DEAL/subs/rings show ranges; commit rerolls + reveals.

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
- **The bash sandbox mount can serve a STALE / truncated view of a file.** Seen 2026-06-12: `wc`/`cat`/`py_compile` reported `tools/balance_sim.py` truncated mid-line at 14701 bytes while the editor (Read tool) had the full, correct file — and the mount stayed frozen at that byte count even after a fresh write. A prior session misread git the same way. **The Read/Write/Edit file tools are the source of truth for file contents; do NOT trust the shell over them when diagnosing "truncation" or "corruption."** A fresh session (or just re-running later) re-syncs the mount. Note: code *executed* via bash reads the (possibly stale) mount, so if a run fails on "truncation" the file is probably fine — verify with Read, don't rewrite blindly.