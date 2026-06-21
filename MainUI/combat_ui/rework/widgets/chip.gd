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

@onready var value_label : RichTextLabel = $ChipBox/ValueLabel

func set_value(v: int) -> void:
	_value = v
	_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	if not value_label:
		return
	value_label.text = "[center]%s[/center]\n[center]%s[/center]" % [_format_value(_value), _role_name(role)]

# returns 3 if base or anti, x3 if mult
func _format_value(v: int) -> String:
	return ("x%d" % v) if role == Rollables.RollIndex.MULT else str(v)

func _role_name(r: int) -> String:
	match r:
		Rollables.RollIndex.BASE: return "base"
		Rollables.RollIndex.MULT: return "mult"
		Rollables.RollIndex.ANTI: return "anti"
		_: return ""
