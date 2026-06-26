extends Control
class_name CombatRework
# Controller / adapter for the reworked combat UI (the CombatRework root).
#
# The ONE node that knows about game state. It owns the player's dice (source of
# truth, model A) and talks to the rest through exactly two narrow channels:
#   OUT  render()        -- state -> dumb widgets (DiceSlot.set_*, chips, DEAL, rings)
#   IN   request_*(...)  -- intents from the input layer -> mutate state -> render()
# Pure helpers live on CurrentRoll (get_roll_from_dice + compute_outcome). Keeping
# ALL the coupling here means the backend (CurrentRoll today, an event pipeline
# later) can change without touching a single widget. The scene tree is authored
# in the editor; this script only holds refs and moves data across the two channels.

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
	_spawn_monster()
	_spawn_player()
	render()


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
	var mhp : int = _monster.hp.current_hp if _monster and _monster.hp else _monster_hp
	var mmax : int = _monster.hp.max_hp if _monster and _monster.hp else _monster_max_hp
	_scouter_ring.set_hp_range(mhp, r.deal[0], r.deal[1], mmax)
	var monster_lo : int = maxi(mhp - r.deal[1], 0)
	var monster_hi : int = maxi(mhp - r.deal[0], 0)
	_hp_text.text = "[center]hp %d → %s[/center]" % [mhp, _range_str(monster_lo, monster_hi)]
	var php : int = _player.hp.current_hp if _player and _player.hp else _player_hp
	var pmax : int = _player.hp.max_hp if _player and _player.hp else _player_max_hp
	_hp_ring.set_hp_range(php, r.take[0], r.take[1], pmax)


# Updates the phase label from the FSM state + current fight number.
func _push_phase() -> void:
	_phase_label.text = "%s · fight %d" % [_phase_word(CombatState.current_state), Encounter.current_monster_order + 1]


func _on_state_changed(_from, _to) -> void:
	_push_phase()


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
	render()


# 3-cycles the dice through the fixed-role slots; +1 forward, -1 back. No reroll, no gamble.
func request_rotate(direction: int) -> void:
	_cycle(_values, direction)
	_cycle(_elements, direction)
	render()


# Cancel: full reset of this turn's planning back to the round-start hand.
func cancel() -> void:
	_reset_pending()
	_values = _snapshot_values.duplicate()
	_elements = _snapshot_elements.duplicate()
	render()


# Confirm: reveal the gamble, then end planning so the FSM resolves (no-op until FSM).
func commit() -> void:
	for i in _pending.size():
		if _pending[i]:
			_values[i] = randi_range(1, 6)
	_reset_pending()
	render()
	CombatState.end_player_turn()


# --- helpers ---------------------------------------------------------------
func roll_dice() -> void:
	for i in _values.size():
		_values[i] = randi_range(1, 6)
	_reset_pending()


# Spawns the lean Monster, fed by the current MonsterResource (set before it enters the tree).
func _spawn_monster() -> void:
	_monster = preload("res://character/monster/Monster.tscn").instantiate() as Monster
	_monster.data = Encounter.next_monster
	add_child(_monster)


# Spawns the lean PlayerCharacter (HP + state only); the rework reads its hp, mirroring the monster.
func _spawn_player() -> void:
	_player = preload("res://character/Player.tscn").instantiate() as PlayerCharacter
	add_child(_player)


# The monster's intended roll [base, mult, anti, anti_type], read from its pattern (the owner).
func _monster_roll() -> Array:
	if _monster and _monster.current_pattern:
		var p : Pattern = _monster.current_pattern
		return [p.base, p.mult, p.anti, p.anti_type]
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


# Swaps two entries of an array in place.
func _swap(arr: Array, i: int, j: int) -> void:
	var t = arr[i]; arr[i] = arr[j]; arr[j] = t


# Rotates an array one step in place; dir >= 0 moves last to front, else first to end.
func _cycle(arr: Array, dir: int) -> void:
	if dir >= 0:
		arr.push_front(arr.pop_back())
	else:
		arr.push_back(arr.pop_front())
