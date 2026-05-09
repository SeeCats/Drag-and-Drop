extends Node

var base : int =1:
	set(new_value):
		base = new_value
		current_roll_list[0] = new_value

var mult : int=2:
	set(new_value):
		mult = new_value
		current_roll_list[1] = new_value

var anti : int =3:
	set(new_value):
		anti = new_value
		current_roll_list[2] = new_value

var anti_type : int =0:
	set(new_value):
		anti_type = new_value
		current_roll_list[3] = new_value

var current_roll_list = [base, mult, anti, anti_type]
#base mult anti
var current_min_list = []
# base, mult, anti, anti_type
var current_monster_roll_list = [0, 0 , 0, 0]
var current_monter_min_list = [0, 0, 0]

var player_damage : int
var monster_damage : int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func turn_end():
	anti_operator()
	player_attack()

func monster_turn_end():
	monster_damage_operator()

func anti_operator():
	current_monster_roll_list[anti_type] -= anti	
	current_monster_roll_list[anti_type] = max(\
	current_monster_roll_list[anti_type],\
	current_monter_min_list[anti_type])
	
	current_roll_list[current_monster_roll_list[4]] -= current_monster_roll_list[3]
	current_roll_list[current_monster_roll_list[4]] = max(\
	current_min_list[current_monster_roll_list[4]],\
	current_roll_list[current_monster_roll_list[4]]
	)

func player_attack():
	player_damage = current_roll_list[0] * current_roll_list [1]
	GlobalSignal.player_attacked.emit()
	
func monster_damage_operator():
	monster_damage = current_monster_roll_list[0] * current_monster_roll_list[1]
