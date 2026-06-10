extends Rollables

var monster_roll_list

@onready var label1: Label = $Add/CenterContainer/Label
@onready var label2: Label = $Mult/CenterContainer/Label
@onready var label3: Label = $Subtract/CenterContainer/Label

var anti_type_name = [
	"Block",
	"Miss",
	"Anti",
	"",
]


func _ready():
	update_text()
	GlobalSignal.updated_roll.connect(update_text)
	

func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(update_text)

func update_text():
	label1.text = "base %d" % [CurrentRoll.current_monster_roll_list[RollIndex.BASE]]
	label2.text = "mult %d" % [CurrentRoll.current_monster_roll_list[RollIndex.MULT]]
	var anti_index = CurrentRoll.current_monster_roll_list[RollIndex.ANTI_TYPE]
	label3.text = "%s -%d" % [ anti_type_name[anti_index] ,CurrentRoll.current_monster_roll_list[2]]
