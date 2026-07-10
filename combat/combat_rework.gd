extends Control
class_name CombatRework
# Controller / adapter for the reworked combat UI (the CombatRework root).
#
# The ONE node that knows about game state. It owns the player's dice (source of truth, model A) and talks to the rest through exactly two narrow channels:
#   OUT  render()        -- state -> dumb widgets (DiceSlot.set_*, chips, DEAL, rings)
#   IN   request_*(...)  -- intents from the input layer -> mutate state -> render()
# Pure helpers live on CurrentRoll (get_roll_from_dice + compute_outcome).

# --- dice state: source of truth. Column order = role order (BASE, MULT, ANTI) ---
var _values : Array[int] = [3, 4, 5]
var _elements : Array[Rollables.Element] = [
	Rollables.Element.RED,
	Rollables.Element.GREEN,
	Rollables.Element.BLUE,
]
# A swapped die rerolls at commit, so its value is unknown until then (the gamble).
var _pending : Array[bool] = [false, false, false]
# round-start snapshot of the dice, for Cancel (full reset to the rolled hand).
var _snapshot_values : Array[int] = []
var _snapshot_elements : Array[Rollables.Element] = []
# The move the player made this turn, for the run log; reset to "pass" each planning phase.
var _turn_action : Dictionary = {"type": "pass"}

# --- HP fallbacks: used only until the spawned entities' Hp nodes resolve ---
var _monster_hp : int = 14
var _monster_max_hp : int = 14
var _player_hp : int = 20
var _player_max_hp : int = 20
var _monster : Monster            # spawned from a MonsterResource; the rework reads its pattern + hp
var _player : PlayerCharacter     # lean entity; the rework reads its hp (mirrors _monster)

# --- dumb view refs ---------------------------------------------------------
@onready var _slots : Array[DiceSlot] = [
	%BaseSlot,
	%MultSlot,
	%AntiSlot,
]
@onready var _chip_row : ChipRow = %ChipRow
@onready var _damage_preview : DamagePreview = %DamagePreview
@onready var _scouter_ring : RadialBar = %ScouterRing
@onready var _monster_texture : TextureRect = %MonsterTexture
@onready var _hp_ring : RadialBar = %HpRing
@onready var _hp_text : RichTextLabel = %HpText
@onready var _phase_label : RichTextLabel = %PhaseLabel
@onready var _cancel_button : Button = %CancelButton
@onready var _confirm_button : Button = %ConfirmButton
# next-hint ref comes next (#11)


func _ready() -> void:
	GlobalSignal.updated_roll.connect(render, CONNECT_DEFERRED)
	CombatState.state_changed.connect(_on_state_changed)
	_cancel_button.pressed.connect(cancel)
	_confirm_button.pressed.connect(commit)
	for e in debug_effects:
		add_effect(e)   # debug grants — must precede the first seam roll (planning entry)
	roll_dice(true)  # boot roll: faces for the pre-FSM render only; the seam does not run
	_snapshot()
	Encounter.current_monster_order = 0   # fresh run starts at the first monster
	_spawn_monster()
	_spawn_player()
	add_child(CombatSfx.new())   # combat hit/miss SFX (replaces the deleted legacy combat_ui.gd audio)
	_spawn_starfield()           # decorative downward starfield behind everything (ui-spec §7)
	RunLog.begin_run(_player.hp.max_hp, _active_relics())   # run history logging
	_log_begin_fight()
	render()
	_sync_rings_exact()   # baseline so rings show real HP before the first planning preview
	CombatState.start()   # drive the FSM from the rework (was only kicked by legacy combat_ui.gd)


# === OUT channel: state -> widgets =========================================
# Repaint from current state. _resolve() folds the swap gamble into min/max ranges.
func render() -> void:
	_push_dice()
	_chip_row.set_roll(_monster_roll())
	var r : Dictionary = _resolve()
	_push_deal(r)
	_push_subs(r)
	_push_rings(r)
	_push_phase()


