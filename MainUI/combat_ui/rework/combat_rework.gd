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

# --- dumb view refs ---------------------------------------------------------
@onready var _slots : Array[DiceSlot] = [
	%BaseSlot,
	%MultSlot,
	%AntiSlot,
]
@onready var _chip_row : ChipRow = %ChipRow
# DEAL / rings / phase refs get added in the display-wiring pass (#11)


func _ready() -> void:
	GlobalSignal.updated_roll.connect(render, CONNECT_DEFERRED)
	roll_dice()      # controller owns rolling now (rework dice don't self-roll)
	render()


# === OUT channel: state -> widgets =========================================
func render() -> void:
	# Side-effecting (void): the "output" is the widgets changing, not a return value.
	_push_dice()
	_chip_row.set_roll(CurrentRoll.current_monster_roll_list)


func _push_dice() -> void:
	for i in _slots.size():
		_slots[i].set_value(_values[i])
		_slots[i].set_element(_elements[i])



# The input layer 
func request_swap(_source_slot: int, _target_slot: int) -> void:
	pass   # model-A swap (reroll grabbed die) on _values/_elements, then render()


func request_rotate(_direction: int) -> void:
	pass   # 3-cycle the dice through the fixed-role slots (no reroll), then render()


# --- helpers ---------------------------------------------------------------
func roll_dice() -> void:
	for i in _values.size():
		_values[i] = randi_range(1, 6)
