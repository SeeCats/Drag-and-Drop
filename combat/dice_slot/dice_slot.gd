@tool
extends VBoxContainer
class_name DiceSlot

# One player roll slot: a framed die (value + element) with a role/sub label below.
# DUMB VIEW — the controller pushes value/element/sub in; input hit-testing is
# rect-based in TrayInput (no hover state here).


@export var role : Rollables.RollIndex = Rollables.RollIndex.BASE :
	set(value):
		role = value
		_refresh_label()

@export var element : Rollables.Element = Rollables.Element.RED :
	set(value):
		element = value
		if dice:
			dice.element = value

@onready var slot : PanelContainer = $Slot
@onready var dice : Dice = $Slot/DiceHolder/Dice
@onready var slot_label : RichLabel = $SlotLabel

var _sub : String = ""         # detail line under the role name ("3/hit", "x3 hits"...)

func _ready() -> void:
	if dice:
		dice.element = element   # push the authored element into the die
	_refresh_label()

# --- dumb setters the controller calls ---
func set_value(v: int) -> void:
	if dice:
		dice.current_roll = v

# Shows the die face as a hidden gamble ("?") until commit reveals it.
func set_unknown() -> void:
	if dice:
		dice.fake_roll()

func set_element(e: Rollables.Element) -> void:
	element = e

func set_sub(text: String) -> void:
	_sub = text
	_refresh_label()

# Shine while this slot is a valid target (drag drop / second tap). The slot's visible
# frame is the wrapping Outliner in the combat scene — this scene has no border of its
# own — so both marks delegate to the parent.
func set_highlight(on: bool) -> void:
	var frame := get_parent() as Outliner
	if frame:
		frame.set_highlight(on)


# Steady "chosen" mark for the first tap of a swap.
func set_selected(on: bool) -> void:
	var frame := get_parent() as Outliner
	if frame:
		frame.set_selected(on)

# --- internal ---
func _refresh_label() -> void:
	if not slot_label:
		return
	slot_label.text = "[center]%s[/center]\n[center]%s[/center]" % [_role_name(role), _sub]

func _role_name(r: int) -> String:
	match r:
		Rollables.RollIndex.BASE: return "Base"
		Rollables.RollIndex.MULT: return "Mult"
		Rollables.RollIndex.ANTI: return "Anti"
		_: return ""
