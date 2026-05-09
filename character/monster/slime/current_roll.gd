extends HBoxContainer

var monster_roll_list

@onready var label1: Label = $Add/CenterContainer/Label
@onready var label2: Label = $Mult/CenterContainer/Label
@onready var label3: Label = $Subtract/CenterContainer/Label




func ready():
	update_text()
	GlobalSignal.updated_roll.connect(update_text)
	

func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(update_text)

func update_text():
	label1.text = "base %d" % [CurrentRoll.current_monster_roll_list[0]]
	label2.text = "mult %d" % [CurrentRoll.current_monster_roll_list[1]]
	label3.text = "anti \n %s -%d" % [Constants.VARIABLE_TYPE[CurrentRoll.current_monster_roll_list[3]] ,CurrentRoll.current_monster_roll_list[2]]