func _push_dice() -> void:
	for i in _slots.size():
		if _pending[i]:
			_slots[i].set_unknown()      # the gamble: "?" until commit
		else:
			_slots[i].set_value(_values[i])
		_slots[i].set_element(_elements[i])


# DEAL: a single number when exact, "lo~hi" when a swap gamble is staged. Deterministic
# commit-reactions (a staged rotate's heal, a ready commit-blast) preview on the sub line.
func _push_deal(r: Dictionary) -> void:
	_damage_preview.value = _range_str(r.deal[0], r.deal[1])
	var sub : String = "exact" if r.deal[0] == r.deal[1] else "gamble"
	var ev : CommitEvent = _preview_commit()
	if _player and _player.hp:
		if ev.hp_delta > 0:
			var heal : int = clampi(ev.hp_delta, 0, _player.hp.max_hp - _player.hp.current_hp)
			if heal > 0:
				sub += " · +%d hp" % heal
		elif ev.hp_delta < 0:
			sub += " · -%d hp" % mini(-ev.hp_delta, _player.hp.current_hp)   # a staged detonation warns exactly
	if ev.monster_damage > 0:
		sub += " · +%d dmg" % ev.monster_damage
	_damage_preview.sub = sub


# Dry-dispatches the commit seam for the staged action and returns the event so callers
# read any accumulator without applying (ADR-003: effects only mutate the event, so
# preview is exact for free). Trace suppressed — this runs every render.
func _preview_commit() -> CommitEvent:
	var ev := CommitEvent.new()
	ev.trigger = Effect.Trigger.COMMIT
	ev.action = _turn_action
	ev.values = _values
	ev.elements = _elements
	ev.dry = true   # dry-dispatch law: stateful effects must not gain/spend/tick from a preview
	_dispatch(ev, false)
	return ev


# Slot subs from the resolved ranges: per-hit, hit count, defense ("?" if anti pending).
func _push_subs(r: Dictionary) -> void:
	_slots[0].set_sub("%s/hit" % _range_str(r.per_hit[0], r.per_hit[1]))
	_slots[1].set_sub("x%s hits" % _range_str(r.hits[0], r.hits[1]))
	var anti_str : String = "?" if _pending[2] else str(_values[2])
	_slots[2].set_sub("%s -%s" % [_defense_word(_elements[2]), anti_str])


# Maps the anti die's element to its defense word (armor / evade / strip).
func _defense_word(element: Rollables.Element) -> String:
	match element:
		Rollables.Element.RED: return "armor"
		Rollables.Element.GREEN: return "evade"
		Rollables.Element.BLUE: return "strip"
		_: return ""


# Rings: bright = sure survivors, middle = uncertain (gamble range), dim = sure loss.
func _push_rings(r: Dictionary) -> void:
	# Planning: rings show the 3-band gamble preview. Resolving/over: the rings are driven by
	# hp_changed tweens (live drain), so render() leaves them alone here and only updates text.
	var mhp : int = _monster.hp.current_hp if _monster and _monster.hp else _monster_hp
	var mmax : int = _monster.hp.max_hp if _monster and _monster.hp else _monster_max_hp
	var php : int = _player.hp.current_hp if _player and _player.hp else _player_hp
	var pmax : int = _player.hp.max_hp if _player and _player.hp else _player_max_hp
	if CombatState.current_state == CombatState.State.PLAYER_PLANNING:
		_scouter_ring.set_hp_range(mhp, r.deal[0], r.deal[1], mmax)
		_hp_ring.set_hp_range(php, r.take[0], r.take[1], pmax)
		var monster_lo : int = maxi(mhp - r.deal[1], 0)
		var monster_hi : int = maxi(mhp - r.deal[0], 0)
		_hp_text.text = "[center]hp %d → %s[/center]" % [mhp, _range_str(monster_lo, monster_hi)]
	else:
		_hp_text.text = "[center]hp %d[/center]" % mhp


