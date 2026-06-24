@tool
extends VBoxContainer
class_name DiceSlot

# One player roll slot: a framed die (value + element) with a role/sub label below.
# DUMB VIEW — the controller pushes value/element/sub in and reads is_inside out.


@export var role : Rollables.RollIndex = Rollables.RollIndex.BASE :
	set(value):
		role = value
		_refresh_label()

@export var element : Rollables.Element = Rollables.Element.RED :
	set(value):
		element = value
		if dice:
			dice.element = value

var is_inside : bool = false   # hovered? the tray controller reads this for swap targeting

@onready var slot : PanelContainer = $Slot
@onready var dice : Dice = $Slot/DiceHolder/Dice
@onready var slot_label : RichLabel = $SlotLabel

var _sub : String = ""         # detail line under the role name ("3/hit", "x3 hits"...)

func _ready() -> void:
	if not Engine.is_editor_hint():
		slot.mouse_entered.connect(func(): is_inside = true)
		slot.mouse_exited.connect(func(): is_inside = false)
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
