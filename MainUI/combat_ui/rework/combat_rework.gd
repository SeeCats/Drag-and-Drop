extends Control
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

# --- HP state: stubbed until real sources (player node + MonsterResource) exist ---
var _monster_hp : int = 14
var _monster_max_hp : int = 14
var _player_hp : int = 20
var _player_max_hp : int = 20

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
# next-hint ref comes next (#11)


func _ready() -> void:
	GlobalSignal.updated_roll.connect(render, CONNECT_DEFERRED)
	CombatState.state_changed.connect(_on_state_changed)
	roll_dice()      # controller owns rolling now (rework dice don't self-roll)
	render()


# === OUT channel: state -> widgets =========================================
func render() -> void:
	# Repaint every widget from current state: dice + chips, then resolve for DEAL + subs.
	_push_dice()
	_chip_row.set_roll(CurrentRoll.current_monster_roll_list)
	var roll : Array = CurrentRoll.get_roll_from_dice(_values, _elements)
	var outcome : Dictionary = CurrentRoll.compute_outcome(roll, CurrentRoll.current_monster_roll_list)
	_damage_preview.value = outcome.player.total
	_damage_preview.sub = "exact"
	_push_subs(outcome)
	_push_rings(outcome)
	_push_phase()


func _push_dice() -> void:
	for i in _slots.size():
		_slots[i].set_value(_values[i])
		_slots[i].set_element(_elements[i])


# Sets each slot's sub line from the resolved outcome: per-hit, hit count, defense.
func _push_subs(outcome: Dictionary) -> void:
	var p : Dictionary = outcome.player
	_slots[0].set_sub("%d/hit" % p.per_hit)
	_slots[1].set_sub("x%d hits" % p.hits)
	_slots[2].set_sub("%s -%d" % [_defense_word(_elements[2]), _values[2]])


# Maps the anti die's element to its defense word (armor / evade / strip).
func _defense_word(element: Rollables.Element) -> String:
	match element:
		Rollables.Element.RED: return "armor"
		Rollables.Element.GREEN: return "evade"
		Rollables.Element.BLUE: return "strip"
		_: return ""


# Pushes monster + player HP to the rings: bright = survivors, dim = at-risk this turn.
func _push_rings(outcome: Dictionary) -> void:
	var monster_projected : int = maxi(_monster_hp - outcome.player.total, 0)
	_scouter_ring.set_hp(_monster_hp, monster_projected, _monster_max_hp)
	_hp_text.text = "[center]hp %d → %d[/center]" % [_monster_hp, monster_projected]
	var player_projected : int = maxi(_player_hp - outcome.monster.total, 0)
	_hp_ring.set_hp(_player_hp, player_projected, _player_max_hp)


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



# The input layer 
func request_swap(_source_slot: int, _target_slot: int) -> void:
	pass   # model-A swap (reroll grabbed die) on _values/_elements, then render()


func request_rotate(_direction: int) -> void:
	pass   # 3-cycle the dice through the fixed-role slots (no reroll), then render()


# --- helpers ---------------------------------------------------------------
func roll_dice() -> void:
	for i in _values.size():
		_values[i] = randi_range(1, 6)