# Snaps both rings to current HP with no preview bands — the live-drain baseline at resolve start.
func _sync_rings_exact() -> void:
	if _monster and _monster.hp:
		_scouter_ring.set_hp_range(_monster.hp.current_hp, 0, 0, _monster.hp.max_hp)
	if _player and _player.hp:
		_hp_ring.set_hp_range(_player.hp.current_hp, 0, 0, _player.hp.max_hp)


# Live HP drain: tween the ring as damage lands. Skipped during planning (preview owns the
# rings) and round start (regen would fire a no-op flash).
func _on_monster_hp_changed(current: int, _maximum: int) -> void:
	if CombatState.current_state in [CombatState.State.PLAYER_PLANNING, CombatState.State.ROUND_START]:
		return
	_scouter_ring.tween_to(current)
	_hp_text.text = "[center]hp %d[/center]" % current


func _on_player_hp_changed(current: int, _maximum: int) -> void:
	if CombatState.current_state in [CombatState.State.PLAYER_PLANNING, CombatState.State.ROUND_START]:
		return
	_hp_ring.tween_to(current)


# Updates the phase label from the FSM state + current fight number. With the debug
# readout on, appends each effect's live state ("surge:2 swap_doom:7 lock(1)") — the
# stopgap until the relic dock (glow/wobble telegraph) is specced.
func _push_phase() -> void:
	var text : String = "%s · fight %d" % [_phase_word(CombatState.current_state), Encounter.current_monster_order + 1]
	if debug_state_readout:
		for e in current_effect_list:
			var s : String = e.state_readout()
			text += "  %s%s%s" % [e.id, ":" + s if s != "" else "", "(%d)" % e.duration if e.duration > 0 else ""]
	_phase_label.text = text


func _on_state_changed(from, to) -> void:
	if from == CombatState.State.PLAYER_PLANNING:
		_tick_statuses()     # status durations are FSM-clocked: one planning phase spent
	if to == CombatState.State.PLAYER_PLANNING:
		move_done = false
		roll_dice()          # fresh hand each round (values reroll; elements persist), then snapshot it
		_snapshot()          # cancel restores THIS round's rolled hand
		_turn_action = {"type": "pass"}   # default; a swap/rotate overwrites it
		RunLog.begin_round(_dice_snapshot(), CurrentRoll.current_monster_roll_list.duplicate(),
			_player.hp.current_hp, _monster.hp.current_hp)
		for entry in _pending_round_events:
			RunLog.record_event(entry)   # roll-seam events fired before the round opened
		_pending_round_events.clear()
	elif to == CombatState.State.TURN_RESOLVING:
		_sync_rings_exact()   # snap rings off the preview to live HP; per-hit tweens drain from here
	elif to == CombatState.State.ROUND_START:
		if from == CombatState.State.MONSTER_ATTACK:
			RunLog.record_result(_player.hp.current_hp, _monster.hp.current_hp)   # round survived → log it
	elif to == CombatState.State.WIN:
		RunLog.record_result(_player.hp.current_hp, _monster.hp.current_hp)
		RunLog.end_fight(_player.hp.current_hp)
		_on_victory.call_deferred()   # deferred so we don't re-enter the FSM mid-transition
	elif to == CombatState.State.LOSE:
		RunLog.record_result(_player.hp.current_hp, _monster.hp.current_hp)
		RunLog.end_fight(_player.hp.current_hp)
		RunLog.end_run("died", _monster.monster_name)
	render()          # repaint chips/deal/dice/phase/text each transition (rings are tween-driven in resolve)


# Maps the FSM state to its status-bar word.
func _phase_word(state: int) -> String:
	match state:
		CombatState.State.PLAYER_PLANNING: return "planning"
		CombatState.State.ROUND_START: return "round start"
		CombatState.State.TURN_RESOLVING, CombatState.State.PLAYER_ATTACK, CombatState.State.MONSTER_ATTACK: return "resolving"
		CombatState.State.WIN: return "victory"
		CombatState.State.LOSE: return "defeat"
		_: return "—"


# Swaps the grabbed die into the target slot; it rerolls at commit, so it's marked pending.
func request_swap(source_slot: int, target_slot: int) -> void:
	_swap(_values, source_slot, target_slot)
	_swap(_elements, source_slot, target_slot)
	_pending[target_slot] = true
	_turn_action = {"type": "swap", "from": source_slot, "to": target_slot}
	move_done = true
	render()


