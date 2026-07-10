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
	roll_dice()      # controller owns rolling now (rework dice don't self-roll)
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


# DEAL: a single number when exact, "lo~hi" when a swap gamble is staged.
func _push_deal(r: Dictionary) -> void:
	_damage_preview.value = _range_str(r.deal[0], r.deal[1])
	_damage_preview.sub = "exact" if r.deal[0] == r.deal[1] else "gamble"


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


# Updates the phase label from the FSM state + current fight number.
func _push_phase() -> void:
	_phase_label.text = "%s · fight %d" % [_phase_word(CombatState.current_state), Encounter.current_monster_order + 1]


func _on_state_changed(from, to) -> void:
	if from == CombatState.State.PLAYER_PLANNING and _swap_lock_rounds > 0:
		_swap_lock_rounds -= 1   # one locked planning phase spent (status duration tick)
	if to == CombatState.State.PLAYER_PLANNING:
		roll_dice()          # fresh hand each round (values reroll; elements persist), then snapshot it
		_snapshot()          # cancel restores THIS round's rolled hand
		_turn_action = {"type": "pass"}   # default; a swap/rotate overwrites it
		RunLog.begin_round(_dice_snapshot(), CurrentRoll.current_monster_roll_list.duplicate(),
			_player.hp.current_hp, _monster.hp.current_hp)
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
	CurrentRoll.current_roll_list = CurrentRoll.get_roll_from_dice(_values, _elements)   # publish the committed roll for the FSM
	RunLog.record_action(_turn_action, _dice_snapshot())
	_fire_rotate_heal()   # reaction proto — on COMMIT, not on staging, so Cancel can't farm it
	CombatState.end_player_turn()


# Reaction proto: a committed rotate heals relic_rotate_heal_amount. Logs the ACTUAL
# healed amount (a near-full heal clamps at max_hp), so the run log stays reconstructible.
func _fire_rotate_heal() -> void:
	if not relic_rotate_heal or _turn_action.get("type") != "rotate":
		return
	if not _player or not _player.hp:
		return
	var before : int = _player.hp.current_hp
	_player.hp.current_hp += relic_rotate_heal_amount
	var healed : int = _player.hp.current_hp - before
	if healed > 0:
		RunLog.record_heal(healed)


# --- relic protos (ADR-002: bare functions + debug grants until ADR-003 picks machinery) ---
@export var relic_skip_highest : bool = false   # "the current highest die skips its reroll"
@export var debug_swap_lock : int = 0           # status proto: swap denied for N rounds at each fight start
@export var relic_rotate_heal : bool = false    # reaction proto: committing a rotate heals (amount below)
@export var relic_rotate_heal_amount : int = 10 # big on purpose — exercises the max-HP clamp + the actual-delta logging

var _swap_lock_rounds : int = 0   # planning phases left that deny swap (ticks down as rounds resolve)


# The gate: input asks, the owner decides — effects veto here, never in TrayInput.
func can_swap() -> bool:
	return _swap_lock_rounds <= 0


# Denial feedback for a gated swap. Proto: console print + a run-log flag; the real
# "how does a denied verb read" UX is an open ui-spec question (see proto findings).
func notify_swap_denied() -> void:
	print("swap denied")
	RunLog.record_swap_denied()


# Names of the active relic/status grants, for the run log.
func _active_relics() -> Array:
	var out : Array = []
	if relic_skip_highest:
		out.append("skip_highest")
	if debug_swap_lock > 0:
		out.append("swap_lock_%d" % debug_swap_lock)
	if relic_rotate_heal:
		out.append("rotate_heal")
	return out


# The relic's target, chosen at the moment of use (live values, not precomputed).
# First slot wins ties.
func _skip_highest_slot() -> int:
	var best : int = 0
	for i in range(1, _values.size()):
		if _values[i] > _values[best]:
			best = i
	return best


# --- helpers ---------------------------------------------------------------
func roll_dice() -> void:
	var skip : int = _skip_highest_slot() if relic_skip_highest else -1
	for i in _values.size():
		if i != skip:
			_values[i] = randi_range(1, 6)
	_reset_pending()


# Spawns the lean Monster, fed by the current MonsterResource (set before it enters the tree).
func _spawn_monster() -> void:
	_swap_lock_rounds = debug_swap_lock   # status proto: each fight opens swap-locked for N rounds
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
		var roll : Array = CurrentRoll.get_roll_from_dice(vals, _elements)
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
