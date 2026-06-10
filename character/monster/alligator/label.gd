extends Label


@export_enum("base", "mult", "anti", "anti_type") var variable_type : int
var variable_name_list = ["base", "mult", "anti", "anti_type"]
var variable_name = variable_name_list[variable_type as int]
@export var variable_size: int = 0

 

 
func _ready() -> void:
	variable_name = variable_name_list[variable_type as int]
	GlobalSignal.updated_roll.connect(_update_text)
	_update_text()
 
 
func _update_text() -> void:
	variable_size = CurrentRoll.current_monster_roll_list[variable_type as int]
	text = "%s\n%d" % [variable_name, variable_size]


func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(_update_text)