# Drag-rotate: cycles the row so the dragged die (src slot) lands on tgt; every other
# die shifts along with it. No reroll, no gamble. drop_global = the release point, so
# the dragged die's value visibly settles from where the player let go.
func request_rotate_to(src: int, tgt: int, drop_global: Vector2) -> void:
	var n : int = _values.size()
	var shift : int = ((tgt - src) % n + n) % n
	var rests : Array[Vector2] = []
	for s in _slots:
		rests.append(s.dice.global_position)   # capture before render/flights
	_shift_right(_values, shift)
	_shift_right(_elements, shift)
	_turn_action = {"type": "rotate", "from": src, "to": tgt}
	move_done = true
	render()
	_animate_rotate(shift, tgt, drop_global, rests)


# Rotate presentation (FLIP): values are final after render(), so each die flies in from
# its value's source slot; a wrap jump (>1 column) arcs over the row instead of teleporting
# (ui-spec §5). The drop target's die instead settles in from the release point — the
# dragged die visibly landing where it was put.
func _animate_rotate(shift: int, tgt: int, drop_global: Vector2, rests: Array[Vector2]) -> void:
	var n : int = _slots.size()
	for i in n:
		if i == tgt:
			_slots[i].dice.fly_from(drop_global - _slots[i].dice.size / 2, 0.0)
			continue
		var src : int = (i - shift + n) % n
		var arc : float = _slots[i].dice.size.y * 1.2 if absi(i - src) > 1 else 0.0
		_slots[i].dice.fly_from(rests[src], arc)


# Cancel: full reset of this turn's planning back to the round-start hand.
func cancel() -> void:
	if CombatState.current_state != CombatState.State.PLAYER_PLANNING:
		return   # buttons act only during planning
	_reset_pending()
	_values = _snapshot_values.duplicate()
	_elements = _snapshot_elements.duplicate()
	_turn_action = {"type": "pass"}   # cancelled → back to no move for the log
	move_done = false
	render()


# Confirm: reveal the gamble, then end planning so the FSM resolves (no-op until FSM).
func commit() -> void:
	if CombatState.current_state != CombatState.State.PLAYER_PLANNING:
		return   # buttons act only during planning
	for i in _pending.size():
		if _pending[i]:
			_values[i] = randi_range(1, 6)
	if _turn_action.get("type") == "swap":
		_turn_action["rerolled"] = _values[_turn_action["to"]]   # the gamble reveal
	_reset_pending()
	render()
	CurrentRoll.current_roll_list = _project(_values, _elements, true)   # publish through the projection seam
	RunLog.record_action(_turn_action, _dice_snapshot())
	_fire_commit_event()   # reactions fire on COMMIT, not staging, so Cancel can't farm them
	CombatState.end_player_turn()


# The commit seam: dispatch, apply the accumulators (clamped by Hp), auto-log actual deltas.
# Commit blasts hit the monster here (pre-resolution); a kill is caught by the FSM's
# _advance at the next boundary, same as round-start chip damage.
func _fire_commit_event() -> void:
	var ev := CommitEvent.new()
	ev.trigger = Effect.Trigger.COMMIT
	ev.action = _turn_action
	ev.values = _values
	ev.elements = _elements
	_dispatch(ev)
	if ev.acted.is_empty():
		return
	var entry : Dictionary = {"trigger": "COMMIT", "acted": ev.acted}
	if ev.hp_delta != 0 and _player and _player.hp:
		var before : int = _player.hp.current_hp
		_player.hp.current_hp += ev.hp_delta
		entry["delta_player_hp"] = _player.hp.current_hp - before
	if ev.monster_damage > 0 and _monster and _monster.hp:
		var m_before : int = _monster.hp.current_hp
		_monster.hp.take_damage(ev.monster_damage)
		entry["delta_monster_hp"] = _monster.hp.current_hp - m_before
	RunLog.record_event(entry)


