extends HBoxContainer

@onready var zone1: Zone = $Zone1
@onready var zone2: Zone = $Zone2
@onready var zone3: Zone = $Zone3
@onready var zone_list = [zone1, zone2, zone3]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GlobalSignal.updated_roll.connect(update_text)

func _exit_tree() -> void:
	GlobalSignal.updated_roll.disconnect(update_text)


func update_text():
	var player_anti_index = CurrentRoll.action_index_list.find(3)
	var monster_anti_index = CurrentRoll.current_monster_roll_list[3]
	pass
