@tool
extends PanelContainer
class_name Chip

# Monster stat chip: a value over a role name (base / mult / anti). 
# the controller calls set_value(); the chip formats the number by its own role.

@export var role : Rollables.RollIndex = Rollables.RollIndex.BASE :
	set(value):
		role = value
		_refresh()

var _value : int = 0
var _anti_type : int = -1   # the anti's element (which player factor it cuts); -1 = unset

@onready var value_label : RichTextLabel = $ChipBox/ValueLabel

func set_value(v: int) -> void:
	_value = v
	_refresh()


# For the ANTI chip: the anti's element, so the label shows its type (armor/evade/strip).
func set_anti_type(element: int) -> void:
	_anti_type = element
	_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not value_label:
		return
	var label : String = _role_name(role)
	if role == Rollables.RollIndex.ANTI and _anti_type >= 0:
		label = _anti_word(_anti_type)   # show the anti's type (armor/evade/strip), not just "anti"
	value_label.text = "[center]%s[/center]\n[center]%s[/center]" % [_format_value(_value), label]

# returns 3 if base or anti, x3 if mult
func _format_value(v: int) -> String:
	return ("x%d" % v) if role == Rollables.RollIndex.MULT else str(v)

func _role_name(r: int) -> String:
	match r:
		Rollables.RollIndex.BASE: return "base"
		Rollables.RollIndex.MULT: return "mult"
		Rollables.RollIndex.ANTI: return "anti"
		_: return ""


# The anti's element → the factor it cuts. Mirrors combat_rework._defense_word.
func _anti_word(element: int) -> String:
	match element:
		Rollables.Element.RED: return "armor"
		Rollables.Element.GREEN: return "evade"
		Rollables.Element.BLUE: return "strip"
		_: return "anti"