# --- effect system (ADR-003: event dispatch, event-side judgment) ----------
@export var debug_effects : Array[Effect] = []   # drag relic/status .tres here (debug grants until a reward flow exists)
@export var effect_trace : bool = false          # console forensics: prints every dispatch's match/skip story
@export var debug_state_readout : bool = false   # phase label shows each effect's live state (charges/cooldowns) — playtest aid until the relic dock exists

var current_effect_list : Array[Effect] = []     # acquisition order = application order
var move_done : bool = false                     # one swap/rotate per turn (owner-side; TrayInput asks)
var _pending_round_events : Array = []           # seam events fired before begin_round; flushed after it


# Duplicates the resource in — per-instance runtime state (duration, cooldowns, charges)
# is EXPORTED state by project convention: the .tres value is the authored start, and the
# duplicate gives each instance its own copy (the shared resource is never mutated).
func add_effect(e: Effect) -> void:
	current_effect_list.append(e.duplicate())


# The one dispatch loop (ADR-003): acquisition order; the EVENT judges; effects mutate the
# event; the calling seam applies results. `acted` records only effects that genuinely DID
# something (effect() returned true) — matched-but-idle (cooldowns, empty targets) traces
# as such and stays out of the log.
func _dispatch(event: GameEvent, trace: bool = true) -> GameEvent:
	for e in current_effect_list:
		var verdict : String
		if event.matches(e):
			if e.effect(event):
				event.acted.append({"relic": e.id, "trigger": Effect.Trigger.keys()[event.trigger]})
				verdict = "ACTED"
			else:
				verdict = "matched, idle"
		else:
			verdict = _skip_reason(event, e)
		if effect_trace and trace:
			print("[FX %s] %s -> %s" % [Effect.Trigger.keys()[event.trigger], e.id, verdict])
	return event


# Trace detail for a non-match: name the reason (the BG3 lesson — silence about non-matches
# is what makes event systems hell to debug).
func _skip_reason(event: GameEvent, e: Effect) -> String:
	if (e.triggers & (1 << event.trigger)) == 0:
		return "skip (listens to %s)" % _trigger_names(e.triggers)
	return "skip (condition failed)"


# "COMMIT+PROJECT_ROLL"-style readout of a triggers bitmask, for the trace.
func _trigger_names(mask: int) -> String:
	var names : Array = []
	for i in Effect.Trigger.size():
		if mask & (1 << i):
			names.append(Effect.Trigger.keys()[i])
	return "+".join(names) if names.size() > 0 else "nothing"


# Dice → roll through the projection seam: pure get_roll_from_dice, then a PROJECT_ROLL
# dispatch that may modify the roll (e.g. resonance spending charges into MULT). ALWAYS
# dry — this runs inside every preview trial, so effects read state but never change it.
# log=true (the commit publish only): a modified roll is recorded so the validator can
# reconstruct deal/take it could no longer derive from the dice alone.
func _project(values: Array, elements: Array, log: bool = false) -> Array:
	var roll : Array = CurrentRoll.get_roll_from_dice(values, elements)
	var ev := ProjectRollEvent.new()
	ev.trigger = Effect.Trigger.PROJECT_ROLL
	ev.values.assign(values)
	ev.elements = elements
	ev.roll = roll
	_dispatch(ev, log)   # trace the publish; preview trials would spam
	if log and not ev.acted.is_empty():
		RunLog.record_event({"trigger": "PROJECT_ROLL", "acted": ev.acted, "roll": roll.duplicate()})
	return roll


# Status durations tick when a planning phase ends; expired statuses self-remove.
func _tick_statuses() -> void:
	for e in current_effect_list.duplicate():
		if e.duration > 0:
			e.duration -= 1
			if e.duration == 0:
				current_effect_list.erase(e)


# The swap gate (MoveEvent dispatch): input asks, the owner decides, effects veto.
func can_swap() -> bool:
	var ev := MoveEvent.new()
	ev.trigger = Effect.Trigger.MOVE_GATE
	ev.verb = "swap"
	_dispatch(ev)
	if not ev.allowed:
		print("swap denied")
		RunLog.record_event({"trigger": "MOVE_GATE", "denied": "swap", "acted": ev.acted})
	return ev.allowed


