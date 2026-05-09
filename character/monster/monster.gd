extends Character
class_name monster

var monster_pattern_list : Array[Pattern] =[]
var current_round : int:
	set(new_value):
		current_round = new_value
		current_pattern = pattern_list[current_round % 3]
@export var pattern_list : Array[Pattern]
var current_pattern : Pattern
@onready var current_roll: HBoxContainer = $VBar/CurrentRoll



func _ready() -> void:
	super()
	current_pattern = pattern_list[current_round]
	update_roll()
	current_roll.update_text()
	GlobalSignal.player_attacked.connect(monster_hit)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func round_start():
	super()
	current_round += 1
	update_roll()

func update_roll():
	CurrentRoll.current_monster_roll_list[0] = current_pattern.base
	CurrentRoll.current_monster_roll_list[1] = current_pattern.mult
	CurrentRoll.current_monster_roll_list[2] = current_pattern.anti
	CurrentRoll.current_monster_roll_list[3] = current_pattern.anti_type
	GlobalSignal.updated_roll.emit()
	
func monster_hit():
	hp.current_hp -= CurrentRoll.player_damage
	monster_attack()
	
func monster_attack():
	GlobalSignal.monster_attacked.emit()
	
	
	
