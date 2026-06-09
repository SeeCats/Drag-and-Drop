extends Label


var variable_name_list = ["base", "mult", "anti", "anti_type"]


func _ready() -> void:
	GlobalSignal.updated_roll.connect(_update_text)
	_update_text()


func _update_text() -> void:
	var anti_type_index: int = CurrentRoll.current_monster_roll_list[3]
	var anti_type_name: String = variable_name_list[anti_type_index]
	var anti_amount: int = CurrentRoll.current_monster_roll_list[2]
	text = "anti %s\n%d" % [anti_type_name, anti_amount]


func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(_update_text)