# Active effect ids (statuses tagged with remaining duration), for the run log.
func _active_relics() -> Array:
	var out : Array = []
	for e in current_effect_list:
		out.append(e.id if e.duration == 0 else "%s_%d" % [e.id, e.duration])
	return out


# --- helpers ---------------------------------------------------------------
# Planning-entry roll = the reroll seam (ADR-003): PRE_ROLL mask → base roll → POST_ROLL
# ops → REROLLED reactions → seam applies accumulators. Base-roll instances enter the
# record tagged source "base"; effect ops tag "op" — reactions declare which count
# (condition_include_base). plain = values only, NO seam: the _ready boot roll (dice need
# faces before the FSM starts, no monster exists, and the planning-entry roll replaces it).
func roll_dice(plain: bool = false) -> void:
	if plain:
		for i in _values.size():
			_values[i] = randi_range(1, 6)
		_reset_pending()
		return
	var ev := RollEvent.new()
	ev.values = _values
	ev.elements = _elements
	for _i in _values.size():
		ev.base_mask.append(true)
	ev.trigger = Effect.Trigger.PRE_ROLL
	_dispatch(ev)
	for i in _values.size():
		if ev.base_mask[i]:
			ev.reroll_slot(i, "base")
	ev.trigger = Effect.Trigger.POST_ROLL
	_dispatch(ev)
	ev.trigger = Effect.Trigger.REROLLED
	_dispatch(ev)
	_apply_roll_reactions(ev)
	_reset_pending()


# Applies the roll seam's accumulators. Round-start chip damage goes straight to the
# monster's Hp — the FSM's _advance catches a kill at the next boundary (death is already
# decoupled from attacks). Events are buffered: begin_round hasn't opened the round yet.
func _apply_roll_reactions(ev: RollEvent) -> void:
	if ev.acted.is_empty():
		return
	var entry : Dictionary = {"trigger": "ROLL", "acted": ev.acted, "rerolled": ev.rerolled.duplicate(true)}
	if ev.monster_damage > 0 and _monster and _monster.hp:
		var before : int = _monster.hp.current_hp
		_monster.hp.take_damage(ev.monster_damage)
		entry["delta_monster_hp"] = _monster.hp.current_hp - before
		if _monster.hp.current_hp <= 0:
			CombatState.check_boundary.call_deferred()   # chip-kill between boundaries: don't leave a dead round waiting for a commit
	_pending_round_events.append(entry)


# Spawns the lean Monster, fed by the current MonsterResource (set before it enters the tree).
func _spawn_monster() -> void:
	_monster = preload("res://character/monster/Monster.tscn").instantiate() as Monster
	_monster.data = Encounter.next_monster
	add_child(_monster)
	_monster.hp.hp_changed.connect(_on_monster_hp_changed)   # live ring drain during resolve
	_push_monster_texture()   # show this monster's portrait in the scouter


# Pushes the current monster's portrait (its MonsterResource.texture) onto the scouter MonsterTexture.
func _push_monster_texture() -> void:
	if _monster_texture and _monster and _monster.data:
		_monster_texture.texture = _monster.data.texture


# Spawns the lean PlayerCharacter (HP + state only); the rework reads its hp, mirroring the monster.
func _spawn_player() -> void:
	_player = preload("res://character/Player.tscn").instantiate() as PlayerCharacter
	add_child(_player)
	_player.hp.hp_changed.connect(_on_player_hp_changed)   # live ring drain during resolve


# Spawns the decorative starfield on a back CanvasLayer (layer -1 → renders behind the whole UI).
func _spawn_starfield() -> void:
	var bg : CanvasLayer = CanvasLayer.new()
	bg.layer = -1
	add_child(bg)
	bg.add_child(Starfield.new())


# On WIN: advance the gauntlet and start the next fight (player + HP persist). Already
# deferred out of the FSM transition by the call_deferred, so no extra wait needed.
# Last monster cleared → stay on the victory screen (run-complete flow is a later step).
func _on_victory() -> void:
	if Encounter.current_monster_order >= Encounter.monster_list.size() - 1:
		RunLog.end_run("cleared")   # last monster down — run logged
		return
	Encounter.current_monster_order += 1
	_respawn_monster()
	CombatState.start()


# Swaps the dead monster for the next gauntlet entry; only the monster is replaced.
func _respawn_monster() -> void:
	if is_instance_valid(_monster):
		_monster.queue_free()
	_spawn_monster()
	_sync_rings_exact()   # show the new monster at full immediately (no 0-flash before planning)
	_log_begin_fight()    # open the next fight's log record (player + HP persist)


# THIS round's monster roll [base, mult, anti, anti_type]. Reads current_monster_roll_list —
# the value update_roll() wrote for this round, which is exactly what the FSM resolves with.
# NOT _monster.current_pattern: round_start advances that to NEXT round's pattern right after
# writing, so reading it made the chips/preview show one turn ahead of what actually resolved.
func _monster_roll() -> Array:
	return CurrentRoll.current_monster_roll_list


# Resolves the outcome over the pending die's 1..6 (or once if none); returns min/max ranges.
func _resolve() -> Dictionary:
	var slot : int = _pending_slot()
	var trials : Array = [1, 2, 3, 4, 5, 6] if slot != -1 else [-1]
	var monster_roll : Array = _monster_roll()
	var deal : Array[int] = []
	var take : Array[int] = []
	var per_hit : Array[int] = []
	var hits : Array[int] = []
	for v in trials:
		var vals : Array = _values.duplicate()
		if slot != -1:
			vals[slot] = v
		var roll : Array = _project(vals, _elements)   # projection seam: previews see roll-modifying effects
		var o : Dictionary = CurrentRoll.compute_outcome(roll, monster_roll)
		deal.append(o.player.total)
		take.append(o.monster.total)
		per_hit.append(o.player.per_hit)
		hits.append(o.player.hits)
	return {
		"deal": [deal.min(), deal.max()],
		"take": [take.min(), take.max()],
		"per_hit": [per_hit.min(), per_hit.max()],
		"hits": [hits.min(), hits.max()],
	}


# Index of the pending (gamble) slot, or -1.
func _pending_slot() -> int:
	for i in _pending.size():
		if _pending[i]:
			return i
	return -1


func _reset_pending() -> void:
	_pending = [false, false, false]


# "5" when lo == hi, else "5~8".
func _range_str(lo: int, hi: int) -> String:
	return str(lo) if lo == hi else "%d~%d" % [lo, hi]


# Saves the current dice as the round-start hand for Cancel.
func _snapshot() -> void:
	_snapshot_values = _values.duplicate()
	_snapshot_elements = _elements.duplicate()


# Opens a run-log fight record for the current monster (player HP carries in).
func _log_begin_fight() -> void:
	if _monster and _monster.hp and _player and _player.hp:
		RunLog.begin_fight(_monster.monster_name, _monster.hp.max_hp, _player.hp.current_hp)


# Current dice as [[value, element_name], ...] for the run log.
func _dice_snapshot() -> Array:
	var out : Array = []
	for i in _values.size():
		out.append([_values[i], _element_name(_elements[i])])
	return out


func _element_name(element: Rollables.Element) -> String:
	match element:
		Rollables.Element.RED: return "RED"
		Rollables.Element.GREEN: return "GREEN"
		Rollables.Element.BLUE: return "BLUE"
		Rollables.Element.WHITE: return "WHITE"
		_: return "?"


# Swaps two entries of an array in place.
func _swap(arr: Array, i: int, j: int) -> void:
	var t = arr[i]; arr[i] = arr[j]; arr[j] = t


# Cycles an array k steps right in place (the last k entries wrap to the front).
func _shift_right(arr: Array, k: int) -> void:
	for _i in k:
		arr.push_front(arr.pop_back())
